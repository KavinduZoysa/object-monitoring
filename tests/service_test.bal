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

type User record {|
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

    stream<User, error?> resStream = mysqlClient->query(`SELECT * from object_monitor.users WHERE username = 'samankumara007'`);
    check resStream.forEach(function(User user) {
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
    check resStream.forEach(function(User user) {
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
    test:assertEquals(res3.statusCode, 500);
    test:assertEquals(check res3.getTextPayload(), "Invalid user data format");
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
    test:assertEquals(res4.statusCode, 500);
    test:assertEquals(check res4.getTextPayload(), "Invalid credentials format");
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
