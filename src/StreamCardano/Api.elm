module StreamCardano.Api exposing
    ( Credentials, credentials
    , getStatus, getLastBlock
    , postQuery
    )

{-| Helpers for sending Http requests to the StreamCardano endpoints.


# Credentials

@docs Credentials, credentials


# Get Requests

@docs getStatus, getLastBlock


# Post Requests

@docs postQuery

-}

import Http exposing (Error)
import StreamCardano.Data.LastBlock as LastBlock exposing (LastBlock)
import StreamCardano.Data.Query as Query exposing (Query)
import StreamCardano.Data.Status as Status exposing (Status)
import StreamCardano.Endpoint as Endpoint


type Credentials
    = Credentials { url : String, key : String }


credentials : { r | host : String, key : String } -> Credentials
credentials { host, key } =
    Credentials
        { url = "https://" ++ host ++ "/api/v1/"
        , key = key
        }


{-| SEND a basic request to check if the Service is online. No authentication is required.
-}
getStatus : (Result Error Status -> msg) -> Credentials -> Cmd msg
getStatus toMsg (Credentials { url }) =
    Http.get
        { url = url ++ Endpoint.status
        , expect = Http.expectJson toMsg Status.decoder
        }


{-| Checking StreamCardano is up-to-date with the Cardano network.
-}
getLastBlock : (Result Error LastBlock -> msg) -> Credentials -> Cmd msg
getLastBlock msg (Credentials { url, key }) =
    let
        bearer =
            "Bearer " ++ key
    in
    Http.request
        { method = "GET"
        , headers = [ Http.header "Authorization" bearer ]
        , url = url ++ Endpoint.lastBlock
        , body = Http.emptyBody
        , expect = Http.expectJson msg LastBlock.decoder
        , timeout = Nothing
        , tracker = Nothing
        }


{-| Selecting data with a custom SQL query.
-}
postQuery : (Result Error Query -> msg) -> Credentials -> String -> Cmd msg
postQuery msg (Credentials { url, key }) query =
    let
        bearer =
            "Bearer " ++ key
    in
    Http.request
        { method = "POST"
        , headers = [ Http.header "Authorization" bearer ]
        , url = url ++ Endpoint.runQuery
        , body = Http.stringBody "text/plain;charset=utf-8" query
        , expect = Http.expectJson msg Query.decoder
        , timeout = Nothing
        , tracker = Nothing
        }
