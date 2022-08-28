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
