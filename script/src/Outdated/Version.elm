module Outdated.Version exposing (Version, VersionRange, compare, fromString, latest, latestWithSameMajor, latestWithinRange, rangeFromString, toString)


type alias Version =
    { major : Int
    , minor : Int
    , patch : Int
    }


type alias VersionRange =
    { lower : Version
    , upper : Version
    }


rangeFromString : String -> Maybe VersionRange
rangeFromString str =
    case String.split " <= v < " str of
        [ lowerStr, upperStr ] ->
            Maybe.map2 VersionRange
                (fromString lowerStr)
                (fromString upperStr)

        _ ->
            Nothing


fromString : String -> Maybe Version
fromString str =
    case String.split "." str of
        [ majStr, minStr, patStr ] ->
            Maybe.map3 Version
                (String.toInt majStr)
                (String.toInt minStr)
                (String.toInt patStr)

        _ ->
            Nothing


compare : Version -> Version -> Order
compare a b =
    case Basics.compare a.major b.major of
        EQ ->
            case Basics.compare a.minor b.minor of
                EQ ->
                    Basics.compare a.patch b.patch

                order ->
                    order

        order ->
            order


latestWithSameMajor : Version -> List Version -> Maybe Version
latestWithSameMajor current =
    latestWhere (\v -> v.major == current.major)


latestWithinRange : VersionRange -> List Version -> Maybe Version
latestWithinRange range =
    latestWhere (\v -> compare v range.lower /= LT && compare v range.upper == LT)


latest : List Version -> Maybe Version
latest =
    latestWhere (always True)


latestWhere : (Version -> Bool) -> List Version -> Maybe Version
latestWhere pred versions =
    versions
        |> List.filter pred
        |> List.sortWith compare
        |> List.reverse
        |> List.head


toString : Version -> String
toString v =
    String.fromInt v.major ++ "." ++ String.fromInt v.minor ++ "." ++ String.fromInt v.patch
