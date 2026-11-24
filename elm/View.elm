module View exposing (..)

import Data exposing (Todos)
import Dict exposing (Dict)
import Html exposing (Html)
import Html.Attributes
import Html.Events


todo : { onClickMsg : Int -> msg, onInputMsg : Int -> String -> msg, done : Bool, name : String, id : Int } -> Html msg
todo { onClickMsg, onInputMsg, done, name, id } =
    Html.li
        []
        [ Html.input
            [ Html.Attributes.checked done
            , Html.Attributes.type_ "checkbox"
            , Html.Events.onClick (onClickMsg id)
            ]
            []
        , Html.node "caret-preserver"
            [ Html.Events.onInput (onInputMsg id)
            , Html.Attributes.attribute "value" name
            , Html.Attributes.attribute "placeholder" "What needs doing?"
            ]
            []
        ]


todoList : { newTodo : msg, onClickMsg : Int -> msg, onInputMsg : Int -> String -> msg, todos : Todos } -> Html msg
todoList { onClickMsg, onInputMsg, newTodo, todos } =
    Html.div
        []
        [ Html.h2 [] [ Html.text todos.title ]
        , Html.button [ Html.Events.onClick newTodo ] [ Html.text "+ Todo" ]
        , todos.items
            |> Dict.toList
            |> List.map (\( k, v ) -> todo { onClickMsg = onClickMsg, onInputMsg = onInputMsg, done = v.done, name = v.name, id = k })
            |> Html.ul []
        ]


todoListList : { todoLists : Dict String Todos, currentList : Maybe String } -> Html msg
todoListList { todoLists, currentList } =
    let
        isCurrent : String -> String
        isCurrent autoUrl =
            currentList
                |> Maybe.map
                    (\current ->
                        if current == autoUrl then
                            "True"

                        else
                            "false"
                    )
                |> Maybe.withDefault "false"
    in
    todoLists
        |> Dict.toList
        |> List.map
            (\( automergeUrl, todoVal ) ->
                Html.li
                    [ Html.Attributes.attribute "aria-current" (isCurrent automergeUrl) ]
                    [ Html.a [ Html.Attributes.href ("#" ++ automergeUrl) ] [ Html.text todoVal.title ] ]
            )
        |> Html.ul []
