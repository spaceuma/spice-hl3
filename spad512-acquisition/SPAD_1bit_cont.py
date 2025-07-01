#!/usr/bin/env python
'''
Last updated: 2024-Sep-20

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
import threading
import queue
import numpy as np
from PIL import Image

frame_queue = queue.Queue()

directory = os.path.join(".", "data")

if not os.path.exists(directory):
    os.makedirs(directory)
          
def next_filename(directory, base_name="img", extension=".PNG"):
    files = os.listdir(directory) 

    #filter out the files that match naming convention
    pattern = re.compile(f"{base_name}(\\d+){extension}")
    numbers = [int(pattern.match(f).group(1)) for f in files if pattern.match(f)]

    #find the next num to use
    next_num = max(numbers) + 1 if numbers else 1

    return f"{base_name}{next_num}{extension}"

def acquire_frames(t, args):
    start = time.time()
    frame_number = 0
    images_per_request = args.images
    frame_interval = 1 / args.fps # interval between frames in seconds

    while time.time() - start < args.time:
        start_frame_time = time.time()
        print(f'Acquiring frame {frame_number}')

        #send the command
        command = bytes("I,1," + str(args.exposure) + "," + str(images_per_request) + ",0" + ",1" + ",0" + ",1" + '\n', "utf8") # for 1-bit binary image streaming with overlap, no frame triggering
        t.send(command)

        data = bytearray() # initialize empty bytearray 1D. Note that data will be saved in bytes not in bits. Needs to be unpack later. 
        
        # look for the response (i.e., camera returns "DONE")
        while 1:
            datablock = t.recv(65536) # read data from socket. Try different buffer sizes ( 32768 bytes). Defalt = 32KB of data at a time.         
            data.extend(datablock) # append received data to bytearray
                                                                        
            # we stream binary pixel values, either 0 for no data, or 255 for a 1 (each byte represents one pixel)
                                                                        
            if datablock[-4:] == bytearray("DONE", 'utf8'): # check the last 4 bytes of datablock
                frame_timestamp = time.time()
                
                print(f"   Frame {frame_number} acquisition complete")

                frame_queue.put((frame_number, frame_timestamp, data)) #add frame to queue
                
                break
                                                                            
            elif datablock[-5:] == bytearray("ERROR", 'utf8'):
                                                                            
                print(datablock[-160:])
                print(f"   Frame {frame_number} completed with errors")
                #quit()
        
        end_frame_time = time.time()
        elapsed_time = end_frame_time - start_frame_time
        print(f"   Total frame {frame_number} time: ", "{:.2f}".format(elapsed_time*1000), " ms")

        frame_number += 1
        sleep_time = max(0, frame_interval - elapsed_time)
        time.sleep(sleep_time)

    read = time.time()
    print("Acquisition time: ", "{:.2f}".format((read - start)*1000), " ms")

def save_frames():
    saving_start = time.time()
    while 1:
        frame_number, frame_timestamp, data = frame_queue.get()

        if data is None: #finish acquisition
            break

        # save data to file
        data = np.array(data, dtype=np.uint8)
        
        filename = f'RAW_{frame_timestamp}.bin'
        path = os.path.join(directory,filename)
        data.tofile(path)
        
        frame_queue.task_done()
    saving_end = time.time()
    print("Saving time: ", "{:.2f}".format((saving_end - saving_start)*1000), " ms")

def main():

    parser = argparse.ArgumentParser(description="user input")
    parser.add_argument('-i', '--images', type=int, help="Number of images", required=True)
    parser.add_argument('-e', '--exposure', type=float, help="Exposure time in us", required=True)
    parser.add_argument('-l', '--long', action='store_true', help="Record a long acquisition")
    parser.add_argument('-t', '--time', type=float, help="Acquisition time in s", required=False, default=0)
    parser.add_argument('-f', '--fps', type=float, help="Frame rate in fps", required=False, default=0)
    parser.add_argument('-d1', '--display1', action='store_true', help="Display 1-bit image")
    parser.add_argument('-d8', '--display8', action='store_true', help="Display 8-bit image")
    parser.add_argument('-s', '--save', action='store_true', help="Save image as PNG")

    args = parser.parse_args()
    print("Bit depth: 1-bit")
    print("Exposure time: ", "{:.2f}".format(args.exposure), " us")

    if args.long and not args.time:
        parser.error('--time and --fps are required for long acquisitions')
        
    if args.long:
        print(f'Total acquisition time: {args.time} s')
        print(f'Frame rate: {args.fps} fps')
    else:
        print("Number of 1-bit frames: ", "{:d}".format(args.images), " frames")

    ## ------- OPEN TCP/IP CONNECTION -------
    # connection to the localhost, port 9999
    # make sure to change the port number if other is used to connect to the camera
    t = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    t.connect(('127.0.0.1', 9999))
    t.setblocking(True) #ensure socket is in blocking mode, fill the buffer as much as possible
    t.settimeout(0.5) # set to 1 second to allow sufficient time to retrieve data

    # read the server response
    data = t.recv(8192)
    print(data.decode('utf8'))
            
    
    ## ------- SINGLE IMAGE ACQUISTIION -------
    if not args.long:
        start = time.time()
        # make intensity images
        command = bytes("I,1," + str(args.exposure) + "," + str(args.images) + ",0" + ",1" + ",0" + ",1" + '\n', "utf8") # for 1-bit binary image streaming with overlap, no frame triggering
        t.send(command)

        data = bytearray() # initialize empty bytearray 1D. Note that data will be saved in bytes not in bits. Needs to be unpack later. 

        # look for the response (i.e., camera returns "DONE")
        while 1:
            datablock = t.recv(32768) # read data from socket. Try different buffer sizes (bytes). Defalt = 32KB of data at a time.
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
        data.tofile('RAW00002.bin')
        read = time.time()
        print("Saving file time: ", "{:.2f}".format((read - start)*1000), " ms")
        
    else:
        ## ------ CONTINUOUS ACQUISITION --------        
        #start threads
        acquisition_thread = threading.Thread(target=acquire_frames, args=(t,args))
        saving_thread = threading.Thread(target=save_frames)

        acquisition_thread.start()
        saving_thread.start()

        acquisition_thread.join()
        frame_queue.put((None, None)) #signal to stop saving threads
        saving_thread.join()
        
        # close communication channel, get read time
        t.close()

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

            filename = next_filename(folder,"bin")
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

            filename = next_filename(folder)
            im.save(os.path.join(folder,filename))


if __name__ == "__main__":
    main()
