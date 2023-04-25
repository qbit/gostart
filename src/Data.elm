module Data exposing (Node, RepoInfo, Watch)


type alias Watch =
    { ownerId : Int
    , name : String
    , repo : String
    , resultCount : Int
    , results : Maybe (List Node)
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
