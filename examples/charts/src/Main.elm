-- ~\~ language=Elm filename=src/Main.elm
-- ~\~ begin <<README.md|src/Main.elm>>[init]


port module Main exposing (main)

{-| This Main module provides an example of how the [StreamCardano API](https://docs-beta.streamcardano.dev/) can be called and processed.
-}

import Browser exposing (Document)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput)
import Http as Http exposing (Error)
import Json.Decode as D
import Json.Encode as E
import RemoteData exposing (RemoteData(..), WebData)
import StreamCardano.Api as Api
import StreamCardano.Data.LastBlock as LastBlock exposing (LastBlock)
import StreamCardano.Data.NewBlock as NewBlock exposing (NewBlock)
import StreamCardano.Data.Query as Query exposing (BlockNo, Query)
import StreamCardano.Data.Status as Status exposing (Status)
import StreamCardano.Endpoint as Endpoint



{- Integrates with Javascript to use Server-Sent Events, which Elm does not support natively. -}


port listenNewBlocks : () -> Cmd msg


port newBlocksReceiver : (E.Value -> msg) -> Sub msg


main : Program Flags Model Msg
main =
    Browser.document
        { init = init
        , subscriptions = subscriptions
        , update = update
        , view = view
        }


{-| The Model contains StreamCardano API credentials and responses.
-}
type alias Model =
    { credentials : Api.Credentials
    , activeTab : Tab
    , query : String
    , isQueryDebugMode : Bool
    , status : WebData Status
    , sqlQuery : WebData Query
    , transactions : WebData Transactions
    , blocks : WebData (List Block)

    --
    , lastBlock : WebData LastBlock
    , newBlocks : RemoteData D.Error (List NewBlock)
    }


type alias Transactions =
    Query


type alias Block =
    BlockNo


type Tab
    = Dashboard
    | Query
    | Transactions
    | Blocks


allTabs : List Tab
allTabs =
    [ Dashboard, Query, Transactions, Blocks ]


tabToStr : Tab -> String
tabToStr tab =
    case tab of
        Dashboard ->
            "Dashboard"

        Query ->
            "Query"

        Transactions ->
            "Transactions"

        Blocks ->
            "Blocks"


{-| StreamCardano host and key values are passed into Elm via Flags.
-}
type alias Flags =
    { host : String
    , key : String
    }


{-| Secret values are passed into Elm with flags on initialization and the `getStatus` command is sent that tells the Elm run-time to perform a GET request upon initialization.
-}
init : Flags -> ( Model, Cmd Msg )
init flags =
    let
        credentials =
            Api.credentials flags
    in
    ( { credentials = credentials
      , activeTab = Blocks --Dashboard
      , query = "SELECT tx_id, value FROM datum ORDER BY tx_id DESC LIMIT 1"
      , isQueryDebugMode = False
      , status = Loading
      , sqlQuery = NotAsked
      , transactions = Loading
      , blocks = Loading

      --
      , lastBlock = NotAsked
      , newBlocks = NotAsked
      }
    , --Api.getStatus GotStatus credentials
      Api.postQuery GotBlocks
        credentials
        "SELECT * FROM block LIMIT 10"
    )


type Msg
    = GotStatus (Result Error Status)
    | ChangedTab Tab
    | ToggledDebugMode
    | GotTransactions (Result Error Query)
    | GotBlocks (Result Error Query)
      --
    | GetLastBlock
    | GotLastBlock (Result Error LastBlock)
    | ChangeQuery String
    | RunQuery
    | PostedQuery (Result Error Query)
    | ListenNewBlocks
    | GotNewBlock (Result D.Error (List NewBlock))


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case Debug.log "msg" msg of
        GotStatus (Ok status) ->
            ( { model | status = Success status }, Cmd.none )

        GotStatus (Err err) ->
            ( { model | status = Failure err }, Cmd.none )

        ChangedTab tab ->
            ( { model | activeTab = tab }, Cmd.none )

        ToggledDebugMode ->
            ( { model | isQueryDebugMode = not model.isQueryDebugMode }, Cmd.none )

        GotTransactions (Ok query) ->
            ( { model | transactions = Success query }, Cmd.none )

        GotTransactions (Err err) ->
            ( { model | transactions = Failure err }, Cmd.none )

        GotBlocks (Ok query) ->
            let
                blocks =
                    query.result
                        |> List.filterMap
                            (\x ->
                                case x of
                                    Query.ResultBlockNo block ->
                                        Just block

                                    _ ->
                                        Nothing
                            )
            in
            ( { model | blocks = Success blocks }, Cmd.none )

        GotBlocks (Err err) ->
            ( { model | blocks = Failure err }, Cmd.none )

        GetLastBlock ->
            ( { model | lastBlock = Loading }
            , Api.getLastBlock GotLastBlock
                model.credentials
            )

        GotLastBlock (Ok block) ->
            ( { model | lastBlock = Success block }, Cmd.none )

        GotLastBlock (Err err) ->
            ( { model | lastBlock = Failure err }, Cmd.none )

        ChangeQuery str ->
            ( { model | query = str }, Cmd.none )

        RunQuery ->
            ( { model | sqlQuery = Loading }
            , postQuery model.isQueryDebugMode
                PostedQuery
                model.credentials
                model.query
            )

        PostedQuery (Ok query) ->
            ( { model | sqlQuery = Success query }, Cmd.none )

        PostedQuery (Err err) ->
            ( { model | sqlQuery = Failure err }, Cmd.none )

        GotNewBlock (Ok newBlocks) ->
            ( { model
                | newBlocks =
                    model.newBlocks
                        |> RemoteData.withDefault []
                        |> (++) newBlocks
                        |> Success
              }
            , Cmd.none
            )

        GotNewBlock (Err err) ->
            ( { model | newBlocks = Failure err }, Cmd.none )

        ListenNewBlocks ->
            ( { model | newBlocks = Loading }, listenNewBlocks () )


