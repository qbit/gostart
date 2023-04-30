module Main exposing (..)

import Browser
import Data
import Html exposing (..)
import Html.Attributes exposing (href, style)
import Html.Events exposing (..)
import Http
import Json.Decode as Decode
    exposing
        ( Decoder
        , bool
        , decodeString
        , field
        , int
        , list
        , map
        , map5
        , map6
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


initialModel : { watches : List Data.Watch, links : List Data.Link }
initialModel =
    { watches = []
    , links = []
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


linkListDecoder : Decoder (List Data.Link)
linkListDecoder =
    list linkDecoder


linkDecoder : Decoder Data.Link
linkDecoder =
    map6 Data.Link
        (field "id" int)
        (field "created_at" string)
        (field "url" string)
        (field "name" string)
        (field "logo_url" string)
        (field "shared" bool)


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
        (field "results" <| list resultsDecoder)


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
    case watch.results of
        [] ->
            text ""

        _ ->
            ul []
                [ li
                    []
                    [ text (watch.repo ++ " :: ")
                    , text watch.name
                    , ul [] (List.map displayResult watch.results)
                    ]
                ]


displayResult : Data.Node -> Html Msg
displayResult node =
    li []
        [ a [ href node.url ] [ text (String.fromInt node.number) ]
        , text (" :: " ++ node.title)
        ]
