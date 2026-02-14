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
        (Decode.at [ "dependencies", "direct" ] (constraintDictDecoder (Version.fromString >> Maybe.map Exact)))
        (Decode.at [ "test-dependencies", "direct" ] (constraintDictDecoder (Version.fromString >> Maybe.map Exact)))


packageDecoder : Decoder (List Dependency)
packageDecoder =
    Decode.map2 (++)
        (Decode.field "dependencies" (constraintDictDecoder (Version.rangeFromString >> Maybe.map Range)))
        (Decode.field "test-dependencies" (constraintDictDecoder (Version.rangeFromString >> Maybe.map Range)))


constraintDictDecoder : (String -> Maybe Constraint) -> Decoder (List Dependency)
constraintDictDecoder parseConstraint =
    Decode.keyValuePairs Decode.string
        |> Decode.andThen
            (\pairs ->
                case parseAllConstraints parseConstraint pairs of
                    Just result ->
                        Decode.succeed result

                    Nothing ->
                        Decode.fail "Invalid version constraint in dependencies"
            )


parseAllConstraints : (String -> Maybe Constraint) -> List ( String, String ) -> Maybe (List Dependency)
parseAllConstraints parseConstraint pairs =
    List.foldr
        (\( name, str ) acc ->
            Maybe.map2 (\constraint list -> { name = name, constraint = constraint } :: list)
                (parseConstraint str)
                acc
        )
        (Just [])
        pairs
