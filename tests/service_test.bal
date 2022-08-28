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
