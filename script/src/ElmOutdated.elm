module ElmOutdated exposing (run)

import BackendTask exposing (BackendTask)
import BackendTask.Custom
import BackendTask.File as File
import BackendTask.Http
import Dict exposing (Dict)
import FatalError exposing (FatalError)
import Json.Decode as Decode
import Json.Encode
import Outdated.ElmJson as ElmJson exposing (Dependency)
import Outdated.Registry as Registry
import Outdated.Report as Report
import Outdated.Version exposing (Version)
import Pages.Script as Script exposing (Script)


run : Script
run =
    Script.withoutCliOptions
        (BackendTask.map3
            (\deps registry colorMode ->
                Report.collectReports deps registry
                    |> Report.formatReport colorMode
            )
            readElmJson
            fetchRegistry
            checkColorSupport
            |> BackendTask.andThen Script.log
            |> BackendTask.quiet
        )


readElmJson : BackendTask FatalError (List Dependency)
readElmJson =
    File.rawFile "elm.json"
        |> BackendTask.allowFatal
        |> BackendTask.andThen
            (\raw ->
                case Decode.decodeString ElmJson.decoder raw of
                    Ok deps ->
                        BackendTask.succeed deps

                    Err err ->
                        BackendTask.fail
                            (FatalError.build
                                { title = "Failed to parse elm.json"
                                , body = Decode.errorToString err
                                }
                            )
            )


fetchRegistry : BackendTask FatalError (Dict String (List Version))
fetchRegistry =
    BackendTask.Http.getJson
        "https://package.elm-lang.org/all-packages"
        Registry.decoder
        |> BackendTask.allowFatal


checkColorSupport : BackendTask FatalError Report.ColorMode
checkColorSupport =
    BackendTask.Custom.run "checkColorSupport"
        Json.Encode.null
        Decode.bool
        |> BackendTask.allowFatal
        |> BackendTask.map
            (\useColor ->
                if useColor then
                    Report.Color

                else
                    Report.NoColor
            )
