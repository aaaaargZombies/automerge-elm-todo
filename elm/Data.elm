module Data exposing (..)

import Array exposing (Array)
import Dict exposing (Dict)


type alias Todo =
    { done : Bool
    , name : String
    }


type alias Todos =
    { title : String
    , items : Dict Int Todo
    }


fakeTodos : Todos
fakeTodos =
    { title = "Example"
    , items = Dict.fromList [ ( 0, { done = False, name = "" } ) ]
    }


emptyTodos : Todos
emptyTodos =
    Todos "My Todos" Dict.empty


withTitle : String -> Todos -> Todos
withTitle title todos =
    { todos | title = title }


fromArray : Array Todo -> Todos
fromArray todoArray =
    todoArray
        |> Array.toIndexedList
        |> Dict.fromList
        |> Todos ""
