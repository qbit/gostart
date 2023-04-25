module Main exposing (..)

import Browser
import Data
import Html exposing (..)
import Html.Attributes exposing (style)
import Html.Events exposing (..)
import Http
import Json.Decode as Decode
    exposing
        ( Decoder
        , decodeString
        , field
        , float
        , int
        , list
        , map
        , map4
        , map5
        , maybe
        , string
        )


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
    | Success (List Data.Watch)


init : () -> ( Model, Cmd Msg )
init _ =
    ( Loading
    , Cmd.batch
        [ getWatches
        ]
    )


type Msg
    = MorePlease
    | GetWatches (Result Http.Error (List Data.Watch))


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


getWatches : Cmd Msg
getWatches =
    Http.get
        { url = "/watches"
        , expect = Http.expectJson GetWatches watchListDecoder
        }


watchListDecoder : Decoder (List Data.Watch)
watchListDecoder =
    list watchDecoder


watchDecoder : Decoder Data.Watch
watchDecoder =
    map5 Data.Watch
        (field "owner_id" int)
        (field "name" string)
        (field "repo" string)
        (field "result_count" int)
        (field "results" <| maybe (list resultsDecoder))


resultsDecoder : Decoder Data.Node
resultsDecoder =
    map5 Data.Node
        (field "number" int)
        (field "createdAt" string)
        (field "repository" repoInfoDecoder)
        (field "title" string)
        (field "url" string)


repoInfoDecoder : Decoder Data.RepoInfo
repoInfoDecoder =
    Decode.map Data.RepoInfo
        (field "nameWithOwner" string)


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


viewWatch : Data.Watch -> Html Msg
viewWatch watch =
    ul []
        [ li
            []
            [ text (String.fromInt watch.resultCount ++ " " ++ watch.name)

            -- I'd like to iterate over watch.results and create an <li> for each
            -- entry that might exist. If watch.results is empty, i'd like to just
            -- have an empty ul.
            , ul [] [ text (Debug.toString watch.results) ]
            ]
        ]


displayResult : Data.Node -> Html Msg
displayResult node =
    li [] [ text (String.fromInt node.number) ]
