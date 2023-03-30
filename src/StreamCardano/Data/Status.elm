module StreamCardano.Data.Status exposing
    ( Status
    , decoder, encode
    )

{-| Using this module, you are able to decode Status data into an Elm record and encode Status record into JSON values.


# Definition

@docs Status


# Decoders

@docs decoder


# Encode record

@docs encode

-}

import Iso8601
import Json.Decode as D
import Json.Decode.Pipeline as Pipeline
import Json.Encode as E
import Time


{-| Representation of a Status record from StreamCardano API.
-}
type alias Status =
    { errors : List String
    , result : StatusResult
    }


type alias StatusResult =
    { appVersionInfo : StatusResultAppVersionInfo
    , databaseTriggers : List StatusResultDatabaseTriggersObject
    , networkName : String
    , pgbouncerWorking : String
    , postgresWorking : String
    , syncBehindBy : String
    }


type alias StatusResultAppVersionInfo =
    { appCommit : String
    , appCommitTime : StatusResultAppVersionInfoAppCommitTime
    , appCompileTime : StatusResultAppVersionInfoAppCompileTime
    , appUpTime : StatusResultAppVersionInfoAppUpTime
    , appVersion : String
    , envName : String
    }


type alias StatusResultAppVersionInfoAppCommitTime =
    { absolute : Time.Posix
    , relative : String
    }


type alias StatusResultAppVersionInfoAppCompileTime =
    { absolute : Time.Posix
    , relative : String
    }


type alias StatusResultAppVersionInfoAppUpTime =
    { absolute : Time.Posix
    , relative : String
    }


type alias StatusResultDatabaseTriggersObject =
    { eventManipulation : String
    , eventTable : String
    , name : String
    }


{-| Decoder to decode Status data from StreamCardano Api into a Status record.
-}
decoder : D.Decoder Status
decoder =
    D.succeed Status
        |> Pipeline.required "errors" (D.list D.string)
        |> Pipeline.required "result" statusResultDecoder


statusResultDecoder : D.Decoder StatusResult
statusResultDecoder =
    D.succeed StatusResult
        |> Pipeline.required "app_version_info" statusResultAppVersionInfoDecoder
        |> Pipeline.required "database_triggers" (D.list statusResultDatabaseTriggersObjectDecoder)
        |> Pipeline.required "network_name" D.string
        |> Pipeline.required "pgbouncer_working" D.string
        |> Pipeline.required "postgres_working" D.string
        |> Pipeline.required "sync_behind_by" D.string


statusResultAppVersionInfoDecoder : D.Decoder StatusResultAppVersionInfo
statusResultAppVersionInfoDecoder =
    D.succeed StatusResultAppVersionInfo
        |> Pipeline.required "app_commit" D.string
        |> Pipeline.required "app_commit_time" statusResultAppVersionInfoAppCommitTimeDecoder
        |> Pipeline.required "app_compile_time" statusResultAppVersionInfoAppCompileTimeDecoder
        |> Pipeline.required "app_up_time" statusResultAppVersionInfoAppUpTimeDecoder
        |> Pipeline.required "app_version" D.string
        |> Pipeline.required "env_name" D.string


statusResultAppVersionInfoAppCommitTimeDecoder : D.Decoder StatusResultAppVersionInfoAppCommitTime
statusResultAppVersionInfoAppCommitTimeDecoder =
    D.succeed StatusResultAppVersionInfoAppCommitTime
        |> Pipeline.required "absolute" Iso8601.decoder
        |> Pipeline.required "relative" D.string


statusResultAppVersionInfoAppCompileTimeDecoder : D.Decoder StatusResultAppVersionInfoAppCompileTime
statusResultAppVersionInfoAppCompileTimeDecoder =
    D.succeed StatusResultAppVersionInfoAppCompileTime
        |> Pipeline.required "absolute" Iso8601.decoder
        |> Pipeline.required "relative" D.string


