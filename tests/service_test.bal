import ballerina/http;
import ballerina/test;
import ballerina/sql;
import ballerina/log;

http:Client testClient = check new ("http://localhost:9090/object-monitor");

@test:BeforeSuite
function beforeSuiteFunc() returns error? {
    log:printInfo("We are going to start the tests in Object Monitoring System");
}

@test:Config {}
function testHealthCheck() returns error? {
    http:Response res = check testClient->get("/health-check");
    test:assertEquals(res.statusCode, 200);
}

@test:Config {}
function testPopulateTables() returns error? {
    http:Response res = check testClient->get("/populate-tables");
    test:assertEquals(res.statusCode, 200);
    return ();
}

type U record {|
    int id;
    string firstName;
    string lastName;
    string username;
    string password;
    boolean isAdmin;
|};

@test:Config {dependsOn: [testPopulateTables]}
function testSignUp() returns error? {
    http:Response res1 = check testClient->post("/signup", {
        firstName: "Saman",
        lastName: "Kumara",
        username: "samankumara007",
        password: "1qa2ws3edRF",
        isAdmin: false
    });
    test:assertEquals(res1.statusCode, 200);

    stream<U, error?> resStream = mysqlClient->query(`SELECT * from object_monitor.users WHERE username = 'samankumara007'`);
    check resStream.forEach(function(U user) {
        test:assertEquals(user.id, 1);
        test:assertEquals(user.firstName, "Saman");
        test:assertEquals(user.lastName, "Kumara");
        test:assertEquals(user.username, "samankumara007");
        test:assertEquals(user.password, "1qa2ws3edRF");
        test:assertEquals(user.isAdmin, false);
    });
    check resStream.close();

    res1 = check testClient->post("/signup", {
        firstName: "Saman",
        lastName: "Kumara",
        username: "samankumara008",
        password: "1qa2ws3edRF",
        isAdmin: false
    });
    test:assertEquals(res1.statusCode, 200);

    resStream = mysqlClient->query(`SELECT * from object_monitor.users`);
    int i = 1;
    check resStream.forEach(function(U user) {
        test:assertEquals(user.id, i);
        i = i + 1;
    });

    http:Response res2 = check testClient->post("/signup", {
        firstName: "Saman",
        lastName: "Kumara",
        username: "samankumara007",
        password: "1qa2ws3edRF",
        isAdmin: false
    });
    test:assertEquals(res2.statusCode, 500);
    test:assertEquals(check res2.getTextPayload(), "Cannot register the user");

    http:Response res3 = check testClient->post("/signup", {
        firstName: "Samanx",
        lastName: "Kumaray",
        username: "samankumara007",
        Password: "1qa2ws3edRFz",
        isAdmin: false
    });
    test:assertEquals(res3.statusCode, 400);
    return ();    
}

@test:Config {dependsOn: [testSignUp]}
function testLogin() returns error? {
    http:Response res1 = check testClient->post("/login", {
        username: "samankumara007",
        password: "1qa2ws3edRF"
    });
    test:assertEquals(res1.statusCode, 200);
    test:assertEquals(check res1.getJsonPayload(), {
        firstName : "Saman",
        lastName : "Kumara",
        userID : 1,
        username : "samankumara007",
        isAdmin : false
    });

    http:Response res2 = check testClient->post("/login", {
        username: "samankumara007",
        password: "1qa2ws3edRf"
    });
    test:assertEquals(res2.statusCode, 500);
    test:assertEquals(check res2.getTextPayload(), "Invalid credentials");

    http:Response res3 = check testClient->post("/login", {
        username: "samankumara009",
        password: "1qa2ws3edRF"
    });
    test:assertEquals(res3.statusCode, 500);
    test:assertEquals(check res3.getTextPayload(), "Invalid credentials");

    http:Response res4 = check testClient->post("/login", {
        username: "samankumara007",
        Password: "1qa2ws3edRF"
    });
    test:assertEquals(res4.statusCode, 400);
}

type ObjData record {|
    string id; 
    string latitude;
    string longitude;
    int timestamp;
|};

@test:Config {dependsOn: [testPopulateTables]}
function testPostObjData() returns error? {
    http:Response res1 = check testClient->post("/object-data", {
        "id" : "00001",
        "longitude" : "2345.45",
        "latitude" : "3.45"
    });
    test:assertEquals(res1.statusCode, 200);

    stream<ObjData, error?> resStream = mysqlClient->query(`SELECT * from object_monitor.object_data`);
    check resStream.forEach(function(ObjData d) {
        test:assertEquals(d.id, "00001");
        test:assertEquals(d.longitude, "2345.45");
        test:assertEquals(d.latitude, "3.45");
        test:assertTrue(d.timestamp > 0);
    });
    check resStream.close();
    _ = check deleteObj("00001");
    res1 = check testClient->post("/object-data", {
        "id" : "00001",
        "longitude" : "2345.45",
        "latitudee" : "3.45"
    });
    test:assertEquals(res1.statusCode, 400);
}

function deleteObj(string id) returns sql:Error? {
    sql:ParameterizedQuery OBJ_INFO_DELETE = `DELETE FROM object_monitor.object_data WHERE id = ${id}`;
    _ = check mysqlClient->execute(OBJ_INFO_DELETE);
}

