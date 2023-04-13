-- ~\~ language=Elm filename=src/Main.elm
-- ~\~ begin <<README.md|src/Main.elm>>[init]


port module Main exposing (main)

{-| This Main module provides an example of how the [StreamCardano API](https://docs-beta.streamcardano.dev/) can be called and processed.
-}

import Browser exposing (Document)
import Dict exposing (Dict)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput)
import Http as Http exposing (Error)
import Json.Decode as D
import Json.Encode as E
import JsonTree exposing (TaggedValue(..))
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
    , activeSwitcher : Switcher

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
    | Contract
      -- Or a way to choose a smart contract from a combo box, and see all transactions on this smart contract.
    | Charts


type Switcher
    = All
    | Table
    | Tree


allTabs : List Tab
allTabs =
    [ Dashboard, Query, Contract, Charts ]


tabToStr : Tab -> String
tabToStr tab =
    case tab of
        Dashboard ->
            "Dashboard"

        Query ->
            "Query"

        Contract ->
            "Contract"

        Charts ->
            "Charts"


allSwitcher : List Switcher
allSwitcher =
    [ All, Table, Tree ]


switcherToStr : Switcher -> String
switcherToStr switcher =
    case switcher of
        All ->
            "All"

        Table ->
            "Table"

        Tree ->
            "Tree"


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
      , activeTab = Dashboard
      , query = "SELECT * FROM tx LIMIT 7"
      , isQueryDebugMode = False
      , status = Loading
      , sqlQuery = NotAsked
      , transactions = Loading
      , blocks = Loading
      , jsonState = JsonTree.defaultState
      , activeSwitcher = All

      --
      , lastBlock = NotAsked
      , newBlocks = NotAsked
      }
    , Cmd.batch
        [ Api.getStatus GotStatus credentials
        , Api.postQuery GotBlocks credentials "SELECT * FROM block LIMIT 7"
        ]
    )


