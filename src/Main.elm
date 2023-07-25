module Main exposing (..)

import Browser
import Html exposing (..)
import Html.Attributes exposing (checked, class, classList, href, name, placeholder, src, type_, value)
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


type alias Watches =
    List Watch


type alias Links =
    List Link


type alias Link =
    { id : Int
    , createdAt : String
    , url : String
    , name : String
    , logoURL : String
    , shared : Bool
    }


type alias Watch =
    { id : Int
    , ownerId : Int
    , name : String
    , repo : String
    , resultCount : Int
    , results : List Node
    }


type alias Node =
    { number : Int
    , createdAt : String
    , repository : RepoInfo
    , title : String
    , url : String
    }


type alias RepoInfo =
    { nameWithOwner : String
    }


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
    | DeleteLink Int
    | DeletedWatch (Result Http.Error ())
    | DeleteWatch Int
    | GotLinks (Result Http.Error (List Link))
    | GotNewLink NewLink
    | GotNewWatch NewWatch
    | GotWatches (Result Http.Error (List Watch))
    | HideWatchedItem Int String
    | HidItem (Result Http.Error ())
    | Reload
    | ReloadLinks
    | ReloadWatches
    | SubmitLink
    | SubmitWatch
    | FetchIcons
    | LoadIcons (Result Http.Error ())


type Status
    = Loading
    | LoadedWatches (List Watch)
    | LoadedLinks (List Link)
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
    { watches : List Watch
    , links : List Link
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

        DeleteWatch watchId ->
            ( model, deleteWatch watchId )

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

        DeletedLink (Ok _) ->
            ( model, getLinks )

        DeletedLink (Err _) ->
            ( { model | status = Errored "Server error deleting link!" }, Cmd.none )

        DeletedWatch (Ok _) ->
            ( model, getWatches )

        DeletedWatch (Err _) ->
            ( { model | status = Errored "Server error deleting watch!" }, Cmd.none )

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

        GotWatches (Err _) ->
            ( { model | status = Errored "Server error when fetching watches!" }, Cmd.none )

        GotLinks (Err _) ->
            ( { model | status = Errored "Server error when fetching links!" }, Cmd.none )

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
                    [ b [] [ text "Maintenence" ] ]
                , button [ onClick FetchIcons ] [ text "Update Icons" ]
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


watchForm : Model -> NewWatch -> Html Msg
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


linkForm : Model -> NewLink -> Html Msg
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


viewLink : Link -> Html Msg
viewLink link =
    div []
        [ div [ class "icon" ]
            [ span [ onClick (DeleteLink link.id) ] [ text "×" ]
            , a [ href link.url ]
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


viewWatch : Watch -> Html Msg
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


viewResult : Node -> Html Msg
viewResult node =
    li []
        [ a [ href node.url ] [ text (String.fromInt node.number) ]
        , text " :: "
        , span [ onClick (HideWatchedItem node.number node.repository.nameWithOwner) ] [ text "⦸" ]
        , text " :: "
        , text node.title
        ]



-- DECODERS


linkListDecoder : Decoder (List Link)
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


watchListDecoder : Decoder (List Watch)
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
