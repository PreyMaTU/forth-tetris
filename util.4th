
\ Masks everything except the last 8 Bits
: mask_8 ( x -- y ) 255 and ;

: emit_utf8_char_byte { character force_print bit_shift -- character did_print }
  character bit_shift rshift mask_8
  dup 0 > force_print or if
    emit
    character 1
  else
    drop
    character 0
  endif
;

\ Emit a single UTF-8 encoded character, where code point data is
\ in the given parameter as a 32bit integer.
: emit_utf8_char ( char -- )
  0 \ Force printing the char

  24 emit_utf8_char_byte
  16 emit_utf8_char_byte
  8 emit_utf8_char_byte

  drop            \ Drop the flag and
  mask_8 emit     \ always print the last byte
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
