module Outdated.ElmJson exposing (Constraint(..), Dependency, decoder)

import Json.Decode as Decode exposing (Decoder)
import Outdated.Version as Version exposing (Version, VersionRange)


type Constraint
    = Exact Version
    | Range VersionRange


type alias Dependency =
    { name : String
    , constraint : Constraint
    }


decoder : Decoder (List Dependency)
decoder =
    Decode.field "type" Decode.string
        |> Decode.andThen
            (\elmJsonType ->
                case elmJsonType of
                    "application" ->
                        applicationDecoder

                    "package" ->
                        packageDecoder

                    _ ->
                        Decode.fail ("Unknown elm.json type: " ++ elmJsonType)
            )


applicationDecoder : Decoder (List Dependency)
applicationDecoder =
    Decode.map2 (++)
        (Decode.at [ "dependencies", "direct" ] (exactDictDecoder))
        (Decode.at [ "test-dependencies", "direct" ] (exactDictDecoder))


packageDecoder : Decoder (List Dependency)
packageDecoder =
    Decode.map2 (++)
        (Decode.field "dependencies" rangeDictDecoder)
        (Decode.field "test-dependencies" rangeDictDecoder)


exactDictDecoder : Decoder (List Dependency)
exactDictDecoder =
    Decode.keyValuePairs Decode.string
        |> Decode.andThen
            (\pairs ->
                case parseAllExact pairs of
                    Just result ->
                        Decode.succeed result

                    Nothing ->
                        Decode.fail "Invalid version string in dependencies"
            )


parseAllExact : List ( String, String ) -> Maybe (List Dependency)
parseAllExact pairs =
    List.foldr
        (\( name, vStr ) acc ->
            Maybe.map2 (\v list -> { name = name, constraint = Exact v } :: list)
                (Version.fromString vStr)
                acc
        )
        (Just [])
        pairs


rangeDictDecoder : Decoder (List Dependency)
rangeDictDecoder =
    Decode.keyValuePairs Decode.string
        |> Decode.andThen
            (\pairs ->
                case parseAllRanges pairs of
                    Just result ->
                        Decode.succeed result

                    Nothing ->
                        Decode.fail "Invalid version range in dependencies"
            )


parseAllRanges : List ( String, String ) -> Maybe (List Dependency)
parseAllRanges pairs =
    List.foldr
        (\( name, rangeStr ) acc ->
            Maybe.map2 (\range list -> { name = name, constraint = Range range } :: list)
                (Version.rangeFromString rangeStr)
                acc
        )
        (Just [])
        pairs
