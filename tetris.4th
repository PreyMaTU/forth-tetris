require random.fs

\ ****** Constants ****** \

: WIDTH 14 ;
: HEIGHT 20 ;
: BLOCK_SIZE 6 ;
: FRAME_RATE 10 ;

: BORDER_CHAR ( -- addr len ) "▧" ;
: SHAPE_CHAR ( -- addr len ) "█" ;
: SPACE_CHAR ( -- addr len ) " " ;

require util.4th
require shapes.4th

\ ****** Global variables ****** \

create mass WIDTH HEIGHT * cells allot 
create block BLOCK_SIZE cells allot
create new_block BLOCK_SIZE cells allot

variable block_x
variable block_y
variable block_w
variable block_h
variable last_move_time

: init_vars ( -- )
  0 mass WIDTH HEIGHT * memset
  0 block BLOCK_SIZE memset
  0 new_block BLOCK_SIZE memset

  0 block_x !
  0 block_y !
  0 block_w !
  0 block_h !
  0 last_move_time !
;


\ ****** Keyboard input ****** \

: pressed_a     ( key_mask -- key_mask flag ) dup  1 and ;
: pressed_d     ( key_mask -- key_mask flag ) dup  2 and ;
: pressed_p     ( key_mask -- key_mask flag ) dup  4 and ;
: pressed_s     ( key_mask -- key_mask flag ) dup  8 and ;
: pressed_space ( key_mask -- key_mask flag ) dup 16 and ;

: gather_pressed_keys ( -- key_mask )
  0 \ Push key_mask
  begin
    key?
  while
    255 \ Push dummy mask

    \ Get the current key and convert the dummy mask to the 
    \ bit for the key
    case key toupper
      'A'     of pressed_a     endof  \ A
      'D'     of pressed_d     endof  \ D
      'P'     of pressed_p     endof  \ P
      'S'     of pressed_s     endof  \ S
      bl      of pressed_space endof  \ Space
      0 swap                          \ default set 0
    endcase
    
    nip or \ Combine the bit with the bit_mask
  repeat
;


\ ****** Printing and drawing functions ***** \

\ Print the symbol a given number of times
: print_rep ( symbol_addr symbol_len number -- )
  0 do
    2dup type
  loop
  drop
;

\ Prints space equal to field width
: print_space ( -- )
  WIDTH 2 * spaces
;


: print_game_over  ( -- )
  print_space cr
  print_space cr
  
  ."        Game Over       " cr
  
  print_space cr
  print_space cr

;

: set_cursor ( x y -- )
  at-xy
;

\ Draws an array of pixels with a given symbol. Pixels that
\ are not set in the array are kept transparent
: draw_shape { shape w h x y symbol_addr symbol_len -- }
  h 0 do \ j
    w 0 do \ i
      j w * i + cells shape + @ \ get pixel shape[i, j]
      0<> if \ pixel not 0
        x i + 2 * 1+ 
        y j +
        set_cursor

        \ Emit the symbol twice to make it square-ish
        symbol_addr symbol_len 2dup type type
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

: draw_mass ( -- )
  mass WIDTH HEIGHT 0 0 SHAPE_CHAR draw_shape
;

: clear_mass ( -- )
  mass WIDTH HEIGHT 0 0 SPACE_CHAR draw_shape 
;


\ ***** Pixel getter and setter helpers ***** \

\ Returns true if a given location has a pixel set in the mass
: mass_pixel_at ( x y -- flag )
  WIDTH * + cells mass + @ 0<> 
;

\ Sets a pixel in the pass to a given value
: set_mass_pixel_at ( x y v -- )
  -rot WIDTH * + cells mass + !
;

\ Returns true if a given location has a pixel set in the current block
: block_pixel_at ( x y -- flag )
  block_w @ * + cells block + @ 0<> 
;  

\ Returns true if a given location has no pixel set in the current block
: block_clear_at ( x y -- flag )
  block_w @ * + cells block + @ 0<> invert
;

