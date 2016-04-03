Elm-Bejeweled

Build instructions:
1. Install Elm (http://elm-lang.org/install)
2. Clone this repo onto your local machine and cd into the directory
3. Run "elm make Elm-Bejeweled.elm"
4. Open index.html in a browser to play

Summary:
Our project was to make the game of Candy Crush in Elm.  Note that we renamed “Candy Crush” to “Bejeweled”, as the rules of these two popular games are identical, but Bejeweled makes more sense with our view.

The instructions for the game of Bejeweled are as follows:
- Swap two adjacent gems to create 3 or more gems in a row of the same color.
- Gems can be aligned vertically or horizontally but never diagonally.
- For each successful “crushing” (3 or more same-color gems you manage to get in a row), you will be awarded points.
- You have 90 seconds to rack up as many points as possible.  After your time is up, you can keep replaying to try to beat your high score.

Highlights:
- We have accomplished everything that we set out to do with our game as outlined in our Part I and Part II write-ups, as well as incorporated additional features listed below.
- Note that, initially, we had mentioned in our Part II Status Update that we were going to scale back the game-play logic by not implementing the “swapping” phase, and instead, just checking whether the clicked gem belonged to a chain of 3 same-color gems in a row.  This is outdated.  We were able to fully implement the swapping logic such that our game-play is identical to the real Bejeweled.

The following is an overview of major features included in our game:

1. Scoring system
  a. The player’s high score is tracked across games and displayed on the right.
  b. The elimination of different colored gems and quantities corresponds to different point values.
  c. An attempt to make an invalid swap will result in a deduction of points.
  d. Attempting to swap two gems that are non-adjacent will simply cancel the swap and have no effect on the score.

2. Timer
  a. Each round lasts 90 seconds, during which the player attempts to “crush” as many gems as possible.
  b. The time is displayed in the form of a countdown and clock visual on the right.
  c. After time is up, the player has the option to restart the game and try to beat their previous high score.

3. Presentation
  a. Since our progress report, improvements to presentation-layer include the following:
    i) Expanded the board from 4x4 to 6x6 and added 3 additional colors, bringing our total to 7 possible colors/gems.
    ii) Included nicer visuals, specifically the gemstone images.

4. Animations
  a. Incorporated “crushing” animation when a successful swap is made and gems can be eliminated.
  b. After a swap is successful and the gems are “crushed”, the gems slide down to fill the gap, and new slots at the top of the board are filled with randomly generated gems.  If this post-crush, slide-down phase results in another valid matching, then the crushing of these gems are also depicted in a multi-step animation phase.  This animation is identical to the one that occurs in the real Bejeweled game.
  c. Clicks are disabled while animations are happening, i.e. the player cannot make a new selection while the current “crush” animation is still completing.

5. Automatic detection for a no-move board after every move
  a. The controller checks to see whether there is at least one possible move remaining in the board after every move.  If there are no valid moves remaining, then the current board will shrink and fade out, to be immediately replaced with a new randomly generated board, so that game-play can continue uninterrupted.

6. Hints
  a. When the “Hint” button is clicked, two adjacent gems will shrink and return to normal size in order to hint at a valid move for swapping.
  b. Note that points will be deducted harshly from the current score every time a hint is requested.
  c. Hints cannot be requested while an existing animation is completing.

Reflection:
Overall, we found that Bejeweled lends itself very nicely to a functional programming paradigm using the MVC framework.  We were able to implement our project entirely in Elm.  We have achieved all the target goals and milestones that we identified, and were able to make the game closely mimic the real game of Bejeweled (which can be played here: http://bejeweled.popcap.com/html5/)  We have achieved all the functionality that we set out to implement.  Future steps involve improving the design in order to make the presentation of our game appear more professional and visually appealing.  We would also like to be able to make the game layout responsive - possibly using CSS media queries - and ideally mobile compatible.
