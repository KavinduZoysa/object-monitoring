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
