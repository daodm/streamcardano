module StreamCardano.Data.NewBlockTest exposing (decoderTest)

import Expect exposing (Expectation)
import Fuzz exposing (Fuzzer, int, list, string)
import Json.Decode exposing (decodeString)
import StreamCardano.Data.NewBlock exposing (..)
import Test exposing (..)


decoderTest : Test
decoderTest =
    test "Decode the Status Response"
        (\_ ->
            sampleJSON
                |> decodeString decoder
                |> Expect.equal (Ok sample)
        )


sample : NewBlock
sample =
    { blockNo = 98491829
    , hash = "string"
    , txCount = 5
    }


sampleJSON : String
sampleJSON =
    """
{
  "block_no": 98491829,
  "hash": "string",
  "tx_count": 5
}

"""
