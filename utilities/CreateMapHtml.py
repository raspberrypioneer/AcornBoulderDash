################################################################################
# CreateMapHtml.py - Generate HTML with images given a JSON file definition

JSON_CAVE_DEF = "BoulderDash02.json"
LEVEL = 0  #Level numbers (levels are 1-5 but zero based)

### Imports
import json
from os import path
import numpy
from PIL import Image

### Constants
TILE_HEIGHT = 16
TILE_WIDTH = 16
TILES_ROWS = 22
TILES_COLUMNS = 40

BLACK = [0, 0, 0]
RED = [255, 0, 0]
GREEN = [0, 255, 0]
YELLOW = [255, 255, 0]
BLUE = [0, 0, 255]
PURPLE = [255, 0, 255]
CYAN = [0, 255, 255]
WHITE = [255, 255, 255]
AVAILABLE_COLOURS = [BLACK, RED, GREEN, YELLOW, BLUE, PURPLE, CYAN, WHITE]

################################################################################
def generate_cave_image(image_file_name, map, pallette, row_col_dimensions, random_type, tile_prob, tile_name_for_prob, below_tile_name_for_prob, initial_tile_name, border_tile_name):

#TODO: Need to use border tile parameter

    #For each tile in each of the lines of a map:
    #  Find the sprite pixel map for the tile
    #  Plot each pixel on each pixel line using the colour represented by the pixel number

    data = numpy.zeros((TILE_HEIGHT * row_col_dimensions[0], TILE_WIDTH * row_col_dimensions[1], 3), dtype=numpy.uint8)
    random_seed1 = 0
    random_seed2 = seed
    row_below = [""] * row_col_dimensions[1]

    y_pos = 0
    for l, line in enumerate(map):  #Loop through all map lines
        x_pos = 0
        t = 0  #Reset counter each line (maximum is the number of columns in the cave)
        for tile in line:  #Loop through all tiles in a line

            #Determine the sprite definition to use
            sprite_name = element_map[tile]["sprite"]
            if sprite_name == "INBOX":  #Replace inbox with rockford for sprite lookup
                sprite_name = "ROCKFORD"
            pixel_sprite = sprite_json[sprite_name]

            #Replace the border top and bottom lines where null tile is used
            if border_tile_name != "" and tile == "-" and (l in [0, row_col_dimensions[0]-1]):
                pixel_sprite = sprite_json[object_element_map[border_tile_name]["sprite"]]

            #elif row_below[t] != "" and l == row_col_dimensions[0]-2:
            #    pixel_sprite = sprite_json[object_element_map[row_below[t]]["sprite"]]

            #For pseudo-random tile generation, determine the replacement for the null tile
            elif random_type and l > 0 and l < row_col_dimensions[0]-1:

                #Sometimes 2 tiles are plotted, the second one below the first. See BD2 caves G, K
                #The second tile may override the calculated random tile
                override_tile = row_below[t]

                #Determine the random tile
                random_tile_name = initial_tile_name  #Assume is the initial fill tile to begin with
                random_seed1, random_seed2 = next_random(random_seed1, random_seed2)  #Get random seed values
                for i in range(len(tile_prob)):  #Check the random seed values against the probabilities for plotting each tile
                    if random_seed1 < tile_prob[i]:
                        #Make the random tile the tile for the probability in range (The random tile may change a few times in this loop)
                        random_tile_name = tile_name_for_prob[i]
                        if below_tile_name_for_prob != []:
                            row_below[t] = below_tile_name_for_prob[i]  #Also keep the tile to plot below (usually this is just "")

                #If there is an override tile from the previous row, use it as the sprite
                if override_tile != "":
                    pixel_sprite = sprite_json[object_element_map[override_tile]["sprite"]]
                    row_below[t] = ""

                #Only replace the cave tile with the random one if the cave tile is null
                #This occurs at this late stage to preserve the ongoing random seed calculations
                else:
                    if tile == "-":
                        pixel_sprite = sprite_json[object_element_map[random_tile_name]["sprite"]]
                    else:
                        row_below[t] = ""

            #Set each pixel colour for the sprite
            for y, pixel_line in enumerate(pixel_sprite):
                for x, px in enumerate(pixel_line):
                    data[y_pos + y, x_pos + x] = pallette[int(px)-1]

            x_pos += TILE_WIDTH
            t += 1

        y_pos += TILE_HEIGHT

    image = Image.fromarray(data)
    #image.show()
    image.save(image_file_name)

def next_random(random_seed1, random_seed2):
    temp_rand1 = (random_seed1 & 0x0001) * 0x0080
    temp_rand2 = (random_seed2 >> 1) & 0x007F
    result = random_seed2 + (random_seed2 & 0x0001) * 0x0080
    carry = result > 0x00FF
    result = result & 0x00FF
    result = result + carry + 0x13
    carry = result > 0x00FF
    random_seed2 = result & 0x00FF
    result = random_seed1 + carry + temp_rand1
    carry = result > 0x00FF
    result = result & 0x00FF
    result = result + carry + temp_rand2
    random_seed1 = result & 0x00FF

    return random_seed1, random_seed2

################################################################################
def create_table_of_params(param_list):
    i = 0
    for param_name in param_list:
        if param_name in json_cave:
            if i == 0:
                html_file.write(f"<table style='margin-left:30px'>\n")

            html_file.write("<tr>")
            if type(json_cave[param_name]) == list:
                add_param_to_html_td(parameter_list[param_name]["label"], json_cave[param_name][LEVEL])
            else:
                add_param_to_html_td(parameter_list[param_name]["label"], json_cave[param_name])
            html_file.write("</tr>\n")
            i += 1
    if i > 0:
        html_file.write("</table>\n")

