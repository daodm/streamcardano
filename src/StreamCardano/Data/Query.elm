module StreamCardano.Data.Query exposing
    ( Query, QueryResult(..), BlockNo, BlockId
    , decoder, encode
    )

{-| Using this module, you are able to decode Query data into an Elm record and encode Query record into JSON values.


# Definition

@docs Query, QueryResult, BlockNo, BlockId


# Decoders

@docs decoder


# Encode record

@docs encode
-}

import Json.Decode as D
import Json.Decode.Pipeline as Pipeline
import Json.Encode as E


{-| Representation of a Query record from StreamCardano API.
-}
type alias Query =
    { errors : List String
    , result : List QueryResult
    }


type QueryResult
    = ResultBlockNo BlockNo
    | ResultBlockId BlockId
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


type alias BlockId =
    { blockId : Int
    , blockIndex : Int
    , deposit : Int
    , fee : Int
    , hash : String
    , id : Int
    , invalidBefore : Int
    , invalidHereafter : Int
    , outSum : Int
    , scriptSize : Int
    , size : Int
    , validContract : Bool
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
        , D.map ResultBlockId <| queryResultMemberDecoder
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


queryResultMemberDecoder : D.Decoder BlockId
queryResultMemberDecoder =
    D.succeed BlockId
        |> Pipeline.required "block_id" D.int
        |> Pipeline.required "block_index" D.int
        |> Pipeline.required "deposit" D.int
        |> Pipeline.required "fee" D.int
        |> Pipeline.required "hash" D.string
        |> Pipeline.required "id" D.int
        |> Pipeline.required "invalid_before" D.int
        |> Pipeline.required "invalid_hereafter" D.int
        |> Pipeline.required "out_sum" D.int
        |> Pipeline.required "script_size" D.int
        |> Pipeline.required "size" D.int
        |> Pipeline.required "valid_contract" D.bool


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

        ResultBlockId value ->
            encodedBlockId value

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


encodedBlockId : BlockId -> E.Value
encodedBlockId queryResultMember =
    E.object
        [ ( "block_id", E.int queryResultMember.blockId )
        , ( "block_index", E.int queryResultMember.blockIndex )
        , ( "deposit", E.int queryResultMember.deposit )
        , ( "fee", E.int queryResultMember.fee )
        , ( "hash", E.string queryResultMember.hash )
        , ( "id", E.int queryResultMember.id )
        , ( "invalid_before", E.int queryResultMember.invalidBefore )
        , ( "invalid_hereafter", E.int queryResultMember.invalidHereafter )
        , ( "out_sum", E.int queryResultMember.outSum )
        , ( "script_size", E.int queryResultMember.scriptSize )
        , ( "size", E.int queryResultMember.size )
        , ( "valid_contract", E.bool queryResultMember.validContract )
        ]
