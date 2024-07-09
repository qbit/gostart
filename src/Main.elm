module Main exposing (..)

import Browser
import Browser.Navigation exposing (load)
import Html exposing (..)
import Html.Attributes
    exposing
        ( checked
        , class
        , classList
        , href
        , name
        , placeholder
        , src
        , type_
        , value
        )
import Html.Events exposing (..)
import Http
import Ignores
import Json.Encode as Encode
import Links
import Table exposing (defaultCustomizations)
import Watches


main : Program () Model Msg
main =
    Browser.element
        { init = init
        , update = update
        , subscriptions = subscriptions
        , view = view
        }


type Msg
    = AddedLink (Result Http.Error ())
    | AddedWatch (Result Http.Error ())
    | DeletedLink (Result Http.Error ())
    | ClickedLink (Result Http.Error String)
    | DeleteLink Int
    | IncrementLink Int
    | DeletedWatch (Result Http.Error ())
    | DeleteWatch Int
    | DeletedIgnore (Result Http.Error ())
    | DeleteIgnore Int
    | GotLinks (Result Http.Error Links.Links)
    | GotNewLink Links.NewLink
    | GotNewWatch Watches.NewWatch
    | GotWatches (Result Http.Error Watches.Watches)
    | GotIgnores (Result Http.Error Ignores.Ignores)
    | HideWatchedItem Int String
    | HidItem (Result Http.Error ())
    | Reload
    | ReloadLinks
    | ReloadWatches
    | ReloadIgnores
    | SubmitLink
    | SubmitWatch
    | FetchIcons
    | LoadIcons (Result Http.Error ())
    | SetLinkTableState Table.State
    | SetWatchTableState Table.State
    | SetIgnoreTableState Table.State


type Status
    = Loading
    | LoadedWatches Watches.Watches
    | LoadedIgnores Ignores.Ignores
    | LoadedLinks Links.Links
    | Errored String


type alias Model =
    { watches : Watches.Watches
    , links : Links.Links
    , ignores : Ignores.Ignores
    , errors : List String
    , status : Status
    , newlink : Links.NewLink
    , newwatch : Watches.NewWatch
    , linkTableState : Table.State
    , watchTableState : Table.State
    , ignoreTableState : Table.State
    }


initialModel : Model
initialModel =
    { watches = []
    , links = []
    , ignores = []
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
    , linkTableState = Table.initialSort "Created"
    , watchTableState = Table.initialSort "Created"
    , ignoreTableState = Table.initialSort "Created"
    }


init : () -> ( Model, Cmd Msg )
init _ =
    ( initialModel, Cmd.batch [ getLinks, getWatches, getIgnores ] )


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


addLink : Model -> Cmd Msg
addLink model =
    let
        body =
            Encode.object
                [ ( "name", Encode.string model.newlink.name )
                , ( "url", Encode.string model.newlink.url )
                , ( "logo_url", Encode.string model.newlink.logo_url )
                , ( "shared", Encode.bool model.newlink.shared )
                ]
                |> Http.jsonBody
    in
    Http.post
        { url = "/links"
        , body = body
        , expect = Http.expectWhatever AddedLink
        }


addWatch : Model -> Cmd Msg
addWatch model =
    let
        body =
            Encode.object
                [ ( "name", Encode.string model.newwatch.name )
                , ( "repo", Encode.string model.newwatch.repo )
                ]
                |> Http.jsonBody
    in
    Http.post
        { url = "/watches"
        , body = body
        , expect = Http.expectWhatever AddedWatch
        }


fetchIcons : Cmd Msg
fetchIcons =
    Http.get
        { url = "/update-icons"
        , expect = Http.expectWhatever LoadIcons
        }


deleteLink : Int -> Cmd Msg
deleteLink linkId =
    Http.request
        { url = "/links/" ++ String.fromInt linkId
        , method = "DELETE"
        , timeout = Nothing
        , tracker = Nothing
        , headers = []
        , body = Http.emptyBody
        , expect = Http.expectWhatever DeletedLink
        }


incrementLink : Int -> Cmd Msg
incrementLink linkId =
    Http.request
        { url = "/links/" ++ String.fromInt linkId
        , method = "GET"
        , timeout = Nothing
        , tracker = Nothing
        , headers = []
        , body = Http.emptyBody
        , expect = Http.expectString ClickedLink
        }


