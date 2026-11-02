module Data exposing (..)

import Dict exposing (Dict)


type alias Todo =
    { done : Bool
    , name : String
    }


type alias Todos =
    { nextId : Int
    , title : String
    , items : Dict Int Todo
    }


fakeTodos : Todos
fakeTodos =
    { nextId = 1
    , title = "Example"
    , items = Dict.fromList [ ( 0, { done = False, name = "" } ) ]
    }


emptyTodos : Todos
emptyTodos =
    Todos 0 "My Todos" Dict.empty


addTodo : Todo -> Todos -> Todos
addTodo todo todos =
    { todos | nextId = todos.nextId + 1, items = Dict.insert todos.nextId todo todos.items }


withTitle : String -> Todos -> Todos
withTitle title todos =
    { todos | title = title }
