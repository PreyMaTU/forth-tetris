# Forth Tetris

A very basic implementation of the Tetris game for the command line
written in Forth for the gforth interpreter. This is part of the
185.310 Stack-based Languages course at TU Wien as the submission
of group 8.

## How to run

This project requires [gforth][gforth]. Download the repository and 
run the `tetris.4th` file from the command line.

```bash
gforth tetris.4th
```

## How to play

Use your keyboard to control the game:

- `P` Ends the game
- `A` Moves the current block to the left
- `D` Moves the current block to the right
- `S` Moves the current block down faster
- `Space` Rotates the block counter clock wise

## Compare with Python

The game is implemented in Forth as well as in Python, so you can compare
the two and see how certain problems are solved differently. The Python
version is written in a very non-pythonic way to better match the style
of Forth.

[gforth]: https://gforth.org/
