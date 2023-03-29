-- ~\~ language=Elm filename=tests/Data/StatusTest.elm

module StreamCardano.Data.StatusTest exposing (..)

import StreamCardano.Data.Status exposing (..)
import Expect exposing (Expectation)
import Fuzz exposing (Fuzzer, int, list, string)
import Json.Decode exposing (decodeString)
import Test exposing (..)

import Time

decoderTest : Test
decoderTest =
    test "Decode the Status Response"
        (\_ ->
            sampleJSON
                |> decodeString decoder
                |> Expect.equal (Ok sample)
        )

sample : Status
sample =
    { errors = []
    , result =
        { appVersionInfo =
            { appCommit = "3cf85731437e46b7adbcb4abc784518b04f2a1b8"
            , appCommitTime =
                { absolute = Time.millisToPosix 1677280122000
                , relative = "string"
                }
            , appCompileTime =
                { absolute = Time.millisToPosix 1677284177000
                , relative = "string"
                }
            , appUpTime =
                { absolute = Time.millisToPosix 1677301833891
                , relative = "string"
                }
            , appVersion = "0.7.4.0"
            , envName = "TestEnv"
            }
        , databaseTriggers =
            [ { eventManipulation = "INSERT"
              , eventTable = "block"
              , name = "blocks_changed"
              }
            , { eventManipulation = "DELETE"
              , eventTable = "block"
              , name = "blocks_changed"
              }
            , { eventManipulation = "UPDATE"
              , eventTable = "block"
              , name = "blocks_changed"
              }
            ]
        , networkName = "mainnet"
        , pgbouncerWorking = "OK"
        , postgresWorking = "OK"
        , syncBehindBy = "string"
        }
    }

sampleJSON : String
sampleJSON =
    """
{
  "errors": [],
  "result": {
    "app_version_info": {
      "app_commit": "3cf85731437e46b7adbcb4abc784518b04f2a1b8",
      "app_commit_time": {
        "absolute": "2023-02-24T23:08:42Z",
        "relative": "string"
      },
      "app_compile_time": {
        "absolute": "2023-02-25T00:16:17Z",
        "relative": "string"
      },
      "app_up_time": {
        "absolute": "2023-02-25T05:10:33.891153159Z",
        "relative": "string"
      },
      "app_version": "0.7.4.0",
      "env_name": "TestEnv"
    },
    "database_triggers": [
      {
        "event_manipulation": "INSERT",
        "event_table": "block",
        "name": "blocks_changed"
      },
      {
        "event_manipulation": "DELETE",
        "event_table": "block",
        "name": "blocks_changed"
      },
      {
        "event_manipulation": "UPDATE",
        "event_table": "block",
        "name": "blocks_changed"
      }
    ],
    "network_name": "mainnet",
    "pgbouncer_working": "OK",
    "postgres_working": "OK",
    "sync_behind_by": "string",
    "wcontroller_status": {
      "count": "OK: to be fixed",
      "creation_cycle": "OK: to be fixed",
      "transaction_test": "OK: to be fixed"
    }
  }
}
"""
