module Control where

import Array as A
import Board exposing (..)
import GemColor exposing (..)
import List as L
import Random exposing (..)
import Set as S
import Time exposing (..)

{- Since either 0 or 1 gem is clicked at any time, we return
   either -1 or the index of the gem already being clicked on
   respectively for simplicity -}
getNumClicked : List (Int, Gem) -> Int
getNumClicked gems =
    case gems of
        [] -> -1
        (i, (_, -1)) :: gs -> getNumClicked gs
        (i, (_, _)) :: gs -> i


mustGem : Int -> Board -> Gem
mustGem i brd =
    let gem = A.get i brd in
    case gem of
        Nothing -> Debug.crash "mustGem: impossible"
        Just gem -> gem

markAsClicked : Int -> Board -> Board
markAsClicked i brd =
    let (c, b) = mustGem i brd in
    if (b >= 0) then
        Debug.crash "markAsClicked: already crushed"
    else
        A.set i (c, -2) brd

markAsNeutral : Int -> Board -> Board
markAsNeutral i brd =
    let (c, b) = mustGem i brd in
    -- if b then
        A.set i (c, -1) brd
    -- else
        -- Debug.crash "markAsNeutral: already False"

isNeighbor : Int -> Int -> Bool
isNeighbor i j =
    let
        i1 = i // boardWidth
        i2 = i % boardWidth
        j1 = j // boardWidth
        j2 = j % boardWidth
    in
        (i1 == j1 && (abs (i2 - j2) == 1))
        || (i2 == j2 && (abs (i1 - j1) == 1))

clear : Bool -> Board -> Board
clear clicked brd =
    let
        foo clicked i brd =
            let total = boardWidth * boardWidth in
            if i >= total then
                brd
            else if clicked then
                markAsClicked i brd |> foo clicked (i + 1)
            else
                markAsNeutral i brd |> foo clicked (i + 1)
    in
    foo clicked 0 brd

clearWithTime : Time -> Board -> Board
clearWithTime t brd =
    let
        foo t i b =
            let total = boardWidth * boardWidth in
            if i >= total then
                b
            else
                let (gc, gt) = mustGem i b in
                b |> A.set i (gc, t)
                  |> foo t (i + 1)
    in
        foo t 0 brd

allGone : Board -> Bool
allGone brd =
    let
        total = boardWidth * boardWidth
        foo i =
            if (i >= total) then
                True
            else
                let (c, t) = mustGem i brd in
                if t < 0 then False
                else foo (i + 1)
    in
        foo 0

swap : Int -> Int -> Board -> Board
swap i j b =
    b |> A.set i (mustGem j b) |> A.set j (mustGem i b)

scanH : Int -> Int -> Board -> S.Set Int -> S.Set Int
scanH i j brd set =
    if j >= boardWidth then
        if S.size set >= 3 then set
        else S.empty
    else if j == 0 then
        S.insert (i * boardWidth + j) set |> scanH i (j + 1) brd
    else
        let ind = i * boardWidth + j
            prevInd = ind - 1
            (prevCol, prevB) = mustGem prevInd brd
            (currCol, currB) = mustGem ind brd
        in
            if prevCol == currCol && (S.member prevInd set) then
                S.insert ind set |> scanH i (j + 1) brd
            else if S.size set >= 3 then
                set
            else
                S.insert ind S.empty |> scanH i (j + 1) brd

scanV : Int -> Int -> Board -> S.Set Int -> S.Set Int
scanV i j brd set =
    if i >= boardWidth then
        if S.size set >= 3 then set
        else S.empty
    else if i == 0 then
        S.insert (i * boardWidth + j) set |> scanV (i + 1) j brd
    else
        let
            ind = i * boardWidth + j
            prevInd = (i - 1) * boardWidth + j
            (prevCol, prevB) = mustGem prevInd brd
            (currCol, currB) = mustGem ind brd
        in
            if prevCol == currCol && (S.member prevInd set) then
                S.insert ind set |> scanV (i + 1) j brd
            else if S.size set >= 3 then
                set
            else
                S.insert ind S.empty |> scanV (i + 1) j brd

elimBoard : Time -> List Int -> Board -> Board
elimBoard time list brd =
    case list of
        [] ->
            brd
        x :: xs ->
            let (c, b) = mustGem x brd in
            A.set x (c, time) brd |> elimBoard time xs

getSwapIndex : Int -> Int -> Board -> Maybe Int
getSwapIndex i j brd =
    if i < 0 then
        Nothing
    else
        let
            ind = i * boardWidth + j
            (c, b) = mustGem ind brd
        in
        if b == -1 then
            Just ind
        else
            getSwapIndex (i - 1) j brd

flowDownOrRandom : Time -> Int -> Int -> Board -> Board
flowDownOrRandom time i j brd =
    let
        row = i - 1
        col = j % boardWidth
        maybeIndex = getSwapIndex row col brd
        ind = i * boardWidth + j
    in
    case maybeIndex of
        Nothing ->
            let (c, b) = (getRandomColor time, -1) in
            A.set ind (c, -1) brd
        Just i ->
            swap i ind brd

scanUp : Time -> Int -> Int -> Board -> Board
scanUp time i j brd =
    if i < 0 then
        brd
    else if j >= boardWidth then
        scanUp time (i - 1) 0 brd
    else
        let
            ind = i * boardWidth + j
            (col, b) = mustGem ind brd
        in
            if b == -1 then
                scanUp time i (j + 1) brd
            else
                brd |> flowDownOrRandom time i j |> scanUp (time + 1) i (j + 1)

updateBoard : Time -> Board -> Board
updateBoard time brd =
    scanUp time (boardWidth - 1) 0 brd

