-- ~\~ language=Elm filename=src/StreamCardano/Api.elm
module StreamCardano.Api exposing (getLastBlock, getStatus, postQuery)
{-| Helpers for sending Http requests to the StreamCardano endpoints.

# Get Requests
@docs getStatus, getLastBlock

# Post Requests
@docs postQuery

-}

import StreamCardano.Endpoint                 as Endpoint
import StreamCardano.Data.LastBlock           as LastBlock exposing (LastBlock)
import StreamCardano.Data.Query               as Query     exposing (Query)
import StreamCardano.Data.Status              as Status    exposing (Status)
import Http                                                exposing (Error)

{-| Send a basic request to check if the Service is online. No authentication is required.
-}
getStatus : (Result Error Status -> msg) -> Cmd msg
getStatus toMsg =
    Http.get
        { url    = Endpoint.status
        , expect = Http.expectJson toMsg Status.decoder
        }
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
{-| Selecting data with a custom SQL query.
-}
postQuery : String -> String -> (Result Error Query -> msg) -> Cmd msg
postQuery key query msg =
    let
        bearer =
            "Bearer " ++ key
    in
    Http.request
        { method  = "POST"
        , headers = [ Http.header "Authorization" bearer ]
        , url     = Endpoint.runQuery
        , body    = Http.stringBody "text/plain;charset=utf-8" query
        , expect  = Http.expectJson msg Query.decoder
        , timeout = Nothing
        , tracker = Nothing
        }
