module Main exposing (..)

import Browser
import Data
import Html exposing (..)
import Html.Attributes exposing (href)
import Html.Events exposing (..)
import Http
import Json.Decode as Decode
    exposing
        ( Decoder
        , bool
        , field
        , int
        , list
        , map5
        , map6
        , string
        )


main : Program () Model Msg
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
    | WatchSuccess (List Data.Watch)
    | LinkSuccess (List Data.Link)


initialModel : { watches : List Data.Watch, links : List Data.Link }
initialModel =
    { watches = []
    , links = []
    }


init : () -> ( Model, Cmd Msg )
init _ =
    ( Loading
    , Cmd.batch
        [ getLinks
        , getWatches
        ]
    )


type Msg
    = MorePlease
    | GetWatches (Result Http.Error (List Data.Watch))
    | GetLinks (Result Http.Error (List Data.Link))


update : Msg -> Model -> ( Model, Cmd Msg )
update msg _ =
    case msg of
        MorePlease ->
            ( Loading, Cmd.batch [ getLinks, getWatches ] )

        GetWatches result ->
            case result of
                Ok watches ->
                    ( WatchSuccess watches, Cmd.none )

                Err _ ->
                    ( Failure, Cmd.none )

        GetLinks result ->
            case result of
                Ok links ->
                    ( LinkSuccess links, Cmd.none )

                Err _ ->
                    ( Failure, Cmd.none )


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none


view : Model -> Html Msg
view model =
    div []
        [ viewData model
        ]


getLinks : Cmd Msg
getLinks =
    Http.get
        { url = "/links"
        , expect = Http.expectJson GetLinks linkListDecoder
        }


getWatches : Cmd Msg
getWatches =
    Http.get
        { url = "/watches"
        , expect = Http.expectJson GetWatches watchListDecoder
        }


linkListDecoder : Decoder (List Data.Link)
linkListDecoder =
    list linkDecoder


watchListDecoder : Decoder (List Data.Watch)
watchListDecoder =
    list watchDecoder


linkDecoder : Decoder Data.Link
linkDecoder =
    map6 Data.Link
        (field "id" int)
        (field "created_at" string)
        (field "url" string)
        (field "name" string)
        (field "logo_url" string)
        (field "shared" bool)


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


viewData : Model -> Html Msg
viewData model =
    case model of
        Failure ->
            div []
                [ text "I can't load the watches"
                , button [ onClick MorePlease ] [ text "Try agan!" ]
                ]

        Loading ->
            text "Loading..."

        WatchSuccess watches ->
            div []
                (List.map viewWatch watches)

        LinkSuccess links ->
            div []
                (List.map viewLink links)


viewLink : Data.Link -> Html Msg
viewLink link =
    div []
        [ h2 [] [ text link.name ]
        ]


viewWatch : Data.Watch -> Html Msg
viewWatch watch =
    case watch.results of
        [] ->
            text ""

        _ ->
            div []
                [ h2 [] [ text "The Watches" ]
                , ul []
                    [ li
                        []
                        [ text (watch.repo ++ " :: ")
                        , text watch.name
                        , ul [] (List.map displayResult watch.results)
                        ]
                    ]
                ]


displayResult : Data.Node -> Html Msg
displayResult node =
    li []
        [ a [ href node.url ] [ text (String.fromInt node.number) ]
        , text (" :: " ++ node.title)
        ]
