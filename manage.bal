import ballerina/log;
import ballerina/sql;
import ballerina/http;

isolated function populateTables() returns http:Response {
    error? res = createTables();
    http:Response resp = new;
    if res is error {
        log:printError("Populate table error ", res);
        resp.statusCode = 500;
        resp.setPayload("Cannot create tables");
    } else {
        resp.statusCode = 200;
    }
    return resp;
}

isolated function signUp(json user) returns http:Response {
    [string, string, string, string, boolean]|error userData = readUserInfo(user);
    http:Response resp = new;
    if userData is error {
        log:printError("SignUp error ", userData);
        resp.statusCode = 500;
        resp.setPayload("Invalid user data format"); 
        return resp;
    } 
    error? res = insertUser(userData[0], userData[1], userData[2], userData[3], userData[4]);
    if res is error {
        log:printError("SignUp error ", res);
        resp.statusCode = 500;
        resp.setPayload("Cannot register the user");
    } else {
        resp.statusCode = 200;
    }
    return resp;
}

isolated function readUserInfo(json user) returns [string, string, string, string, boolean]|error {
    return [check user.firstName, check user.lastName, check user.username, check user.password, check user.isAdmin];
}

type LoginData record {|
    string firstName;
    string lastName;
    int id;
    string username;
    boolean isAdmin;
|};

isolated function getLoginData(json credentials) returns http:Response {
    [string, string]|error cred = getCredentials(credentials);
    http:Response resp = new;
    if cred is error {
        log:printError("Credential format error ", cred);
        resp.statusCode = 500;
        resp.setPayload("Invalid credentials format");
        return resp;
    }

    LoginData|error? userData = getUserLoginData(cred[0], cred[1]);
    if (userData is error?) {
        log:printError("Login error ", userData);
        resp.statusCode = 500;
        resp.setPayload("Invalid credentials");
    } else {
        LoginData li = <LoginData> userData;
        resp.statusCode = 200;
        resp.setJsonPayload({
            firstName : li.firstName,
            lastName : li.lastName,
            userID : li.id,
            username : li.username,
            isAdmin : li.isAdmin
        });
    }
    return resp;
}

isolated function getCredentials(json credentials) returns [string, string]|error {
    return [check credentials.username, check credentials.password];
}

isolated function setObjData(json data) returns http:Response {
    var objData = getObjData(data);
    http:Response resp = new;
    if objData is error {
        log:printError("Object data insertion error ", objData);
        resp.statusCode = 500;
        resp.setPayload("Invalid object data");
        return resp;
    }
    error? res = insertObjData(objData[0], objData[1], objData[2]);
    if res is error {
        log:printError("Object data insertion error ", res);
        resp.statusCode = 500;
        resp.setPayload("Cannot insert object data");
        return resp;
    }
    resp.statusCode = 200;
    return resp;     
}

isolated function getObjData(json data) returns [string, string, string]|error {
    return [check data.id, check data.latitude, check data.longitude];
}

type ObjLocation record {|
    string id;
    string latitude;
    string longitude;
    int timestamp;
|};

isolated function getObjLocations() returns http:Response {
    var locations = selectObjLocation();

    json[] res = []; 
    var location = locations.next();
    while location !is () {
        if location is error {
            continue;
        }
        var data = getLocations(location.value);
        if data is error {
            log:printError("Invalid longitude/latitude", data);
            continue;                
        }
        // TODO: Check for restricted areas
        res.push({
            id : data[0],
            latitude : data[1],
            longitude : data[2],
            isRestricted : isRestrcited(data[1], data[2])
        });
        location = locations.next();
    }

    var closeRes = locations.close();
    http:Response resp = new;
    if closeRes is error {
        log:printError("Object locations selecting error ", closeRes);
        resp.statusCode = 500;
        resp.setPayload("Object locations selecting error");
        return resp;        
    }

    resp.statusCode = 200;
    resp.setJsonPayload(res);
    return resp;
}

isolated function getLocations(ObjLocation ol) returns [string, float, float]|error {
    return [ol.id, check float:fromString(ol.latitude), check float:fromString(ol.longitude)];
}

isolated function addRestrictedAreas(json polygon) returns http:Response {
    [string, int, string]|error restrictedAreaData = getRestrictedAreaData(polygon);
    http:Response resp = new;
    if restrictedAreaData is error {
        log:printError("Restricted area insertion error ", restrictedAreaData);
        resp.statusCode = 500;
        resp.setPayload("Cannot insert Restricted area");
        return resp;
    }
    error? res = insertRestrictedArea(restrictedAreaData[0], restrictedAreaData[1], restrictedAreaData[2]);
    if res is error {
        log:printError("Restricted area insertion error ", res);
        resp.statusCode = 500;
        resp.setPayload("Cannot insert Restricted area");
        return resp;        
    }

    resp.statusCode = 200;
    return resp;
}

