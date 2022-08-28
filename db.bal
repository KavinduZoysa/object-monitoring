import ballerinax/mysql;
import ballerina/sql;

final mysql:Client mysqlClient = check new(user = DB_USER, password = DB_PASSWORD);

isolated function createTables() returns error? {
    check createDB();
    _ = check mysqlClient->execute(`CREATE TABLE IF NOT EXISTS object_monitor.users_info(id INT NOT NULL AUTO_INCREMENT, firstName VARCHAR(255), lastName VARCHAR(255), username VARCHAR(255) UNIQUE, password VARCHAR(255), role VARCHAR(255), PRIMARY KEY (id));`);
}

isolated function createDB() returns sql:Error? {
    _ = check mysqlClient->execute(`CREATE DATABASE IF NOT EXISTS object_monitor`);
}
