#! /usr/bin/python3

"""
	Name		: UEF2INF.py
	Author		: David Boddie <davidb@mcs.st-and.ac.uk>
	Created		: Tue 21st November 2000
	Last updated	: Wed 11th July 2001
	Purpose		: Convert UEF archives to files on a disc.
	WWW		: http://www.david.boddie.net/Software/Tape2Disc/
"""

import sys, os, gzip

def str2num(size, s):
    n = 0
    for i in range(size):
        #n |= ord(s[i]) << (i * 8)
        n |= s[i] << (i * 8)
    return n


def read_block(in_f):
    global eof
    while eof == 0:
        # Read chunk ID
        chunk_id = in_f.read(2)
        if not chunk_id:
            eof = 1
            break

        chunk_id = str2num(2, chunk_id)

        if chunk_id == 0x100 or chunk_id == 0x102:
            length = str2num(4, in_f.read(4))
            if length > 1:
                # Read block
                data = in_f.read(length)
                break
            else:
                in_f.read(length)

        else:
            # Skip chunk
            length = str2num(4, in_f.read(4))
            in_f.read(length)

    if eof == 1:
        return ("", 0, 0, "", 0)

    # For the implicit tape data chunk, just read the block as a series
    # of bytes, as before
    if chunk_id == 0x100:
        block = data

    else:  # 0x102
        if UEF_major == 0 and UEF_minor < 9:
            ignore = 0
            bit_ptr = 0
        else:
            ignore = data[0]
            bit_ptr = 8

        block = []
        write_ptr = 0
        after_end = (len(data) * 8) - ignore
        while bit_ptr < after_end:
            bit_ptr += 1
            bit_offset = bit_ptr % 8
            if bit_offset == 0:
                block.append(data[bit_ptr >> 3])
            else:
                b1 = data[bit_ptr >> 3]
                b2 = data[(bit_ptr >> 3) + 1]
                b1 >>= bit_offset
                b2 = (b2 << (8 - bit_offset)) & 0xff
                block.append(b1 | b2)

            write_ptr += 1
            bit_ptr += 9

    name = ""
    a = 1
    while 1:
        c = block[a]
        #if ord(c) != 0:
        if c != 0:            
            #name += c
            name += chr(c)
        a += 1
        #if ord(c) == 0:
        if c == 0:
            break

    load = str2num(4, block[a:a + 4])
    exec_addr = str2num(4, block[a + 4:a + 8])
    block_number = str2num(2, block[a + 8:a + 10])

    if verbose == 1:
        if block_number == 0:
            print()
            print(name, end=" ")
        print(hex(block_number)[2:].upper(), end=" ")

    return (name, load, exec_addr, block[a + 19:-2], block_number)


def get_leafname(path):
    return os.path.basename(path)


# Main program
version = '0.12 (Fri 10th August 2001)'
syntax = "Syntax: UEF2INF.py [-l] [-v] <UEF file> <destination path> [-name <stem>]"

args = sys.argv[1:]

# If there are no arguments then print the help text
if len(args) < 2:
    print(syntax)
    print()
    print(f"UEF2INF version {version}")
    print()
    print("This program attempts to decode UEF files and save the files contained to")
    print("the directory given by <destination path>.")
    print("The load and execution addresses, and the file lengths are written to .inf")
    print("files corresponding to each file extracted.")
    print()
    print("The options perform the following functions:")
    print()
    print("-l              Lists the names of the files as they are extracted.")
    print()
    print("-name <stem>    Writes files without names in the format <stem><number>")
    print("                with <number> starting at 1.")
    print()
    print("-v              Verbose output.")
    print()
    sys.exit()

# Determine the platform on which the program is running
sep = os.sep

if sys.platform == "RISCOS":
    suffix = "/"
elif sys.platform == "DOS":
    suffix = "."
else:
    suffix = "."

# List files
list_files = "-l" in args
if list_files:
    args.remove("-l")

# Verbose output
verbose = "-v" in args
if verbose:
    args.remove("-v")

# Stem for unknown filenames
stem = "noname"
found = False
if "-name" in args:
    try:
        stem = args[args.index("-name") + 1]
        found = True
    except IndexError:
        print(syntax)
        sys.exit()
    args.remove("-name")
    args.remove(stem)

# Input file and output path specified?
if not list_files and len(args) < 2:
    print(syntax)
    sys.exit()

if list_files and len(args) < 1:
    print(syntax)
    sys.exit()

# Open the input file
try:
    in_f = open(args[0], "rb")
except IOError:
    print(f"The input file, {args[0]} could not be found.")
    sys.exit()

# Is it gzipped?
if in_f.read(10) != b"UEF File!\000":
    in_f.close()
    in_f = gzip.open(args[0], "rb")
    try:
        if in_f.read(10) != b"UEF File!\000":
            print(f"The input file, {args[0]} is not a UEF file.")
            sys.exit()
    except:
        print(f"The input file, {args[0]} could not be read.")
        sys.exit()

# Read version number of the file format
UEF_minor = str2num(1, in_f.read(1))
UEF_major = str2num(1, in_f.read(1))

if not list_files:
    leafname = get_leafname(args[1])
    print(f"leafname: {leafname}")
    try:
        os.listdir(args[1])
    except:
        try:
            os.mkdir(args[1])
            print(f"Created directory {args[1]}")
        except:
            print(f"Directory {leafname} already exists.")
            sys.exit()

eof = 0  # End of file flag
out_file = ""  # Currently open file as specified in the block
write_file = ""  # Write the file using this name
file_length = 0  # File length
first_file = 1

# List of files already created
created = []

# Unnamed file counter
n = 1

while True:
    # Read block details
    try:
        name, load, exec_addr, block, block_number = read_block(in_f)
    except IOError:
        print("Unexpected end of file")
        sys.exit()

    if not list_files:
        if eof == 1:
            out.close()
            inf.write(f"{hex(file_length)[2:].upper()}\n")
            inf.close()
            break

        if block_number == 0 or first_file == 1:
            out_file = name
            write_file = name

            if write_file in created:
                write_file = f"{write_file}-{n}"
                n += 1

            if write_file == "":
                write_file = f"{stem}{n}"
                n += 1

            if first_file == 0:
                out.close()
                inf.write(f"{hex(file_length)[2:].upper()}\tNEXT $.{write_file}\n")
                inf.close()
            else:
                first_file = 0

            file_length = 0

            try:
                out = open(os.path.join(args[1], write_file), "wb")
            except IOError:
                write_file = f"{stem}{n}"
                n += 1
                try:
                    out = open(os.path.join(args[1], write_file), "wb")
                except IOError:
                    print(f"Couldn't open the file {os.path.join(args[1], write_file)}")
                    sys.exit()

            created.append(write_file)

            try:
                inf = open(os.path.join(args[1], write_file + suffix + "inf"), "w")
            except IOError:
                print(f"Couldn't open the information file {os.path.join(args[1], write_file + suffix + 'inf')}")
                sys.exit()

            inf.write(f"$.{write_file}\t{hex(load)[2:].upper()}\t{hex(exec_addr)[2:].upper()}\t")

        if block != b"":
            out.write(block)
            file_length += len(block)
    else:
        if eof == 1:
            break

        if not verbose and block_number == 0:
            print(name)

# Close the input file
in_f.close()

# Exit
sys.exit()
