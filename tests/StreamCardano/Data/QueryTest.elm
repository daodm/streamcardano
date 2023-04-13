module StreamCardano.Data.QueryTest exposing (decoderTest)

import Expect
import Json.Decode exposing (decodeString)
import Json.Encode as E
import StreamCardano.Data.Query exposing (..)
import StreamCardano.Data.Tx as Tx exposing (Tx)
import Test exposing (..)


decoderTest : Test
decoderTest =
    describe "Decode the Status Response"
        [ test "sample json" <|
            \_ ->
                sampleJSON
                    |> decodeString decoder
                    |> Expect.equal (Ok sample)
        , test "transactions json" <|
            \_ ->
                transactionsSampleJSON
                    |> decodeString decoder
                    |> Expect.equal (Ok sampleTxsSampleJSON)
        ]


sample : Query
sample =
    { errors = [ "string" ]
    , result =
        [ ResultBlockNo blockNo
        , ResultTx sampleTx
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


sampleTx : Tx
sampleTx =
    { blockId = 9223372036854775616
    , blockIndex = 9223372036854775616
    , deposit = 9223372036854775616
    , fee = 9223372036854775616
    , hash = "string"
    , id = 9223372036854775616
    , invalidBefore = Just 9223372036854775616
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


sampleTxsSampleJSON : Query
sampleTxsSampleJSON =
    { errors = []
    , result =
        [ ResultTx sampleTx2 ]
    }


sampleTx2 : Tx
sampleTx2 =
    { blockId = 8623519
    , blockIndex = 9
    , deposit = 0
    , fee = 173201
    , hash = "string"
    , id = 64420163
    , invalidBefore = Just 28693459
    , invalidHereafter = 89425972
    , outSum = 5796037338
    , scriptSize = 0
    , size = 371
    , validContract = True
    }


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
      "block_index": 9,
      "deposit": 0,
      "fee": 173201,
      "hash": "string",
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