def add_param_to_html_td(label, value):
    html_file.write(f"<td>{label}</td><td style='padding-left:30px; text-align:right'>{value}</td>")

################################################################################
# Main Routine
if __name__ == '__main__':

    ### Config and file paths
    base_path = path.dirname(path.abspath(__file__))
    base_path = path.join(base_path, "..")
    config_file = open(path.join(base_path, "config", "config.json"))
    config_settings = json.load(config_file)
    element_map = config_settings["element_map"]
    parameter_list = config_settings["parameters"]
    colour_map = config_settings["colour_map"]
    colour_schemes = config_settings["colour_schemes"]
    config_file.close()

    #Create object_element_map from element_map by making the element name the key, using substitute values if available
    object_element_map = {}
    for e in element_map:
        new_key = element_map[e]["element"]
        object_element_map[new_key] = {}
        object_element_map[new_key]["sprite"] = element_map[e]["sprite"]

    #Parameters to output
    core_params = ["DiamondValue", "DiamondExtraValue", "DiamondsRequired", "CaveTime"]
    other_params = ["AmoebaTime", "MagicWallTime", "SlimePermeability", "Bombs", "ZeroGravityTime"]

    #Add files / folders needed
    html_folder = path.join(base_path, "bdcff_conversions", "done", "html")
    images_folder = path.join(html_folder, "images")
    json_cave_list = json.load(open(path.join(base_path, "bdcff_conversions", "done", "json", JSON_CAVE_DEF)))
    sprite_json = json.load(open(path.join(base_path, "sprites", "Text_sprites.json")))

    title = JSON_CAVE_DEF.split('.')[0]
    html_file = open(path.join(html_folder, title + ".html"), "w")
    html_file.write(f"<!DOCTYPE html><html lang='en'><head><title>{title}</title></head><body style='font-family:arial; max-width:max-content; margin:auto;'>\n")

    bonus_count = 0
    for json_cave in json_cave_list:

        print(f'Generating html and images for cave: {json_cave["CaveLetter"]}')

        html_file.write("<br/><br/><br/>\n")
        html_file.write("<table>\n")
        #Assign dimensions and html headings
        row_col_dimensions = [22, 40]  #Normal cave rows, columns
        if "Intermission" in json_cave:
            if json_cave["Intermission"] == True:
                row_col_dimensions = [12, 20]  #Intermission rows, columns
                bonus_count += 1
                label = f"Intermission {bonus_count}"
                html_file.write(f"<tr><td colspan=2 style='padding-left:10px'><b>{label}&nbsp;&nbsp;&nbsp;level {LEVEL+1}</b></td></tr>\n")
        else:
            label = f'Cave {json_cave["CaveLetter"]}'
            html_file.write(f'<tr><td colspan=2 style="padding-left:10px"><b>{label}&nbsp;&nbsp;&nbsp;level {LEVEL+1}</b></td></tr>\n')

        #Add html image reference
        image_file_name = f'{title}_cave{json_cave["CaveLetter"]}.png'
        html_file.write(f"<tr><td colspan=2><img src='images/{image_file_name}' alt='{label}'/></td></tr>\n")

        #Add core parameters (always present) and others which may not be present. Two separate tables are created
        html_file.write("<tr><td style='width:40%; vertical-align:top'>")
        create_table_of_params(core_params)
        html_file.write("</td><td style='width:40%; vertical-align:top'>")
        create_table_of_params(other_params)
        html_file.write("</td></tr></table>\n")

        #Get colour pallette for the cave
        pallette = [BLACK]  #Black (0) is always present
        for colour in json_cave["Colors"]:
            if colour_map.get(colour.lower()) != None:  #Attempt to map the colour text values e.g. "red" becomes 1
                c = colour_map[colour.lower()]
                pallette.append(AVAILABLE_COLOURS[c])
        if len(pallette) != 4:  #Were all 4 colours mapped for the pallette? If not, use the predefined pallette for the cave
            pallette = [BLACK]
            for c in colour_schemes[str(json_cave["CaveNumber"])]['code']:
                pallette.append(AVAILABLE_COLOURS[c])

        #For border tile when used
        border_tile_name = ""
        if "BorderTile" in json_cave:
            border_tile_name = json_cave["BorderTile"]

        #Pseudo-random tile-plotting parameters
        random_type = False
        seed = 0
        tile_prob = []
        tile_name_for_prob = []
        below_tile_name_for_prob = []
        initial_tile_name = "DIRT"
        if "RandSeed" in json_cave:
            random_type = True
            seed = json_cave["RandSeed"][LEVEL]
            tile_prob = json_cave["TileProbability"]
            tile_name_for_prob = json_cave["TileForProbability"]
            if "RandomFillBelow" in json_cave:
                below_tile_name_for_prob = json_cave["RandomFillBelow"]
            if "InitialFill" in json_cave:
                initial_tile_name = json_cave["InitialFill"]

        #Create cave image
        #if json_cave["CaveLetter"] == "K":  #For debug
        image_file_name = path.join(images_folder, image_file_name)
        generate_cave_image(image_file_name, json_cave["Map"], pallette, row_col_dimensions, random_type, tile_prob, tile_name_for_prob, below_tile_name_for_prob, initial_tile_name, border_tile_name)

    html_file.write("</body></html>\n")
    html_file.close()