isolated function getRestrictedAreaData(json polygon) returns [string, int, string]|error {
    return [check polygon.name, check polygon.numOfPoints, (check polygon.points).toString()];
}

isolated function getRestrictedAreas() returns http:Response {
    var restrictedAreas = selectRestrictedAreas();

    json[] res = [];
    var restrictedArea = restrictedAreas.next();
    while restrictedArea !is () {
        if restrictedArea !is error {
            var data = extractRestrictedAreaRawData(restrictedArea.value);
            if data is error {
                log:printError("Invalid restricted area", data);
            } else {
                res.push({
                    id: data[0],
                    name: data[1],
                    numOfPoints: data[2],
                    points: data[3]
                });
            }
            restrictedArea = restrictedAreas.next();
        }
    }

    var closeRes = restrictedAreas.close();
    http:Response resp = new;
    if closeRes is error {
        log:printError("Restricted areas selecting error ", closeRes);
        resp.statusCode = 500;
        resp.setPayload("Restricted areas selecting error");
        return resp;        
    }

    resp.statusCode = 200;
    resp.setJsonPayload(res);
    return resp;
}

isolated function extractRestrictedAreaRawData(record {|anydata...;|} data) returns [int, string, int, string]|error {
    anydata id = data["id"];
    anydata name = data["name"];
    anydata numOfPoints = data["numOfPoints"];
    anydata points = data["points"];
    if id is int && name is string && numOfPoints is int && points is string {
        return [id, name, numOfPoints, points];
    }
    return error("Invalid data");
}

isolated function deleteRestrictedArea(json area) returns http:Response {
    json|error id = area.id;
    http:Response resp = new;
    if id is error {
        log:printError("Invalid restricted area id", id);
        resp.statusCode = 500;
        resp.setPayload("Invalid restricted area id");
        return resp;     
    }
    sql:ExecutionResult|sql:Error res = reomveRestrictedArea(<int> id);
    if res is sql:Error {
        log:printError("Error in removing restricted area", res);
        resp.statusCode = 500;
        resp.setPayload("Error in removing restricted area");
        return resp;           
    }
    resp.statusCode = 200;
    return resp;
}

isolated function isRestrcited(float latitude, float longitude) returns boolean {
    [float, float][][]|error restrictedAreas = getAllRestrictedAreas();
    if restrictedAreas is error {
        return false;
    }
    foreach var restrictedArea in restrictedAreas {
        if isInsidePolygon(restrictedArea, [latitude, longitude]) {
            return true;
        }
    }
    return false;
}

isolated function isInsidePolygon([float, float][] polygon, [float, float] position) returns boolean {
    int l = polygon.length();
    int j = l - 1;
    boolean inside = checkPoints(polygon[0], polygon[j], position, false);
    foreach var i in 0..<l-1 {
        j = i + 1;
        inside = checkPoints(polygon[i], polygon[j], position, inside);
    } 
    return inside;    
}

isolated function checkPoints(float[] pointA, float[] pointB, float[] position, boolean inside) returns boolean {
    float latA = pointA[1];
    float lngA = pointA[0];

    float latB = pointB[1];
    float lngB = pointB[0];

    float latP = position[1];
    float lngP = position[0];

    boolean intersect = ((lngA > lngP) != (lngB > lngP)) && (latP < (latA - latB) * (lngP - lngB)/(lngA - lngB) + latB);
    if (intersect) {
        return !inside;
    }
    return inside;
}

isolated function getAllRestrictedAreas() returns [float, float][][]|error {
    [float, float][][] polygons = [];

    var restrictedAreas = selectRestrictedAreas();
    var restrictedArea = check restrictedAreas.next();
    while restrictedArea !is () {
        polygons.push(check getPolygon(restrictedArea.value));
        restrictedArea = check restrictedAreas.next();
    }
    return polygons;
}

isolated function getPolygon(record {| anydata...; |} value) returns [float, float][]|error {
    [float, float][] polygon = [];

    anydata p = value["points"];
    if p !is string { 
        return error("Invalid polygon");
    }
    json[] points = <json[]>(check p.fromJsonFloatString());
    foreach var point in points {
        polygon.push([check point.lat, check point.long]);
    }
    return polygon;
}
