module Main exposing (..)

import Browser
import Html exposing (..)
import Html.Attributes exposing (style)
import Html.Events exposing (..)
import Http
import Json.Decode exposing (Decoder, field, int, list, map3, map4, map5, maybe, string)


main =
    Browser.element
        { init = init
        , update = update
        , subscriptions = subscriptions
        , view = view
        }


type Model
    = Failure
    | Loading
    | Success (List Watch)


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


init : () -> ( Model, Cmd Msg )
init _ =
    ( Loading
    , Cmd.batch
        [ getWatches
        ]
    )


type Msg
    = MorePlease
    | GetWatches (Result Http.Error (List Watch))


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        MorePlease ->
            ( Loading, getWatches )

        GetWatches result ->
            case result of
                Ok watches ->
                    ( Success watches, Cmd.none )

                Err _ ->
                    ( Failure, Cmd.none )


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none


view : Model -> Html Msg
view model =
    div []
        [ h2 [] [ text "Watches" ]
        , viewWatches model
        ]


viewWatches : Model -> Html Msg
viewWatches model =
    case model of
        Failure ->
            div []
                [ text "I can't load the watches"
                , button [ onClick MorePlease ] [ text "Try agan!" ]
                ]

        Loading ->
            text "Loading..."

        Success watches ->
            div []
                (List.map viewWatch watches)


viewLinks : Model -> Html Msg
viewLinks model =
    case model of
        Failure ->
            div []
                [ text "I can't load the links"
                , button [ onClick MorePlease ] [ text "Try agan!" ]
                ]

        Loading ->
            text "Loading..."

        Success links ->
            text "success links..."


getWatches : Cmd Msg
getWatches =
    Http.get
        { url = "/watches"
        , expect = Http.expectJson GetWatches watchListDecoder
        }


watchListDecoder : Decoder (List Watch)
watchListDecoder =
    list watchDecoder


watchDecoder : Decoder Watch
watchDecoder =
    map4 Watch
        (field "owner_id" int)
        (field "name" string)
        (field "repo" string)
        (field "result_count" int)


viewWatch : Watch -> Html Msg
viewWatch watch =
    li []
        [ text (String.fromInt watch.result_count ++ " " ++ watch.name)
        , li [] [ text "butter" ]
        ]
