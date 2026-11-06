port module Remote exposing (OutMsg(..), PortValue(..), incoming, outgoing, outgoingValue, portDecoder, send)

import Data exposing (Todo, Todos)
import Json.Decode exposing (Decoder)
import Json.Encode exposing (Value)


type OutMsg
    = GetTodos String
    | AddTodo
    | MarkTodo Int
    | RenameTodo Int String


outgoingValue : OutMsg -> { tag : String, data : Value }
outgoingValue msg =
    case msg of
        GetTodos automergeUrl ->
            { tag = "GET_TODOS", data = Json.Encode.string automergeUrl }

        AddTodo ->
            { tag = "ADD_TODO", data = Json.Encode.null }

        MarkTodo id ->
            { tag = "MARK_TODO", data = Json.Encode.int id }

        RenameTodo id name ->
            { tag = "RENAME_TODO"
            , data = Json.Encode.object [ ( "id", Json.Encode.int id ), ( "name", Json.Encode.string name ) ]
            }


send : OutMsg -> Cmd msg
send msg =
    msg |> outgoingValue |> outgoing


port outgoing : { tag : String, data : Json.Encode.Value } -> Cmd msg


port incoming : (Value -> msg) -> Sub msg


type PortValue
    = SynchedTodo Todos
    | HandleChanged String


portDecoder : Decoder PortValue
portDecoder =
    Json.Decode.field "tag" Json.Decode.string
        |> Json.Decode.andThen
            (\tag ->
                case tag of
                    "SYNCHED_TODOS" ->
                        Json.Decode.field "data" todosDecoder

                    "HANDLE_CHANGED" ->
                        Json.Decode.field "data" Json.Decode.string
                            |> Json.Decode.map HandleChanged

                    other ->
                        Json.Decode.fail ("Unknown tag: " ++ other)
            )


todosDecoder : Decoder PortValue
todosDecoder =
    Json.Decode.array (Json.Decode.map2 Todo (Json.Decode.at [ "done" ] Json.Decode.bool) (Json.Decode.at [ "name" ] Json.Decode.string))
        |> Json.Decode.map Data.fromArray
        |> Json.Decode.map SynchedTodo