postQuery : Bool -> (Result Error Query -> msg) -> Api.Credentials -> String -> Cmd msg
postQuery isDebugMode =
    if isDebugMode then
        Api.postQuery

    else
        Api.postQueryDebug


{-| Subscribe to the `newBlocksReceiver` port to listen streaming events
-}
subscriptions : Model -> Sub Msg
subscriptions _ =
    (GotNewBlock << D.decodeValue (D.list NewBlock.decoder))
        |> newBlocksReceiver


{-| View displays the Stream Cardano API responses in simple styles, and all stylesheets are in main.css.
-}
view : Model -> Document Msg
view model =
    { title = "StreamCardano"
    , body =
        [ viewNav model
        , viewMain model
        ]
    }


viewNav : Model -> Html Msg
viewNav model =
    header [ class "cds--header", attribute "data-carbon-theme" "g100" ]
        [ a [ class "cds--header__name" ] [ text "Stream Cardano Charts" ]
        , nav [ class "cds--header__menu-bar" ]
            [ viewGetLastBlockButton
            , viewListenNewBlockButton
            ]
        ]


viewGetLastBlockButton : Html Msg
viewGetLastBlockButton =
    a [ class "cds--header__menu-item", onClick GetLastBlock ] [ text "Get Last Block" ]


viewListenNewBlockButton : Html Msg
viewListenNewBlockButton =
    a [ class "cds--header__menu-item", onClick ListenNewBlocks ] [ text "Listen to New Blocks" ]


viewRunQueryForm : Bool -> String -> Html Msg
viewRunQueryForm isDebugMode query =
    div [ class "cds--form" ]
        [ div [ class "cds--stack-vertical cds--stack-scale-7" ]
            [ div [ class "cds--form-item" ]
                [ div [ class "cds--toggle", onClick ToggledDebugMode ]
                    [ div [ class "cds--toogle_label" ]
                        [ span [ class "cds--toggle__label-text" ]
                            [ text "Debug mode"
                            ]
                        , div [ class "cds--toggle__appearance" ]
                            [ div [ classList [ ( "cds--toggle__switch", True ), ( "cds--toggle__switch--checked", isDebugMode ) ] ] []
                            , div [ class "cds-toggle__text" ] []
                            ]
                        ]
                    ]
                ]
            , div [ class "cds--form-item" ]
                [ div [ class "cds--text-area__label-wrapper" ]
                    [ div [ class "cds--label" ] [ text "Query" ] ]
                , div [ class "cds--text-area__wrapper" ]
                    [ textarea [ class "cds--text-area", attribute "cols" "75", attribute "rows" "3", onInput ChangeQuery, value query ] [] ]
                ]
            , button [ class "cds--btn cds--btn--primary", onClick RunQuery ] [ text "Submit" ]
            ]
        ]


viewMain : Model -> Html Msg
viewMain model =
    main_ [ class "main" ]
        [ div [ class "header" ]
            [ div [ class "cds--grid" ]
                [ div [ class "cds--row" ]
                    [ div [ class "cds--col-sm-3" ]
                        [ h1 [ class "title" ] [ text "UI Elements" ]
                        , h4 [ class "description" ] [ text "Streamlines Cardano dApp Development" ]
                        ]
                    , div [ class "cds--col-sm-1", attribute "data-carbon-theme" "g90" ]
                        [ div [ class "notification" ] [ viewStatus model.status ] ]
                    ]
                ]
            ]
        , div [ class "tabs" ]
            [ div [ class "cds--grid" ]
                [ div [ class "cds--row" ]
                    [ div [ class "cds--col" ]
                        [ div [ class "cds--tabs cds--tabs" ]
                            [ div [ class "cds--tabs--list" ]
                                (List.map (viewTab ((==) model.activeTab)) allTabs)
                            ]
                        ]
                    ]
                ]
            ]
        , div [ class "body" ]
            [ div [ class "cds--grid" ]
                [ div [ class "cds--row" ]
                    [ div [ class "cds--col" ]
                        [ viewBody model
                        ]
                    ]
                ]
            ]
        ]


viewTab : (Tab -> Bool) -> Tab -> Html Msg
viewTab isActive tab =
    button
        [ classList
            [ ( "cds--tabs__nav-item cds--tabs__nav-link", True )
            , ( "cds--tabs__nav-item--selected", isActive tab )
            ]
        , onClick (ChangedTab tab)
        ]
        [ text (tabToStr tab) ]


