module StreamCardano.Data.TxTest exposing (decoderTest)

import Expect exposing (Expectation)
import Fuzz exposing (Fuzzer, int, list, string)
import Json.Decode exposing (decodeString)
import StreamCardano.Data.Tx exposing (..)
import Test exposing (..)


decoderTest : Test
decoderTest =
    test "Decode the Status Response"
        (\_ ->
            sampleJSON
                |> decodeString decoder
                |> Expect.equal (Ok sample)
        )


sample : Tx
sample =
    { blockId = 8623519
    , blockIndex = 9
    , deposit = 0
    , fee = 173201
    , hash = "string"
    , id = 64420163
    , invalidBefore = 28693459
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
"""
