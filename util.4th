
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
