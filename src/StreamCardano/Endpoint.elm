-- ~\~ language=Elm filename=src/StreamCardano/Endpoint.elm


module StreamCardano.Endpoint exposing (lastBlock, runQuery, runQueryDebug, status)


status : String
status =
    "status"


lastBlock : String
lastBlock =
    "last/block"


runQuery : String
runQuery =
    "query"


runQueryDebug : String
runQueryDebug =
    "query"
