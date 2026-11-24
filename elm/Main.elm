module Main exposing (main)

import AppUrl
import Browser exposing (Document, UrlRequest(..))
import Browser.Navigation exposing (Key)
import Data exposing (Todos)
import Dict exposing (Dict)
import Html
import Json.Decode
import Json.Encode exposing (Value)
import Remote exposing (OutMsg(..), PortValue(..))
import Url exposing (Url)
import View


init : flags -> Url -> Key -> ( Model, Cmd Msg )
init flags url key =
    let
        initialModel =
            { key = key, todoLists = Dict.empty, currentList = Nothing }
    in
    case (AppUrl.fromUrl url).fragment of
        Nothing ->
            ( initialModel, Remote.send (GetTodos "") )

        Just fragment ->
            ( { initialModel | currentList = Just fragment }, Remote.send (GetTodos fragment) )


type Msg
    = UserToggledDone Int
    | UserUpdatedTodoName Int String
    | UserClickedNewTodo
    | PortProvidedValue Value
    | UrlChanged Url
    | LinkClicked UrlRequest
    | NoOp


type alias Model =
    { todoLists : Dict String Todos
    , currentList : Maybe String
    , key : Browser.Navigation.Key
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
                                lists =
                                    model.currentList
                                        |> Maybe.map (\key -> Dict.update key (always (Just todos)) model.todoLists)
                                        |> Maybe.withDefault model.todoLists
                            in
                            ( { model | todoLists = lists }, Cmd.none )

                        HandleChanged handle ->
                            ( model, Browser.Navigation.pushUrl model.key ("#" ++ handle) )

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
            let
                appUrl =
                    AppUrl.fromUrl url
            in
            case ( appUrl.path, appUrl.queryParameters, appUrl.fragment ) of
                ( [], _, Nothing ) ->
                    ( model, Cmd.none )

                ( [], _, Just fragment ) ->
                    ( { model | currentList = Just fragment }, Remote.send (GetTodos fragment) )

                _ ->
                    ( model, Cmd.none )

        LinkClicked urlRequest ->
            ( model, Cmd.none )

        NoOp ->
            ( model, Cmd.none )


view : Model -> Document Msg
view model =
    let
        todos =
            model.currentList
                |> Maybe.andThen (\key -> Dict.get key model.todoLists)
                |> Maybe.withDefault Data.emptyTodos
    in
    Document
        "Automerged Todos"
        [ Html.div
            []
            [ View.todoListList { todoLists = model.todoLists, currentList = model.currentList }
            , View.todoList { newTodo = UserClickedNewTodo, onClickMsg = UserToggledDone, onInputMsg = UserUpdatedTodoName, todos = todos }
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
