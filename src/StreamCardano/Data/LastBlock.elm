module StreamCardano.Data.LastBlock exposing
    ( LastBlock
    , decoder, encode
    )

{-| Using this module, you are able to decode Last Block data into an Elm record and encode Last Block record into JSON values.


# Definition

@docs LastBlock


# Decoders

@docs decoder


# Encode record

@docs encode

-}

import Json.Decode as D
import Json.Decode.Pipeline as Pipeline
import Json.Encode as E


{-| Representation of a Last Block record from StreamCardano API.
-}
type alias LastBlock =
    { errors : List Error
    , result : Int
    }


type alias Error =
    { message : String
    }


{-| Decoder to decode Last Block data from StreamCardano Api into a Last Block record.
-}
decoder : D.Decoder LastBlock
decoder =
    D.succeed LastBlock
        |> Pipeline.required "errors" (D.list errorDecoder)
        |> Pipeline.required "result" D.int


errorDecoder : D.Decoder Error
errorDecoder =
    D.succeed Error
        |> Pipeline.required "message" D.string


{-| Encode Last Block record into JSON values.
-}
encode : LastBlock -> E.Value
encode block =
    E.object
        [ ( "errors", E.list encodeError block.errors )
        , ( "result", E.int block.result )
        ]


encodeError : Error -> E.Value
encodeError error =
    E.object
        [ ( "message", E.string error.message )
        ]
