module StreamCardano.Data.Query exposing
    ( Query, QueryResult(..), BlockNo
    , decoder
    , encode, encodedQueryResultItem
    )

{-| Using this module, you are able to decode Query data into an Elm record and encode Query record into JSON values.


# Definition

@docs Query, QueryResult, BlockNo


# Decoders

@docs decoder


# Encode record

@docs encode, encodedQueryResultItem

-}

import Json.Decode as D
import Json.Decode.Pipeline as Pipeline
import Json.Encode as E
import StreamCardano.Data.Tx as Tx exposing (Tx)


{-| Representation of a Query record from StreamCardano API.
-}
type alias Query =
    { errors : List String
    , result : List QueryResult
    }


type QueryResult
    = ResultBlockNo BlockNo
    | ResultTx Tx
    | ResultArbitrary D.Value


type alias BlockNo =
    { blockNo : Int
    , epochNo : Int
    , epochSlotNo : Int
    , hash : String
    , id : Int
    , opCert : String
    , opCertCounter : Int
    , previousId : Int
    , protoMajor : Int
    , protoMinor : Int
    , size : Int
    , slotLeaderId : Int
    , slotNo : Int
    , time : String
    , txCount : Int
    , vrfKey : String
    }


{-| Decoder to decode Query data from StreamCardano Api into a Query record.
-}
decoder : D.Decoder Query
decoder =
    D.succeed Query
        |> Pipeline.required "errors" (D.list D.string)
        |> Pipeline.required "result" (D.list queryResultItemDecoder)


queryResultItemDecoder : D.Decoder QueryResult
queryResultItemDecoder =
    D.oneOf
        [ D.map ResultBlockNo <| queryResultObjectDecoder
        , D.map ResultTx <| Tx.decoder
        , D.map ResultArbitrary <| queryResultEntityDecoder
        ]


queryResultObjectDecoder : D.Decoder BlockNo
queryResultObjectDecoder =
    D.succeed BlockNo
        |> Pipeline.required "block_no" D.int
        |> Pipeline.required "epoch_no" D.int
        |> Pipeline.required "epoch_slot_no" D.int
        |> Pipeline.required "hash" D.string
        |> Pipeline.required "id" D.int
        |> Pipeline.required "op_cert" D.string
        |> Pipeline.required "op_cert_counter" D.int
        |> Pipeline.required "previous_id" D.int
        |> Pipeline.required "proto_major" D.int
        |> Pipeline.required "proto_minor" D.int
        |> Pipeline.required "size" D.int
        |> Pipeline.required "slot_leader_id" D.int
        |> Pipeline.required "slot_no" D.int
        |> Pipeline.required "time" D.string
        |> Pipeline.required "tx_count" D.int
        |> Pipeline.required "vrf_key" D.string


queryResultEntityDecoder : D.Decoder D.Value
queryResultEntityDecoder =
    D.value


{-| Encode Query record into JSON values.
-}
encode : Query -> E.Value
encode query =
    E.object
        [ ( "errors", E.list E.string query.errors )
        , ( "result", E.list encodedQueryResultItem query.result )
        ]


encodedQueryResultItem : QueryResult -> E.Value
encodedQueryResultItem queryResult =
    case queryResult of
        ResultBlockNo value ->
            encodedBlockNo value

        ResultTx value ->
            Tx.encode value

        ResultArbitrary value ->
            value


encodedBlockNo : BlockNo -> E.Value
encodedBlockNo queryResultObject =
    E.object
        [ ( "block_no", E.int queryResultObject.blockNo )
        , ( "epoch_no", E.int queryResultObject.epochNo )
        , ( "epoch_slot_no", E.int queryResultObject.epochSlotNo )
        , ( "hash", E.string queryResultObject.hash )
        , ( "id", E.int queryResultObject.id )
        , ( "op_cert", E.string queryResultObject.opCert )
        , ( "op_cert_counter", E.int queryResultObject.opCertCounter )
        , ( "previous_id", E.int queryResultObject.previousId )
        , ( "proto_major", E.int queryResultObject.protoMajor )
        , ( "proto_minor", E.int queryResultObject.protoMinor )
        , ( "size", E.int queryResultObject.size )
        , ( "slot_leader_id", E.int queryResultObject.slotLeaderId )
        , ( "slot_no", E.int queryResultObject.slotNo )
        , ( "time", E.string queryResultObject.time )
        , ( "tx_count", E.int queryResultObject.txCount )
        , ( "vrf_key", E.string queryResultObject.vrfKey )
        ]
