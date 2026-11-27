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


init : Value -> Url -> Key -> ( Model, Cmd Msg )
init flags url key =
    let
        todoLists : Dict String Todos
        todoLists =
            Json.Decode.decodeValue Remote.flagsDecoder flags
                |> Result.withDefault Dict.empty

        initialModel =
            { key = key, todoLists = todoLists, currentList = Nothing }
    in
    case (AppUrl.fromUrl url).fragment of
        Nothing ->
            ( initialModel, Remote.send (GetTodos "") )

        Just fragment ->
            ( { initialModel | currentList = Just fragment }, Remote.send (GetTodos fragment) )


type Msg
    = UserToggledDone String Int
    | UserUpdatedTodoName String Int String
    | UserClickedNewTodo String
    | UserClickedNewTodoList
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
        UserClickedNewTodo automergeUrl ->
            ( model, Remote.send (AddTodo automergeUrl) )

        UserClickedNewTodoList ->
            ( model, Remote.send AddTodoList )

        UserToggledDone automergeUrl id ->
            ( model, Remote.send (MarkTodo automergeUrl id) )

        UserUpdatedTodoName automergeUrl id name ->
            ( model, Remote.send (RenameTodo automergeUrl id name) )

        PortProvidedValue jsonValue ->
            case Json.Decode.decodeValue Remote.portDecoder jsonValue of
                Err _ ->
                    ( model, Cmd.none )

                Ok portValue ->
                    case portValue of
                        SynchedTodo ( automergeUrl, todos ) ->
                            let
                                lists =
                                    Dict.update automergeUrl (always (Just todos)) model.todoLists
                            in
                            ( { model | todoLists = lists }, Cmd.none )

                        HandleChanged handle ->
                            ( model, Browser.Navigation.pushUrl model.key ("#" ++ handle) )

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
            case urlRequest of
                Browser.Internal url ->
                    ( model
                    , Browser.Navigation.pushUrl model.key (Url.toString url)
                    )

                Browser.External href ->
                    ( model
                    , Browser.Navigation.load href
                    )

        NoOp ->
            ( model, Cmd.none )


view : Model -> Document Msg
view model =
    let
        todos =
            model.currentList
                |> Maybe.andThen (\key -> Dict.get key model.todoLists)
                |> Maybe.withDefault Data.emptyTodos

        url =
            Maybe.withDefault "" model.currentList
    in
    Document
        "Automerged Todos"
        [ Html.div
            []
            [ View.todoListList { todoLists = model.todoLists, currentList = model.currentList, newList = UserClickedNewTodoList }
            , View.todoList { newTodo = UserClickedNewTodo url, onClickMsg = UserToggledDone url, onInputMsg = UserUpdatedTodoName url, todos = todos }
            ]
        ]


subscriptions : Model -> Sub Msg
subscriptions _ =
    Remote.incoming PortProvidedValue


main : Program Value Model Msg
main =
    Browser.application
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        , onUrlRequest = LinkClicked
        , onUrlChange = UrlChanged
        }
