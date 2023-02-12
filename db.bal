import ballerinax/mysql;
import ballerina/sql;

final mysql:Client mysqlClient = check new(user = DB_USER, password = DB_PASSWORD);

isolated function createTables() returns error? {
    check createDB();
    _ = check mysqlClient->execute(`CREATE TABLE IF NOT EXISTS object_monitor.users(id INT NOT NULL AUTO_INCREMENT, firstName VARCHAR(255), lastName VARCHAR(255), username VARCHAR(255) UNIQUE, password VARCHAR(255), isAdmin BOOLEAN, PRIMARY KEY (id));`);
    _ = check mysqlClient->execute(`CREATE TABLE IF NOT EXISTS object_monitor.object_data(id VARCHAR(255), latitude VARCHAR(255), longitude VARCHAR(255), timestamp int(15));`);
    _ = check mysqlClient->execute(`CREATE TABLE IF NOT EXISTS object_monitor.restricted_areas(id INT(50) NOT NULL AUTO_INCREMENT, name VARCHAR(255), numOfPoints INT(50), points VARCHAR(2550), PRIMARY KEY (id));`);
}

isolated function createDB() returns sql:Error? {
    _ = check mysqlClient->execute(`CREATE DATABASE IF NOT EXISTS object_monitor`);
}

isolated function insertUser(string firstName, string lastName, string username, string password, boolean isAdmin) returns error? {
    sql:ParameterizedQuery USER_INSERTION = `INSERT INTO object_monitor.users(firstName, lastName, username, password, isAdmin) values (${firstName}, ${lastName}, ${username}, ${password}, ${isAdmin})`;
    _ = check mysqlClient->execute(USER_INSERTION);
}

// TODO: Refactor this to return the stream
isolated  function getUserLoginData(Credentials credentials) returns LoginData|error? {
    sql:ParameterizedQuery USER_DATA_SELECTION = `SELECT firstName, lastName, id, username, isAdmin FROM object_monitor.users WHERE username = ${credentials.username} AND BINARY password = ${credentials.password}`;
    stream<LoginData, error?> resultStream = mysqlClient->query(USER_DATA_SELECTION);

    record {|LoginData value;|}? result = check resultStream.next();
    check resultStream.close();
    if result is record {|record {} value;|} {
        return result.value;
    }
    return result;
}

isolated function insertObjData(Location location) returns error? {
    sql:ParameterizedQuery OBJ_DATA_INSERTION = `INSERT INTO object_monitor.object_data(id, latitude, longitude, timestamp) values (${location.id}, ${location.latitude}, ${location.longitude}, UNIX_TIMESTAMP(now()))`;
    _ = check mysqlClient->execute(OBJ_DATA_INSERTION);
}

isolated function selectObjLocation() returns stream<LocationOnTimestamp, error?> {
    sql:ParameterizedQuery OBJ_LOCATIONS = `SELECT * FROM object_monitor.object_data WHERE timestamp IN (SELECT MAX(timestamp) FROM object_monitor.object_data GROUP BY id)`;
    stream<LocationOnTimestamp, error?> resultStream = mysqlClient->query(OBJ_LOCATIONS);
    return resultStream;
}

isolated function insertRestrictedArea(RestrictedArea polygon) returns error? {
    sql:ParameterizedQuery RESTRICTED_AREA_INSERTION = `INSERT INTO object_monitor.restricted_areas(name, numOfPoints, points) values (${polygon.name}, ${polygon.numOfPoints}, ${polygon.points.toString()})`;
    _ = check mysqlClient->execute(RESTRICTED_AREA_INSERTION);
}

isolated function selectRestrictedAreas() returns stream<record {|anydata...;|}, error?> {
    sql:ParameterizedQuery SELECT_RESTRICTED_AREAS = `SELECT * FROM object_monitor.restricted_areas`;
    return mysqlClient->query(SELECT_RESTRICTED_AREAS);
}

isolated function reomveRestrictedArea(int id) returns sql:ExecutionResult|sql:Error {
    sql:ParameterizedQuery DELETE_RETRICTED_AREA = `DELETE FROM object_monitor.restricted_areas WHERE id = ${id}`;
    return mysqlClient->execute(DELETE_RETRICTED_AREA);
}