type Msg
    = GotStatus (Result Error Status)
    | ChangedTab Tab
    | ToggledDebugMode
    | GotTransactions (Result Error Query)
    | GotBlocks (Result Error Query)
    | SetTreeViewState JsonTree.State
    | ChangedSwitcher Switcher
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
            , Cmd.none
            )

        ChangedSwitcher switcher ->
            ( { model | activeSwitcher = switcher }
            , Cmd.none
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
        [ a [ class "cds--header__name" ] [ text "Stream Cardano Dashboard" ]
        , nav [ class "cds--header__menu-bar" ] []
        ]


viewDocsButton : Html Msg
viewDocsButton =
    a [ class "cds--header__menu-item", href "https://docs-beta.streamcardano.dev" ] [ text "DOCS" ]


viewRunQueryForm : Bool -> String -> Html Msg
viewRunQueryForm isDebugMode query =
    div [ class "cds--grid" ]
        [ div [ class "cds--row" ]
            [ div [ class "cds--col-sm-3 cds--col-lg-7" ]
                [ div [ class "cds--form" ]
                    [ div [ class "cds--stack-vertical cds--stack-scale-7" ]
                        [ div [ class "cds--form-item" ]
                            [ div [ class "cds--text-area__label-wrapper" ]
                                [ div [ class "cds--label" ] [ text "Query" ] ]
                            , div [ class "cds--text-area__wrapper" ]
                                [ textarea [ class "cds--text-area", attribute "cols" "75", attribute "rows" "3", onInput ChangeQuery, value query ] [] ]
                            ]
                        , button [ class "cds--btn cds--btn--primary", onClick RunQuery ] [ text "Submit" ]
                        ]
                    ]
                ]
            , div [ class "cds--col-sm-1" ]
                [ viewDebugMode isDebugMode ]
            ]
        ]


viewDebugMode : Bool -> Html Msg
viewDebugMode isDebugMode =
    div [ class "cds--form-item" ]
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
        , div [ id "body" ]
            [ viewBody model ]
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
            viewDashboard model

        Query ->
            div []
                [ viewRunQueryForm model.isQueryDebugMode model.query
                , viewPostedQuery model.activeSwitcher model.jsonState model.sqlQuery
                ]

        Contract ->
            viewTransactions model.transactions

        Charts ->
            viewCharts model.blocks


viewDashboard : Model -> Html Msg
viewDashboard model =
    div [ class " dashboard" ]
        [ div [ class "cds--grid" ]
            [ div [ class "cds--row charts-demo" ]
                [ div [ class "cds--col-sm-4 cds--col-lg-16 cds--col-xlg-10" ]
                    [ div [ class "chart-demo" ]
                        [ model.blocks
                            |> RemoteData.map viewBarSimple
                            |> RemoteData.withDefault (text "loading")
                        ]
                    ]
                , div [ class "cds--col-sm-4 cds--col-lg-16 cds--col-xlg-6" ]
                    [ viewStatus model.status ]
                ]
            ]
        , div []
            [ viewRunQueryForm model.isQueryDebugMode model.query
            , viewPostedQuery model.activeSwitcher model.jsonState model.sqlQuery
            ]
        ]


viewTransactions : WebData Transactions -> Html Msg
viewTransactions wd =
    case wd of
        NotAsked ->
            viewNotAsked

        Loading ->
            viewLoading

        Failure err ->
            viewGeneralError

        Success transactions ->
            div []
                [ text "transactions" ]


viewCharts : WebData (List Block) -> Html Msg
viewCharts wd =
    case wd of
        NotAsked ->
            viewNotAsked

        Loading ->
            viewLoading

        Failure err ->
            viewGeneralError

        Success blocks ->
            viewChartsBlocks blocks


viewChartsBlocks : List BlockNo -> Html msg
viewChartsBlocks blocks =
    div [ class "cds--grid" ]
        [ div [ class "cds--row charts-demo" ]
            [ div [ class "cds--col-sm-4 cds--col-lg-16 cds--col-xlg-8" ]
                [ div [ class "chart-demo" ]
                    [ viewBarSimple blocks ]
                ]
            , div [ class "cds--col-sm-4 cds--col-lg-16 cds--col-xlg-8" ]
                [ div [ class "chart-demo" ]
                    [ viewAreaBounded blocks ]
                ]
            ]
        ]


barEncode : Block -> E.Value
barEncode b =
    E.object
        [ ( "group", E.string <| String.fromInt b.blockNo )
        , ( "date", E.string b.time )
        , ( "value", E.int b.txCount )
        ]


viewBarSimple : List BlockNo -> Html msg
viewBarSimple blocks =
    node "bar-simple"
        [ attribute "title" "The number of transactions per block"
        , blocks
            |> E.list barEncode
            |> property "chartData"
        ]
        []


areaEncode : Block -> E.Value
areaEncode b =
    E.object
        [ ( "group", E.string "Blocks" )
        , ( "date", E.string b.time )
        , ( "value", E.int b.txCount )
        ]


viewAreaBounded : List Block -> Html msg
viewAreaBounded blocks =
    node "area-bounded"
        [ attribute "title" "The number of transactions per block"
        , blocks
            |> E.list areaEncode
            |> property "chartData"
        ]
        []


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


viewPostedQuery : Switcher -> JsonTree.State -> WebData Query -> Html Msg
viewPostedQuery activeSwitcher jsonState rd =
    case rd of
        NotAsked ->
            viewNotAsked

        Loading ->
            viewLoading

        Failure err ->
            viewGeneralError

        Success query ->
            viewPostedQuerySuccess activeSwitcher jsonState query


viewPostedQuerySuccess : Switcher -> JsonTree.State -> Query -> Html Msg
viewPostedQuerySuccess activeSwitcher treeState query =
    let
        encoded =
            E.list Query.encodedQueryResultItem query.result
    in
    div [ class "response" ]
        [ div [ class "cds--grid switcher" ]
            [ div [ class "cds--row" ]
                [ div [ class "cds--col-sm-2 cds--col-lg-4 " ]
                    [ div [ class "cds--content-switcher cds--content-switcher--sm" ]
                        (List.map (viewSwitcher ((==) activeSwitcher)) allSwitcher)
                    ]
                ]
            ]
        , div [ class "cds--row panels" ]
            (div [ class "cds--col-sm-4 cds--col-lg-4" ] [ viewJSONRaw encoded ]
                :: (case activeSwitcher of
                        All ->
                            [ div [ class "cds--col-sm-4 cds--col-lg-6" ]
                                [ viewJSONTable encoded ]
                            , div
                                [ class "cds--col-sm-4 cds--col-lg-6" ]
                                [ viewJSONTree treeState encoded ]
                            ]

                        Table ->
                            [ div [ class "cds--col-sm-4 cds--col-lg-12" ] [ viewJSONTable encoded ] ]

                        Tree ->
                            [ div [ class "cds--col-sm-4 cds--col-lg-12" ] [ viewJSONTree treeState encoded ] ]
                   )
            )
        ]


viewSwitcher : (Switcher -> Bool) -> Switcher -> Html Msg
viewSwitcher isSelected switcher =
    button
        [ classList [ ( "cds--content-switcher-btn", True ), ( "cds--content-switcher--selected", isSelected switcher ) ]
        , onClick (ChangedSwitcher switcher)
        ]
        [ span
            [ class "cds--content-switcher__label"
            ]
            [ text (switcherToStr switcher) ]
        ]


viewJSONRaw : E.Value -> Html msg
viewJSONRaw value =
    div [ class "cds--snippet cds--snippet--multi cds--snippet--has-right-overflow" ]
        [ div [ class "cds--snippet-container" ]
            [ pre []
                [ value
                    |> E.encode 4
                    |> text
                ]
            ]
        ]


viewJSONTable : E.Value -> Html msg
viewJSONTable value =
    let
        x : Result D.Error JsonTree.Node
        x =
            JsonTree.parseValue value
    in
    case x of
        Err e ->
            text "error"

        Ok v ->
            div []
                (viewNodeInternal 0 v)


viewNodeInternal : Int -> JsonTree.Node -> List (Html msg)
viewNodeInternal depth node =
    case node.value of
        TString str ->
            viewScalar str

        TBool True ->
            viewScalar "true"

        TBool False ->
            viewScalar "false"

        TFloat x ->
            viewScalar (String.fromFloat x)

        TNull ->
            viewScalar "NULL"

        TList nodes ->
            viewList depth nodes

        TDict dict ->
            viewDict depth dict


viewTheadItem : Int -> JsonTree.Node -> List (Html msg)
viewTheadItem depth node =
    case node.value of
        TString str ->
            viewScalar str

        TBool True ->
            viewScalar "true"

        TBool False ->
            viewScalar "false"

        TFloat x ->
            viewScalar (String.fromFloat x)

        TNull ->
            viewScalar "NULL"

        TList nodes ->
            viewList depth nodes

        TDict dict ->
            viewDictHead depth dict


viewScalar : String -> List (Html msg)
viewScalar str =
    [ text str ]


viewList : Int -> List JsonTree.Node -> List (Html msg)
viewList depth nodes =
    let
        innerContent =
            case nodes of
                [] ->
                    []

                n1 :: ns ->
                    [ div [ class "cds--data-table-header" ]
                        [ div [ class "cds--data-table-content" ]
                            [ table [ class "cds--data-table" ]
                                [ thead [] (viewTheadItem (depth + 1) n1)
                                , tbody []
                                    (viewNodeInternal (depth + 1) n1
                                        ++ List.concatMap (viewNodeInternal (depth + 1)) ns
                                    )
                                ]
                            ]
                        ]
                    ]
    in
    innerContent


viewDictHead : Int -> Dict String JsonTree.Node -> List (Html msg)
viewDictHead depth dict =
    let
        viewListItem ( fieldName, node ) =
            th [] [ span [] [ text fieldName ] ]
    in
    List.map viewListItem (Dict.toList dict)


viewDict : Int -> Dict String JsonTree.Node -> List (Html msg)
viewDict depth dict =
    let
        viewListItem ( fieldName, node ) =
            td [] (viewNodeInternal (depth + 1) node)
    in
    [ tr []
        (List.map viewListItem (Dict.toList dict))
    ]



-- viewDict : Int -> Dict String JsonTree.Node -> List (Html msg)
-- viewDict depth dict =
--     let
--         innerContent =
--             if Dict.isEmpty dict then
--                 []
--             else
--                 [ ul
--                     []
--                     (List.map viewListItem (Dict.toList dict))
--                 ]
--         viewListItem ( fieldName, node ) =
--             li
--                 []
--                 ([ span [] [ text fieldName ]
--                  , text ": "
--                  ]
--                     ++ viewNodeInternal (depth + 1) node
--                     ++ [ text "," ]
--                 )
--     in
--     [ text "{" ] ++ innerContent ++ [ text "}" ]


viewJSONTree : JsonTree.State -> E.Value -> Html Msg
viewJSONTree state value =
    div [ class "cds--snippet cds--snippet--multi cds--snippet--has-right-overflow" ]
        [ div [ class "cds--snippet-container" ]
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
