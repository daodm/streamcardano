module StreamCardano.Data.Tx exposing
    ( Tx
    , decoder
    , encode
    )

{-| Using this module, you are able to decode Tx data into an Elm record and encode Tx record into JSON values.


# Definition

@docs Tx


# Decoders

@docs decoder


# Encode record

@docs encode

-}

import Json.Decode as D
import Json.Encode as E


{-| Representation of a Tx record from StreamCardano API.
-}
type alias Tx =
    { blockId : Int
    , blockIndex : Int
    , deposit : Int
    , fee : Int
    , hash : String
    , id : Int
    , invalidBefore : Maybe Int
    , invalidHereafter : Int
    , outSum : Int
    , scriptSize : Int
    , size : Int
    , validContract : Bool
    }


decoder : D.Decoder Tx
decoder =
    let
        fieldSet0 =
            D.map8 Tx
                (D.field "block_id" D.int)
                (D.field "block_index" D.int)
                (D.field "deposit" D.int)
                (D.field "fee" D.int)
                (D.field "hash" D.string)
                (D.field "id" D.int)
                (D.field "invalid_before" (D.nullable D.int))
                (D.field "invalid_hereafter" D.int)
    in
    D.map5 (<|)
        fieldSet0
        (D.field "out_sum" D.int)
        (D.field "script_size" D.int)
        (D.field "size" D.int)
        (D.field "valid_contract" D.bool)


{-| Encode Tx record into JSON values.
-}
encode : Tx -> E.Value
encode tx =
    E.object
        [ ( "block_id", E.int tx.blockId )
        , ( "block_index", E.int tx.blockIndex )
        , ( "deposit", E.int tx.deposit )
        , ( "fee", E.int tx.fee )
        , ( "hash", E.string tx.hash )
        , ( "id", E.int tx.id )
        , ( "invalid_before"
          , tx.invalidBefore
                |> Maybe.map E.int
                |> Maybe.withDefault E.null
          )
        , ( "invalid_hereafter", E.int tx.invalidHereafter )
        , ( "out_sum", E.int tx.outSum )
        , ( "script_size", E.int tx.scriptSize )
        , ( "size", E.int tx.size )
        , ( "valid_contract", E.bool tx.validContract )
        ]
