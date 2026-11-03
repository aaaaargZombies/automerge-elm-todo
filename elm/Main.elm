module Main exposing (main)

import Browser exposing (Document, UrlRequest(..))
import Browser.Navigation exposing (Key)
import Data exposing (Todos)
import Html
import Json.Decode
import Json.Encode exposing (Value)
import Remote exposing (OutMsg(..), PortValue(..))
import Url exposing (Url)
import View


init : flags -> Url -> Key -> ( Model, Cmd Msg )
init flags url key =
    ( { todos = Data.emptyTodos }, Remote.send GetTodos )


type Msg
    = UserToggledDone Int
    | UserUpdatedTodoName Int String
    | UserClickedNewTodo
    | PortProvidedValue Value
    | UrlChanged Url
    | LinkClicked UrlRequest
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
                            ( { todos = todos }, Cmd.none )

        UserClickedNewTodo ->
            -- send out to port
            ( model, Remote.send AddTodo )

        UserToggledDone id ->
            -- send out to port let
            ( model, Remote.send (MarkTodo id) )

        UserUpdatedTodoName id name ->
            -- send out to port
            ( model, Remote.send (RenameTodo id name) )

        UrlChanged url ->
            ( model, Cmd.none )

        LinkClicked urlRequest ->
            ( model, Cmd.none )

        NoOp ->
            ( model, Cmd.none )


view : Model -> Document Msg
view { todos } =
    Document
        "Automerged Todos"
        [ Html.div
            []
            [ View.todoList { newTodo = UserClickedNewTodo, onClickMsg = UserToggledDone, onInputMsg = UserUpdatedTodoName, todos = todos }
            ]
        ]


subscriptions : Model -> Sub Msg
subscriptions _ =
    Remote.incoming PortProvidedValue


main : Program () Model Msg
main =
    Browser.application
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        , onUrlRequest = LinkClicked
        , onUrlChange = UrlChanged
        }