scanBoardForElims : Time -> Int -> Int -> S.Set Int -> Board -> S.Set Int
scanBoardForElims time i j set brd =
    if (i >= boardWidth && j >= boardWidth) then
        set
    else if (i >= boardWidth) then
        let newSet = S.union set (scanV 0 j brd S.empty) in
        scanBoardForElims time i (j + 1) newSet brd
    else
        let newSet = S.union set (scanH i 0 brd S.empty) in
        scanBoardForElims time (i + 1) j newSet brd

hasElims : Int -> Int -> Board -> Bool
hasElims i j brd =
    if (i >= boardWidth && j >= boardWidth) then
        False
    else if (i >= boardWidth) then
        let set = scanV 0 j brd S.empty in
        if (S.isEmpty set |> not) then
            True
        else
            hasElims i (j + 1) brd
    else
        let set = scanH i 0 brd S.empty in
        if (S.isEmpty set |> not) then
            True
        else
            hasElims (i + 1) j brd

hasMoves : Int -> Board -> Bool
hasMoves ind b =
    let
        total = boardWidth * boardWidth - 1
        i = ind // boardWidth
        j = ind % boardWidth
        foo i j b =
            if (i < boardWidth - 1) && (j < boardWidth - 1) then
                let
                    b1 = swap ind (ind + 1) b
                    b2 = swap ind (ind + boardWidth) b
                in
                    hasElims 0 0 b1 || hasElims 0 0 b2
            else if i < boardWidth - 1 then
                swap ind (ind + boardWidth) b |> hasElims 0 0
            else
                swap ind (ind + 1) b |> hasElims 0 0
    in
        if ind == total then
            False
        else
            if foo i j b then True
            else hasMoves (ind + 1) b

isHintedBoard : Board -> Bool
isHintedBoard b =
    let
        foo i =
            if (i >= boardWidth * boardWidth) then
                0
            else
                let (c, t) = mustGem i b in
                if t > 0 then 1 + foo (i + 1)
                else foo (i + 1)
    in
        if (foo 0 == 2) then True
        else False

markGemsAsHints : Time -> Int -> Int -> Board -> Board
markGemsAsHints t i1 i2 brd =
    let
        (c1, t1) = mustGem i1 brd
        (c2, t2) = mustGem i2 brd
    in
        brd |> A.set i1 (c1, t) |> A.set i2 (c2, t)

-- Mark the first two gems that can generate an elimination
-- Note: board must be valid at this point
checkForHints : Time -> BoardAndScore -> BoardAndScore
checkForHints t (brd, score) =
    let
        foo ind brd =
            if (ind >= (boardWidth * boardWidth - 1)) then
                (brd, score)
            else
                let
                    i = ind // boardWidth
                    j = ind % boardWidth
                in
                if (i < boardWidth - 1) && (j < boardWidth - 1) then
                    let
                        b1 = swap ind (ind + 1) brd
                        b2 = swap ind (ind + boardWidth) brd
                    in
                    if (hasElims 0 0 b1) then
                        (brd |> markGemsAsHints t ind (ind + 1), score - 2 * scoreUnit)
                    else if (hasElims 0 0 b2) then
                        (brd |> markGemsAsHints t ind (ind + boardWidth), score - 2 * scoreUnit)
                    else foo (ind + 1) brd
                else if (i < boardWidth - 1) then
                    if (swap ind (ind + boardWidth) brd |> hasElims 0 0) then
                        (brd |> markGemsAsHints t ind (ind + boardWidth), score - 2 * scoreUnit)
                    else foo (ind + 1) brd
                else
                    if (swap ind (ind + 1) brd |> hasElims 0 0) then
                        (brd |> markGemsAsHints t ind (ind + 1), score - 2 * scoreUnit)
                    else foo (ind + 1) brd
    in
    foo 0 brd

generateRandomBoard : Seed -> Board -> Board
generateRandomBoard seed brd =
    let
        total = boardWidth * boardWidth
        foo s i b =
            if i >= total then
                let set = scanBoardForElims 0 0 0 S.empty b in
                if S.isEmpty set && hasMoves 0 b then
                    b
                else
                    foo s 0 b
            else
                let (n, ns) = generate (int 0 (numColors - 1)) s in
                b |> A.set i (getColor n, -1)
                  |> foo ns (i + 1)
    in
        foo seed 0 brd

rinseAndRepeat : Time -> BoardAndScore -> BoardAndScore
rinseAndRepeat time (brd, scr) =
    let set = scanBoardForElims time 0 0 S.empty brd in
    if S.isEmpty set then
        (brd, scr)
    else
        let nb = elimBoard time (S.toList set) brd in
            (nb, scr + scoreUnit * (S.size set - 2))

checkAndUpdateBoard : Time -> Int -> Int -> BoardAndScore -> BoardAndScore
checkAndUpdateBoard time i j (brd, score) =
    let
        h1 = i // boardWidth
        h2 = j // boardWidth
        v1 = i % boardWidth
        v2 = j % boardWidth
        setH = S.union (scanH h1 0 brd S.empty) (scanH h2 0 brd S.empty)
        setV = S.union (scanV 0 v1 brd S.empty) (scanV 0 v2 brd S.empty)
        removeSet = S.union setH setV
    in
        if S.isEmpty removeSet then -- Reset
            let newBoard =
              brd |> markAsNeutral i
                  |> markAsNeutral j
                  |> swap i j
            in
              (newBoard, score - scoreUnit)

        -- There will be a crushing.
        else
          let newBoard =
            brd |> markAsNeutral i
                |> markAsNeutral j
                |> elimBoard time (S.toList removeSet)
          in
            (newBoard, score + scoreUnit * (S.size removeSet - 2))
