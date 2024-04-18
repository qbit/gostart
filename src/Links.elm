module Links exposing (..)

import Json.Decode
    exposing
        ( Decoder
        , bool
        , field
        , int
        , list
        , map6
        , string
        )


type alias Links =
    List Link


type alias NewLink =
    { name : String
    , url : String
    , shared : Bool
    , logo_url : String
    }


type alias Link =
    { id : Int
    , createdAt : String
    , url : String
    , name : String
    , logoURL : String
    , shared : Bool
    }


linkListDecoder : Decoder Links
linkListDecoder =
    list linkDecoder


linkDecoder : Decoder Link
linkDecoder =
    map6 Link
        (field "id" int)
        (field "created_at" string)
        (field "url" string)
        (field "name" string)
        (field "logo_url" string)
        (field "shared" bool)
