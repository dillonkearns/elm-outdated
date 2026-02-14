module Outdated.Registry exposing (decoder)

import Dict exposing (Dict)
import Json.Decode as Decode exposing (Decoder)
import Outdated.Version as Version exposing (Version)


decoder : Decoder (Dict String (List Version))
decoder =
    Decode.keyValuePairs (Decode.list Decode.string)
        |> Decode.andThen
            (\pairs ->
                case parseAll pairs of
                    Just result ->
                        Decode.succeed (Dict.fromList result)

                    Nothing ->
                        Decode.fail "Invalid version string in registry"
            )


parseAll : List ( String, List String ) -> Maybe (List ( String, List Version ))
parseAll pairs =
    List.foldr
        (\( name, vStrs ) acc ->
            Maybe.map2 (\versions list -> ( name, versions ) :: list)
                (parseVersionList vStrs)
                acc
        )
        (Just [])
        pairs


parseVersionList : List String -> Maybe (List Version)
parseVersionList strs =
    List.foldr
        (\s acc ->
            Maybe.map2 (::) (Version.fromString s) acc
        )
        (Just [])
        strs
