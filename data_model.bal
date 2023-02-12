type CommonUserData record {|
    string firstName; 
    string lastName;
    string username;
    boolean isAdmin;
|};

type User record {|
    *CommonUserData;
    string password;
|};

type LoginData record {|
    *CommonUserData;
    int id;
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
