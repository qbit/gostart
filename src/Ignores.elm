module Ignores exposing (..)

import Json.Decode
    exposing
        ( Decoder
        , field
        , int
        , list
        , map5
        , string
        )


type alias Ignores =
    List Ignore


type alias Ignore =
    { id : Int
    , ownerId : Int
    , createdAt : String
    , repo : String
    , number : Int
    }


ignoreListDecoder : Decoder Ignores
ignoreListDecoder =
    list ignoreDecoder


ignoreDecoder : Decoder Ignore
ignoreDecoder =
    map5 Ignore
        (field "id" int)
        (field "owner_id" int)
        (field "created_at" string)
        (field "repo" string)
        (field "number" int)
