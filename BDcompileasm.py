################################################################################
# BDcompileasm.py - Compile Boulder Dash assembler code and build ssd
#
# See https://github.com/TobyLobster/Boulderdash for the disassembly
# The complete original asm is in /source/___1___.asm
# This file has been renamed as main.asm and is where changes to the assembler code are made
#
# V0.1 06/03/2024: First working version
#

import os
from os import path
from distutils.dir_util import copy_tree
import json
import image

CAVE_LETTERS = ['A','B','C','D','Q','E','F','G','H','R','I','J','K','L','S','M','N','O','P','T']
ASM_SOURCE = "main.asm"
#SSD_NAME = "BoulderDash01"
#SSD_NAME = "BoulderDash02"
SSD_NAME = "BoulderDashP1"
INCLUDE_CAVES = True

################################################################################
#region Helper functions

def create_ssd(disk_title, ssd_filepath, tracks, boot_option):
    #boot_option 0=None, 1=Load, 2=Run, 3=Exec
    disk_type = 0  # 0=Acorn DFS or Watford DFS <= 256K
    num_sectors = tracks * 10  # 40 or 80 tracks, 10 sectors per track
    split_title = [disk_title[0:8],disk_title[8:12]]

    # Add the first 8 characters of the title, then pad to 256 bytes
    ssd_bytes = bytearray(split_title[0], 'Latin-1')
    for i in range(len(split_title[0]), 0x100):
        ssd_bytes.append(0)

    # Add the next 4 (max) characters of the title, then pad to 262 bytes
    ssd_bytes.extend(bytearray(split_title[1], 'Latin-1'))
    for i in range(len(ssd_bytes), 0x106):
        ssd_bytes.append(0)

    # Add the boot and related information, then pad to 512 bytes
    ssd_bytes.append((boot_option * 16) + (disk_type * 4) + (num_sectors // 256))
    ssd_bytes.append(num_sectors & 255)
    for i in range(0x108, 0x200):
        ssd_bytes.append(0)

    # Write the empty ssd file
    with open(ssd_filepath, 'wb') as f:
        f.write(ssd_bytes)

#endregion

################################################################################
# Main Routine
if __name__ == '__main__':

    ### Config and file paths
    base_path = path.dirname(path.abspath(__file__))
    config_file = open(path.join(base_path, "config/config.json"))
    config_settings = json.load(config_file)
    ssd_file_settings = config_settings["ssd_file_settings"]
    config_file.close()

    BD_code_folder = path.join(base_path, "BDcode")
    BD_sourcecaves_folder = path.join(base_path, "BDoriginalcaves")  #Boulder Dash 1
    if SSD_NAME == "BoulderDash02":
        BD_sourcecaves_folder = path.join(base_path, "BD2originalcaves")  #Boulder Dash 2
    else:
        if SSD_NAME == "BoulderDashP1":
            BD_sourcecaves_folder = path.join(base_path, "BDplus1caves")  #Boulder Dash +1

    output_subfolder = path.join(base_path, "output", "build")
    BD_filename = SSD_NAME

    #Copy sourcecode to build folder
    print(f"Copy sourcecode and caves to build folder")
    copy_tree(BD_code_folder, output_subfolder)
    copy_tree(BD_sourcecaves_folder, output_subfolder)

    #Compile the main program asm code using acme, this overwrites the existing main program "BDSH3"
    print(f"Compile {ASM_SOURCE} asm code using acme.exe")
    os.system(".\\bin\\acme.exe -o .\\output\\build\\BDSH3 .\\asm\\" + ASM_SOURCE)

    #Create SSD file
    print(f"Creating SSD for {BD_filename}")
    ssd_filepath = path.join(base_path, "output", "ssd", BD_filename + ".ssd")
    create_ssd(BD_filename, ssd_filepath, 40, 3)  #SSD with file name as title, 40 tracks and bootable
    output_subfolder_relpath = path.join("output", "build")
    os.chdir(output_subfolder_relpath)

    #Create INF files for each source file using config data (INF files needed for inserting into SSD)
    for file in ssd_file_settings:
        if file not in CAVE_LETTERS or (file in CAVE_LETTERS and INCLUDE_CAVES):
            if path.exists(file):
                values = ssd_file_settings[file]
                with open(file + ".inf", 'w') as f:
                    f.write("$.{: <9} {:0>8} {:0>8} L {:0>8}".format(file, values['load'], values['exec'], values['size']))

    #Insert each file into the SSD in order per the config file
    disk_image = image.DiskImage()
    disk_image.set_disk(ssd_filepath)

    for file in ssd_file_settings:
        if file not in CAVE_LETTERS or (file in CAVE_LETTERS and INCLUDE_CAVES):
            if path.exists(file):
#                print(f"  Inserting {file}")
                disk_image.insert(file)

    os.chdir("../../")
    print(f"Completed {BD_filename}")
