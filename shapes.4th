
\ Copies the shape of a block from stack elements into 
\ a given array. The number of stack elements provided must
\ match the BLOCK_SIZE constant.
: set_shape ( block_address a b c d e f -- )
  BLOCK_SIZE pick \ ba a b c d e f ba

  BLOCK_SIZE cells +  \ Move the block array pointer behind the last cell

  BLOCK_SIZE 0 do
    1 cells -         \ Move one cell towards the begin
    dup rot swap !    \ Store the last shape value
  loop 

  2drop \ drop both the remaining block_adresses
;

\ ****** Define all the possible block shapes ****** \

: shape_t ( block_address -- width height )
  0 1 0
  1 1 1
  set_shape
  3 2
;

: shape_l1 ( block_address -- width height )
  0 0 1
  1 1 1
  set_shape
  3 2
;

: shape_l2 ( block_address -- width height )
  1 0 0
  1 1 1
  set_shape
  3 2
;

: shape_s1 ( block_address -- width height )
  1 1 0
  0 1 1
  set_shape
  3 2
;

: shape_s2 ( block_address -- width height )
  0 1 1
  1 1 0
  set_shape
  3 2
;

: shape_square ( block_address -- width height )
  1 1
  1 1   
        0 0 \ padding to BLOCK_SIZE
  set_shape
  2 2
;

: shape_line ( block_address -- width height )
  1
  1
  1
  1
        0 0 \ padding to BLOCK_SIZE
  set_shape
  1 4
;
