# Marbles
This is the digital adaptation of the beloved **Marbles** game that was created by the Lindaman family (or someone they know) and tortures the McGregor family (and everyone they know). That game is actually an adaptation of the **Aggravation** board game, but since the Case family are born *cheaters*, they changed all the rules.

## The Game (Physical)
### The Board
The physical game is played on a wooden square with divots carved into the top surface in the following pattern:

```
 1              o  o  o  o  2              2 
    1           o     2     o           2    
       1        o     2     o        2       
          1     o     2     o     2          
                o     2     o                
 1  o  o  o  o  o           o  o  o  o  o  o 
 o                                         o 
 o  1  1  1  1        o        3  3  3  3  o 
 o                                         o 
 o  o  o  o  o  o           o  o  o  o  o  3 
                o     4     o                
          4     o     4     o     3          
       4        o     4     o        3       
    4           o     4     o           3    
 4              4  o  o  o  o              3 
```

Each of the diagonal rows of four are the home rows, one for each player, and this is where all the marbles start. Once I figure out how to add color to these README files, I'll show the colors for each players spaces instead of numbers. For now, you can reference this photo of an Aggravation board: 

![alt text][board]

From each home row, each marble starts in the space to the right of the row in the corner and moves *forward* in a clockwise direction around the board. Two spaces to the right (or counterclockwise) of the start space is where the marble turns into their respective finish row. All of these spaces are color-coded (as shown on the photo).

### The Cards
The Lindamans decided to use a deck of cards for each player instead of a communal pair of die. Each card has a different value and some have special attributes.

| Card | Number of spaces | Can start a marble | Play again? | Special attributes |
| :---: | :---: | :---: | :---: | --- |
| Ace  | 1 | Yes | Yes |  |
| Two  | 2 | No | No |  |
| Three  | 3 | No | No |  |
| Four  | 4 | No | No | You must move back four spaces. |
| Five  | 5 | No | No |  |
| Six  | 6 | Yes | Yes |  |
| Seven  | 7 | No | No | You can split the seven moves between **two** marbles. You need to move at least one of your marbles at least one space if you decide to split, but all seven moves must be used. |
| Eight | 8 | No | No |  |
| Nine  | 9 | No | No |  |
| Ten  | 10 | No | No |  |
| Jack  | 1 | No | Yes | You can swap one other player's marble with one of your own instead of moving one space. |
| Queen  | 1 | No | Yes |  |
| King  | 1 | No | Yes |  |
| Joker | 1 | Yes | Yes |  |

`Rules are subject to change, of course. Sometimes midgame! (Cameron, looking at you...)`

## How to play
### Terminology
Kelsey's written instructions use different names for parts of the board. Both sets of names mean the same thing, and the code uses Kelsey's names.

| This README | Kelsey's instructions (and the code) | What it is |
| --- | --- | --- |
| Home row | **Starting Block** | The four colored spaces where a player's marbles begin (the diagonal rows of four) |
| Start space | **Starting Exit** | The colored space on the outer edge where marbles enter the track |
| The board / the path | **Main Track** | The loop of holes that marbles travel around clockwise |
| Finish lane / finish row | **Home Base** | The colored row of four spaces where marbles finish |
| Fast Track space | **Fast Track** | The four colored inner corners of the Main Track, closest to the center |
| Bull's Eye | **Bull's Eye** | The center hole |

### Setup
Each player chooses a color and places all of their marbles in their home row and grabs a deck of cards (a standard 52-card deck plus two Jokers). After shuffling the deck of cards, each player cuts the deck and shows the card in the middle of the deck. The player with the highest card (Ace is the high) goes first and the turns go clockwise around the board.

### Play
Once a starting player is determined, he/she draws a card off the top of their deck. If the player draws a "Can start a marble" card, then the player can move their first marble to their start space. If a move cannot be made, the next turn commences. If the player drew a card with a "Play again?" attribute, then the player draws again. Multiple "Play again?" cards can be played in succession. 

Referencing The Cards table above, the player makes a move, moving marbles in play and progressing clockwise around the board. If they can move, they must move, even if it kills a teammate's marble.  If the player runs out of cards, then the player must reshuffle the deck and continue.

Each player continues this pattern, moving their marbles strategically around the board toward their finish lane.

Once a player's turn is finished, the player to their left (clockwise around the board) goes next.

This continues until someone meets the goal below.

Notes
* If a card can start a marble, the start space can't hold one of your own marbles. If an opponent's marble is sitting on your start space, starting a marble kills it. Once the marble is moved, the turn for that card is over and another card must be drawn, beginning another turn.
* A marble cannot land on another marble of the same color or surpass a marble of the same color on the board. The marble in front of it must be moved first.
* If a marble lands on a marble of another color, that opposing marble is considered killed, murdered in cold blood even, and the body is removed from the board and placed back in the home row. (This graphic nature is derived from Kelsey's ruthlessness in past games. She enjoys murder.)
* The fastest route for a marble into the finish lane is for the marble to start on the start space and for the player to draw a four, moving the marble close to the entrance of the lane.
* **Moving backward (the Four).** Backward moves follow the same rules as forward moves: a marble can't land on or hop over a marble of its own color, and landing on another color kills it. A marble moving backward may pass its own start space and the entrance to its finish lane, and then later move forward into its finish lane without going all the way around the board. A Four can also move a marble backward onto a Fast Track space or into the Bull's Eye.
* **Finish lane marbles are safe.** Once a marble is in its finish lane, it can't be killed, moved backward, or taken out. It can only move forward within the lane, to make room for the rest.
* **Jack swap.** The Jack can swap one of your marbles with any other marble of a different color on the board.
* **Seven split.** The two marbles can be two of your own, or one of yours and one of your teammate's. At least one of your own marbles has to move at least one space.

### Fast Track and Bull's Eye
Each inner corner pointing towards the middle of the board is called a Fast Track space. If your marble has just enough moves to land on this space, then during the next turn, you can use the next card you draw to move around to other Fast Track spaces, skipping the path around to get to them. If you don't use the next card you draw to move the marble that landed on the Fast Track space, then that chance is lost and that marble will have to continue moving around the board regularly. On the Fast Track, once your marble lands on the space nearest your finish lane (which should be the same color as your finish lane), the marble must exit the Fast Track and continue towards the finish lane.

The Bull's Eye is the space in the center of the board. If a marble on the Main Track (not one already riding the Fast Track) lands on a Fast Track space and has one move left, the player can choose to move that marble to the Bull's Eye. This is a gamble because the only way out of the Bull's Eye is to draw a face card (Jack, Queen, or King). Once a face card is drawn, the marble can be moved to the Fast Track space nearest the players finish lane.

### Goal
The goal for each player is to get all of his or her own marbles into the finish lane. 

If the game is played with teams, the goal is to get all of the marbles for each teammate in their respective finish lanes. Once one of the teammates completes their finish lane, their drawn cards from then on can be used to move their partner's marbles.

The first player or team to get all of the marbles in the finish lane is declared the ****winner****.

### Strategies
#### Kelsey's Strategy
Be evil and smart. Make strategic kills as soon as they're available, but still consider the goal of the game.
#### Jordan's Strategy
Kill all opponents at every chance. Don't even try to win the game. No one is safe.


## Notes
* Kelsey's original written instructions have been merged into this README (see Terminology). Where the two disagreed, the family's decisions are recorded in [docs/DESIGN.md](docs/DESIGN.md) under "Rules: decisions and open questions".


[board]: https://i.etsystatic.com/11793226/r/il/2c1ed6/1279172207/il_570xN.1279172207_fqc9.jpg "Aggravation game board"
