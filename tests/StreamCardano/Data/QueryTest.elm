-- ~\~ language=Elm filename=tests/Data/QueryTest.elm

module StreamCardano.Data.QueryTest exposing (..)

import StreamCardano.Data.Query exposing (..)
import Expect
import Json.Decode exposing (decodeString)
import Test exposing (..)
import Json.Encode as E

decoderTest : Test
decoderTest =
    test "Decode the Status Response"
        (\_ ->
            sampleJSON
                |> decodeString decoder
                |> Expect.equal (Ok sample)
        )

sample : Query
sample =
    { errors = [ "string" ]
    , result =
        [ ResultBlockNo   blockNo
        , ResultBlockId   blockId
        , ResultArbitrary arbitrary
        ]
    }

blockNo : BlockNo
blockNo =
    { blockNo       = 9223372036854775616
    , epochNo       = 9223372036854775616
    , epochSlotNo   = 9223372036854775616
    , hash          = "string"
    , id            = 9223372036854775616
    , opCert        = "string"
    , opCertCounter = 9223372036854775616
    , previousId    = 9223372036854775616
    , protoMajor    = 9223372036854775616
    , protoMinor    = 9223372036854775616
    , size          = 9223372036854775616
    , slotLeaderId  = 9223372036854775616
    , slotNo        = 9223372036854775616
    , time          = "string"
    , txCount       = 9223372036854775616
    , vrfKey        = "string"
    }

blockId : BlockId
blockId =
    { blockId          = 9223372036854775616
    , blockIndex       = 9223372036854775616
    , deposit          = 9223372036854775616
    , fee              = 9223372036854775616
    , hash             = "string"
    , id               = 9223372036854775616
    , invalidBefore    = 9223372036854775616
    , invalidHereafter = 9223372036854775616
    , outSum           = 9223372036854775616
    , scriptSize       = 9223372036854775616
    , size             = 9223372036854775616
    , validContract    = True
    }

arbitrary : E.Value
arbitrary =
    E.object
        [ ( "description", E.string "arbitrary" ) ]

sampleJSON : String
sampleJSON =
    """
{
  "errors": [
    "string"
  ],
  "result": [
    {
      "block_no": 9223372036854776000,
      "epoch_no": 9223372036854776000,
      "epoch_slot_no": 9223372036854776000,
      "hash": "string",
      "id": 9223372036854776000,
      "op_cert": "string",
      "op_cert_counter": 9223372036854776000,
      "previous_id": 9223372036854776000,
      "proto_major": 9223372036854776000,
      "proto_minor": 9223372036854776000,
      "size": 9223372036854776000,
      "slot_leader_id": 9223372036854776000,
      "slot_no": 9223372036854776000,
      "time": "string",
      "tx_count": 9223372036854776000,
      "vrf_key": "string"
    },
    {
      "block_id": 9223372036854776000,
      "block_index": 9223372036854776000,
      "deposit": 9223372036854776000,
      "fee": 9223372036854776000,
      "hash": "string",
      "id": 9223372036854776000,
      "invalid_before": 9223372036854776000,
      "invalid_hereafter": 9223372036854776000,
      "out_sum": 9223372036854776000,
      "script_size": 9223372036854776000,
      "size": 9223372036854776000,
      "valid_contract": true
    },
    {
      "description": "arbitrary"
    }
  ]
}
"""
