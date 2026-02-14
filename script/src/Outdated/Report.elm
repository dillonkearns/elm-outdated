module Outdated.Report exposing (Report, collectReports, formatReport)

import Dict exposing (Dict)
import Outdated.Version as Version exposing (Version)


type alias Report =
    { name : String
    , current : Version
    , wanted : Version
    , latest : Version
    }


collectReports : List ( String, Version ) -> Dict String (List Version) -> List Report
collectReports deps registry =
    deps
        |> List.filterMap
            (\( name, current ) ->
                case Dict.get name registry of
                    Just versions ->
                        let
                            wanted =
                                Version.latestWithSameMajor current versions
                                    |> Maybe.withDefault current

                            latestVersion =
                                Version.latest versions
                                    |> Maybe.withDefault current
                        in
                        if Version.compare current wanted /= EQ || Version.compare current latestVersion /= EQ then
                            Just
                                { name = name
                                , current = current
                                , wanted = wanted
                                , latest = latestVersion
                                }

                        else
                            Nothing

                    Nothing ->
                        Nothing
            )


formatReport : List Report -> String
formatReport reports =
    case reports of
        [] ->
            "All packages are up to date!"

        _ ->
            let
                header =
                    { name = "Package", current = "Current", wanted = "Wanted", latest = "Latest" }

                rows =
                    List.map
                        (\r ->
                            { name = r.name
                            , current = Version.toString r.current
                            , wanted = Version.toString r.wanted
                            , latest = Version.toString r.latest
                            }
                        )
                        reports

                allRows =
                    header :: rows

                nameWidth =
                    allRows |> List.map (.name >> String.length) |> List.maximum |> Maybe.withDefault 0

                currentWidth =
                    allRows |> List.map (.current >> String.length) |> List.maximum |> Maybe.withDefault 0

                wantedWidth =
                    allRows |> List.map (.wanted >> String.length) |> List.maximum |> Maybe.withDefault 0

                padRight width str =
                    str ++ String.repeat (width - String.length str) " "

                formatRow r =
                    padRight nameWidth r.name
                        ++ "  "
                        ++ padRight currentWidth r.current
                        ++ "  "
                        ++ padRight wantedWidth r.wanted
                        ++ "  "
                        ++ r.latest
            in
            allRows
                |> List.map formatRow
                |> String.join "\n"
