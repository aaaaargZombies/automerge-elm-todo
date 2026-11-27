port module Remote exposing (OutMsg(..), PortValue(..), flagsDecoder, incoming, outgoing, outgoingValue, portDecoder, send)

import Data exposing (Todo, Todos)
import Dict exposing (Dict)
import Json.Decode exposing (Decoder)
import Json.Encode exposing (Value)


type OutMsg
    = GetTodos String
    | AddTodo String
    | MarkTodo String Int
    | RenameTodo String Int String
    | AddTodoList


outgoingValue : OutMsg -> { tag : String, data : Value }
outgoingValue msg =
    case msg of
        GetTodos automergeUrl ->
            { tag = "GET_TODOS", data = Json.Encode.string automergeUrl }

        AddTodo automergeUrl ->
            { tag = "ADD_TODO", data = Json.Encode.string automergeUrl }

        AddTodoList ->
            { tag = "ADD_TODO_LIST", data = Json.Encode.null }

        MarkTodo automergeUrl id ->
            { tag = "MARK_TODO"
            , data = Json.Encode.object [ ( "url", Json.Encode.string automergeUrl ), ( "id", Json.Encode.int id ) ]
            }

        RenameTodo automergeUrl id name ->
            { tag = "RENAME_TODO"
            , data = Json.Encode.object [ ( "url", Json.Encode.string automergeUrl ), ( "id", Json.Encode.int id ), ( "name", Json.Encode.string name ) ]
            }


send : OutMsg -> Cmd msg
send msg =
    msg |> outgoingValue |> outgoing


port outgoing : { tag : String, data : Json.Encode.Value } -> Cmd msg


port incoming : (Value -> msg) -> Sub msg


type PortValue
    = SynchedTodo ( String, Todos )
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
    Json.Decode.map2 Tuple.pair
        (Json.Decode.index 0 Json.Decode.string)
        (Json.Decode.index 1
            (Json.Decode.map2 Data.fromArray
                (Json.Decode.field "title" Json.Decode.string)
                (Json.Decode.field "items"
                    (Json.Decode.array (Json.Decode.map2 Todo (Json.Decode.field "done" Json.Decode.bool) (Json.Decode.field "name" Json.Decode.string)))
                )
            )
        )
        |> Json.Decode.map SynchedTodo


flagsDecoder : Decoder (Dict String Todos)
flagsDecoder =
    Json.Decode.list
        (Json.Decode.map2 Tuple.pair
            (Json.Decode.index 0 Json.Decode.string)
            (Json.Decode.index 1
                (Json.Decode.map2 Data.fromArray
                    (Json.Decode.field "title" Json.Decode.string)
                    (Json.Decode.field "items"
                        (Json.Decode.array (Json.Decode.map2 Todo (Json.Decode.field "done" Json.Decode.bool) (Json.Decode.field "name" Json.Decode.string)))
                    )
                )
            )
        )
        |> Json.Decode.map Dict.fromList
