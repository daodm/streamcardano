-- ~\~ language=Elm filename=src/StreamCardano/Endpoint.elm
module StreamCardano.Endpoint exposing (..)

status : String
status =
    "status"

lastBlock : String
lastBlock =
    "last/block"

runQuery : String
runQuery =
    "query"
