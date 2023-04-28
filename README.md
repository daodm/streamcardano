# StreamCardano

Decoders and a few other helpers for using [Stream Cardano APIs](https://streamcardano.com).


See more end-to-end example code in the `examples/` folder.

[Live Demo](https://daodm.github.io/streamcardano)

## Getting started

### Set up a StreamCardano account

Before you can use this package you need a StreamCardano API key. To do this, signup for a [StreamCardano](https://streamcardano.com) account.

### Example code

Once you've completed the previous step you can write something like this to check that StreamCardano is up-to-date with the Cardano network.

```elm
import StreamCardano.Api as Api
import RemoteData exposing (RemoteData(..), WebData)

type alias Model =
    { status : WebData Status
    }

type alias Flags =
    { host : String
    , key : String
    }


init : Flags -> ( Model, Cmd Msg )
init flags =
    ( { credentials = credentials
      , query = "SELECT tx_id, value FROM datum ORDER BY tx_id DESC LIMIT 1"
      , status = Loading
      , lastBlock = NotAsked
      , sqlQuery = NotAsked
      , newBlocks = NotAsked
      }
    , Api.getStatus GotStatus credentials
    )

```

## Learning Resources

Ask for help on the [Elm Slack](https://elm-lang.org/community/slack) in the #streamcardano.
