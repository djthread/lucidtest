module Main exposing (main)

import Html exposing (Html, div, p, span, text, button, ul, li)
import Html.Attributes exposing (class, style)
import Html.Events exposing (onClick)
import Phoenix.Socket
import Phoenix.Channel
import Phoenix.Push
import Json.Encode as JE
import Json.Decode exposing (Decoder, decodeValue, list, int, string)
import Json.Decode.Pipeline exposing (decode, required, optional)
import MD5


-- MAIN

main : Program Never Model Msg
main =
  Html.program
    { init          = init
    , update        = update
    , view          = view
    , subscriptions = subscriptions
    }


-- MODEL

type Msg
  = PhoenixMsg (Phoenix.Socket.Msg Msg)
  | AddRandomCard
  | ReceiveRefresh JE.Value
  | ReceiveAddRandomCard JE.Value
  | LogState

type alias Card =
  Int

type alias ServerMessage =
  { hash    : String
  , card    : Int
  , board   : (List Int)
  }

type alias Model =
  { hash      : String
  , board     : List Int
  , phxSocket : Phoenix.Socket.Socket Msg
  }

init : ( Model, Cmd Msg )
init =
  let
    channel =
      Phoenix.Channel.init "board"
    initSocket =
      Phoenix.Socket.init socketServer
      |> Phoenix.Socket.withDebug
      |> Phoenix.Socket.on "add_random_card" "board" ReceiveAddRandomCard
      |> Phoenix.Socket.on "state" "board" ReceiveRefresh
    ( phxSocket, phxCmd ) =
      Phoenix.Socket.join channel initSocket
  in
    ( Model "" [] phxSocket
    , Cmd.map PhoenixMsg phxCmd
    )


-- SUBSCRIPTIONS

subscriptions : Model -> Sub Msg
subscriptions model =
  Phoenix.Socket.listen model.phxSocket PhoenixMsg


-- CONSTANTS

socketServer : String
socketServer =
  "ws://localhost:4000/socket/websocket"

cardOptions : Int
cardOptions =
  5


-- UPDATE

update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
  case msg of
    PhoenixMsg msg ->
      let
        ( phxSocket, phxCmd ) =
          Phoenix.Socket.update msg model.phxSocket
      in
        ( { model | phxSocket = phxSocket }
        , Cmd.map PhoenixMsg phxCmd
        )

    AddRandomCard ->
      pushMessage "add_random_card" model

    ReceiveRefresh raw ->
      case decodeValue serverMessageDecoder raw of
        Ok serverMessage ->
          ( { model
            | hash = serverMessage.hash
            , board = serverMessage.board
            }
          , Cmd.none
          )

        Err error ->
          ( model, Cmd.none )

    ReceiveAddRandomCard raw ->
      case decodeValue serverMessageDecoder raw of
        Ok serverMessage ->
          let
            newBoard = model.board ++ [serverMessage.card]
          in
            -- Debug.log ("winning: " ++ toString newBoard)
            ( { model | board = newBoard }, Cmd.none )

        Err error ->
          -- Debug.log "losing"
          ( model, Cmd.none )

    LogState ->
      Debug.log ("Board: " ++ (toString model.board))
      ( model, Cmd.none )


pushMessage : String -> Model -> ( Model, Cmd Msg )
pushMessage message model =
  let
    push_ =
      Phoenix.Push.init message "board"
    ( phxSocket, phxCmd ) =
      Phoenix.Socket.push push_ model.phxSocket
  in
    ( { model | phxSocket = phxSocket }
    , Cmd.map PhoenixMsg phxCmd
    )


-- DECODERS

serverMessageDecoder : Decoder ServerMessage
serverMessageDecoder =
  decode ServerMessage
  |> required "hash" string
  |> optional "card" int 0
  |> optional "board" (list int) []
  

-- VIEW

view : Model -> Html Msg
view model = 
  let
    stringlist =
      List.map toString model.board
    countlabel =
      ["(", List.length stringlist |> toString, " cards)"]
      |> String.join ""
    boardstr =
      stringlist
      |> String.join " "
    hash =
      stringlist
      |> String.join ""
      |> Debug.log "tohash"
      |> MD5.hex
      |> Debug.log "hash"
  in
    div []
      [ button [ onClick AddRandomCard ] [ text "Add Random Card" ]
      , button [ onClick LogState ] [ text "Log State" ]
      , text " "
      , span [] [ text countlabel ]
      , p [] [ text boardstr ]
      , p [ style [ ( "font-family", "monospace" ) ] ] [ text hash ]
      , ul [] (List.map renderCard stringlist)
      ]

renderCard : String -> Html Msg
renderCard card =
  let
    color =
      case card of
        "1" -> "#66c"
        "2" -> "#c66"
        "3" -> "#6c6"
        "4" -> "#cc6"
        _   -> "#6cc"
    cardstyle =
      [ ( "background-color", color ) ]
    content =
      [ text " " ]
  in
    li [ class "card", style cardstyle ] content

