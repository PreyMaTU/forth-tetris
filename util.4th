
\ Check if a given integer is within a set interval, where the lower
\ bound is inclusive and the upper bound is exclusive --> lower <= value < upper
: within_interval ( val min_inclusive max_exclusive -- flag )
  -rot over <=
  -rot >
  and
;

\ Checks whether both components of a 2D vector are zero
: is_zero_vector ( x y -- flag )
  0= swap 0= and
;

\ Adds two 2D vectors component wise
: vector_add ( x1 y1 x2 y2 -- x y )
  rot +
  -rot +
  swap
;

\ Swaps the contents of two variables
: swap_variables ( addr1 addr2 -- )
  2dup @ swap @ rot ! swap !
;


\ Copy the contents from the source array to the destination array.
: memcopy ( source destination size -- )
  0 do 
    over @ \ s d s -> s d v
    over ! \ s d v d -> s d
    1 cells \ s d o
    swap over + \ s o d+o
    -rot + swap \ s+o d+o
  loop

  2drop
;


\ Set all cells in the array to a given value.
: memset ( value addr size -- )
  0 do
    2dup !
    1 cells +
  loop

  2drop
;