\ Copy the data from a given block to another one
: copy_block ( source destination -- )
  BLOCK_SIZE memcopy
;


\ ***** Block play field and mass checks ***** \

: block_touches_floor ( -- flag )
  block_y @ block_h @ + HEIGHT >=
;

\ Returns true if the current block touches either the left or right wall.
\ If the dx value is negative the left wall gets checked, when it is positive
\ the right one, otherwise false is returned.
: block_touches_wall ( dx -- flag )
  dup 0< if 
    drop block_x @ 0<= exit
  endif

  0> if
    block_x @ block_w @ + WIDTH >= exit
  endif

  false
;

\ Returns true if the current block touches the mass on a given side. dx and dy
\ describe in which direction to check. dx for left/right and dy for bottom if it
\ is positive.
: block_touches_mass ( dx dy -- flag )
  2dup 0= swap 0= and if
    2drop false exit
  endif

  \ Add delta to block position
  block_y @ + swap
  block_x @ + swap

  block_h @ 0 do    \ j
    block_w @ 0 do  \ i
      i j block_pixel_at if
        2dup
        j + swap  \ my = block_y + dy + j
        i + swap  \ mx = block_x + dx + i

        \ Check if mx and my are within bounds
        2dup HEIGHT <  \ my < HEIGHT  &&
        swap dup 0>=   \ mx >= 0      &&
        swap WIDTH <   \ mx < HEIGHT
        and and if
          mass_pixel_at if
            2drop true unloop unloop exit
          endif
        else
          2drop
        endif
      endif
    loop
  loop

  2drop false
;

\ Returns true if the current block touches the mass either left or right as
\ defined by dx.
: block_touches_mass_x ( dx -- flag )
  0 block_touches_mass
;

\ Returns true if the current block touches the mass on the bottom side.
: block_touches_mass_y ( -- flag )
  0 1 block_touches_mass
;

\ Returns true if the current block intersects with the mass anywhere.
: block_stuck_in_mass { block_array h w x y -- flag }
  h 0 do    \ j
    w 0 do  \ i
      \ Check for pixel at block_array[i, j]
      w j * i + cells block_array + @ 0<> if
        x i +
        y j +
        mass_pixel_at if
          true unloop unloop exit
        endif
      endif
    loop
  loop
  false
;



\ ***** Block and playfield game functions ***** \

\ Try to move a block in a given direction as a dx dy vector. The vector
\ components can be between -1...1 for x and 0...1 for y. If no movement
\ is performed false is returned.
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
    dx block_touches_mass_x invert if
      dx block_x +!
    endif
  endif

  draw_block

  true
;


\ Creates a copy of the current shape in block that is rotated counter-clock wise.
\ Reads from the global block and modifies the global new_block variables.
: make_rotated_new_block ( -- )
  0 block_w @ 1- do       \ j -> block_w-1 ... 0
    block_h @ 0 do        \ i -> 0 ... block_h
      i block_w @ * j + cells block + @                     \ Get block[j, i]
      block_w @ 1- j - block_h @ * i + cells new_block + !  \ Store new_block[i, block_w-1-j]
    loop
  -1 +loop
;

\ Try to rotate a block counter clock wise around its origin in the left
\ top corner. If the rotation fails because the rotated block would 
\ interfere with the walls or the mass false gets returned.
: rotate_block ( -- did_rotate )
  \ Check that rotation does not interfere with walls
  block_x @ block_h @ + WIDTH >=
  block_y @ block_w @ + HEIGHT >=
  or if
    false exit
  endif

  \ Create a rotated copy of the block in new_block
  make_rotated_new_block

  new_block
  block_w @ block_h @
  block_x @ block_y @
  block_stuck_in_mass if
    false exit
  endif

  clear_block

  new_block block copy_block

  \ Swap width and height
  block_w block_h swap_variables

  draw_block

  true
;

\ Adds the shape of the current block to the mass. Only the
\ set pixels of the block are considered, as to not punch holes
\ into the existing mass array pixels.
: add_block_to_mass ( -- )
  block_h @ 0 do    \ j
    block_w @ 0 do  \ i
      i j block_pixel_at if
        block_x @ i +
        block_y @ j +
        1 set_mass_pixel_at
      endif
    loop
  loop
