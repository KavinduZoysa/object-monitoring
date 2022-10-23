import ballerina/log;
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
            isRestricted : false
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
