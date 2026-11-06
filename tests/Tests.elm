module Tests exposing (..)

import AppUrl
import Expect
import Fuzz exposing (Fuzzer)
import Test exposing (Test)
import Url


suite : Test
suite =
    Test.describe "Just checking how AppUrl works"
        [ Test.test "get a fragment" <|
            \_ ->
                "http://localhost:5173/#automerge:2mdM9TnM2sJgLhHhYjyBzfusSsyr"
                    |> Url.fromString
                    |> Maybe.map AppUrl.fromUrl
                    |> Maybe.andThen
                        (\url ->
                            let
                                _ =
                                    Debug.log "APPURL" url
                            in
                            url.fragment
                        )
                    |> Maybe.withDefault "fail"
                    |> Expect.equal "automerge:2mdM9TnM2sJgLhHhYjyBzfusSsyr"
        ]
