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
import JsonTree
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
    , jsonState : JsonTree.State

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
      , activeTab = Query --Dashboard
      , query = "SELECT * FROM block LIMIT 3"
      , isQueryDebugMode = False
      , status = Loading
      , sqlQuery = NotAsked
      , transactions = Loading
      , blocks = Loading
      , jsonState = JsonTree.defaultState

      --
      , lastBlock = NotAsked
      , newBlocks = NotAsked
      }
    , --Api.getStatus GotStatus credentials
      postQuery False
        PostedQuery
        credentials
        "SELECT * FROM block LIMIT 3"
    )


type Msg
    = GotStatus (Result Error Status)
    | ChangedTab Tab
    | ToggledDebugMode
    | GotTransactions (Result Error Query)
    | GotBlocks (Result Error Query)
    | SetTreeViewState JsonTree.State
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
    case msg of
        GotStatus (Ok status) ->
            ( { model | status = Success status }, Cmd.none )

        GotStatus (Err err) ->
            ( { model | status = Failure err }, Cmd.none )

        ChangedTab tab ->
            ( { model | activeTab = tab }
            , case tab of
                Blocks ->
                    Api.postQuery GotBlocks model.credentials "SELECT * FROM block LIMIT 7"

                _ ->
                    Cmd.none
            )

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

        SetTreeViewState state ->
            ( { model | jsonState = state }, Cmd.none )

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
                [ viewBody model ]
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
                [ div [ class "cds--row" ]
                    [ div [ class "cds--col" ] [ viewRunQueryForm model.isQueryDebugMode model.query ]
                    ]
                , viewPostedQuery model.jsonState model.sqlQuery
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
    case wd of
        NotAsked ->
            viewNotAsked

        Loading ->
            viewLoading

        Failure err ->
            viewGeneralError

        Success blocks ->
            viewBlocksSuccess blocks


barEncode : Block -> E.Value
barEncode b =
    E.object
        [ ( "group", E.string <| String.fromInt b.blockNo )
        , ( "date", E.string b.time )
        , ( "value", E.int b.txCount )
        ]


areaEncode : Block -> E.Value
areaEncode b =
    E.object
        [ ( "group", E.string "Blocks" )
        , ( "date", E.string b.time )
        , ( "value", E.int b.txCount )
        ]


viewBlocksSuccess : List BlockNo -> Html msg
viewBlocksSuccess blocks =
    div [ class "cds--row charts-demo" ]
        [ div [ class "cds--col-sm-4 cds--col-lg-16 cds--col-xlg-8" ]
            [ div [ class "chart-demo" ]
                [ node "bar-simple"
                    [ attribute "title" "The number of transactions per block"
                    , blocks
                        |> E.list barEncode
                        |> property "chartData"
                    ]
                    []
                ]
            ]
        , div [ class "cds--col-sm-4 cds--col-lg-16 cds--col-xlg-8" ]
            [ div [ class "chart-demo" ]
                [ node "area-bounded"
                    [ attribute "title" "The number of transactions per block"
                    , blocks
                        |> E.list areaEncode
                        |> property "chartData"
                    ]
                    []
                ]
            ]
        ]


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


viewPostedQuery : JsonTree.State -> WebData Query -> Html Msg
viewPostedQuery tree rd =
    case rd of
        NotAsked ->
            viewNotAsked

        Loading ->
            viewLoading

        Failure err ->
            viewGeneralError

        Success query ->
            viewPostedQuerySuccess tree query


viewPostedQuerySuccess : JsonTree.State -> Query -> Html Msg
viewPostedQuerySuccess treeState query =
    let
        encoded =
            Query.encode query
    in
    div [ class "response" ]
        [ div [ class "cds--row switcher" ]
            [ div [ class "cds--col-sm-1" ] [ text "menu" ] ]
        , div [ class "cds--row" ]
            [ div [ class "cds--col-sm-1" ] [ viewJSONRaw encoded ]

            -- , div [ class "cds--col-sm-1" ] [ viewJSONTable encoded ]
            , div [ class "cds--col-sm-1" ] [ viewJSONTree treeState encoded ]
            ]
        ]


viewJSONRaw : E.Value -> Html msg
viewJSONRaw value =
    div [ class "cds--snippet" ]
        [ code []
            [ pre []
                [ value
                    |> E.encode 4
                    |> text
                ]
            ]
        ]


viewJSONTable : E.Value -> Html msg
viewJSONTable value =
    div [ class "cds--snippet" ]
        [ code []
            [ pre []
                [ value
                    |> E.encode 4
                    |> text
                ]
            ]
        ]


viewJSONTree : JsonTree.State -> E.Value -> Html Msg
viewJSONTree state value =
    div [ class "cds--snippet" ]
        [ code []
            [ pre []
                [ JsonTree.parseValue value
                    |> Result.map (\tree -> JsonTree.view tree config state)
                    |> Result.withDefault (text "Failed to parse JSON")
                ]
            ]
        ]


config =
    { onSelect = Nothing, toMsg = SetTreeViewState, colors = JsonTree.defaultColors }


viewStatus : WebData Status -> Html msg
viewStatus rd =
    case rd of
        NotAsked ->
            viewNotAsked

        Loading ->
            viewLoading

        Failure err ->
            viewGeneralError

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


viewGeneralError : Html msg
viewGeneralError =
    div [ class "error" ] [ text "Error..." ]


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
