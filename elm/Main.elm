module Main exposing (main)

import Browser
import Data exposing (Todo, Todos)
import Dict
import Html exposing (Html)
import Json.Decode
import Json.Encode exposing (Value)
import Remote exposing (OutMsg(..), PortValue(..))
import View


initialModel : flags -> ( Model, Cmd Msg )
initialModel _ =
    ( { todos = Data.emptyTodos }, GetTodos |> Remote.outgoingValue |> Remote.outgoing )


type Msg
    = UserToggledDone Int
    | UserUpdatedTodoName Int String
    | UserClickedNewTodo
    | PortProvidedValue Value
    | NoOp


type alias Model =
    { todos : Todos
    }


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        PortProvidedValue jsonValue ->
            case Json.Decode.decodeValue Remote.portDecoder jsonValue of
                Err _ ->
                    ( model, Cmd.none )

                Ok portValue ->
                    case portValue of
                        SynchedTodo todos ->
                            let
                                _ =
                                    Debug.log "PORT TODOS" todos
                            in
                            ( { todos = todos }, Cmd.none )

        NoOp ->
            ( model, Cmd.none )

        UserClickedNewTodo ->
            -- send out to port
            ( model, AddTodo |> Remote.outgoingValue |> Remote.outgoing )

        UserToggledDone id ->
            -- send out to port let
            ( model, Cmd.none )

        UserUpdatedTodoName id name ->
            -- send out to port
            ( model, Cmd.none )


view : Model -> Html Msg
view { todos } =
    Html.div []
        [ View.todoList { newTodo = UserClickedNewTodo, onClickMsg = UserToggledDone, onInputMsg = UserUpdatedTodoName, todos = todos }
        ]


subscriptions : Model -> Sub Msg
subscriptions _ =
    Remote.incoming PortProvidedValue


main : Program () Model Msg
main =
    Browser.element
        { init = initialModel
        , view = view
        , update = update
        , subscriptions = subscriptions
        }
