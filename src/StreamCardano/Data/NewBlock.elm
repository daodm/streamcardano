module StreamCardano.Data.NewBlock exposing
    ( NewBlock
    , decoder
    , encode
    )

{-| Using this module, you are able to decode New Block data into an Elm record and encode Status record into JSON values.


# Definition

@docs NewBlock


# Decoders

@docs decoder


# Encode record

@docs encode

-}

import Json.Decode as D
import Json.Decode.Pipeline as Pipeline
import Json.Encode as E


{-| Representation of a New Block record from StreamCardano API.
-}
type alias NewBlock =
    { blockNo : Int
    , hash : String
    , txCount : Int
    }


{-| Decoder to decode New Blcok data from StreamCardano Api into a New Block record.
-}
decoder : D.Decoder NewBlock
decoder =
    D.succeed NewBlock
        |> Pipeline.required "block_no" D.int
        |> Pipeline.required "hash" D.string
        |> Pipeline.required "tx_count" D.int


{-| Encode Status record into JSON values.
-}
encode : NewBlock -> E.Value
encode newBlock =
    E.object
        [ ( "block_no", E.int newBlock.blockNo )
        , ( "hash", E.string newBlock.hash )
        , ( "tx_count", E.int newBlock.txCount )
        ]
