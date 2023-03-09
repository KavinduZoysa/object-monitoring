type CommonUserData record {|
    string username;
|};

type User record {|
    *CommonUserData;
    string firstName; 
    string lastName;
    string password;
|};

type LoginData record {|
    *CommonUserData;
    boolean isAdmin;
|};

type Credentials record {|
    string username;
    string password;
|};

type Location record {|
    string id;
    string latitude;
    string longitude;
|};

type RestrictedArea record {|
    string name;
    int numOfPoints;
    json points;
|};

type RestrictedAreaId record {|
    int id;
|};

type LocationOnTimestamp record {|
    *Location;
    int timestamp;
|};
