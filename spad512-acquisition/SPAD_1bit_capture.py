#!/usr/bin/env python
'''
Last updated: 2024-Sep-05

This script is meant to connect and capture 1-bit frames from Pi-Imaging's SPAD512s.
It is a modified version of the original script 'python_tcp_stream_binary_intensity1bit.py'
provided by the SPAD512s User Documentation - Programming Examples under
https://piimaging.com/doc-spad512s

IMPORTANT: Numpy uses a row-major order when reshaping arrays as opposed to matlab which uses a
column-major order

'''
import os
import re
import sys
import socket
import time
import argparse
import numpy as np
from PIL import Image

parser = argparse.ArgumentParser(description="user input")
parser.add_argument('-f', '--folder', type=str, help="Subfolder name", required=True )
parser.add_argument('-b','--bit', type=int, help="Bit depth", required=True)
parser.add_argument('-i', '--images', type=int, help="Number of images", required=True)
parser.add_argument('-e', '--exposure', type=float, help="Exposure time in us", required=True)
parser.add_argument('-d1', '--display1', action='store_true', help="Display 1-bit image")
parser.add_argument('-d8', '--display8', action='store_true', help="Display 8-bit image")
parser.add_argument('-s', '--save', action='store_true', help="Save image as PNG")

args = parser.parse_args()
print("Bit depth: ", "{:d}".format(args.bit), "-bit")
print("Exposure time: ", "{:.2f}".format(args.exposure), " us")
print("Number of 1-bit frames: ", "{:d}".format(args.images), " frames")

directory = os.path.join(".", "data", "SPAD", f'{args.folder}')

if not os.path.exists(directory):
    os.makedirs(directory)

def next_filename(directory, base_name="img", extension=".PNG"):

    files_per_step = 5

    files = os.listdir(directory) # get a list of all the files in the directory
    
    #Regular expression to match filenames with a number before the extension
    pattern = re.compile(rf"(\d+){re.escape(extension)}$")

    # extract number from files
    numbers = [int(pattern.search(f).group(1)) for f in files if pattern.search(f)]

    # Determine the current highest number and count how many files have that number
    if numbers:
        max_num = max(numbers)
        count_max_num = sum(1 for f in files if re.search(rf"{max_num}{re.escape(extension)}$", f))
    else:
        max_num = 1
        count_max_num = 0

    # If there are already 5 files with the highest number, increment the number
    if count_max_num >= files_per_step:
        next_num = max_num + 1
    else:
        next_num = max_num

    return f"{base_name}{next_num}{extension}"

def next_filename_simple(directory, base_name="img", extension=".PNG"):

    files = os.listdir(directory)

    #filter out the files that match naming convention
    pattern = re.compile(f"{base_name}(\\d+){extension}")

    # extract number from files
    numbers = [int(pattern.match(f).group(1)) for f in files if pattern.match(f)]

    #find the next num to use
    next_num = max(numbers) + 1 if numbers else 1

    return f"{base_name}{next_num}{extension}"

def main():

    ## ------- OPEN TCP/IP CONNECTION -------
    # connection to the localhost, port 9999
    # make sure to change the port number if other is used to connect to the camera
    t = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    t.connect(('127.0.0.1', 9999))

    # read the server response
    data = t.recv(8192)
    print(data.decode('utf8'))
    
    ## ------- IMAGE ACQUISTIION -------
    start = time.time()
    # make intensity images
    command = bytes("I," + str(args.bit) + "," + str(args.exposure) + "," + str(args.images) + ",0" + ",1" + ",0" + ",1" + '\n', "utf8") # for 1-bit binary image streaming with overlap, no frame triggering
    t.send(command)

    data = bytearray() # initialize empty bytearray 1D. Note that data will be saved in bytes not in bits. Needs to be unpack later. 

    # look for the response (i.e., camera returns "DONE")
    while 1:
        datablock = t.recv(262144) # read data from socket. Try different buffer sizes (bytes). Defalt = 32KB of data at a time.
        data.extend(datablock) # append received data to bytearray
        
        # we stream binary pixel values, either 0 for no data, or 255 for a 1 (each byte represents one pixel)
        
        if datablock[-4:] == bytearray("DONE", 'utf8'): # check the last 4 bytes of datablock
            
            print("Process complete")
            break
            
        elif datablock[-5:] == bytearray("ERROR", 'utf8'):
            
            print(datablock[-160:])
            print("Completed the run with errors")
            quit()

    # close communication channel, get read time
    t.close()
    read = time.time()
    print("Read time: ", "{:.2f}".format((read - start)*1000), " ms")

    start = time.time();
    data = np.array(data, dtype=np.uint8)
    filename = next_filename(directory,f"SPAD_{args.exposure}us_{time.time()}_",".bin")
    data.tofile(os.path.join(directory,filename))
    read = time.time()
    print("Saving file time: ", "{:.2f}".format((read - start)*1000), " ms")

    ## ------- DEBUGGING/CHECKING DATA -------

    if args.save and not args.display1 and not args.display8:
            parser.error('Either --display1 or --display8 are required for saving the image')

    if args.display1: # display the last 1-bit image
    
        data = data[:-4] # remove DONE from the end of the data
        datamap = np.zeros((512, 512, args.images), dtype=np.uint8) # initialize 3D array

        for i in range(args.images): 
            img_index_old = i*512*64 # each byte of data received contains 8 pixels in 1-bit format (or 8 bits; 512/8 = 64) 
            img_index = (i+1)*512*64
                
            dataint = np.array(data[img_index_old:img_index], dtype = "uint8") # extract frame data from byte array
            
            databit = np.unpackbits(dataint) # unpack single bit values from data

            datamap[:,:,i] = databit.reshape(512,512) # reshape to 2d array and add to datamap

        bit_image = databit*255
        im = Image.new('L', (512, 512), "black") # create new grayscale image and write the data to an image file
        im.putdata(bit_image)
        im = im.transpose(Image.Transpose.ROTATE_90)
        im.show()

        if args.save: 
            folder = os.path.join(".","img")
            if not os.path.exists(folder):
                os.makedirs(folder)

            filename = next_filename_simple(folder,"bin")
            im.save(os.path.join(folder,filename))
            

    if args.display8: #display 8-bit image
        data = data[:-4]
        datamap = np.zeros(512*512)
                           
        for i in range(args.images): 
            img_index_old = i*512*64 
            img_index = (i+1)*512*64
                
            dataint = np.array(data[img_index_old:img_index], dtype = "uint8") 
            databit = np.unpackbits(dataint)    

            datamap += databit

        im = Image.new('L', (512, 512), "black") # create new grayscale image and write the data to an image file
        im.putdata(datamap)
        im = im.transpose(Image.Transpose.ROTATE_90)
        im.show()

        if args.save: 
            folder = os.path.join(".","img")
            if not os.path.exists(folder):
                os.makedirs(folder)

            filename = next_filename_simple(folder)
            im.save(os.path.join(folder,filename))

if __name__ == "__main__":
    main()
