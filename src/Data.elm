module Data exposing (Link, Links, Node, RepoInfo, Watch, Watches)


type alias Watches =
    List Watch


type alias Links =
    List Link


type alias Link =
    { id : Int
    , createdAt : String
    , url : String
    , name : String
    , logoURL : String
    , shared : Bool
    }


type alias Watch =
    { ownerId : Int
    , name : String
    , repo : String
    , resultCount : Int
    , results : List Node
    }


type alias Node =
    { number : Int
    , createdAt : String
    , repository : RepoInfo
    , title : String
    , url : String
    }


type alias RepoInfo =
    { nameWithOwner : String
    }
