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
      "tx_id": 64418244,
      "value": {
        "constructor": 0,
        "fields": [
          {
            "bytes": "71db50c7aa49754f63f9cb1e81935d6ef5618ae55d28f8a87cc33c35"
          },
          {
            "list": [
              {
                "constructor": 0,
                "fields": [
                  {
                    "constructor": 0,
                    "fields": [
                      {
                        "constructor": 0,
                        "fields": [
                          {
                            "bytes": "63e649a20be51104adc34f5f3042d7eca49d66561966a887f520c1ad"
                          }
                        ]
                      },
                      {
                        "constructor": 0,
                        "fields": [
                          {
                            "constructor": 0,
                            "fields": [
                              {
                                "constructor": 0,
                                "fields": [
                                  {
                                    "bytes": "e6e241c94acfd2e57b98bc25c1526fc1fb38fde44e3e07c88e94734f"
                                  }
                                ]
                              }
                            ]
                          }
                        ]
                      }
                    ]
                  },
                  {
                    "map": [
                      {
                        "k": { "bytes": "" },
                        "v": {
                          "constructor": 0,
                          "fields": [
                            { "int": 0 },
                            {
                              "map": [
                                {
                                  "k": { "bytes": "" },
                                  "v": { "int": 10500000 }
                                }
                              ]
                            }
                          ]
                        }
                      }
                    ]
                  }
                ]
              },
              {
                "constructor": 0,
                "fields": [
                  {
                    "constructor": 0,
                    "fields": [
                      {
                        "constructor": 0,
                        "fields": [
                          {
                            "bytes": "70e60f3b5ea7153e0acc7a803e4401d44b8ed1bae1c7baaad1a62a72"
                          }
                        ]
                      },
                      {
                        "constructor": 0,
                        "fields": [
                          {
                            "constructor": 0,
                            "fields": [
                              {
                                "constructor": 0,
                                "fields": [
                                  {
                                    "bytes": "1e78aae7c90cc36d624f7b3bb6d86b52696dc84e490f343eba89005f"
                                  }
                                ]
                              }
                            ]
                          }
                        ]
                      }
                    ]
                  },
                  {
                    "map": [
                      {
                        "k": { "bytes": "" },
                        "v": {
                          "constructor": 0,
                          "fields": [
                            { "int": 0 },
                            {
                              "map": [
                                {
                                  "k": { "bytes": "" },
                                  "v": { "int": 3000000 }
                                }
                              ]
                            }
                          ]
                        }
                      }
                    ]
                  }
                ]
              },
              {
                "constructor": 0,
                "fields": [
                  {
                    "constructor": 0,
                    "fields": [
                      {
                        "constructor": 0,
                        "fields": [
                          {
                            "bytes": "71db50c7aa49754f63f9cb1e81935d6ef5618ae55d28f8a87cc33c35"
                          }
                        ]
                      },
                      {
                        "constructor": 0,
                        "fields": [
                          {
                            "constructor": 0,
                            "fields": [
                              {
                                "constructor": 0,
                                "fields": [
                                  {
                                    "bytes": "536f517c3ebd6b092f217b096eccdb58f0514f3f4983c06bfa966953"
                                  }
                                ]
                              }
                            ]
                          }
                        ]
                      }
                    ]
                  },
                  {
                    "map": [
                      {
                        "k": { "bytes": "" },
                        "v": {
                          "constructor": 0,
                          "fields": [
                            { "int": 0 },
                            {
                              "map": [
                                {
                                  "k": { "bytes": "" },
                                  "v": { "int": 136500000 }
                                }
                              ]
                            }
                          ]
                        }
                      }
                    ]
                  }
                ]
              }
            ]
          }
        ]
      }
    }
  ]
}
"""
