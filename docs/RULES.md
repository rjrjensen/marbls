# Marbles: the Rules

This is the complete rulebook. It combines the original README rules, Kelsey's written instructions, and every rule the family has decided since. The game code follows it, and `tests/core/` checks it.

> *Rules are subject to change, of course. Sometimes midgame!* (Cameron, looking at you...)
>
> In the game, every rule that has ever been argued about is a **house-rule option**; see [House rules](#house-rules).

## Contents

- [The board](#the-board)
- [Names for things](#names-for-things)
- [The cards](#the-cards)
- [Setup](#setup)
- [Taking a turn](#taking-a-turn)
- [Moving marbles](#moving-marbles)
- [Kills](#kills)
- [Fast Track](#fast-track)
- [Bull's Eye](#bulls-eye)
- [Home Base](#home-base)
- [Teams](#teams)
- [Winning](#winning)
- [House rules](#house-rules)
- [Family strategies](#family-strategies)

## The board

The physical game is a wooden square with holes in this pattern (numbers are the four players' colored holes):

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

It's the same layout as an [Aggravation board](https://i.etsystatic.com/11793226/r/il/2c1ed6/1279172207/il_570xN.1279172207_fqc9.jpg).

- **Marbles start** in the diagonal row of four in each corner.
- **They come out** onto the colored space next to that row, on the outer edge.
- **They travel** clockwise around the board.
- **Two spaces before their exit** (counterclockwise from it), they turn into their own colored lane in the middle of the arm.

The digital game also supports 3 and 5–8 players on round boards with one arm per player. See [docs/DESIGN.md](DESIGN.md#3-player-counts).

## Names for things

The README and Kelsey's instructions used different names. The game (and this rulebook) uses Kelsey's.

| Name used here (and in the code) | Also called | What it is |
| --- | --- | --- |
| **Starting Block** | Home row | The four colored holes where a player's marbles begin |
| **Starting Exit** | Start space | The colored hole on the outer edge where marbles come out |
| **Main Track** | The path | The loop of holes that marbles travel around clockwise |
| **Home Base** | Finish lane | The colored row of four holes where marbles finish |
| **Fast Track** | Fast Track space | The four inner corners of the Main Track, closest to the center |
| **Bull's Eye** | | The center hole |

## The cards

Each player has their **own deck: 52 cards plus 2 Jokers**. There's no shared deck and no dice.

| Card | Spaces | Starts a marble | Play again | Special |
| :---: | :---: | :---: | :---: | --- |
| Ace | 1 | Yes | Yes | |
| 2 | 2 | | | |
| 3 | 3 | | | |
| 4 | 4 **backward** | | | See [Moving backward](#moving-backward-the-four) |
| 5 | 5 | | | |
| 6 | 6 | Yes | Yes | |
| 7 | 7 | | | May be **split between two marbles**. See [Seven split](#seven-split) |
| 8 | 8 | | | |
| 9 | 9 | | | |
| 10 | 10 | | | |
| Jack | 1 | | Yes | Or **swap** places with another marble. See [Jack swap](#jack-swap). Also leaves the Bull's Eye. |
| Queen | 1 | | Yes | Also leaves the Bull's Eye |
| King | 1 | | Yes | Also leaves the Bull's Eye |
| Joker | 1 | Yes | Yes | |

## Setup

1. Each player picks a color, puts four marbles in their Starting Block, and shuffles their deck.
2. **Cut for first player:** everyone cuts their deck and shows a card.
   - The highest card goes first. **Ace is high, and a Joker beats an Ace.**
   - **Tied players cut again.**
   - The game plays this as a little starting ceremony.
3. Turns go **clockwise** (to the left).

## Taking a turn

1. **Draw** the top card of your deck.
2. **Move** according to the card. If you can move, you **must** move, even if it kills a teammate's marble. If you have more than one legal move, you choose.
3. If no move is possible, the card is simply used up.
4. **Play again** cards (Ace, 6, Jack, Queen, King, Joker) let you draw again. This happens even if the card couldn't move anything. Several can chain.
5. Otherwise the turn passes to the left.
6. When your deck runs out, reshuffle your used cards and keep going.

## Moving marbles

- **Starting a marble:**
  - An Ace, 6 or Joker moves one marble from your Starting Block onto your Starting Exit.
  - The Starting Exit can't hold one of your own marbles.
  - If an **opponent's** marble is sitting on your Starting Exit, starting a marble **kills** it.
- **Never your own color:** a marble can't land on, or hop over, another marble of its own color. The marble in front has to move first. This applies forward and backward, on the Main Track, on the Fast Track and in Home Base.
- **Other colors:** hopping over them is fine; landing on them kills them. See [Kills](#kills).
- **Turning home:** a marble that reaches its own Home Base entrance (two spaces before its Starting Exit) always turns in. Other colors pass by.

### Moving backward (the Four)
- The Four moves one marble **4 spaces backward**. It follows the same rules as moving forward.
- **Backing past your exit:** a marble can back up past its own Starting Exit and Home Base entrance. It can then move forward into Home Base later without going all the way around.
- **The best Four:** starting a marble and then drawing a Four puts it just short of Home Base. This is the fastest route there is.
- **Where a Four can land:**
  - It can back a marble **onto a Fast Track corner**, which gives a Fast Track chance.
  - It can back a marble **into the Bull's Eye**, the same way as below.
  - A marble **on** a Fast Track corner just backs off onto the Main Track.
- **What a Four can't move:**
  - marbles in **Home Base**
  - marbles in the **Bull's Eye**

### Seven split
You can move one marble 7, or **split the 7 between exactly two marbles**:
- **Which marbles:** two of your own, or one of yours and one of your teammate's.
- **Full count:** all 7 must be used, and at least one of *your* marbles must move.
- **Order matters:** the second half happens after the first. **Either or both halves can kill, and either or both can go into Home Base.**

### Jack swap
Instead of moving 1, swap one of your marbles with **any other color's** marble:
- **Which marbles can be swapped:** marbles on the Main Track (including Fast Track corners and Starting Exits) or in the Bull's Eye. **Teammates count**, and that can be strategic.
- **Which can't:** marbles in a Starting Block or Home Base.
- **No kills:** a swap isn't a kill.
- **Fast Track:** a marble swapped onto a Fast Track corner **is on the Fast Track**.

## Kills

Land on another color's marble and it's **killed** ("murdered in cold blood, even"; Kelsey enjoys this part). It goes back to its owner's Starting Block.
- **Teammates can be killed.** If it's your only move, you have to make it.
- **Home Base marbles are safe.**
- **Anywhere else is fair game:** kills happen on a Starting Exit, on a Fast Track corner, or in the Bull's Eye.

## Fast Track

The four inner corners of the Main Track form a shortcut around the board.
- **Getting on:** a marble whose move **ends exactly on a Fast Track corner** is on the Fast Track. This can happen by any means: a normal move, a backward Four, or a Jack swap.
- **Riding it:** with your **very next card**, that marble can ride the Fast Track. **Each point of the card is one decision**: hop to the next corner (clockwise), or step off onto the Main Track. Once it steps off, the rest of the count goes along the Main Track.
- **Your own corner:** at **your own color's corner** (the last one before your Home Base) you must step off toward home.
- **Your own marbles:** you can't land on or hop over them on the corners, so you have to step off before them.
- **Other marbles:** landing on an opponent kills it. Landing on a teammate does too, so you'd normally step off early. Hopping past marbles on corners doesn't kill them.
- **Losing the chance:** if your next card doesn't move that marble along the Fast Track, the chance is gone and it continues the long way. A move that ends on a corner again gives a new chance.
- **Example:** Red's marble lands on the first corner past its exit. With a 5 it hops three corners to Red's own corner, then steps two spaces, landing 5 spaces from Home Base.

## Bull's Eye

The center hole is a gamble.
- **Getting in:** a marble on the Main Track that **arrives at a Fast Track corner with exactly one step left** may take that step into the Bull's Eye instead of continuing. A backward Four can do this too.
  - There's **no entry from your own color's corner** (the one right before your Home Base).
  - A marble already riding the Fast Track can't drop in.
  - A marble just sitting on a corner doesn't count as "arriving" there.
- **Getting out:** the **only** way out is a **Jack, Queen or King**. It moves the marble to your own color's Fast Track corner, and it continues toward home from there.
- **Kills:** entering an occupied Bull's Eye kills the marble there.

## Home Base

- **Exact count:** a marble must fit exactly. It can't run past the end of Home Base.
- **Own marbles:** no hopping your own marbles inside it.
- **Safety:** Home Base marbles can't be killed, moved backward, or taken out. They can only move deeper to make room.

## Teams

Teams are played with partners **sitting opposite** each other: 4 players make 2 teams, 6 make 3, and 8 make 4.
- **After you finish:** once you have all four marbles home, **your cards move your teammates' marbles.**
- **Sevens:** a Seven can be split between your marble and a teammate's.
- **Kills:** teammates can be killed, but try not to.

## Winning

- **Solo:** the first player to get all four marbles into Home Base wins.
- **Teams:** the first team with **every** member's marbles home wins.

## House rules

In the game these are `RuleSet` options (`core/rules/rule_set.gd`); the defaults are the family rules above.

| Option | Default | What it changes |
| --- | --- | --- |
| `starting_exit_must_be_empty` | off | On: you can't start a marble onto an opponent (the README's original rule) |
| `play_again_without_move` | on | Off: a play-again card that couldn't move ends your turn |
| `cut_for_first_seat` | on | Off: seat 0 always goes first |
| `jokers_cut_high` | on | Off: a Joker is the lowest card when cutting |
| `fast_track_enabled` | on | Off: no Fast Track |
| `bulls_eye_enabled` | on | Off: no Bull's Eye |
| `swap_grants_fast_track` | on | Off: a marble swapped onto a corner doesn't get a Fast Track chance |
| `team_of_seat` | none | The team for each seat (the New game "Teams" switch sets opposite partners) |

Ideas still under discussion (the Comeback Joker, shorter games, Doubles, Classic-mode mistakes) are in [docs/DESIGN.md](DESIGN.md) and the [story backlog](https://github.com/rjrjensen/marbls/issues).

## Family strategies

- **Kelsey's strategy:** be evil and smart. Make strategic kills as soon as they're available, but still consider the goal of the game.
- **Jordan's strategy:** kill all opponents at every chance. Don't even try to win the game. No one is safe.

Both are computer opponents in the game.
