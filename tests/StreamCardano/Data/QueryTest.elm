module StreamCardano.Data.QueryTest exposing (decoderTest)

import Expect
import Json.Decode exposing (decodeString)
import Json.Encode as E
import StreamCardano.Data.Query exposing (..)
import Test exposing (..)


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
        [ ResultBlockNo blockNo
        , ResultBlockId blockId
        , ResultArbitrary arbitrary
        ]
    }


blockNo : BlockNo
blockNo =
    { blockNo = 9223372036854775616
    , epochNo = 9223372036854775616
    , epochSlotNo = 9223372036854775616
    , hash = "string"
    , id = 9223372036854775616
    , opCert = "string"
    , opCertCounter = 9223372036854775616
    , previousId = 9223372036854775616
    , protoMajor = 9223372036854775616
    , protoMinor = 9223372036854775616
    , size = 9223372036854775616
    , slotLeaderId = 9223372036854775616
    , slotNo = 9223372036854775616
    , time = "string"
    , txCount = 9223372036854775616
    , vrfKey = "string"
    }


blockId : BlockId
blockId =
    { blockId = 9223372036854775616
    , blockIndex = 9223372036854775616
    , deposit = 9223372036854775616
    , fee = 9223372036854775616
    , hash = "string"
    , id = 9223372036854775616
    , invalidBefore = 9223372036854775616
    , invalidHereafter = 9223372036854775616
    , outSum = 9223372036854775616
    , scriptSize = 9223372036854775616
    , size = 9223372036854775616
    , validContract = True
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


transactionsSampleJSON : String
transactionsSampleJSON =
    """
{
  "errors": [],
  "result": [
    {
      "block_id": 8623519,
      "block_index": 11,
      "deposit": 0,
      "fee": 194277,
      "hash": "\\xbb74fdc5641760e474da29ca6482aa93bc98bdc74b6dba16c17b90b2a695f7ed",
      "id": 64420165,
      "invalid_before": 0,
      "invalid_hereafter": 89430837,
      "out_sum": 2610352148,
      "script_size": 0,
      "size": 884,
      "valid_contract": true
    },
    {
      "block_id": 8623519,
      "block_index": 10,
      "deposit": 0,
      "fee": 516286,
      "hash": "\\x5e833be733eaba89ad3497a84ac6449bc1d08f19eb4571d7fe77b05f6255b8fd",
      "id": 64420164,
      "invalid_before": null,
      "invalid_hereafter": 89419446,
      "out_sum": 42092683,
      "script_size": 0,
      "size": 1513,
      "valid_contract": true
    },
    {
      "block_id": 8623519,
      "block_index": 9,
      "deposit": 0,
      "fee": 173201,
      "hash": "\\xead712c7f15a0e0f11a822b6f3b3210fb5410dfd06da8c8c26ecf3fdbf1d9ad9",
      "id": 64420163,
      "invalid_before": 28693459,
      "invalid_hereafter": 89425972,
      "out_sum": 5796037338,
      "script_size": 0,
      "size": 371,
      "valid_contract": true
    }
  ]
}
"""
