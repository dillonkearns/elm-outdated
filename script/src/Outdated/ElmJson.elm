module Outdated.ElmJson exposing (decoder)

import Json.Decode as Decode exposing (Decoder)
import Outdated.Version as Version exposing (Version)


decoder : Decoder (List ( String, Version ))
decoder =
    Decode.map2 (++)
        (Decode.at [ "dependencies", "direct" ] versionDictDecoder)
        (Decode.at [ "test-dependencies", "direct" ] versionDictDecoder)


versionDictDecoder : Decoder (List ( String, Version ))
versionDictDecoder =
    Decode.keyValuePairs Decode.string
        |> Decode.andThen
            (\pairs ->
                case parseAll pairs of
                    Just result ->
                        Decode.succeed result

                    Nothing ->
                        Decode.fail "Invalid version string in dependencies"
            )


parseAll : List ( String, String ) -> Maybe (List ( String, Version ))
parseAll pairs =
    List.foldr
        (\( name, vStr ) acc ->
            Maybe.map2 (\v list -> ( name, v ) :: list)
                (Version.fromString vStr)
                acc
        )
        (Just [])
        pairs
