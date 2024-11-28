
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
