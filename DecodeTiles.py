################################################################################
# DecodeTiles.py - Decode bytes for tile sprites into colour coded 
#                  values and display the results
#

### Imports
import csv
import math
from os import path
from datetime import datetime

BLACK = "\033[0;30m"
RED = "\033[0;31m"
GREEN = "\033[0;32m"
YELLOW = "\033[1;33m"
BLUE = "\033[0;34m"
PURPLE = "\033[0;35m"
CYAN = "\033[0;36m"
WHITE = "\033[1;37m"
NEGATIVE = "\033[7m"
END = "\033[0m"

NUM_SPRITE_BYTES = 2912
NUM_BYTES_PER_TILE = 32
#palette = [BLACK, PURPLE, RED, WHITE]
palette = [BLACK, GREEN, RED, WHITE]

USE_INPUT_SPRITES_FILE = False
OUTPUT_SPRITES_TO_FILE = False

#Read bytes for tile sprites
#This is at the start address in the source code, not need to position to a location - input_source_file.seek(pos)
base_path = path.dirname(path.abspath(__file__))
if USE_INPUT_SPRITES_FILE:
    BD_input_sprites_folder = path.join(base_path, "BDconvert", "sprites")
    sprites_bytes = []
    for i in range(32):  #First 32 bytes are the space character, all zeros
        sprites_bytes.append(0)
    with open(path.join(BD_input_sprites_folder, "input_sprites.csv"), newline="") as csvfile:
        for row in csv.reader(csvfile, skipinitialspace=True, delimiter=","):
            for byte in row:
                if byte != '':
                    sprites_bytes.append(int(byte))
else:
    BD_code_folder = path.join(base_path, "BDcode")
    input_source_file = open(path.join(BD_code_folder, "BDSH3"), "rb")  #Open the file as binary
    sprites_bytes = input_source_file.read(NUM_SPRITE_BYTES)
    input_source_file.close()

#Output to file if required
if OUTPUT_SPRITES_TO_FILE:
    output_subfolder = path.join(base_path, "output", "sprites")
    output_file_name = path.join(output_subfolder, f"sprites_{datetime.now().strftime('%Y%m%d_%H%M')}.bin")
    output_file = open(output_file_name, "wb")
    for byte in sprites_bytes:
        output_file.write(byte.to_bytes(1, byteorder='big'))
    output_file.close()

#Process each byte, the individual bits in the high and low nibbles are matched as shown and added together
# E.g. 01010111 becomes 0101
#                   and 0111
#   colour coding total 00 = 0, 11 = 3, 01 = 1, 11 = 3
#Each processed byte becomes a colour code for the 4 colours in the palette
# E.g. 01010111 is morphed into 0313
colour_codes = []
for i, byte in enumerate(sprites_bytes):
    high, low = byte >> 4, byte & 0x0F
    s_high_byte = str(f"{high:04b}")
    s_low_byte = str(f"{low:04b}")
    sprite_byte = ""
    #Add first bit in high nibble added to first bit in low nibble, then second of each etc and join together
    for j in range(0,len(s_high_byte)):
        sprite_byte += str(int(s_high_byte[j] + s_low_byte[j], 2))
    colour_codes.append(sprite_byte)  #Append the colour code value to the output, e.g. "0313" using the example above

#Matchup each colour code value to the one which follows 8 colour codes (bytes) later, forming one color coded line of the output tile
colour_code_lines = []
for i in range(0, len(colour_codes)):
    if (math.floor(i/8) % 2) == 0:
        colour_code_lines.append(colour_codes[i]+colour_codes[i+8])

#Output each line, looking up their colour code and printing beside each other
pos = 0  #Start address is 0 in this case
tile_count = 0
for i, line in enumerate(colour_code_lines):

    if i%(NUM_BYTES_PER_TILE/2) == 0:  #Two bytes for a line
        tile_count += 1
        print (f"Character {tile_count} in address position {pos}")
        pos += NUM_BYTES_PER_TILE

    for j in range(0, len(line)):
        print(f"{palette[int(line[j])]}{NEGATIVE}  {line[j]}  {END}", end="")
    print(f" {int(i%(NUM_BYTES_PER_TILE/2))}")
  