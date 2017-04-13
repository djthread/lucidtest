module Main exposing (main)

import Html exposing (Html, div, p, span, text, button, ul, li)
import Html.Attributes exposing (class, style)
import Html.Events exposing (onClick)
import Phoenix
import Phoenix.Socket as Socket
import Phoenix.Channel as Channel
import Phoenix.Push as Push
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
  = AddRandomCard
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
  { hash  : String
  , board : List Int
  }

init : ( Model, Cmd Msg )
init =
  ( Model "" []
  , Cmd.none
  )


-- SUBSCRIPTIONS

subscriptions : Model -> Sub Msg
subscriptions model =
  let
    socket =
      Socket.init socketServer
    channel =
      Channel.init "board"
      |> Channel.on "add_random_card" ReceiveAddRandomCard
      |> Channel.on "state" ReceiveRefresh
  in
    Phoenix.connect socket [channel]


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
    push =
      Push.init "board" message
    --   Phoenix.Push.init message "board"
    -- ( phxSocket, phxCmd ) =
    --   Phoenix.Socket.push push_ model.phxSocket
  in
    model ! [Phoenix.push socketServer push]
    -- ( { model | phxSocket = phxSocket }
    -- , Cmd.map PhoenixMsg phxCmd
    -- )


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

