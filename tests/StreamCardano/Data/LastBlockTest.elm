-- ~\~ language=Elm filename=tests/Data/LastBlockTest.elm

module StreamCardano.Data.LastBlockTest exposing (..)

import StreamCardano.Data.LastBlock exposing (..)
import Expect 
import Json.Decode    exposing (decodeString)
import Test           exposing (..)

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
