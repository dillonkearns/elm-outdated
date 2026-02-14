module VersionTest exposing (..)

import Dict
import Expect
import Json.Decode as Decode
import Outdated.ElmJson as ElmJson
import Outdated.Registry as Registry
import Outdated.Report as Report
import Outdated.Version as Version exposing (Version)
import Test exposing (Test, describe, test)


suite : Test
suite =
    describe "Version"
        [ describe "fromString"
            [ test "parses valid version" <|
                \() ->
                    Version.fromString "1.2.3"
                        |> Expect.equal (Just { major = 1, minor = 2, patch = 3 })
            , test "parses zero version" <|
                \() ->
                    Version.fromString "0.0.0"
                        |> Expect.equal (Just { major = 0, minor = 0, patch = 0 })
            , test "rejects invalid input" <|
                \() ->
                    Version.fromString "not-a-version"
                        |> Expect.equal Nothing
            , test "rejects too few parts" <|
                \() ->
                    Version.fromString "1.2"
                        |> Expect.equal Nothing
            , test "rejects too many parts" <|
                \() ->
                    Version.fromString "1.2.3.4"
                        |> Expect.equal Nothing
            ]
        , describe "toString"
            [ test "formats version as string" <|
                \() ->
                    Version.toString { major = 1, minor = 2, patch = 3 }
                        |> Expect.equal "1.2.3"
            , test "round-trips with fromString" <|
                \() ->
                    Version.fromString "10.20.30"
                        |> Maybe.map Version.toString
                        |> Expect.equal (Just "10.20.30")
            ]
        , describe "compare"
            [ test "equal versions" <|
                \() ->
                    Version.compare
                        { major = 1, minor = 0, patch = 0 }
                        { major = 1, minor = 0, patch = 0 }
                        |> Expect.equal EQ
            , test "major difference" <|
                \() ->
                    Version.compare
                        { major = 1, minor = 0, patch = 0 }
                        { major = 2, minor = 0, patch = 0 }
                        |> Expect.equal LT
            , test "minor difference" <|
                \() ->
                    Version.compare
                        { major = 1, minor = 2, patch = 0 }
                        { major = 1, minor = 1, patch = 0 }
                        |> Expect.equal GT
            , test "patch difference" <|
                \() ->
                    Version.compare
                        { major = 1, minor = 0, patch = 3 }
                        { major = 1, minor = 0, patch = 5 }
                        |> Expect.equal LT
            ]
        , describe "latestWithSameMajor"
            [ test "finds latest version with same major" <|
                \() ->
                    Version.latestWithSameMajor
                        { major = 1, minor = 0, patch = 0 }
                        [ { major = 1, minor = 0, patch = 0 }
                        , { major = 1, minor = 1, patch = 0 }
                        , { major = 1, minor = 2, patch = 0 }
                        , { major = 2, minor = 0, patch = 0 }
                        ]
                        |> Expect.equal (Just { major = 1, minor = 2, patch = 0 })
            , test "returns Nothing if no versions with same major" <|
                \() ->
                    Version.latestWithSameMajor
                        { major = 3, minor = 0, patch = 0 }
                        [ { major = 1, minor = 0, patch = 0 }
                        , { major = 2, minor = 0, patch = 0 }
                        ]
                        |> Expect.equal Nothing
            , test "picks highest among same major" <|
                \() ->
                    Version.latestWithSameMajor
                        { major = 1, minor = 0, patch = 0 }
                        [ { major = 1, minor = 0, patch = 5 }
                        , { major = 1, minor = 1, patch = 0 }
                        , { major = 1, minor = 0, patch = 3 }
                        ]
                        |> Expect.equal (Just { major = 1, minor = 1, patch = 0 })
            ]
        , describe "latest"
            [ test "returns last element" <|
                \() ->
                    Version.latest
                        [ { major = 1, minor = 0, patch = 0 }
                        , { major = 2, minor = 0, patch = 0 }
                        , { major = 3, minor = 0, patch = 0 }
                        ]
                        |> Expect.equal (Just { major = 3, minor = 0, patch = 0 })
            , test "returns Nothing for empty list" <|
                \() ->
                    Version.latest []
                        |> Expect.equal Nothing
            ]
        , describe "ElmJson.decoder"
            [ test "decodes application elm.json" <|
                \() ->
                    let
                        json =
                            """{"type":"application","dependencies":{"direct":{"elm/core":"1.0.5","elm/json":"1.1.3"},"indirect":{}},"test-dependencies":{"direct":{"elm-explorations/test":"2.1.0"},"indirect":{}}}"""
                    in
                    Decode.decodeString ElmJson.decoder json
                        |> Expect.equal
                            (Ok
                                [ ( "elm/core", { major = 1, minor = 0, patch = 5 } )
                                , ( "elm/json", { major = 1, minor = 1, patch = 3 } )
                                , ( "elm-explorations/test", { major = 2, minor = 1, patch = 0 } )
                                ]
                            )
            ]
        , describe "Registry.decoder"
            [ test "decodes registry response" <|
                \() ->
                    let
                        json =
                            """{"elm/core":["1.0.0","1.0.2","1.0.5"],"elm/json":["1.0.0","1.1.3"]}"""
                    in
                    Decode.decodeString Registry.decoder json
                        |> Result.map (Dict.toList >> List.map (Tuple.mapSecond (List.map Version.toString)))
                        |> Expect.equal
                            (Ok
                                [ ( "elm/core", [ "1.0.0", "1.0.2", "1.0.5" ] )
                                , ( "elm/json", [ "1.0.0", "1.1.3" ] )
                                ]
                            )
            ]
        , describe "Report"
            [ test "collectReports finds outdated packages" <|
                \() ->
                    let
                        deps =
                            [ ( "elm/core", { major = 1, minor = 0, patch = 2 } )
                            , ( "elm/json", { major = 1, minor = 1, patch = 3 } )
                            ]

                        registry =
                            Dict.fromList
                                [ ( "elm/core"
                                  , [ { major = 1, minor = 0, patch = 0 }
                                    , { major = 1, minor = 0, patch = 2 }
                                    , { major = 1, minor = 0, patch = 5 }
                                    ]
                                  )
                                , ( "elm/json"
                                  , [ { major = 1, minor = 0, patch = 0 }
                                    , { major = 1, minor = 1, patch = 3 }
                                    ]
                                  )
                                ]
                    in
                    Report.collectReports deps registry
                        |> Expect.equal
                            [ { name = "elm/core"
                              , current = { major = 1, minor = 0, patch = 2 }
                              , wanted = { major = 1, minor = 0, patch = 5 }
                              , latest = { major = 1, minor = 0, patch = 5 }
                              }
                            ]
            , test "collectReports handles major version bump" <|
                \() ->
                    let
                        deps =
                            [ ( "some/pkg", { major = 1, minor = 0, patch = 0 } ) ]

                        registry =
                            Dict.fromList
                                [ ( "some/pkg"
                                  , [ { major = 1, minor = 0, patch = 0 }
                                    , { major = 1, minor = 1, patch = 0 }
                                    , { major = 2, minor = 0, patch = 0 }
                                    ]
                                  )
                                ]
                    in
                    Report.collectReports deps registry
                        |> Expect.equal
                            [ { name = "some/pkg"
                              , current = { major = 1, minor = 0, patch = 0 }
                              , wanted = { major = 1, minor = 1, patch = 0 }
                              , latest = { major = 2, minor = 0, patch = 0 }
                              }
                            ]
            , test "formatReport produces aligned table" <|
                \() ->
                    let
                        reports =
                            [ { name = "elm/core"
                              , current = { major = 1, minor = 0, patch = 2 }
                              , wanted = { major = 1, minor = 0, patch = 5 }
                              , latest = { major = 1, minor = 0, patch = 5 }
                              }
                            , { name = "some/long-package"
                              , current = { major = 1, minor = 0, patch = 0 }
                              , wanted = { major = 1, minor = 1, patch = 0 }
                              , latest = { major = 2, minor = 0, patch = 0 }
                              }
                            ]
                    in
                    Report.formatReport reports
                        |> Expect.equal
                            (String.join "\n"
                                [ "Package            Current  Wanted  Latest"
                                , "elm/core           1.0.2    1.0.5   1.0.5"
                                , "some/long-package  1.0.0    1.1.0   2.0.0"
                                ]
                            )
            , test "formatReport returns message when all up to date" <|
                \() ->
                    Report.formatReport []
                        |> Expect.equal "All packages are up to date!"
            ]
        ]
