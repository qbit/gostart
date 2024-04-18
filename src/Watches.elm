module Watches exposing (..)

import Json.Decode as Decode
    exposing
        ( Decoder
        , field
        , int
        , list
        , map5
        , map6
        , string
        )


type alias NewWatch =
    { name : String
    , repo : String
    }


type alias Watches =
    List Watch


type alias Watch =
    { id : Int
    , ownerId : Int
    , name : String
    , repo : String
    , resultCount : Int
    , results : List Node
    }


type alias RepoInfo =
    { nameWithOwner : String
    }


type alias Node =
    { number : Int
    , createdAt : String
    , repository : RepoInfo
    , title : String
    , url : String
    }


watchListDecoder : Decoder Watches
watchListDecoder =
    list watchDecoder


watchDecoder : Decoder Watch
watchDecoder =
    map6 Watch
        (field "id" int)
        (field "owner_id" int)
        (field "name" string)
        (field "repo" string)
        (field "result_count" int)
        (field "results" <| list resultsDecoder)


resultsDecoder : Decoder Node
resultsDecoder =
    map5 Node
        (field "number" int)
        (field "createdAt" string)
        (field "repository" repoInfoDecoder)
        (field "title" string)
        (field "url" string)


repoInfoDecoder : Decoder RepoInfo
repoInfoDecoder =
    Decode.map RepoInfo
        (field "nameWithOwner" string)
