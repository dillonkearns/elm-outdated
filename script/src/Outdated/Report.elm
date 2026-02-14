module Outdated.Report exposing (ColorMode(..), Report, collectReports, formatReport)

import Ansi.Color
import Dict exposing (Dict)
import Outdated.ElmJson exposing (Constraint(..), Dependency)
import Outdated.Version as Version exposing (Version)


type alias Report =
    { name : String
    , current : Version
    , wanted : Version
    , latest : Version
    }


type ColorMode
    = Color
    | NoColor


collectReports : List Dependency -> Dict String (List Version) -> List Report
collectReports deps registry =
    deps
        |> List.filterMap
            (\dep ->
                case Dict.get dep.name registry of
                    Just versions ->
                        let
                            ( current, wanted ) =
                                case dep.constraint of
                                    Exact version ->
                                        ( version
                                        , Version.latestWithSameMajor version versions
                                            |> Maybe.withDefault version
                                        )

                                    Range range ->
                                        let
                                            best =
                                                Version.latestWithinRange range versions
                                                    |> Maybe.withDefault range.lower
                                        in
                                        ( best, best )

                            latestVersion =
                                Version.latest versions
                                    |> Maybe.withDefault current
                        in
                        if Version.compare current wanted /= EQ || Version.compare current latestVersion /= EQ then
                            Just
                                { name = dep.name
                                , current = current
                                , wanted = wanted
                                , latest = latestVersion
                                }

                        else
                            Nothing

                    Nothing ->
                        Nothing
            )


formatReport : ColorMode -> List Report -> String
formatReport colorMode reports =
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

                formatPlainRow r =
                    padRight nameWidth r.name
                        ++ "  "
                        ++ padRight currentWidth r.current
                        ++ "  "
                        ++ padRight wantedWidth r.wanted
                        ++ "  "
                        ++ r.latest

                formatColorRow report r =
                    let
                        nameColor =
                            if Version.compare report.wanted report.latest /= EQ then
                                Ansi.Color.red

                            else
                                Ansi.Color.yellow
                    in
                    Ansi.Color.fontColor nameColor (padRight nameWidth r.name)
                        ++ "  "
                        ++ Ansi.Color.fontColor Ansi.Color.white (padRight currentWidth r.current)
                        ++ "  "
                        ++ Ansi.Color.fontColor Ansi.Color.magenta (padRight wantedWidth r.wanted)
                        ++ "  "
                        ++ Ansi.Color.fontColor Ansi.Color.blue r.latest

                formatDataRow report r =
                    case colorMode of
                        NoColor ->
                            formatPlainRow r

                        Color ->
                            formatColorRow report r
            in
            formatPlainRow header
                :: List.map2 formatDataRow reports rows
                |> String.join "\n"
