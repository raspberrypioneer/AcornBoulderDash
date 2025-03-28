################################################################################
# bd_build_all.py - Compile Boulder Dash assembler code and build ssd
#
# V0.1 06/03/2024: First working version
# V0.2 26/03/2025: Amended to build all versions with all caves in one SSD
# V1.0 28/03/2025: Amended with changes to folder structure
#

import os
from os import path
from distutils.dir_util import copy_tree
import json
import image

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
    config_file = open(path.join(base_path, "config", "config.json"))
    config_settings = json.load(config_file)
    versions = config_settings["versions"]
    ssd_file_settings = config_settings["ssd_file_settings"]
    config_file.close()

    build_folder = path.join(base_path, "build")

    #Copy existing program binaries to build folder
    copy_tree(path.join(base_path, "code_bin"), build_folder)

    #Compile the main program asm code using acme, this overwrites the existing main program "BDSH3"
    print(f"Compile main.asm code using acme.exe")
    os.system(".\\bin\\acme.exe -l .\\build\\symbols -o .\\build\\BDSH3 main.asm")

    #Loop through the caves folder for each version and merge individual cave binary files into 2 groups
    for version in versions:
        print(f"Creating cave groups for {version}")
        values = versions[version]

        os.chdir(path.join(base_path, "caves_bin", values["folder"]))
        os.system('copy /b A+B+C+D+E+F+G+H+Q+R "' + build_folder + '\\' + values["prefix"] + '-1" >nul')
        os.system('copy /b I+J+K+L+M+N+O+P+S+T "' + build_folder + '\\' + values["prefix"] + '-2" >nul')

    #Build SSD usiing files prepared above
    os.chdir(build_folder)

    #Create INF files for each file using config data (INF files needed for inserting into SSD)
    for file in ssd_file_settings:
        if path.exists(file):
            values = ssd_file_settings[file]
            with open(file + ".inf", 'w') as f:
                f.write("$.{: <9} {:0>8} {:0>8} L {:0>8}".format(file, values['load'], values['exec'], values['size']))

    #Create empty SSD file
    print(f"Creating Boulder Dash SSD")
    ssd_filepath = path.join(base_path, "ssd", "BoulderDash.ssd")
    create_ssd("BoulderDash", ssd_filepath, 40, 3)  #SSD with file name as title, 40 tracks and bootable

    #Insert each file into the SSD in order per the config file
    disk_image = image.DiskImage()
    disk_image.set_disk(ssd_filepath)

    for file in ssd_file_settings:
        if path.exists(file):
#            print(f"  Inserting {file}")
            disk_image.insert(file)

    os.chdir("../../")
    print(f"Build complete")