deleteIgnore : Int -> Cmd Msg
deleteIgnore ignoreId =
    Http.request
        { url = "/prignores/" ++ String.fromInt ignoreId
        , method = "DELETE"
        , timeout = Nothing
        , tracker = Nothing
        , headers = []
        , body = Http.emptyBody
        , expect = Http.expectWhatever DeletedIgnore
        }


deleteWatch : Int -> Cmd Msg
deleteWatch watchId =
    Http.request
        { url = "/watches/" ++ String.fromInt watchId
        , method = "DELETE"
        , timeout = Nothing
        , tracker = Nothing
        , headers = []
        , body = Http.emptyBody
        , expect = Http.expectWhatever DeletedWatch
        }


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        LoadIcons (Ok _) ->
            ( model, getLinks )

        LoadIcons (Err _) ->
            ( { model | status = Errored "Server error reloading icons!" }, Cmd.none )

        FetchIcons ->
            ( model, fetchIcons )

        DeleteLink linkId ->
            ( model, deleteLink linkId )

        IncrementLink linkId ->
            ( model, incrementLink linkId )

        DeleteWatch watchId ->
            ( model, deleteWatch watchId )

        DeleteIgnore ignoreId ->
            ( model, deleteIgnore ignoreId )

        GotNewWatch newwatch ->
            ( { model | newwatch = newwatch }, Cmd.none )

        GotNewLink newlink ->
            ( { model | newlink = newlink }, Cmd.none )

        AddedWatch (Err _) ->
            ( { model | status = Errored "Server error adding a watch!" }, Cmd.none )

        AddedWatch (Ok _) ->
            ( { model | newwatch = initialModel.newwatch }, getWatches )

        AddedLink (Err _) ->
            ( { model | status = Errored "Server error adding a link!" }, Cmd.none )

        AddedLink (Ok _) ->
            ( { model | newlink = initialModel.newlink }, getLinks )

        ClickedLink (Ok newUrl) ->
            ( model, load newUrl )

        ClickedLink (Err _) ->
            ( { model | status = Errored "Server error incrementing link!" }, Cmd.none )

        DeletedLink (Ok _) ->
            ( model, getLinks )

        DeletedLink (Err _) ->
            ( { model | status = Errored "Server error deleting link!" }, Cmd.none )

        DeletedWatch (Ok _) ->
            ( model, getWatches )

        DeletedWatch (Err _) ->
            ( { model | status = Errored "Server error deleting watch!" }, Cmd.none )

        DeletedIgnore (Ok _) ->
            ( model, getIgnores )

        DeletedIgnore (Err _) ->
            ( { model | status = Errored "Server error deleting ignore!" }, Cmd.none )

        HidItem (Err _) ->
            ( { model | status = Errored "Server error when hiding a watch item!" }, Cmd.none )

        HidItem (Ok _) ->
            ( model, getWatches )

        HideWatchedItem itemId repo ->
            ( model, hideWatched itemId repo )

        SubmitWatch ->
            ( model, addWatch model )

        SubmitLink ->
            ( model, addLink model )

        Reload ->
            ( model, Cmd.batch [ getWatches, getLinks ] )

        ReloadWatches ->
            ( model, getWatches )

        ReloadLinks ->
            ( model, getLinks )

        ReloadIgnores ->
            ( model, getIgnores )

        GotWatches (Err _) ->
            ( { model | status = Errored "Server error when fetching watches!" }, Cmd.none )

        GotLinks (Err _) ->
            ( { model | status = Errored "Server error when fetching links!" }, Cmd.none )

        GotIgnores (Err _) ->
            ( { model | status = Errored "Server error when fetching ignores!" }, Cmd.none )

        GotWatches (Ok watches) ->
            case watches of
                _ :: _ ->
                    ( { model
                        | watches = watches
                        , status = LoadedWatches watches
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
                            LoadedLinks links
                      }
                    , Cmd.none
                    )

                [] ->
                    ( { model | status = Errored "No Links found" }, Cmd.none )

        GotIgnores (Ok ignores) ->
            case ignores of
                _ :: _ ->
                    ( { model
                        | ignores = ignores
                        , status = LoadedIgnores ignores
                      }
                    , Cmd.none
                    )

                [] ->
                    ( { model | status = Errored "No Watches found" }, Cmd.none )

        SetLinkTableState newState ->
            ( { model | linkTableState = newState }, Cmd.none )

        SetWatchTableState newState ->
            ( { model | watchTableState = newState }, Cmd.none )

        SetIgnoreTableState newState ->
            ( { model | ignoreTableState = newState }, Cmd.none )


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
            , div [ class "grid" ]
                [ case model.status of
                    Errored e ->
                        div
                            [ classList
                                [ ( "error", True )
                                ]
                            ]
                            [ text e ]

                    _ ->
                        text ""
                ]
            ]
        , footer []
            [ details []
                [ summary []
                    [ b [] [ text "Maintenence" ]
                    ]
                , div []
                    [ button [ onClick FetchIcons ] [ text "Update Icons" ]
                    ]
                , div []
                    [ h3 [] [ text "Links" ]
                    , Table.view linkTableConfig model.linkTableState model.links
                    ]
                , div []
                    [ h3 [] [ text "Watched Items" ]
                    , Table.view watchTableConfig model.watchTableState model.watches
                    ]
                , div []
                    [ h3
                        []
                        [ text "Watched Items Ignores" ]
                    , Table.view ignoreTableConfig model.ignoreTableState model.ignores
                    ]
                ]
            ]
        ]


