---
authors: Dima S., Michal J. Gajda

title: Calling StreamCardano from Elm

date: 2023-02-14

layout: tutorial

categories: [tutorial]

description: "Call StreamCardano from the Elm web application, parse responses, and examine results."

---

In this tutorial we will show you how to call [StreamCardano API](https://docs-beta.streamcardano.dev/) using [Elm](https://elm-lang.org), parse the responses, test and debug your queries.

# Preliminaries

Firstly, create an [Elm](https://elm-lang.org) app with a [Vite's](https://vitejs.dev) vanilla template from scratch using the following command.

```sh
npm create --yes vite@3 my-app -- --template vanilla
```

Next, change into your project directory and install dependencies.

```sh
cd my-app
```

```{.sh #runit}
npm i
```

Install __vite-plugin-elm__ which provides Elm support.

```{.sh #runit}
npm i -D vite-plugin-elm
```

After running this, we will update vite.config.js to include the new elm plugin. This leaves the vite config looking as follows:

```{.js file=vite.config.js}
import { defineConfig } from 'vite'
import elmPlugin from 'vite-plugin-elm'

console.log(elmPlugin.plugin())
export default defineConfig({
  plugins: [elmPlugin.plugin()]
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
```

Add elm-stuff and elm-repl generated files to .gitignore.

```{.sh #gitignore}
elm-stuff
repl-temp-*
```

In the src directory, we'll create a file called main.js. Provide the host and key values through flags in the main.js file to set up the Elm application.

```{.js file=main.js}
import { Elm } from "./src/Main.elm";
import styles from "./src/main.css";

const key = import.meta.env.VITE_STREAMCARDANO_KEY;
const host = import.meta.env.VITE_STREAMCARDANO_HOST;
const flags = { streamcardanoKey: key, streamcardanoHost: host };

let app = Elm.Main.init({ flags: flags });
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
<<import>>
<<ports>>

<<main>>
<<model>>
<<update>>
<<subscriptions>>
<<view>>
```

We tell Elm to create a document in the main function

```{.elm #main}
main : Program Flags Model Msg
main =
    Browser.document
        { init          = init
        , subscriptions = subscriptions
        , update        = update
        , view          = view
        }
```

### Imports

We will try to import a minimum amount of third-party packages. Elm provides a package called [Http](https://package.elm-lang.org/packages/elm/http/2.0.0/) for sending and receiving data from a server and we need a [JSON](htts://package.elm-lang.org/packages/elm/json/1.1.3/) package to convert between Elm values and JSON values.

Install them by running the following command from the root directory in terminal.

```{.sh #runit}
yes | npx elm install elm/http
yes | npx elm install elm/json
```

After that, import the Elm modules in Main.elm.

```{.elm #import-elm-modules}
import Html                                exposing (..)
import Html.Attributes                     exposing (..)
import Html.Events                         exposing (onClick, onInput)
import Http                   as Http      exposing (Error)
import Json.Decode            as D
import Json.Encode            as E
import Browser                             exposing (Document)
```

To represent API-fetched data, we will use a data type called `RemoteData`. We need to install the [RemoteData](https://package.elm-lang.org/packages/krisajenkins/remotedata/6.0.1/) package.

```{.sh #runit}
yes | npx elm install krisajenkins/remotedata
```

Additionally, the RemoteData module should be imported into Main.elm.

```{.elm #import-community-modules}
import RemoteData                     exposing (RemoteData(..), WebData)
```
Last but not least, we must ensure that our internal modules are imported in Main.elm.

```{.elm #import-internal-modules}
import StreamCardano.Api      as Api 
import StreamCardano.Endpoint as Endpoint
import Data.Status            as Status    exposing (Status)
import Data.LastBlock         as LastBlock exposing (LastBlock)
import Data.NewBlock          as NewBlock  exposing (NewBlock)
import Data.Query             as Query     exposing (Query)
```

```{.elm #import}
<<import-elm-modules>>
<<import-community-modules>>
<<import-internal-modules>>
```

## The Model

Data modeling is extremely important in Elm. The model will consist of StreamCardano API credentials and responses. To represent remote data fetch state, we're going to use a `RemoteData` type. We also add a query field to track the user input. 

```{.elm #model}
{-| The Model contains StreamCardano API credentials and responses.
-}
type alias Model =
    { flags     : Flags
    , query     : String
    , status    : WebData Status
    , lastBlock : WebData LastBlock
    , sqlQuery  : WebData Query
    , newBlocks : RemoteData D.Error (List NewBlock)
    }
```

There will be a StreamCardano key and host in the Flags.

```{.elm #model}
{-| StreamCardano host and key values are passed into Elm via Flags.
-}
type alias Flags =
    { streamcardanoKey  : String
    , streamcardanoHost : String
    }
```

We'll create a data type for each request we need to keep track of: `Status`, `LastBlock`, `SqlQuery`, `NewBlocks`. Below the document, you'll find (an illustration of the LastBlock data type)[##Datatypes]. In the appendix.md, you'll find the other types. 

### Init

We pass our secret values into Elm with flags on initialization and set our initial state as Loading for the status remote data and NotAsked for the rest.

  * [ ] We also send a `getStatus` command that tells the Elm run-time to perform a GET request upon initialization. That command will eventually produce a `GotStatus` message that gets fed into our `update` function.

```{.elm #model}
{-| Secret values are passed into Elm with flags on initialization and the `getStatus` command is sent that tells the Elm run-time to perform a GET request upon initialization.
-}
init : Flags -> ( Model, Cmd Msg )
init flags =
    ( { flags     = flags
      , query     = "SELECT tx_id, value FROM datum ORDER BY tx_id DESC LIMIT 1"
      , status    = Loading
      , lastBlock = NotAsked
      , sqlQuery  = NotAsked
      , newBlocks = NotAsked
      }
    , Api.getStatus GotStatus
    )
```

The `getStatus api` call is checking if the service is online, to make sure the internet connection works. It's making a `GET` request with (Http.get)[https://package.elm-lang.org/packages/elm/http/latest/Http#get], the URL is pointing at a (StreamCardano status endpoint)[https://docs-beta.streamcardano.dev/#/default/get_api_v1_status], and we expect it to be a `Status` datatype.

```{.elm #ApiGetStatus}
{-| Send a basic request to check if the Service is online. No authentication is required.
-}
getStatus : (Result Error Status -> msg) -> Cmd msg
getStatus toMsg =
    Http.get
        { url    = Endpoint.status
        , expect = Http.expectJson toMsg Status.decoder
        }
```

The first argument `toMsg : Result Error Status -> msg` is saying that when we get a response, it should be turned into a message with a result type. 

```{.elm #msg-type}
type Msg
    = GotStatus (Result Error Status)
```

The Result type allows us to fully account for the possible failures in our update function. 

## Update

```{.elm #update-function}
update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GotStatus (Ok status) ->
            ( { model | status = Success status }, Cmd.none )

        GotStatus (Err err) ->
            ( { model | status = Failure err }, Cmd.none )
```

Our update function is returning a bit more information. We pattern-match on messages. When a GotStatus message comes in, we inspect the Result of our HTTP request and update our model depending on whether it was a success or failure. 

```{.elm #update}
<<msg-type>>
<<update-function>>
```

We need to create a `View` function to describes how to translate the response state into an HTML element.

```{.elm #viewStatus}
viewStatus: WebData Status -> Html msg 
viewStatus status =
    viewRemoteData
        { description = "Retrieve status information about the backend. Does not require authentication."
        , path = Endpoint.status
        , method = "GET"
        , encode = Status.encode
        , errorToString = httpErrorToString
        }
        status
```
 
If the connection is good we should see a response result.

![Succesfull Status Response](assets/images/tutorials/elm-tutorial/status_response.png)


## Checking That StreamCardano Is Up-to-Date With the Cardano Network?

And now we may check what the last block ID recorded in the database is, let's create the button which sends a `GetLastBlock` message to call `getLastBlock` command after that.


```{.elm #viewGetLastBlockButton}
viewGetLastBlockButton : Html Msg
viewGetLastBlockButton =
    button [ onClick GetLastBlock ] [ text "Get Last Block" ]
```

```{.elm #msg-type}
    | GetLastBlock
```

```{.elm #update-function}
        GetLastBlock ->
            ( { model | lastBlock = Loading }
            , Api.getLastBlock model.flags.streamcardanoKey
                GotLastBlock
            )
```

### Authorization

The `getLastBlock` api call is making a GET request and it is expecting a `LastBlock` result type. 


```{.elm #ApiGetLastBlock}
{-| Checking StreamCardano is up-to-date with the Cardano network.
-}
getLastBlock : String -> (Result Error LastBlock -> msg) -> Cmd msg
getLastBlock key msg =
    let
        bearer =
            "Bearer " ++ key
    in
    Http.request
        { method  = "GET"
        , headers = [ Http.header "Authorization" bearer ]
        , url     = Endpoint.lastBlock
        , body    = Http.emptyBody
        , expect  = Http.expectJson msg LastBlock.decoder
        , timeout = Nothing
        , tracker = Nothing
        }
```

But in order to make a call you need to provide the Streamcardano API key. You have a developer key with a unique id for your application. For now, you may use all developer APIs at a limited rate. To deploy in production, you will get a key with only a limited functionality but a much higher allowed query rate that permits thousands of simultaneous users.

```{.elm #msg-type}
    | GotLastBlock (Result Error LastBlock)
```

The update function handles the result response in quite the same manner.

```{.elm #update-function}
        GotLastBlock (Ok block) ->
            ( { model | lastBlock = Success block }, Cmd.none )

        GotLastBlock (Err err) ->
            ( { model | lastBlock = Failure err }, Cmd.none )
```

You can see a screenshot of the successful "Get Last Block" response here.

![Succesfull Get Last Block Response](assets/images/tutorials/elm-tutorial/get_last_block_response.png)

## Run a custom database query

To get better performance you may want to avoid transmitting unnecessary data. This can be done using a custom SQL query that only gets the block number, hash, and transaction count. 

Using the `view` function, we'll have one input field and one button for running the query. 

```{.elm #viewRunQueryForm}
viewRunQueryForm : String -> Html Msg
viewRunQueryForm query =
    div [class "run-query-form"]
        [ textarea [ onInput ChangeQuery, value query] []
        , button [ onClick RunQuery ] [ text "Run Query"]
        ]
```

We have a pretty clear idea of what the `update` code will look like. There are three cases we need to handle: changing the text area, running a query, and handling the server response.

```{.elm #msg-type}
    | ChangeQuery String
    | RunQuery
    | PostedQuery (Result Error Query)
```

This means our update needs a case for all three variations:

```{.elm #update-function}
        ChangeQuery str ->
            ( { model | query = str }, Cmd.none )
        RunQuery ->
            ( { model | sqlQuery = Loading }
            , Api.postQuery model.flags.streamcardanoKey model.query
                PostedQuery
            )

        PostedQuery (Ok query) ->
            ( { model | sqlQuery = Success query }, Cmd.none )

        PostedQuery (Err err) ->
            ( { model | sqlQuery = Failure err }, Cmd.none )
```

The view fucntion is using `viewRemoteData` helper functions to display the server response.

```{.elm #viewPostedQuery}
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
```

You can see a screenshot of the successful "Run Query" response here.

![Succesfull Run Query Response](assets/images/tutorials/elm-tutorial/posted_query_response.png)

## Streaming Events of StreamCardano API

Elm doesn't support Server-Sent Events natively, so let's use ports. Let's start by creating and importing a `port.js` file and exporting a `setupPorts` function.

```{.js file=main.js}
import { setupPorts } from "./src/ports";

setupPorts(app, `https://${host}/api/v1/sse`, key);
```

For streaming events we will use __fetchEventSource__ from [@microsoft/fetch-event-source](https://www.npmjs.com/package/@microsoft/fetch-event-source) npm package, to smoothly receive live events.

```{.sh #runit}
yarn add @microsoft/fetch-event-source
```

### Outgoing Messages (Cmd)

The `listenNewBlocks` declaration lets us send messages out of Elm 

```{.elm #ports}
{- Integrates with Javascript to use Server-Sent Events, which Elm does not support natively.
-}
port listenNewBlocks   : ()              -> Cmd msg
```

Now we need to create the button which sends a `ListenNewBlocks` message to call `listenNewBlocks` command after that.

```{.elm #viewListenNewBlockButton}
viewListenNewBlockButton : Html Msg
viewListenNewBlockButton =
    button [ onClick ListenNewBlocks ] [ text "Listen to New Blocks" ]
```

Now we can use `listenNewBlocks` in our `update` function to produce a command.

```{.elm #update}
        ListenNewBlocks ->
            ( { model | newBlocks = Loading }, listenNewBlocks () )
```

We will hear about about it on the JavaScript side:

```{.js #portsLitenNewBlocks}
  app.ports.listenNewBlocks.subscribe(() => {
    fetchData(sseEndpoint, key, app);
  });
```

### Incoming Messages (Sub)

The `newBlocksReceiver` declaration lets us listen for messages coming in to Elm. 

```{.elm #ports}
port newBlocksReceiver : (E.Value -> msg) -> Sub msg
```

On the JavaScript side, we'll send the parsed date when the request succeeds:

```{.js #portsNewBlockReceiver}
        const parsedData = JSON.parse(event.data);
        if(parsedData) {
          app.ports.newBlocksReceiver.send(parsedData);
        }
```

### Subscriptions

Subscribe to the `newBlocksReceiver` port to hear about messages coming in from JS. 

```{.elm #subscriptions}
{-| Subscribe to the `newBlocksReceiver` port to listen streaming events 
-}
subscriptions : Model -> Sub Msg
subscriptions _ =
    (GotNewBlock << D.decodeValue (D.list NewBlock.decoder))
        |> newBlocksReceiver
```

```{.elm #msg-type}
    | ListenNewBlocks
    | GotNewBlock (Result D.Error (List NewBlock))
```

As soon as we get the message, we decode the value and update our model.

```{.elm #update-function}
        GotNewBlock (Ok newBlocks) ->
            ( { model
                | newBlocks =
                    model.newBlocks
                        |> RemoteData.withDefault []
                        |> ((++) newBlocks)
                        |> Success
              }
            , Cmd.none
            )
        GotNewBlock (Err err) ->
            ( { model | newBlocks = Failure err }, Cmd.none )
```

The screenshot below shows what it looks like to listen to streaming events using StreamCardano's API.

![Succesfull Listen to new blocks Response](assets/images/tutorials/elm-tutorial/listen_new_blocks_response.png)

### View

Data will be displayed with simple styles, and all stylesheets are in the `main.css` file. Which can be found in appendix. To normalize the browser's default style, we'll install and add modern-normalize. 

```{.sh #runit}
npm install modern-normalize
```

Our main `view` function is split into two parts: view the navigation bar and view the results of the server responses.

```{.elm #view}
{-| View displays the Stream Cardano API responses in simple styles, and all stylesheets are in main.css.
-}
view : Model -> Document Msg
view model =
    { title = "StreamCardano"
    , body =
        [ div [ id "main" ]
            [ viewNav model
            , viewResponses model
            ]
        ]
    }
```

There's nothing complicated about the navigation bar. Besides a button to get the latest block, it has another button to listen to new blocks and a form to submit an SQL query

```{.elm #view}
viewNav : Model -> Html Msg
viewNav model =
    header [ id "navbar" ] 
        [ div [ class "topbar" ] 
            [ h2 [] [ text "StreamCardano" ]
            , nav [ class "navbar-buttons" ] 
                [ viewGetLastBlockButton
                , viewListenNewBlockButton
                ]
            ]
        , viewRunQueryForm model.query
        ]

<<viewGetLastBlockButton>>
<<viewListenNewBlockButton>>
<<viewRunQueryForm>>
```

You can see a screenshot of the navigation bar below. 

![Navigation Bar](assets/images/tutorials/elm-tutorial/navbar.png)

With the help of the `viewRemoteData` helper function, the `viewResponses` function shows all four response results in a row.

```{.elm #view}
viewResponses : Model -> Html msg
viewResponses model =
    div [ class "response" ]
        [ viewListenNewBlocks model.newBlocks
        , viewLastBlock model.lastBlock
        , viewPostedQuery model.sqlQuery
        , viewStatus model.status
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

<<viewPostedQuery>>
<<viewStatus>>
<<viewRemoteData>>
```

For the `viewRemoteData` function we need to provide the view function for every case of `RemoteData`: `NotAsked`, `Loading`, `Failure`, and `Success`.

```{.elm #viewRemoteData}
viewRemoteData :
    { description : String
    , path        : String
    , method      : String
    , encode      : a -> E.Value
    , errorToString   : e -> String
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
    div [ class "loading"] [ text "Loading..." ]

viewSuccess : String -> String -> String -> E.Value -> Html msg
viewSuccess desc path method value =
    div [ class "success" ]
        [ p [] [ text desc ]
        , span [ class "path" ]
            [ strong [] [ text method ], text path ]
        , p [] [ strong [] [ text "Response:" ] ]
        , pre []
            [ value
                |> E.encode 4
                |> text
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

## Datatypes

In order to proceed an api responses we will generate four datatypes with a help of [json2Elm](https://korban.net/elm/json2elm/): `Status`, `LastBlock`, `Query`, `NewBlock` and write tests for their decoders.

Here's an example of the last block implementation. The remaining implementation can be found in an appendix.md file. 

### LastBlock

The `LastBlock` module exposes its type and two functions for encoding and decoding JSON values.

```{.elm #LastBlockModule}
module Data.LastBlock exposing (LastBlock, decoder, encode)
{-| Using this module, you are able to decode Last Block data into an Elm record and encode Last Block record into JSON values.

# Definition
@docs LastBlock

# Decoders
@docs decoder

# Encode
@docs encode

-}
```

Elm provides a package called `elm/json` which includes modules for encoding and decoding JSON values. We recommend using a third-party package called Decode.Pipeline which builds JSON decoders using the pipeline (`|>`) operator.

We will install those packages by running the following command in terminal.

```{.sh #runit}
yes | npx elm install elm/json
yes | npx elm install NoRedInk/elm-json-decode-pipeline
```

After that import two modules `Json.Decode`, `Json.Encode` from `elm/json` and `Json.Decode.Pipeline` from `NoRedInk/elm-json-decode-pipeline`.

```{.elm #LastBlockImport}
import Json.Decode          as D
import Json.Decode.Pipeline as Pipeline
import Json.Encode          as E
```

The below JSON defines the example value: 

```{.elm #LastBlockTestSampleJson}
   """
{
  "errors": [
    {
      "message": "string"
    }
  ],
  "result": 98064369
}
"""
```

The first thing we need to create the LastBlock type.

```{.elm #LastBlockType}
{-| Representation of a Last Block record from StreamCardano API.
-}
type alias LastBlock =
    { errors : List Error
    , result : Int
    }

type alias Error =
    { message : String
    }
```

Next we need to define a decoder that knows how to translate JSON into Elm values.

```{.elm #LastBlockDecoder}
{-| Decoder to decode Last Block data from StreamCardano Api into a Last Block record.
-}
decoder : D.Decoder LastBlock
decoder =
    D.succeed LastBlock
        |> Pipeline.required "errors" (D.list errorDecoder)
        |> Pipeline.required "result"  D.int

errorDecoder : D.Decoder Error
errorDecoder =
    D.succeed Error
        |> Pipeline.required "message" D.string
```

We also need to define an encode function that knows how to convert Elm values into JSON.

```{.elm #LastBlockEncode}
{-| Encode Last Block record into JSON values.
-}
encode : LastBlock -> E.Value
encode block =
    E.object
        [ ( "errors", E.list encodeError block.errors )
        , ( "result", E.int              block.result )
        ]

encodeError : Error -> E.Value
encodeError error =
    E.object
        [ ( "message", E.string error.message )
        ]
```


### Testing LastBlock Decoder

Before we can write tests in Elm, we need to first set some things up in our project using a tool called elm-test. Let’s install it by running the following command from the root directory in terminal and remove an example tests file.

```{.sh #runit}
npm i -D elm-test 
yes | npx elm-test init
rm tests/Example.elm
```

After we need to create the `LastBlcokTest.elm` file and write a simple decoder test.

```{.elm #LastBlockTestDecoder}
decoderTest : Test
decoderTest =
    test "Decode the Status Response"
        (\_ ->
            sampleJSON
                |> decodeString decoder
                |> Expect.equal (Ok sample)
        )

sample : LastBlock
sample =
    { errors = [ { message = "string" } ]
    , result = 98064369
    }
```
