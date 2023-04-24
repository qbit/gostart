module Data exposing (Edge, Link, Node, Watch, WatchData)


type alias Watch =
    { owner_id : Int
    , name : String
    , repo : String
    , result_count : Int
    }


type alias Node =
    { number : Int
    }


type alias Edge =
    { node : Node
    }


type alias WatchData =
    { search : List Edge
    }


type alias Link =
    { id : Int
    , owner_id : Int
    , created_at : String
    , name : String
    , url : String
    , logo_url : String
    }
