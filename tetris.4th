require random.fs

\ Setup constants
: WIDTH 14 ;
: HEIGHT 20 ;
: BLOCK_SIZE 6 ;
: FRAME_RATE 10 ;

: SPACE_CHAR 32 ;
: BORDER_CHAR 14849703 ; \ ▧
: SHAPE_CHAR 14849672 ; \ █

require util.4th
require shapes.4th

\ Setup global variables, automatically initialized with 0

create mass WIDTH HEIGHT * cells allot 
create block BLOCK_SIZE cells allot
create new_block BLOCK_SIZE cells allot

variable block_x
variable block_y
variable block_w
variable block_h
variable last_move_time

: set_cursor ( x y -- )
  at-xy
;

: pressed_a ( key_mask -- flag ) dup 1 and ;
: pressed_d ( key_mask -- flag ) dup 2 and ;
: pressed_p ( key_mask -- flag ) dup 4 and ;
: pressed_s ( key_mask -- flag ) dup 8 and ;
: pressed_space ( key_mask -- flag ) dup 16 and ;

: gather_pressed_keys ( -- key_mask )
  0 \ key_mask
  begin
    key?
  while
    255 \ push dummy mask

    \ Get the current key and convert the dummy mask to the 
    \ bit for the key
    case key toupper
      65          of pressed_a     endof \ A
      68          of pressed_d     endof \ D
      80          of pressed_p     endof \ P
      83          of pressed_s     endof \ S
      SPACE_CHAR  of pressed_space endof \ Space
      0 swap                             \ default set 0
    endcase
    
    nip or \ Combine the bit with the bit_mask
  repeat
;

\ Print the symbol a number of times
: print_rep ( symbol number -- )
  0 do
    dup emit_utf8_char
  loop
  drop
;

\ Prints space equal to field width
: print_space
  SPACE_CHAR WIDTH 2 * print_rep
;

: draw_shape { shape w h x y symbol -- }
  h 0 do \ j
    w 0 do \ i
      j w * i + cells shape + @ \ get pixel shape[i, j]
      0<> if \ pixel not 0
        x i + 2 * 1+ 
        y j +
        set_cursor

        symbol emit_utf8_char
        symbol emit_utf8_char
      endif
    loop
  loop
;

: clear_block ( -- )
  block
  block_w @
  block_h @
  block_x @
  block_y @
  SPACE_CHAR
  draw_shape
;

: draw_block ( -- )
  block 
  block_w @ 
  block_h @ 
  block_x @ 
  block_y @ 
  SHAPE_CHAR
  draw_shape
;

: copy_block ( source destination -- )
  BLOCK_SIZE 0 do 
    over @ \ s d s -> s d v
    over ! \ s d v d -> s d
    1 cells \ s d o
    swap over + \ s o d+o
    -rot + swap \ s+o d+o
  loop

  2drop
;

\ return -1 if the pixel x,y is set in the mass variable, 0 otherwise
: mass_pixel_at ( x y -- value )
  WIDTH * + cells mass + @ 0<> 
;  

\ return -1 if the pixel x,y is set in the block variable, 0 otherwise
: block_pixel_at ( x y -- value )
  block_w @ * + cells block + @ 0<> 
;  

\ return -1 if the pixel x,y is NOT set in the block variable, 0 otherwise
: block_clear_at ( x y -- value )
  block_w * + cells block + @ 0<> if 0 else -1 endif 
; 

: block_touches_floor ( -- flag )
  block_y @ block_h @ + HEIGHT >=
;

: block_touches_wall ( dx -- flag )
  dup 0< if 
    drop block_x @ 0<= exit
  endif

  0> if
    block_x @ block_w @ + WIDTH >= exit
  endif

  false
;

: move_block { dx dy -- did_move }
  dx 0= dy 0= and if
    false exit
  endif

  clear_block

  \ Add the y movement if we did not hit the floor yet
  dy 0> block_touches_floor invert and if
    dy block_y +!
  endif

  dx block_touches_wall invert if
    \ dx block_touches_mass_x if <-- TODO
      dx block_x +!
    \ endif
  endif

  draw_block

  true
;

: rotate_block ( -- did_rotate )
  \ Check that rotation does not interfere with walls
  block_x @ block_h @ + WIDTH >=
  block_y @ block_w @ + HEIGHT >=
  or if
    false exit
  endif

  \ Create a rotated copy of the block in new_block
  0 block_w @ 1- do       \ j -> block_w-1 ... 0
    block_h @ 0 do        \ i -> 0 ... block_h
      i block_w @ * j + cells block + @                     \ Get block[j, i]
      block_w @ 1- j - block_h @ * i + cells new_block + !  \ Store new_block[i, block_w-1-j]
    loop
  -1 +loop

  \ block_stuck_in_mass <-- TODO

  clear_block

  new_block block copy_block

  \ Swap width and height
  block_w block_h swap_variables

  draw_block

  true
;

\ Stores a random block in the block array and returns the width
\ and height
: generate_random_block ( -- width height )
  7 random \ get a random number between [0,7[
  case
    0 of block shape_t endof
    1 of block shape_l1 endof
    2 of block shape_l2 endof
    3 of block shape_s1 endof
    4 of block shape_s2 endof
    5 of block shape_square endof
    6 of block shape_line endof
  endcase
;

: set_new_block
  generate_random_block   \ --> Returns width and height
  block_h !
  block_w !

  WIDTH block_w @ - 2 / block_x !
  0 block_y !

  draw_block
;

\ Gets the current time and compares it to the last time 
\ the block got dropped. Updates the time and returns 1 if
\ the block should be dropped
: drop_block_now ( -- flag )
  \ Get the time in ms
  utime drop 1000 /

  \ Did 500 ms pass?
  dup last_move_time @ - 500 > if
    \ Store the time for the next check
    last_move_time !
    1
  else
    drop
    0
  endif
;

: handle_move_keys ( key_mask dx dy -- dx dy )
  rot
  case
    pressed_a ?of drop swap drop -1 swap endof
    pressed_d ?of drop swap drop  1 swap endof
    pressed_s ?of 2drop 1 endof
  endcase
;

\ Clears the page and draws the border around the play field
: setup_field
  page          \ Clear the page and set cursor to (0,0)
  
  HEIGHT 0 do
    BORDER_CHAR emit_utf8_char
    print_space
    BORDER_CHAR emit_utf8_char
    cr
  loop

  BORDER_CHAR WIDTH 1+ 2 * print_rep
;


: main 
  setup_field

  set_new_block

  1 0 do
    gather_pressed_keys

    pressed_p if
      drop leave
    endif

    false swap \ flag: need to check mass merging

    pressed_space if
      swap
      rotate_block or \ or the merge flag
      swap
    endif

    0 \ dx
    0 \ dy

    drop_block_now if
      drop 1 \ dy = 1
    endif

    handle_move_keys

    move_block or \ or the merge flag

    if
      \ do the merging
    endif

    1000 FRAME_RATE / ms \ Wait for milliseconds

  0 +loop

  \ Move cursor below play field
  0 HEIGHT 2 + set_cursor

  \ TODO print loose message
;


main bye
