import ballerina/http;

service "/object-monitor" on new http:Listener(9090) {
    
    resource function get health\-check() returns http:Response {
        http:Response resp = new;
        return resp;
    }

    isolated resource function get populate\-tables() returns http:Response {
        return populateTables();
    }

    isolated resource function post signup(@http:Payload json payload) returns http:Response {
        return signUp(payload);
    }

    isolated resource function post login(@http:Payload json payload) returns http:Response {
        return getLoginData(payload);
    }

    isolated resource function post object\-data(@http:Payload json payload) returns http:Response {
        return setObjData(payload);
    }

    isolated resource function get get\-object\-locations() returns http:Response {
        return getObjLocations();
    }
}