@test:Config {dependsOn: [testPopulateTables, testPostObjData]}
function testGetObjData() returns error? {
    http:Response res = check testClient->post("/object-data", {
        "id" : "001",
        "longitude" : "2345.45",
        "latitude" : "3.45"
    });
    test:assertEquals(res.statusCode, 200);
    res = check testClient->post("/object-data", {
        "id" : "002",
        "longitude" : "2346.45",
        "latitude" : "4.45"
    });
    test:assertEquals(res.statusCode, 200);
    res = check testClient->post("/object-data", {
        "id" : "002",
        "longitude" : "2347.45",
        "latitude" : "5.45"
    });
    test:assertEquals(res.statusCode, 200);

    http:Response res1 = check testClient->get("/get-object-locations");
    test:assertEquals(res1.statusCode, 200);

    json[] locations = <json[]> check res1.getJsonPayload();
    test:assertEquals(locations.length(), 3);
    json location = locations[2];
    test:assertEquals(check location.id, "002");
    test:assertEquals(check location.longitude, 2347.45d);
    test:assertEquals(check location.latitude, 5.45d);
}

@test:Config {dependsOn: [testPopulateTables]}
function testPostRestrictedArea() returns error? {
    http:Response res = check testClient->post("/restricted-area", {
        "name": "general-hospital", 
        "numOfPoints": 5, 
        "points": [{lat: 6.876678, long: 79.920579},
                    {lat: 6.874974, long: 79.929333},
                    {lat: 6.868156, long: 79.932423},
                    {lat: 6.864066, long: 79.925042},
                    {lat: 6.875996, long: 79.911824}]
    });
    test:assertEquals(res.statusCode, 200);
    res = check testClient->post("/restricted-area", {
        "name": "port-city", 
        "numOfPoints": 6, 
        "points": [{lat: 6.947229, long: 79.820157},
                    {lat: 6.953875, long: 79.835606},
                    {lat: 6.945014, long: 79.846592},
                    {lat: 6.923543, long: 79.841271},
                    {lat: 6.924054, long: 79.825993},
                    {lat: 6.939561, long: 79.819470}]
    });
    test:assertEquals(res.statusCode, 200);    
}

@test:Config {dependsOn: [testPopulateTables, testPostRestrictedArea]}
function testGetRestrictedAreas() returns error? {
    http:Response res = check testClient->get("/restricted-areas");
    test:assertEquals(res.statusCode, 200);

    json[] restrictedAreas = <json[]> check res.getJsonPayload();
    test:assertEquals(restrictedAreas.length(), 2);
    json restrictedArea = restrictedAreas[1];
    test:assertEquals(check restrictedArea.name, "port-city");
    test:assertEquals(check restrictedArea.numOfPoints, 6);
    test:assertEquals(check restrictedArea.points, "[{\"lat\":6.947229,\"long\":79.820157},{\"lat\":6.953875,\"long\":79.835606},{\"lat\":6.945014,\"long\":79.846592},{\"lat\":6.923543,\"long\":79.841271},{\"lat\":6.924054,\"long\":79.825993},{\"lat\":6.939561,\"long\":79.81947}]");
}

@test:Config {dependsOn: [testPopulateTables, testPostRestrictedArea, testGetRestrictedAreas]}
function testRemoveRestrictedArea() returns error? {
    http:Response res = check testClient->post("/delete-restricted-area", {
        "id": 1
    });
    test:assertEquals(res.statusCode, 200);

    res = check testClient->get("/restricted-areas");
    test:assertEquals(res.statusCode, 200);
    json[] restrictedAreas = <json[]> check res.getJsonPayload();
    test:assertEquals(restrictedAreas.length(), 1);
    json restrictedArea = restrictedAreas[0];
    test:assertEquals(check restrictedArea.name, "port-city");
    test:assertEquals(check restrictedArea.numOfPoints, 6);
    test:assertEquals(check restrictedArea.points, "[{\"lat\":6.947229,\"long\":79.820157},{\"lat\":6.953875,\"long\":79.835606},{\"lat\":6.945014,\"long\":79.846592},{\"lat\":6.923543,\"long\":79.841271},{\"lat\":6.924054,\"long\":79.825993},{\"lat\":6.939561,\"long\":79.81947}]");
}

@test:Config {dependsOn: [testPostRestrictedArea]}
function testRestrictedArea() returns error? {
    http:Response res = check testClient->post("/object-data", {
        "id" : "004",
        "latitude" : "6.9351051",
        "longitude" : "79.8398552"
    });
    test:assertEquals(res.statusCode, 200);    
    res = check testClient->get("/get-object-locations");
    test:assertEquals(res.statusCode, 200);

    json[] locations = <json[]> check res.getJsonPayload();
    foreach var location in locations {
        if check location.id == "004" {
            test:assertEquals(check location.isRestricted, true);
            return;
        }
    }
    test:assertEquals(true, false);
}

@test:AfterSuite
function afterSuiteFunc() returns sql:Error? {
    check deleteDB();
    log:printInfo("We ran the tests successfully");
    return ();
}

function deleteDB() returns sql:Error? {
    _ = check mysqlClient->execute(`DROP DATABASE object_monitor`);
    check mysqlClient.close();
    return ();
}
