port module Main exposing (main)

import Json.Decode as JD
import Json.Encode as JE
import Url
import Url.Parser as U exposing ((</>))


type alias Model =
    ()


init : () -> ( Model, Cmd Msg )
init _ =
    ( (), Cmd.none )


type Method
    = GET
    | POST


type alias Request =
    { url : String
    , method : Method
    , bodyMaybe : Maybe String
    }


requestDecoder : JD.Decoder Request
requestDecoder =
    JD.map3 Request
        (JD.field "url" JD.string)
        methodDecoder
        (JD.field "body" <| JD.maybe JD.string)


methodDecoder : JD.Decoder Method
methodDecoder =
    JD.field "method" JD.string |> JD.andThen methodDecoderHelp


methodDecoderHelp : String -> JD.Decoder Method
methodDecoderHelp str =
    case str of
        "GET" ->
            JD.succeed GET

        "POST" ->
            JD.succeed POST

        _ ->
            JD.fail "un supported method."


type alias Response =
    { status : Int
    , body : String
    }


type Msg
    = HandleRequest JE.Value


type Route
    = Echo String
    | Add String String
    | Sum
    | NotFound


route : U.Parser (Route -> a) a
route =
    U.oneOf
        [ U.map Echo (U.s "echo" </> U.string)
        , U.map Add (U.s "add" </> U.string </> U.string)
        , U.map Sum (U.s "sum")
        ]


toRoute : String -> Route
toRoute urlString =
    case Url.fromString urlString of
        Nothing ->
            NotFound

        Just url ->
            Maybe.withDefault NotFound (U.parse route url)


handleRequest : Request -> Response
handleRequest req =
    case ( req.method, toRoute req.url ) of
        ( GET, Echo str ) ->
            Response 200 str

        ( GET, Add n1Str n2Str ) ->
            case ( String.toInt n1Str, String.toInt n2Str ) of
                ( Just n1, Just n2 ) ->
                    Response 200 (String.fromInt <| n1 + n2)

                _ ->
                    Response 400 "Parameter must be a number."

        ( POST, Sum ) ->
            let
                intValuesDecoder : JD.Decoder (List Int)
                intValuesDecoder =
                    JD.field "values" <| JD.list JD.int
            in
            case req.bodyMaybe of
                Just body ->
                    case JD.decodeString intValuesDecoder body of
                        Ok values ->
                            Response 200 <| String.fromInt <| List.sum values

                        Err _ ->
                            Response 400 """Body must be { "values" : number[] }"""

                Nothing ->
                    Response 400 "empty body."

        ( _, _ ) ->
            Response 404 "404 NotFound"


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        HandleRequest requestJson ->
            case JD.decodeValue requestDecoder requestJson of
                Ok req ->
                    ( model
                    , response <| handleRequest req
                    )

                Err _ ->
                    ( model, response { status = 500, body = "Fail parse request." } )


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.batch
        [ request HandleRequest
        ]


main : Program () Model Msg
main =
    Platform.worker
        { init = init
        , update = update
        , subscriptions = subscriptions
        }


port response : Response -> Cmd msg


port request : (JE.Value -> msg) -> Sub msg