shareTxt : Links.Link -> Table.HtmlDetails Msg
shareTxt link =
    if link.shared then
        Table.HtmlDetails []
            [ text "Yes" ]

    else
        Table.HtmlDetails []
            [ text "No" ]


shareColumn : Table.Column Links.Link Msg
shareColumn =
    Table.veryCustomColumn
        { name = "Shared"
        , viewData = \data -> shareTxt data
        , sorter = Table.unsortable
        }


linkTimeColumn : Table.Column Links.Link Msg
linkTimeColumn =
    Table.customColumn
        { name = "Created"
        , viewData = .createdAt
        , sorter = Table.decreasingOrIncreasingBy .createdAt
        }


deleteLinkColumn : Table.Column Links.Link Msg
deleteLinkColumn =
    Table.veryCustomColumn
        { name = "Action"
        , viewData = linkDeleteView
        , sorter = Table.unsortable
        }


linkTableConfig : Table.Config Links.Link Msg
linkTableConfig =
    Table.customConfig
        { toId = .name
        , toMsg = SetLinkTableState
        , columns =
            [ Table.stringColumn "Name" .name
            , Table.stringColumn "URL" .url
            , shareColumn
            , Table.stringColumn "Logo URL" .logoURL
            , linkTimeColumn
            , deleteLinkColumn
            ]
        , customizations = defaultCustomizations
        }


linkDeleteView : Links.Link -> Table.HtmlDetails Msg
linkDeleteView { id } =
    Table.HtmlDetails []
        [ button
            [ onClick (DeleteLink id) ]
            [ text "Delete" ]
        ]


watchTableConfig : Table.Config Watches.Watch Msg
watchTableConfig =
    Table.config
        { toId = .name
        , toMsg = SetWatchTableState
        , columns =
            [ Table.stringColumn "Name" .name
            , Table.stringColumn "Repo" .repo
            , deleteWatchColumn
            ]
        }


deleteWatchColumn : Table.Column Watches.Watch Msg
deleteWatchColumn =
    Table.veryCustomColumn
        { name = "Action"
        , viewData = watchDeleteView
        , sorter = Table.unsortable
        }


watchDeleteView : Watches.Watch -> Table.HtmlDetails Msg
watchDeleteView { id } =
    Table.HtmlDetails []
        [ button
            [ onClick (DeleteWatch id) ]
            [ text "Delete" ]
        ]


ignoreTimeColumn : Table.Column Ignores.Ignore Msg
ignoreTimeColumn =
    Table.customColumn
        { name = "Created"
        , viewData = .createdAt
        , sorter = Table.decreasingOrIncreasingBy .createdAt
        }


deleteIgnoreColumn : Table.Column Ignores.Ignore Msg
deleteIgnoreColumn =
    Table.veryCustomColumn
        { name = "Action"
        , viewData = ignoreDeleteView
        , sorter = Table.unsortable
        }


ignoreDeleteView : Ignores.Ignore -> Table.HtmlDetails Msg
ignoreDeleteView { id } =
    Table.HtmlDetails []
        [ button
            [ onClick (DeleteIgnore id) ]
            [ text "Delete" ]
        ]


ignoreTableConfig : Table.Config Ignores.Ignore Msg
ignoreTableConfig =
    Table.customConfig
        { toId = .createdAt
        , toMsg = SetIgnoreTableState
        , columns =
            [ Table.intColumn "ID" .id
            , Table.stringColumn "Repo" .repo
            , Table.intColumn "Number" .number
            , ignoreTimeColumn
            , deleteIgnoreColumn
            ]
        , customizations = defaultCustomizations
        }


