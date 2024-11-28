import sys
from time import sleep, time
import random

import keyboard

WIDTH= 14
HEIGHT= 20
BLOCK_SIZE= 6

mass= [0]* (WIDTH* HEIGHT)
block= [0]* BLOCK_SIZE
new_block= [0]* BLOCK_SIZE
block_w= 0
block_h= 0
block_x= 0
block_y= 0

def shape_t(block):
  copy_block(block, [
    0, 1, 0,
    1, 1, 1
  ])
  return 3,2

def shape_l1(block):
  copy_block(block, [
    0, 0, 1,
    1, 1, 1
  ])
  return 3,2

def shape_l2(block):
  copy_block(block, [
    1, 0, 0,
    1, 1, 1
  ])
  return 3,2

def shape_s1(block):
  copy_block(block, [
    1, 1, 0,
    0, 1, 1
  ])
  return 3,2

def shape_s2(block):
  copy_block(block, [
    0, 1, 1,
    1, 1, 0
  ])
  return 3,2

def shape_square(block):
  copy_block(block, [
    1, 1,
    1, 1
  ])
  return 2,2

def shape_line(block):
  copy_block(block, [
    1, 
    1,
    1, 
    1
  ])
  return 1, 4

def set_cursor(x, y):
  sys.stdout.write("\033[%d;%dH" % (y+1, x+1))

def is_key_pressed( key ):
  return keyboard.is_pressed(key)

# Returns width & hight
def generate_random_block( block ):
  kind= random.randint(0, 6) # Assuming that random.fs works later in forth
  
  if kind == 0:
    return shape_t(block)
  elif kind == 1:
    return shape_l1(block)
  elif kind == 2:
    return shape_l2(block)
  elif kind == 3:
    return shape_s1(block)
  elif kind == 4:
    return shape_s2(block)
  elif kind == 5:
    return shape_square(block)
  elif kind == 6:
    return shape_line(block)
  
def print_rep( symbol, count ):
  for i in range(0, count):
    print(symbol, end='')

def print_space():
  print_rep(' ', 2* WIDTH)

def draw_shape(shape, w, h, x, y, symbol ):
  ctr= 0
  for i in range(0, h):
    for j in range(0, w):
      if shape[ctr] == 1:
        set_cursor(2*(x+ j)+ 1, y+ i)
        sys.stdout.write(symbol)
      ctr+= 1

  sys.stdout.flush()

# Delete block at current position
def clear_block():
  draw_shape( block, block_w, block_h, block_x, block_y, '  ')

def draw_block():
  draw_shape( block, block_w, block_h, block_x, block_y, '██')

def draw_mass():
  draw_shape(mass, WIDTH, HEIGHT, 0, 0, '██')

def clear_mass():
  draw_shape(mass, WIDTH, HEIGHT, 0, 0, '  ')  

def mass_pixel_at(x, y):
  return mass[ x+ y* WIDTH ]

def block_pixel_at(x, y):
  return block[ x+ y* block_w]

def block_clear_at(x, y):
  return 1 if block[ x+ y* block_w] == 0 else 0

def set_mass_at(x, y, value):
   mass[ x+ y* WIDTH ]= value

def block_touches_floor():
  return block_y+ block_h >= HEIGHT

def block_touches_wall(dx):
  if dx < 0:
    return block_x <= 0
  
  if dx > 0:
    return block_x+block_w >= WIDTH

  return False

def move_block(dx, dy):
  global mass, block, block_h, block_w, block_y, block_x

  # Directly return if no movement
  if dx == 0 and dy == 0:
    return False

  # Delete block at current position
  clear_block()

  # Try to move down by one step
  if dy > 0 and not block_touches_floor():
    block_y+= dy

  # Try to move left/right by one step
  if not block_touches_wall(dx) and not block_touches_mass_x(dx):
    block_x+= dx

  # Draw block at new position
  draw_block()

  return True

# Assumes that destination has enough space for source data
def copy_block(destination, source):
  for i in range(0, len(source)):
    destination[i]= source[i]

def rotate_block():
  global mass, block, block_h, block_w, block_y, block_x, new_block

  new_w= block_h
  new_h= block_w

  # Rotation would interfere with walls
  if block_x+ new_w >= WIDTH or block_y+ new_h >= HEIGHT:
    return False

  for i in range(block_w-1, -1, -1):
    for j in range(0, block_h):
      new_block[(block_w-1-i)*block_h+ j]= block[j*block_w+ i]
      # print( j, (w-1-i), f'({(w-1-i)*h+ j}) <-', i, j, f'({j*w+ i})' )

  # Block would rotate into the mass
  if block_stuck_in_mass(new_block, new_w, new_h, block_x, block_y):
    return False

  clear_block()

  copy_block(block, new_block)

  block_w= new_w
  block_h= new_h

  draw_block()

  return True


