module StreamCardano.Data.LastBlockTest exposing (decoderTest)

import Expect
import Json.Decode exposing (decodeString)
import StreamCardano.Data.LastBlock exposing (..)
import Test exposing (..)


decoderTest : Test
decoderTest =
    test "Decode the Status Response"
        (\_ ->
            sampleJSON
                |> decodeString decoder
                |> Expect.equal (Ok sample)
        )


sample : LastBlock
sample =
    { errors = [ { message = "string" } ]
    , result = 98064369
    }


sampleJSON : String
sampleJSON =
    """
{
  "errors": [
    {
      "message": "string"
    }
  ],
  "result": 98064369
}
"""
