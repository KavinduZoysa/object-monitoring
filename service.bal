import ballerina/http;

service "/object-monitor" on new http:Listener(9090) {
    
    resource function get health\-check() returns http:Response {
        http:Response resp = new;
        return resp;
    }

    isolated resource function get populate\-tables() returns http:Response {
        return populateTables();
    }
}
