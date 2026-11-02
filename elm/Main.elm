module Main exposing (main)

import Browser
import Data exposing (Todo, Todos)
import Dict
import Html exposing (Html)
import Json.Decode exposing (maybe)
import View


initialModel : flags -> ( Model, Cmd Msg )
initialModel _ =
    ( { todos = Data.emptyTodos }, Cmd.none )


type Msg
    = UserToggledDone Int
    | UserUpdatedTodoName Int String
    | UserClickedNewTodo
    | NoOp


type alias Model =
    { todos : Todos
    }


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            ( model, Cmd.none )

        UserClickedNewTodo ->
            ( { model | todos = Data.addTodo (Todo False "") model.todos }, Cmd.none )

        UserToggledDone id ->
            let
                todosItems =
                    Dict.update id (Maybe.map (\t -> { t | done = not t.done })) model.todos.items

                todos_ =
                    Todos model.todos.nextId model.todos.title todosItems
            in
            ( { model
                | todos = todos_
              }
            , Cmd.none
            )

        UserUpdatedTodoName id name ->
            let
                todosItems =
                    Dict.update id (Maybe.map (\t -> { t | name = name })) model.todos.items

                todos_ =
                    Todos model.todos.nextId model.todos.title todosItems
            in
            ( { model
                | todos = todos_
              }
            , Cmd.none
            )


view : Model -> Html Msg
view { todos } =
    Html.div []
        [ View.todoList { newTodo = UserClickedNewTodo, onClickMsg = UserToggledDone, onInputMsg = UserUpdatedTodoName, todos = todos }
        ]


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none


main : Program () Model Msg
main =
    Browser.element
        { init = initialModel
        , view = view
        , update = update
        , subscriptions = subscriptions
        }