statusResultAppVersionInfoAppUpTimeDecoder : D.Decoder StatusResultAppVersionInfoAppUpTime
statusResultAppVersionInfoAppUpTimeDecoder =
    D.succeed StatusResultAppVersionInfoAppUpTime
        |> Pipeline.required "absolute" Iso8601.decoder
        |> Pipeline.required "relative" D.string


statusResultDatabaseTriggersObjectDecoder : D.Decoder StatusResultDatabaseTriggersObject
statusResultDatabaseTriggersObjectDecoder =
    D.succeed StatusResultDatabaseTriggersObject
        |> Pipeline.required "event_manipulation" D.string
        |> Pipeline.required "event_table" D.string
        |> Pipeline.required "name" D.string


{-| Encode Status record into JSON values.
-}
encode : Status -> E.Value
encode status =
    E.object
        [ ( "errors", E.list E.string status.errors )
        , ( "result", encodedStatusResult status.result )
        ]


encodedStatusResult : StatusResult -> E.Value
encodedStatusResult statusResult =
    E.object
        [ ( "app_version_info", encodedStatusResultAppVersionInfo statusResult.appVersionInfo )
        , ( "database_triggers", E.list encodedStatusResultDatabaseTriggersObject statusResult.databaseTriggers )
        , ( "network_name", E.string statusResult.networkName )
        , ( "pgbouncer_working", E.string statusResult.pgbouncerWorking )
        , ( "postgres_working", E.string statusResult.postgresWorking )
        , ( "sync_behind_by", E.string statusResult.syncBehindBy )
        ]


encodedStatusResultAppVersionInfo : StatusResultAppVersionInfo -> E.Value
encodedStatusResultAppVersionInfo statusResultAppVersionInfo =
    E.object
        [ ( "app_commit", E.string statusResultAppVersionInfo.appCommit )
        , ( "app_commit_time", encodedStatusResultAppVersionInfoAppCommitTime statusResultAppVersionInfo.appCommitTime )
        , ( "app_compile_time", encodedStatusResultAppVersionInfoAppCompileTime statusResultAppVersionInfo.appCompileTime )
        , ( "app_up_time", encodedStatusResultAppVersionInfoAppUpTime statusResultAppVersionInfo.appUpTime )
        , ( "app_version", E.string statusResultAppVersionInfo.appVersion )
        , ( "env_name", E.string statusResultAppVersionInfo.envName )
        ]


encodedStatusResultAppVersionInfoAppCommitTime : StatusResultAppVersionInfoAppCommitTime -> E.Value
encodedStatusResultAppVersionInfoAppCommitTime statusResultAppVersionInfoAppCommitTime =
    E.object
        [ ( "absolute", Iso8601.encode statusResultAppVersionInfoAppCommitTime.absolute )
        , ( "relative", E.string statusResultAppVersionInfoAppCommitTime.relative )
        ]


encodedStatusResultAppVersionInfoAppCompileTime : StatusResultAppVersionInfoAppCompileTime -> E.Value
encodedStatusResultAppVersionInfoAppCompileTime statusResultAppVersionInfoAppCompileTime =
    E.object
        [ ( "absolute", Iso8601.encode statusResultAppVersionInfoAppCompileTime.absolute )
        , ( "relative", E.string statusResultAppVersionInfoAppCompileTime.relative )
        ]


encodedStatusResultAppVersionInfoAppUpTime : StatusResultAppVersionInfoAppUpTime -> E.Value
encodedStatusResultAppVersionInfoAppUpTime statusResultAppVersionInfoAppUpTime =
    E.object
        [ ( "absolute", Iso8601.encode statusResultAppVersionInfoAppUpTime.absolute )
        , ( "relative", E.string statusResultAppVersionInfoAppUpTime.relative )
        ]


encodedStatusResultDatabaseTriggersObject : StatusResultDatabaseTriggersObject -> E.Value
encodedStatusResultDatabaseTriggersObject statusResultDatabaseTriggersObject =
    E.object
        [ ( "event_manipulation", E.string statusResultDatabaseTriggersObject.eventManipulation )
        , ( "event_table", E.string statusResultDatabaseTriggersObject.eventTable )
        , ( "name", E.string statusResultDatabaseTriggersObject.name )
        ]