getIgnores : Cmd Msg
getIgnores =
    Http.get
        { url = "/prignores"
        , expect = Http.expectJson GotIgnores Ignores.ignoreListDecoder
        }


getLinks : Cmd Msg
getLinks =
    Http.get
        { url = "/links"
        , expect = Http.expectJson GotLinks Links.linkListDecoder
        }


getWatches : Cmd Msg
getWatches =
    Http.get
        { url = "/watches"
        , expect = Http.expectJson GotWatches Watches.watchListDecoder
        }


watchForm : Model -> Watches.NewWatch -> Html Msg
watchForm model newwatch =
    div []
        [ createForm "Watches"
            SubmitWatch
            (div
                []
                [ labeledInput "Item: " "some string..." "name" model.newwatch.name (\v -> GotNewWatch { newwatch | name = v })
                , labeledInput "Repository: " "NixOS/nixpkgs" "repo" model.newwatch.repo (\v -> GotNewWatch { newwatch | repo = v })
                ]
            )
        ]


linkForm : Model -> Links.NewLink -> Html Msg
linkForm model newlink =
    div []
        [ createForm "Links"
            SubmitLink
            (div [ class "form-content" ]
                [ div
                    []
                    [ labeledInput "Name: " "Potato" "name" model.newlink.name (\v -> GotNewLink { newlink | name = v })
                    , labeledInput "URL: " "https://...." "url" model.newlink.url (\v -> GotNewLink { newlink | url = v })
                    , labeledInput "Icon: " "https://...." "logo_url" model.newlink.logo_url (\v -> GotNewLink { newlink | logo_url = v })
                    , label []
                        [ text "Shared: "
                        , input
                            [ type_ "checkbox"
                            , name "linkshared"
                            , onCheck (\v -> GotNewLink { newlink | shared = v })
                            , checked <| newlink.shared
                            ]
                            []
                        ]
                    ]
                ]
            )
        ]


labeledInput : String -> String -> String -> String -> (String -> msg) -> Html msg
labeledInput labelStr placeStr inputName inputValue inputHandler =
    label []
        [ text labelStr
        , input
            [ type_ "text"
            , name inputName
            , onInput inputHandler
            , placeholder placeStr
            , value inputValue
            ]
            []
        ]


createForm : String -> Msg -> Html Msg -> Html Msg
createForm title action content =
    details []
        [ summary [] [ b [] [ text title ] ]
        , Html.form
            [ onSubmit action
            , class "form-container"
            ]
            [ div [ class "form-content" ]
                [ content
                , button
                    []
                    [ text "Submit" ]
                ]
            ]
        ]


viewBar : Html Msg -> Html Msg -> Html Msg
viewBar left right =
    header [ class "bar" ]
        [ div [ class "bar-left" ] [ left ]
        , div [ class "bar-right" ] [ right ]
        ]


viewLinks : Model -> Html Msg
viewLinks model =
    div []
        [ viewBar (linkForm model model.newlink) (a [ onClick ReloadLinks ] [ text " ⟳" ])
        , case model.links of
            _ :: _ ->
                div
                    [ class "icon-grid" ]
                    (List.map viewLink model.links)

            [] ->
                text "No links found!"
        ]


viewLink : Links.Link -> Html Msg
viewLink link =
    div []
        [ div [ class "icon" ]
            [ span [ onClick (DeleteLink link.id) ] [ text "×" ]
            , a
                [ onClick (IncrementLink link.id)

                -- , href link.url
                ]
                [ div
                    []
                    [ header []
                        [ img [ src ("/icons/" ++ String.fromInt link.id) ] []
                        ]
                    , text link.name
                    ]
                ]
            ]
        ]


viewWatches : Model -> Html Msg
viewWatches model =
    div []
        [ viewBar (watchForm model model.newwatch) (a [ onClick ReloadWatches ] [ text " ⟳" ])
        , case model.watches of
            _ :: _ ->
                ul [] (List.map viewWatch model.watches)

            [] ->
                text "No watches found!"
        ]


viewWatch : Watches.Watch -> Html Msg
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
                            , span [ onClick (DeleteWatch watch.id) ] [ text " ×" ]
                            ]
                        , ul [] (List.map viewResult watch.results)
                        ]
                    ]
                ]


viewResult : Watches.Node -> Html Msg
viewResult node =
    li []
        [ a [ href node.url ] [ text (String.fromInt node.number) ]
        , text " :: "
        , span [ onClick (HideWatchedItem node.number node.repository.nameWithOwner) ] [ text "⦸" ]
        , text " :: "
        , text node.title
        ]
