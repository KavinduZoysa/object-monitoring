import ballerinax/mysql;
import ballerina/sql;

final mysql:Client mysqlClient = check new(user = DB_USER, password = DB_PASSWORD);

isolated function createTables() returns error? {
    check createDB();
    _ = check mysqlClient->execute(`CREATE TABLE IF NOT EXISTS object_monitor.users(id INT NOT NULL AUTO_INCREMENT, firstName VARCHAR(255), lastName VARCHAR(255), username VARCHAR(255) UNIQUE, password VARCHAR(255), isAdmin BOOLEAN, PRIMARY KEY (id));`);
}

isolated function createDB() returns sql:Error? {
    _ = check mysqlClient->execute(`CREATE DATABASE IF NOT EXISTS object_monitor`);
}

isolated function insertUser(string firstName, string lastName, string username, string password, boolean isAdmin) returns error? {
    sql:ParameterizedQuery ADD_USER = `INSERT INTO object_monitor.users(firstName, lastName, username, password, isAdmin) values (${firstName}, ${lastName}, ${username}, ${password}, ${isAdmin})`;
    _ = check mysqlClient->execute(ADD_USER);
}

isolated  function getUserLoginData(string username, string password) returns LoginData|error? {
    sql:ParameterizedQuery SELECT_USER_INFO = `SELECT firstName, lastName, id, username, isAdmin FROM object_monitor.users WHERE username = ${username} AND BINARY password = ${password}`;
    stream<LoginData, error?> resultStream = mysqlClient->query(SELECT_USER_INFO);

    record {|LoginData value;|}? result = check resultStream.next();
    check resultStream.close();
    if result is record {|record {} value;|} {
        return result.value;
    }
    return result;
}