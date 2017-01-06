module Main exposing (..)

import Html exposing (Html, div, text, button, ul, li)
import Html.Attributes exposing (class, style)
import Html.Events exposing (onClick)
import Phoenix.Socket
import Phoenix.Channel
import Phoenix.Push
import Json.Encode as JE
import Json.Decode as JD


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
  | ChangeCard
  | ShowCardAdded Int String
  | ShowCardChanged Int Int String
  | PhoenixMsg (Phoenix.Socket.Msg Msg)
  | ReceiveAddRandomCard JE.Value
  | LogState

type alias Card =
  Int

type alias ServerMessage =
  { hash    : String
  , card    : Int
  }

type alias Model =
  { board     : List Int
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
    ( phxSocket, phxCmd ) =
      Phoenix.Socket.join channel initSocket
  in
    ( Model [] phxSocket
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
      let
        push_ =
          Phoenix.Push.init "add_random_card" "board"
        ( phxSocket, phxCmd ) =
          Phoenix.Socket.push push_ model.phxSocket
      in
        ( { model | phxSocket = phxSocket }
        , Cmd.map PhoenixMsg phxCmd
        )

    ChangeCard ->
      ( model, Cmd.none )

    ShowCardAdded num hash ->
      ( model, Cmd.none )

    ShowCardChanged idx num hash ->
      ( model, Cmd.none )

    ReceiveAddRandomCard raw ->
      case JD.decodeValue serverMessageDecoder raw of
        Ok serverMessage ->
          let
            board = serverMessage.card :: model.board
          in
            Debug.log ("winning: " ++ toString board)
            ( { model
              | board = board
              }
            , Cmd.none
            )

        Err error ->
          Debug.log "losing"
          ( model, Cmd.none )

    LogState ->
      Debug.log ("Board: " ++ (toString model.board))
      ( model, Cmd.none )


-- DECODERS

serverMessageDecoder : JD.Decoder ServerMessage
serverMessageDecoder =
  JD.map2 ServerMessage
    (JD.at ["hash"] JD.string)
    (JD.at ["card"] JD.int)
  

-- VIEW

view : Model -> Html Msg
view model = 
  div []
    [ button [onClick AddRandomCard] [text "Add Card"]
    , button [onClick LogState] [text "Log State"]
    , ul [] (List.map renderCard model.board)
    ]

renderCard : Card -> Html Msg
renderCard card =
  let
    color =
      case card of
        1 -> "blue"
        2 -> "red"
        3 -> "yellow"
        4 -> "green"
        _ -> "orange"
    cardstyle =
      [("background-color", color)]
    content =
      [text "."]
  in
    li [class "card", (style cardstyle)] content

