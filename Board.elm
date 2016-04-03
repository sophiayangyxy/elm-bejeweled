module Board where

import Array exposing (..)
import Color exposing (..)
import List exposing (..)
import Graphics.Collage as C exposing (..)
import Graphics.Element as E exposing (..)
import Graphics.Input exposing (..)
import GemColor exposing (..)
import Mouse
import Signal exposing (..)
import Text as T
import Time exposing (..)
import Window

-- Macros
boardWidth = 6
boardContainerWidth = boardWidth * 110
clockRad = 80
clockWidth = clockRad * 2 + 20
margin = 200
noCrushHappening = -1
playTime = 90 -- in seconds
restartIndex = -3
restartButtonHeight = 70
restartButtonWidth = 180
hintIndex = -4
scoreUnit = 150
secondsPerMin = 60
seed0 = 31415
spacing = 100
tCrush = 0.8 * Time.second -- Crush animation duration
textStyle = { typeface = ["helvetica neue", "helvetica", "arial", "sans-serif"]
              , height   = Just 50
              , color    = lightRed
              , bold     = True
              , italic   = True
              , line     = Nothing
            }

{- The Time field of a gem will correspond to the time at which the gem started
  being crushed, if at all.  The "elimination" field value will correspond as follows:
  -1: Default.  Gem is neither being crushed nor clicked.
  -2: Gem is clicked but not being crushed.
  >= 0: Gem is being crushed, with the value corresponding to the start crush time.
-}
type alias Gem = (GemColor, Time)
type alias Board = Array Gem
type Update = NewTime Time.Time | NewClick Click
type alias BoardAndScore = (Board, Int)
-- High score is recalculated at the end of each round.
type alias HighScore = Int
type alias RoundStartTime = Time
type alias State = ((Time, RoundStartTime), (BoardAndScore, HighScore))
-- A click is the timestamp and index of clicked gem.
type alias Click = (Time, Int)

initBoard =
    let foo l =
      if (List.length l == boardWidth * boardWidth) then l
      else foo ((Green, -1) :: l)
    in
      fromList (foo [])

initState = ((0, 0), ((initBoard, 0), 0))

time : Signal Time
time = Signal.foldp (+) 0 (Time.fps 10)

-- Mailbox that receives a message containing the index of the clicked gem
-- whenever a gem on the board is clicked.
clickMailbox : Signal.Mailbox Int
clickMailbox = Signal.mailbox 0

timestamp : Signal a -> Signal (Time, a)
timestamp sig = Signal.map2 (,) (Signal.sampleOn sig time) sig

-- Whenever the clickMailbox receives a new message containing
-- the index of a clicked gem, we stamp it with a time.
clicks : Signal Click
clicks = timestamp clickMailbox.signal

timeRemaining : Time -> Time -> Int
timeRemaining time roundStartTime = round (playTime - ((inSeconds time) - (inSeconds roundStartTime)))

hand c len angle =
    segment (0, 0) (fromPolar (len, angle))
        |> traced (solid c)

view : (Int,Int) -> State -> E.Element
view (w,h) st =
  let ((time, roundStartTime), ((board, score), highScore)) = st
      timeRem = timeRemaining time roundStartTime
      timerString =
        if (timeRem > 0) then "You have: " ++ (toString timeRem) ++ " s"
        else "GAME OVER"
      angle = degrees (360 / playTime * toFloat (timeRem) + 90)
      scoreString = "Score: " ++ (toString score)
      timerText = T.fromString timerString
                    |> T.style textStyle
                    |> leftAligned
      scoreText = T.fromString scoreString
                    |> T.style textStyle
                    |> leftAligned
      clock = C.collage clockWidth clockWidth
                [ filled lightYellow (circle clockRad)
                , outlined (solid orange) (circle clockRad)
                , if (timeRem > 0) then hand red 70 angle
                  else hand red 70 (degrees 90)
                ]
      highScoreText = T.fromString ("Highscore: " ++ (toString highScore))
                        |> T.style textStyle
                        |> leftAligned
      restartRect = rect restartButtonWidth restartButtonHeight |> filled lightYellow
      restartOutline = rect restartButtonWidth restartButtonHeight |> outlined (solid lightRed)
      restartText = (if (timeRem <= 0) then
                        T.fromString ("Play Again")
                    else
                        T.fromString ("Hint"))
                      |> T.style textStyle
                      |> T.color lightRed
                      |> T.height 30
                      |> T.line T.Under
                      |> leftAligned
      restartButtonImg = collage restartButtonWidth restartButtonHeight [restartRect, restartOutline, restartText |> toForm]
      restartButton =
          let index = if (timeRem <= 0) then restartIndex else hintIndex in
          customButton (Signal.message clickMailbox.address index)
            restartButtonImg restartButtonImg restartButtonImg
  in
      flow right
        [ E.container boardContainerWidth h E.middle <| drawState st,
          E.container 500 h (E.midLeftAt (E.absolute 50) (E.absolute 400)) <|
              flow down [
                          scoreText,
                          E.spacer 10 20,
                          timerText,
                          E.spacer 10 20,
                          clock,
                          E.spacer 10 20,
                          highScoreText,
                          E.spacer 10 20,
                          restartButton
                        ]
        ]
      |> E.container w h E.middle

drawState : State -> Element
drawState ((now, rst), (bSc, hs)) =
  case bSc of
    (board, score) ->
      drawBoard now rst board

drawBoard : Time -> Time -> Board -> Element
drawBoard now roundStartTime board =
  let xs = drawGemsList now roundStartTime board in
    flow down
      ((spacer 250 5)::List.map (flow right) (partitionGemsListByRow xs))

-- Partition the flat gems list into a list of lists,
-- each corresponding to a row of the board.
partitionGemsListByRow : List Element -> List (List Element)
partitionGemsListByRow xs =
  case xs of
    [] -> []
    _ -> (take boardWidth xs) :: partitionGemsListByRow (drop boardWidth xs)

-- Produces a flat, 1D list of all gem elements in the board.
drawGemsList : Time -> Time -> Board -> List Element
drawGemsList now roundStartTime board =
  List.map (drawGem now roundStartTime) (toIndexedList board)

-- Note: need to convert the board array to an indexed list before using this function.
drawGem : Time -> Time -> (Int, Gem) -> Element
drawGem now roundStartTime (index, (c, elim)) =
  let
    xPos = toFloat (index % boardWidth * spacing) - margin
    yPos = toFloat (boardWidth - (index // boardWidth)) * spacing - margin
    timeElapsed = now - elim
    animationPercentComplete = timeElapsed / tCrush
    sz = if (elim == -2) then 40
         else if (elim == -1) then 60
         else round (60 - 60 * animationPercentComplete)
    imgForm = (image sz sz ("img/"++(toSrc c))) |> toForm
    timeRem = timeRemaining now roundStartTime
    img = if (elim < 0) then imgForm else imgForm |> alpha (1 - animationPercentComplete)
    imgFade = if (timeRem <= 0) then img |> alpha 0.5 else img
    outline = (square 80.0) |> outlined (solid yellow)
    formList = if (elim == -2) then [imgFade, outline] else [imgFade]
  in
    collage spacing spacing formList
      |> clickable (Signal.message clickMailbox.address index)
