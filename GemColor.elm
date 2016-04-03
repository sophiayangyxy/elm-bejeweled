module GemColor where

import Color exposing (..)
import Random as R
import Signal
import Time exposing (..)

type GemColor = Red | Orange | Yellow | Green | Blue | Purple | Grey

numColors = 7

toSrc : GemColor -> String
toSrc c =
  case c of
    Red -> "ruby.jpg"
    Orange -> "topaz.png"
    Yellow -> "tourmaline.png"
    Green -> "emerald.png"
    Blue -> "sapphire.png"
    Purple -> "amethyst.jpg"
    Grey ->  "opal.png"

toColor : GemColor -> Color
toColor c =
  case c of
    Red -> red
    Orange -> orange
    Yellow -> yellow
    Green -> green
    Blue -> blue
    Purple -> purple
    Grey -> grey

getRandomColor : Time -> GemColor
getRandomColor time =
    getColor ((round time) % numColors)

getColor : Int -> GemColor
getColor i =
    case i of
        0 -> Red
        1 -> Orange
        2 -> Yellow
        3 -> Green
        4 -> Blue
        5 -> Purple
        6 -> Grey
        _ -> Debug.crash "getColor: index out of bound"