def block_stuck_in_mass(block, h, w, x, y):
  for i in range(0, h):
    for j in range(0, w):
      if block[i* w+ j] == 0:
        continue

      mx= x+ j
      my= y+ i

      if mass_pixel_at(mx, my):
        return True
      
  return False

def block_touches_mass_x(dx):
  return block_touches_mass(dx, 0)

def block_touches_mass_y():
  return block_touches_mass(0, 1)

def block_touches_mass(dx, dy):
  global mass, block, block_h, block_w, block_y, block_x

  if dx == 0 and dy == 0:
    return False

  for i in range(0, block_h):
    for j in range(0, block_w):
      if block_clear_at(j, i):
        continue

      # Compute position of neighboring pixel to check in the mass
      mx= block_x+ j+ dx
      my= block_y+ i+ dy

      # Check if out of field boundary
      if mx < 0 or mx >= WIDTH or my >= HEIGHT:
        continue

      # Check whether a neighboring pixel is set
      if mass_pixel_at(mx, my):
        return True
      
  return False


def add_block_to_mass():
  global mass, block, block_h, block_w, block_y, block_x

  for i in range(0, block_h):
      for j in range(0, block_w):
        if block_pixel_at(j, i):
          mx= block_x+ j
          my= block_y+ i
          set_mass_at(mx, my, 1)

def merge_block_with_mass():
  if block_touches_floor() or block_touches_mass_y():
    add_block_to_mass()
    return True

  return False


def find_complete_line():
  for i in range(0, HEIGHT):
    is_complete= True

    for j in range(0, WIDTH):
      is_complete = is_complete and mass_pixel_at(j, i)

    if is_complete:
      return i
  
  return -1

def remove_line( line ):
  for i in range( line, 0, -1 ):
    for j in range( 0, WIDTH ):
      set_mass_at(j, i, mass_pixel_at(j, i-1))

def remove_complete_lines():
  did_remove_line= False

  while True:
    line= find_complete_line()
    if line < 0:
      break
    
    # When we remove the first line we know that we will have
    # to redraw later on --> erase the old mass before we delete
    # the late
    if not did_remove_line:
      clear_mass()

    remove_line( line )

    did_remove_line= True

  if did_remove_line:
    draw_mass()

def is_top_line_empty():
  for i in range(0, WIDTH):
    if mass_pixel_at(i, 0):
      return False
    
  return True


def print_game_over():
  set_cursor( 0, HEIGHT+ 2)

  print_space()
  print('\n', end='')

  print_space()
  print('\n', end='')
  
  print('       Game Over       \n', end='')

  print_space()
  print('\n', end='')

  print_space()
  print('\n', end='')

def set_new_block():
  global mass, block, block_h, block_w, block_y, block_x

  block_w, block_h= generate_random_block( block )
  block_x= (WIDTH- block_w) // 2
  block_y= 0
  draw_block()
  

def setup_field():
  set_cursor(0,0)
  for i in range(0, HEIGHT+1):
    print_rep(' ', 2* WIDTH+ 10)

  set_cursor(0,0)
  for i in range(0, HEIGHT):
    print('▧', end='')
    print_space()
    print('▧\n', end='')

  print_rep('▧', 2*(WIDTH+1))


def main():
  global mass, block, block_h, block_w, block_y, block_x

  setup_field()

  set_new_block()

  last_time= 0

  did_rotate_last_frame= False
  did_generate_block= False

  while True:   
    if is_key_pressed('p'):
      return

    # set_cursor(60, 10)
    # print(f'block: {block_x} {block_y}')

    # Handle inputs
    dx= 0
    dy= 0

    if time() - last_time > 0.5:
      dy= 1
      last_time= time()

    did_rotate= False

    if is_key_pressed(' ') and not did_rotate_last_frame:
      did_rotate= rotate_block()

    elif is_key_pressed('a'):
      dx= -1

    elif is_key_pressed('s'):
      dy= 1

    elif is_key_pressed('d'):
      dx= 1
      
    # Move block
    did_move= move_block( dx, dy )

    # Do merging with mass
    if did_rotate or did_move or did_generate_block:
      did_generate_block= False

      did_merge= merge_block_with_mass()

      if did_merge:
        remove_complete_lines()
        set_new_block()
        did_generate_block= True

    # Detect lose state
    if not is_top_line_empty():
      break

    sleep(1 / 10)
    did_rotate_last_frame= did_rotate

  print_game_over()

if __name__ == '__main__':
  main()