viewBody : Model -> Html Msg
viewBody model =
    case model.activeTab of
        Dashboard ->
            viewResponses model

        Query ->
            div []
                [ viewRunQueryForm model.isQueryDebugMode model.query
                , viewPostedQuery model.sqlQuery
                ]

        Transactions ->
            viewTransactions model.transactions

        Blocks ->
            viewBlocks model.blocks


viewTransactions : WebData Transactions -> Html Msg
viewTransactions wd =
    case Debug.log "wd: " wd of
        NotAsked ->
            viewNotAsked

        Loading ->
            text ""

        Failure err ->
            viewLoading

        -- errorToString err
        --     |> viewError description path method
        Success transactions ->
            div []
                [ text "transactions" ]


viewBlocks : WebData (List Block) -> Html Msg
viewBlocks wd =
    case Debug.log "wd: " wd of
        NotAsked ->
            viewNotAsked

        Loading ->
            text ""

        Failure err ->
            viewLoading

        -- errorToString err
        --     |> viewError description path method
        Success blocks ->
            blocks
                |> List.map (\b -> span [] [ text b.hash ])
                |> div []


viewResponses : Model -> Html msg
viewResponses model =
    div [ class "cds--grid" ]
        [ viewListenNewBlocks model.newBlocks
        , viewLastBlock model.lastBlock
        ]


viewListenNewBlocks : RemoteData D.Error (List NewBlock) -> Html msg
viewListenNewBlocks newBlocks =
    viewRemoteData
        { description = "Listen to new blocks on the chain"
        , path = Endpoint.runQuery
        , method = "POST"
        , encode = E.list NewBlock.encode
        , errorToString = D.errorToString
        }
        newBlocks


viewLastBlock : WebData LastBlock -> Html msg
viewLastBlock lastBlock =
    viewRemoteData
        { description = "Get the number of the last block."
        , path = Endpoint.lastBlock
        , method = "GET"
        , encode = LastBlock.encode
        , errorToString = httpErrorToString
        }
        lastBlock


viewPostedQuery : WebData Query -> Html msg
viewPostedQuery query =
    viewRemoteData
        { description = "Run a custom database query and retrieve its results."
        , path = Endpoint.runQuery
        , method = "POST"
        , encode = Query.encode
        , errorToString = httpErrorToString
        }
        query


viewStatus : WebData Status -> Html msg
viewStatus rd =
    case rd of
        NotAsked ->
            viewNotAsked

        Loading ->
            text ""

        Failure err ->
            viewLoading

        -- errorToString err
        --     |> viewError description path method
        Success status ->
            div [ class "cds--toast-notification cds--toast-notification--success", title "" ]
                [ div [ class "cds--toast-notification_details" ]
                    [ h3 [ class "cds--toast-notification__title" ] [ text "Connected to server" ]
                    , p [ class "cds--toast-notification__subtitle" ] [ text <| "Network name: " ++ status.result.networkName ]
                    , p [ class "cds--toast-notification__caption", title status.result.appVersionInfo.appCommit ] [ text <| "version: " ++ (String.left 10 <| status.result.appVersionInfo.appCommit) ++ "..." ]
                    ]
                ]


viewRemoteData :
    { description : String
    , path : String
    , method : String
    , encode : a -> E.Value
    , errorToString : e -> String
    }
    -> RemoteData e a
    -> Html msg
viewRemoteData { description, path, method, encode, errorToString } rd =
    case rd of
        NotAsked ->
            viewNotAsked

        Loading ->
            viewLoading

        Failure err ->
            errorToString err
                |> viewError description path method

        Success x ->
            viewSuccess description path method (encode x)


viewNotAsked : Html msg
viewNotAsked =
    text ""


viewLoading : Html msg
viewLoading =
    div [ class "loading" ] [ text "Loading..." ]


viewSuccess : String -> String -> String -> E.Value -> Html msg
viewSuccess desc path method value =
    div []
        [ code []
            [ p [] [ text desc ]
            , span [ class "path" ]
                [ strong [] [ text method ], text path ]
            , p [] [ strong [] [ text "Response:" ] ]
            , div [ class "cds--snippet" ]
                [ code []
                    [ pre []
                        [ value
                            |> E.encode 4
                            |> text
                        ]
                    ]
                ]
            ]
        ]


viewError : String -> String -> String -> String -> Html msg
viewError desc path method error =
    div [ class "error" ]
        [ p [] [ text desc ]
        , span [ class "path" ]
            [ strong [] [ text method ], text path ]
        , p [] [ strong [] [ text "Response:" ] ]
        , pre []
            [ text error ]
        ]


httpErrorToString : Error -> String
httpErrorToString error =
    case error of
        Http.BadUrl u ->
            "Invalid URL: " ++ u

        Http.Timeout ->
            "Request timed out"

        Http.NetworkError ->
            "Network Error occured"

        Http.BadStatus i ->
            "Bad Status Error: " ++ String.fromInt i

        Http.BadBody s ->
            "Bad Body." ++ s



-- ~\~ end
