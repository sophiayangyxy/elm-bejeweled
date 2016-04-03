module Bejeweled where

import Array as A
import Board exposing (..)
import Control exposing (..)
import Graphics.Element as E exposing (..)
import Graphics.Collage as C exposing (..)
import Random exposing (..)
import Time exposing (..)
import Window

upstate : Update -> State -> State
upstate u ((_, roundStartTime), ((board, score), highScore)) =
    case u of
      NewClick (t, index) ->
        let
            numClicked = getNumClicked (A.toIndexedList board)
            n = newestCrushTime (A.toList board)
            timeElapsed = t - n
            timeRem = timeRemaining t roundStartTime
        in
          -- If the round has finished and the user clicked the restart button,
          -- then update the round start time to current time and generate a new random board.
          if (index == restartIndex) then
            let randomBoard = generateRandomBoard (initialSeed (round t)) board in
            ((t, t), ((randomBoard, 0), highScore))
          -- Disable clicks if there is no time left in this round and update the high score.
          else if (timeRem <= 0) then
            let newHighScore = max score highScore in
              ((t, roundStartTime), ((board, score), newHighScore))
          -- Disable clicks while an existing animation is completing.
          else if (n /= noCrushHappening && timeElapsed < tCrush) then
            ((t, roundStartTime), ((board, score), highScore))
          -- Player requested a hint.
          else if (index == hintIndex) then
              let (b, s) = checkForHints t (board, score) in
              ((t, roundStartTime), ((b, s), highScore))
          else if numClicked == -1 then
              let (col, b) = mustGem index board in
              ((t, roundStartTime), ((markAsClicked index board, score), highScore))
          -- 2nd click wasn't a neighbor; invalid swap, so reset swap.
          else if (isNeighbor index numClicked |> not) then
              ((t, roundStartTime), ((clear False board, score), highScore))
          else
              let
                  (col, b) = mustGem index board
                  newBoard = board |> swap index numClicked
                                   |> markAsClicked index
                  (brd, s) = checkAndUpdateBoard t index numClicked (newBoard, score)
              in
                ((t, roundStartTime), ((brd, s), highScore))
      NewTime t ->
        let (newBoard, newScore) = pruneOld t (board, score)
            timeRem = timeRemaining t roundStartTime
        in
          if (timeRem <= 0) then
            let newHighScore = max score highScore in
              ((t, roundStartTime), ((newBoard, score), newHighScore))
          else
            ((t, roundStartTime), ((newBoard, newScore), highScore))

-- Returns the start crush time of any currently occuring crush, otherwise -1 (noCrushHappening)
-- if no crushing is currently happening.
newestCrushTime : List Gem -> Time
newestCrushTime xs =
  newestCrushTimeHelper xs noCrushHappening

-- Pass in t as -1 (noCrushHappening).
newestCrushTimeHelper : List Gem -> Time -> Time
newestCrushTimeHelper xs t =
  case xs of
    [] -> t
    (_, elim)::xs' ->
      if (elim > t) then newestCrushTimeHelper xs' elim
      else newestCrushTimeHelper xs' t

pruneOld: Time -> BoardAndScore -> BoardAndScore
pruneOld now (board, score) =
  let
      n = newestCrushTime (A.toList board)
      timeElapsed = now - n
  in
    -- If there is no crushing happening or the crushing
    -- hasn't finished animating yet, don't update the board yet.
    if (timeElapsed < tCrush) then
        (board, score)
    -- Finished animating board replacement
    else if (allGone board) then
        let nb = generateRandomBoard (initialSeed (round now)) board in
        (nb, score)
    else if (isHintedBoard board) then
        let nb = clear False board in
        (nb, score)
    else if (n == noCrushHappening) then
        if (hasMoves 0 board |> not) then
            (clearWithTime now board, score)
        else
            (board, score)
    else
        let nb = updateBoard now board in
        rinseAndRepeat now (nb, score)

state : Signal State
state =
    let
        ((t, rst), ((ib, s), hs)) = initState
        rb = generateRandomBoard (initialSeed seed0) ib
    in
    Signal.foldp upstate
            ((0, 0), ((rb, 0), 0))
          (Signal.merge (Signal.map NewTime time)
                        (Signal.map NewClick clicks))

main : Signal E.Element
main =
  Signal.map2 view Window.dimensions state
