-- ~\~ language=Elm filename=src/StreamCardano/Endpoint.elm
module StreamCardano.Endpoint exposing (..)

type Endpoint
    = Endpoint { host : String, key : String }

host : String
host =
    "https://beta.streamcardano.dev/api/v1/"

status : String
status =
    host ++ "status"

lastBlock : String
lastBlock =
    host ++ "last/block"

runQuery : String
runQuery =
    host ++ "query"
