---
authors: Dima S., Michal J. Gajda

title: Data visualization

date: 2023-03-31

layout: tutorial

categories: [tutorial]

description: "Data visualization"

---

In this tutorial we will show you how to draw the chart using the [StreamCardano API](https://docs-beta.streamcardano.dev/). 

# Preliminaries

Firstly, create an [Elm](https://elm-lang.org) app with a [Vite's](https://vitejs.dev) vanilla template from scratch using the following command.

```sh
npm create --yes vite@3 my-app -- --template vanilla
```

Next, change into your project directory, install dependenciesi, and install __vite-plugin-elm__ which provides Elm support.

```sh
cd charts
```

```{.sh #runit}
npm i
npm i -D vite-plugin-elm
```

After running this, we will update vite.config.js to include the new elm plugin. This leaves the vite config looking as follows:

```{.js file=vite.config.js}
import { defineConfig } from 'vite'
import elmPlugin from 'vite-plugin-elm'

console.log(elmPlugin.plugin())

export default defineConfig({
  plugins: [elmPlugin.plugin()],
  css: {
    preprocessorOptions: {
      scss: {
        includePaths: ['node_modules'],
      },
    },
  }
})
```

Let's setup the environment variables so our App does not hold our configuration and secrets, make sure to name your environment variables starting with __VITE__ naming convention otherwise Vite application will not pick them:

```{.sh file=.env.example}
VITE_STREAMCARDANO_HOST=beta.streamcardano.dev
VITE_STREAMCARDANO_KEY=YOUR_API_KEY_HERE
```

To get started with Elm, we'll use an `init` command to create an elm.json file.

```{.sh #runit}
yes | npx elm init
yes | npx elm install elm/http
yes | npx elm install elm/json
yes | npx elm install krisajenkins/remotedata
yarn add @microsoft/fetch-event-source
yarn add @carbon/styles
yes | npx elm install elm/json
yes | npx elm install NoRedInk/elm-json-decode-pipeline
npm i -D elm-test 
yes | npx elm-test init
rm tests/Example.elm
yes | npx elm install elm/time
yes | npx elm install rtfeldman/elm-iso8601-date-strings
```

Add elm-stuff and elm-repl generated files to .gitignore.

```{.sh #gitignore}
elm-stuff
repl-temp-*
```

In the src directory, we'll create a file called main.js. Provide the host and key values through flags in the main.js file to set up the Elm application.

```{.js file=main.js}
import { Elm } from "./src/Main.elm";
import styles from "./src/main.scss";
import { setupPorts } from "./src/ports";

const key = import.meta.env.VITE_STREAMCARDANO_KEY;
const host = import.meta.env.VITE_STREAMCARDANO_HOST;
const flags = { key: key, host: host };

let app = Elm.Main.init({ flags: flags });
setupPorts(app, `https://${host}/api/v1/sse`, key);

```

# Elm app

We will be creating an Elm app, which does:

1. Check if the StreamCardano service is online
2. Check that StreamCardano is up-to-date with the cardano network
3. Listing transaction data of Your smart contract
4. Streaming Events of StreamCardano API


## Main

We will be creating a (document)[https://package.elm-lang.org/packages/elm/browser/latest/Browser#document] program, compile it to a JavaScript file. This is the layout of such a program in Elm:

```{.elm file=src/Main.elm}


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
import StreamCardano.Data.Query as Query exposing (Query)
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
    , query : String
    , status : WebData Status
    , lastBlock : WebData LastBlock
    , sqlQuery : WebData Query
    , newBlocks : RemoteData D.Error (List NewBlock)
    }


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
      , query = "SELECT tx_id, value FROM datum ORDER BY tx_id DESC LIMIT 1"
      , status = Loading
      , lastBlock = NotAsked
      , sqlQuery = NotAsked
      , newBlocks = NotAsked
      }
    , Api.getStatus GotStatus credentials
    )


type Msg
    = GotStatus (Result Error Status)
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
            , Api.postQuery PostedQuery
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
    header [ class "cds--header" ]
        [ a [ class "cds--header__name" ] [ text "Stream Cardano Charts" ]
        , nav [ class "cds--header__menu-bar" ]
            [ viewGetLastBlockButton
            , viewListenNewBlockButton
            ]

        -- , viewRunQueryForm model.query
        ]


viewGetLastBlockButton : Html Msg
viewGetLastBlockButton =
    a [ class "cds--header__menu-item", onClick GetLastBlock ] [ text "Get Last Block" ]


viewListenNewBlockButton : Html Msg
viewListenNewBlockButton =
    a [ class "cds--header__menu-item", onClick ListenNewBlocks ] [ text "Listen to New Blocks" ]


viewRunQueryForm : String -> Html Msg
viewRunQueryForm query =
    div [ class "run-query-form" ]
        [ textarea [ onInput ChangeQuery, value query ] []
        , button [ onClick RunQuery ] [ text "Run Query" ]
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
                    , div [ class "cds--col-sm-1" ]
                        [ div [ class "notification" ] [ viewStatus model.status ] ]
                    ]
                ]
            ]
        , div [ class "tabs" ]
            [ div [ class "cds--grid" ]
                [ div [ class "cds--row" ]
                    [ div [ class "cds--col" ]
                        [ div [ class "cds--tabs cds--tabs--contained" ]
                            [ div [ class "cds--tabs--list" ]
                                [ button [ id "tab-id-1", class "cds--tabs__nav-item cds--tabs__nav-link cds--tabs__nav-item--selected" ] [ text "Dashboard" ]
                                , button [ class "cds--tabs__nav-item cds--tabs__nav-link" ] [ text "Transactions Per Block" ]
                                , button [ class "cds--tabs__nav-item cds--tabs__nav-link" ] [ text "Status" ]
                                , button [ class "cds--tabs__nav-item cds--tabs__nav-link" ] [ text "Status" ]
                                ]
                            ]
                        ]
                    ]
                ]
            ]
        , div [ class "body" ]
            [ div [ class "cds--grid" ]
                [ div [ class "cds--row" ]
                    [ div [ class "cds--col" ]
                        [ div [ class "outside" ]
                            [ viewResponses model ]
                        ]
                    ]
                ]
            ]
        ]


viewResponses : Model -> Html msg
viewResponses model =
    div [ class "cds--grid" ]
        [ viewListenNewBlocks model.newBlocks
        , viewLastBlock model.lastBlock
        , viewPostedQuery model.sqlQuery
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



```
