import ballerina/http;

listener http:Listener securedEP = new (9090,
    secureSocket = {
        key: {
            certFile: "./resources/public.crt",
            keyFile: "./resources/private.key"
        }
    }
);

service "/object-monitor" on securedEP {
    
    resource function get health\-check() returns http:Response {
        http:Response resp = new;
        return resp;
    }

    isolated resource function get populate\-tables() returns http:Response {
        return populateTables();
    }

    isolated resource function post signup(@http:Payload User payload) returns http:Response {
        return signUp(payload);
    }

    isolated resource function post login(@http:Payload Credentials payload) returns http:Response {
        return getLoginData(payload);
    }

    isolated resource function post object\-data(@http:Payload Location payload) returns http:Response {
        return setObjData(payload);
    }

    isolated resource function get get\-object\-locations() returns http:Response {
        return getObjLocations();
    }

    isolated resource function post restricted\-area(@http:Payload RestrictedArea payload) returns http:Response {
        return addRestrictedAreas(payload);
    }

    isolated resource function get restricted\-areas() returns http:Response {
        return getRestrictedAreas();
    }

    isolated resource function post delete\-restricted\-area(@http:Payload RestrictedAreaId payload) returns http:Response {
        return deleteRestrictedArea(payload);
    }
}
