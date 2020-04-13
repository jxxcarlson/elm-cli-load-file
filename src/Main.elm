port module Main exposing (main)

import Cmd.Extra exposing (withCmd, withNoCmd)
import Json.Decode as Decode
import Json.Encode as Encode
import List.Extra
import Platform exposing (Program)


port get : (String -> msg) -> Sub msg


port put : String -> Cmd msg


port sendFileName : Encode.Value -> Cmd msg


port receiveData : (Encode.Value -> msg) -> Sub msg


type alias Model =
    { contents : Maybe String }


type alias Flags =
    ()


initModel : Flags -> Model
initModel _ =
    { contents = Nothing }


type Msg
    = Input String
    | ReceiveFileContents Encode.Value


main : Program Flags Model Msg
main =
    Platform.worker
        { init = \f -> ( initModel f, Cmd.none )
        , update = update
        , subscriptions = subscriptions
        }


parseArgs : String -> Maybe ( String, String )
parseArgs str =
    let
        words =
            String.words str

        cmd =
            List.Extra.getAt 0 words

        arg =
            List.Extra.getAt 1 words
    in
    case ( cmd, arg ) of
        (Just "show", _) ->
          Just ("show", "-")

        ( Nothing, _ ) ->
            Nothing

        ( _, Nothing ) ->
            Nothing

        ( Just x, Just y ) ->
            Just ( x, y )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Input input ->
            case parseArgs input of
                Nothing ->
                    model |> withCmd (put "bad input")

                Just ( cmd, arg ) ->
                    case cmd of
                        "load" ->
                            model |> withCmd (sendFileName (Encode.string <| arg))

                        "show" ->
                            case model.contents of
                                Nothing ->
                                    model |> withCmd (put "No file contents to show")

                                Just str ->
                                    model |> withCmd (put <| str)

                        _ ->
                            model |> withCmd (put "I don't understand")

        ReceiveFileContents value ->
            case decodeFileContents value of
                Nothing ->
                    model |> withCmd (put "Error getting file")

                Just contents ->
                    { model | contents = Just contents }
                      |> withCmd (put ("Received file"))


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.batch [ get Input, receiveData ReceiveFileContents ]


decodeFileContents : Encode.Value -> Maybe String
decodeFileContents value =
    case Decode.decodeValue Decode.string value of
        Ok str ->
            Just str

        Err _ ->
            Nothing