;

\ Try to merge the current block with the mass. The block gets
\ merged when it either hits the floor, or when it touches the
\ mass with its bottom side. When the block is merged true is
\ returned else the mass and block remain unchanged and false
\ gets returned.
: merge_block_with_mass ( -- did_merge )
  block_touches_floor
  block_touches_mass_y
  or if 
    add_block_to_mass
    true exit
  endif

  false
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

\ ***** Mass line functions ***** \

\ Returns whether the top line of the mass does not have any pixels set.
: is_top_line_empty ( -- flag )
  WIDTH 0 do
    i 0 mass_pixel_at if
      false unloop exit
    endif
  loop

  true
;

\ Returns the number of the first completed line beginning from the top
\ or -1.
: find_complete_line ( -- line_num )
  HEIGHT 0 do \ j
    true
    WIDTH 0 do \ i
      i j mass_pixel_at and
    loop
    
    if
      \ Beware j is now called i outside the inner loop :(
      i unloop exit
    endif
  loop

  -1
;

\ Remove a given line (index between 0 and HEIGHT) and move all lines
\ above it one step down to fill its place.
: remove_line ( line_num -- )
  \ Loop runs from line_num .. 1
  1 swap do \ j = height
    WIDTH 0 do \ i
      i j 
      2dup 1 - mass_pixel_at
      set_mass_pixel_at
    loop
  -1 +loop
;

\ Remove all completed lines in the mass and compact the mass downwards.
: remove_complete_lines ( -- )
  false \ did_remove_line

  1 0 do \ for loop that does not count so that we can use leave -> while True + break
    \ Get line number of first completed line or stop
    find_complete_line dup 0< if
      drop leave
    endif

    \ check if line was removed
    swap invert if 
      clear_mass
    endif
    
    remove_line \ consumes line number

    true \ at least one line was already removed

  0 +loop

  if \ did_remove_line
    draw_mass
  endif
;


\ ***** Game loop functions ***** \


: set_new_block ( -- )
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

\ Consume the key mask and update the dx dy movement vector if
\ a movement key (a, d, s) was pressed.
: handle_move_keys ( key_mask dx dy -- dx dy )
  rot
  case
    pressed_a ?of drop swap drop -1 swap endof
    pressed_d ?of drop swap drop  1 swap endof
    pressed_s ?of 2drop 1 endof
  endcase
;

\ Clears the page and draws the border around the play field
: setup_field   ( -- )
  page          \ Clear the page and set cursor to (0,0)
  
  HEIGHT 0 do
    BORDER_CHAR type
    print_space
    BORDER_CHAR type
    cr
  loop

  BORDER_CHAR WIDTH 1+ 2 * print_rep
;


: game_loop ( -- did_loose )
  set_new_block \ Select initial block

  false         \ Flag: need to check mass merging

  begin
    gather_pressed_keys

    \ Stack: merge_flag keyboard_mask

    pressed_p if
      2drop false exit
    endif

    pressed_space if
      swap
      rotate_block or \ or the merge flag
      swap
    endif

    0 \ dx
    0 \ dy

    drop_block_now if
      drop 1 \ Set dy = 1
    endif

    \ Stack: merge_flag keyboard_mask dx dy

    handle_move_keys

    move_block or \ or the merge flag

    \ Stack: merge_flag

    dup if
      drop false \ Override the merge flag back to false

      merge_block_with_mass if
        remove_complete_lines
        set_new_block

        drop true \ Force the merge flag to true
      endif
    endif

    \ Stack: merge_flag

    is_top_line_empty invert if
      drop true exit
    endif

    1000 FRAME_RATE / ms \ Wait for milliseconds

  again
;

: main
  init_vars
  setup_field

  game_loop

  \ Move cursor below play field
  0 HEIGHT 2 + set_cursor

  if
    print_game_over
  endif
;


main bye

