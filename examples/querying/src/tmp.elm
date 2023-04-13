module Main exposing (Flags, Model, init)

import RemoteData exposing (RemoteData(..), WebData)
import StreamCardano.Api as Api
import StreamCardano.Data.Status as Status exposing (Status)


type alias Model =
    { status : WebData Status
    }


type alias Flags =
    { host : String
    , key : String
    }


init : Flags -> ( Model, Cmd Msg )
init flags =
    ( { status = Loading
      }
    , Api.getStatus GotStatus credentials
    )
