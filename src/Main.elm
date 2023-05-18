module Main exposing (..)

import Browser
import Data
import Html exposing (..)
import Html.Attributes exposing (class, href, name, placeholder, src, type_)
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
import Json.Encode as Encode


main : Program () Model Msg
main =
    Browser.element
        { init = init
        , update = update
        , subscriptions = subscriptions
        , view = view
        }


type Msg
    = Reload
    | ReloadLinks
    | ReloadWatches
    | GotWatches (Result Http.Error (List Data.Watch))
    | GotLinks (Result Http.Error (List Data.Link))
    | SubmitWatch
    | SubmitLink
    | HideWatchedItem Int String
    | HidItem (Result Http.Error ())


type Status
    = Loading
    | LoadedWatches (List Data.Watch)
    | LoadedLinks (List Data.Link)
    | Errored String


type alias NewWatch =
    { name : String
    , repo : String
    }


type alias NewLink =
    { name : String
    , url : String
    , shared : Bool
    , logo_url : String
    }


type alias Model =
    { watches : List Data.Watch
    , links : List Data.Link
    , errors : List String
    , status : Status
    , newlink : NewLink
    , newwatch : NewWatch
    }


initialModel : Model
initialModel =
    { watches = []
    , links = []
    , errors = []
    , status = Loading
    , newlink =
        { name = ""
        , url = ""
        , shared = False
        , logo_url = ""
        }
    , newwatch =
        { name = ""
        , repo = ""
        }
    }


init : () -> ( Model, Cmd Msg )
init _ =
    ( initialModel, Cmd.batch [ getLinks, getWatches ] )


hideWatched : Int -> String -> Cmd Msg
hideWatched id repo =
    let
        body =
            Encode.object
                [ ( "number", Encode.int id )
                , ( "repo", Encode.string repo )
                ]
                |> Http.jsonBody
    in
    Http.post
        { url = "/prignores"
        , body = body
        , expect = Http.expectWhatever HidItem
        }


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        HidItem (Err _) ->
            ( { model | status = Errored "Server error when hiding a watch item!" }, Cmd.none )

        HidItem (Ok _) ->
            ( model, Cmd.batch [ getWatches, getLinks ] )

        HideWatchedItem itemId repo ->
            ( model, Cmd.batch [ hideWatched itemId repo ] )

        SubmitWatch ->
            ( { model | newwatch = model.newwatch }, Cmd.batch [ getWatches ] )

        SubmitLink ->
            ( model, Cmd.batch [ getLinks ] )

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


watchForm : Model -> Html Msg
watchForm _ =
    div []
        [ createForm SubmitWatch
            (div
                []
                [ labeledTextBox "Item: " "some string..." ""
                , labeledTextBox "Repository: " "NixOS/nixpkgs" ""
                ]
            )
        ]


linkForm : Model -> Html Msg
linkForm _ =
    div []
        [ createForm SubmitLink
            (div
                []
                [ labeledTextBox "Name: " "Potato" ""
                , labeledTextBox "URL: " "https://...." ""
                , labeledTextBox "Icon: " "https://...." ""
                ]
            )
        ]


labeledTextBox : String -> String -> String -> Html Msg
labeledTextBox labelStr placeStr inputName =
    label []
        [ text labelStr
        , input
            [ type_ "text"
            , name inputName
            , placeholder placeStr
            ]
            []
        ]


createForm : Msg -> Html Msg -> Html Msg
createForm action content =
    details []
        [ summary [] [ text "" ]
        , Html.form
            [ onSubmit action
            , class "form-container"
            ]
            [ div [ class "form-content" ]
                [ content
                , button [] [ text "Submit" ]
                ]
            ]
        ]


bar : Html Msg -> Html Msg -> Html Msg
bar left right =
    header [ class "bar" ]
        [ div [ class "bar-left" ] [ left ]
        , div [ class "bar-right" ] [ right ]
        ]


viewLinks : Model -> Html Msg
viewLinks model =
    div []
        [ bar (linkForm model) (a [ onClick ReloadLinks ] [ text " ⟳" ])
        , case model.links of
            _ :: _ ->
                div
                    [ class "icon-grid" ]
                    (List.map viewLink model.links)

            [] ->
                text "No links found!"
        ]


viewWatches : Model -> Html Msg
viewWatches model =
    div []
        [ bar (watchForm model) (a [ onClick ReloadWatches ] [ text " ⟳" ])
        , case model.watches of
            _ :: _ ->
                ul [] (List.map viewWatch model.watches)

            [] ->
                text "No watches found!"
        ]


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
                        [ b []
                            [ text watch.repo
                            , text " -> "
                            , text watch.name
                            ]
                        , ul [] (List.map displayResult watch.results)
                        ]
                    ]
                ]


displayResult : Data.Node -> Html Msg
displayResult node =
    li []
        [ a [ href node.url ] [ text (String.fromInt node.number) ]
        , text " :: "
        , span [ onClick (HideWatchedItem node.number node.repository.nameWithOwner) ] [ text "⦸" ]
        , text " :: "
        , text node.title
        ]
