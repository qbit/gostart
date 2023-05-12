module Main exposing (..)

import Browser
import Data
import Html exposing (..)
import Html.Attributes exposing (class, href, src)
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


type Status
    = Loading
    | LoadedWatches (List Data.Watch)
    | LoadedLinks (List Data.Link)
    | Errored String


type alias Model =
    { watches : List Data.Watch
    , links : List Data.Link
    , errors : List String
    , status : Status
    }


initialModel : Model
initialModel =
    { watches = []
    , links = []
    , errors = []
    , status = Loading
    }


init : () -> ( Model, Cmd Msg )
init _ =
    ( initialModel, Cmd.batch [ getLinks, getWatches ] )


type Msg
    = Reload
    | ReloadLinks
    | ReloadWatches
    | AddLink
    | AddWatch
    | GotWatches (Result Http.Error (List Data.Watch))
    | GotLinks (Result Http.Error (List Data.Link))


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        AddLink ->
            ( model, Cmd.none )

        AddWatch ->
            ( model, Cmd.none )

        Reload ->
            ( model, Cmd.batch [ getWatches, getLinks ] )

        ReloadWatches ->
            ( model, Cmd.batch [ getWatches ] )

        ReloadLinks ->
            ( model, Cmd.batch [ getLinks ] )

        GotWatches (Err _) ->
            ( { model | status = Errored "Server error when fetching watches!" }, Cmd.none )

        GotLinks (Err _) ->
            ( { model | status = Errored "Server error when fetching links!" }, Cmd.none )

        GotWatches (Ok watches) ->
            case watches of
                _ :: _ ->
                    ( { model
                        | watches = watches
                        , status =
                            case List.head watches of
                                Just _ ->
                                    LoadedWatches watches

                                Nothing ->
                                    LoadedWatches []
                      }
                    , Cmd.none
                    )

                [] ->
                    ( { model | status = Errored "No Watches found" }, Cmd.none )

        GotLinks (Ok links) ->
            case links of
                _ :: _ ->
                    ( { model
                        | links = links
                        , status =
                            case List.head links of
                                Just _ ->
                                    LoadedLinks links

                                Nothing ->
                                    LoadedLinks []
                      }
                    , Cmd.none
                    )

                [] ->
                    ( { model | status = Errored "No Watches found" }, Cmd.none )


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none


mainEle : List (Attribute msg) -> List (Html msg) -> Html msg
mainEle attributes children =
    node "main" attributes children


view : Model -> Html Msg
view model =
    div []
        [ mainEle
            []
            [ div [ class "grid" ]
                [ div [ class "col" ]
                    [ viewWatches model
                    ]
                , div [ class "col" ]
                    [ viewLinks model
                    ]
                ]
            , footer []
                [ text "the foot" ]
            ]
        ]


getLinks : Cmd Msg
getLinks =
    Http.get
        { url = "/links"
        , expect = Http.expectJson GotLinks linkListDecoder
        }


getWatches : Cmd Msg
getWatches =
    Http.get
        { url = "/watches"
        , expect = Http.expectJson GotWatches watchListDecoder
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


viewLinks : Model -> Html Msg
viewLinks model =
    case model.links of
        _ :: _ ->
            div []
                [ header [ class "bar" ]
                    [ a [ onClick ReloadLinks ] [ text " ⟳" ]
                    , a [ onClick AddLink ] [ text " + " ]
                    ]
                , div
                    [ class "icon-grid" ]
                    (List.map viewLink model.links)
                ]

        [] ->
            text "No Links!"


viewWatches : Model -> Html Msg
viewWatches model =
    case model.watches of
        _ :: _ ->
            div []
                [ header [ class "bar" ]
                    [ a [ onClick ReloadWatches ] [ text " ⟳" ]
                    , a [ onClick AddWatch ] [ text " + " ]
                    ]
                , ul
                    []
                    (List.map viewWatch model.watches)
                ]

        [] ->
            text "No Watches!"


viewLink : Data.Link -> Html Msg
viewLink link =
    div []
        [ div []
            [ a [ href link.url ]
                [ div
                    [ class "icon" ]
                    [ header []
                        [ img [ src link.logoURL ] []
                        ]
                    , text link.name
                    ]
                ]
            ]
        ]


viewWatch : Data.Watch -> Html Msg
viewWatch watch =
    case watch.results of
        [] ->
            text ""

        _ ->
            div []
                [ ul []
                    [ li
                        []
                        [ text watch.repo
                        , text " :: "
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
