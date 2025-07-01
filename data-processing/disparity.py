#!/usr/bin/env python
'''
Last updated: 2024-Oct-05
'''
import os
import re
import sys
import cv2
import numpy as np

def compute_disparity_maps(left_dir, right_dir, output_dir='disparity_map', method = "SBM") -> None:
    """
    Computes disparity maps for multiple stereo image pairs stored in left and right directories.
    Saves the output disparity maps as PNG images in the specified output directory.
    """
    output_dir = os.path.join(OUTPUT_DATA_PATH, output_dir)
    pattern_left = re.compile(r"stereo_left_(\d+).(\d+)_(\d+)\.png")
    pattern_right = re.compile(r"stereo_right_(\d+).(\d+)_(\d+)\.png")

    os.makedirs(output_dir, exist_ok=True)

    # Get a sorted list of filenames in the left directory
    left_images = sorted(os.listdir(left_dir))
    right_images = sorted(os.listdir(right_dir))

    # Loop through the left images and process each corresponding pair
    for left_image_name in left_images:
        # Extract left_image fileID
        fileID = pattern_left.match(left_image_name).group(3)

        # Derive the corresponding right image
        for right_image_name in right_images:
            rightID = pattern_right.match(right_image_name).group(3)
            if rightID == fileID:
                right_image_name = right_image_name
                break
            else:
                right_image_name = None

        # Check if the corresponding right image exists
        if right_image_name is None:
            print(f"Warning: No matching right image for {left_image_name}.")
            sys.exit(1) 

        left_image_path = os.path.join(left_dir, left_image_name)
        right_image_path = os.path.join(right_dir, right_image_name)

        # Load the left and right images in grayscale
        left_img = cv2.imread(left_image_path, cv2.IMREAD_GRAYSCALE)
        right_img = cv2.imread(right_image_path, cv2.IMREAD_GRAYSCALE)

        if left_img is None or right_img is None:
            print(f"Error: Could not load image pair ({left_image_name}, {right_image_name}). Skipping.")
            continue

        if method == "SBM":
            # Create a StereoBM object
            window_size = 15 
            nDispFactor = 1 
            stereo = cv2.StereoBM_create(numDisparities=16*nDispFactor, blockSize=window_size)
        
        elif method == "SGBM":
            # Semi-Global Matching Method (SGM/SGBM)
            window_size = 15
            min_disp = 16
            nDispFactor = 2 
            num_disp = 16*nDispFactor-min_disp
            stereo = cv2.StereoSGBM_create(minDisparity = min_disp, 
                                           numDisparities = num_disp,
                                           blockSize = window_size,
                                           P1 = 8*3*window_size**2,
                                           P2 = 32*3*window_size**2,
                                           disp12MaxDiff = 1,
                                           uniquenessRatio = 15,
                                           speckleWindowSize = 100,
                                           speckleRange = 2, 
                                           preFilterCap = 63,
                                           mode=cv2.STEREO_SGBM_MODE_SGBM)

        else: 
            print("No method called ", "{:s}".format(method), ". Choose either SBM or SGBM.")
            quit

        # Compute the disparity map
        disparity_map = stereo.compute(left_img, right_img)

        # Set negative disparity values to 0 to mark them as invalid
        disparity_map[disparity_map < 0] = 0

        # Normalize disparity values to be in the range suitable for 16-bit images
        disparity_map = np.uint16(disparity_map)

        # Define the output file path for the disparity map
        disparity_map_filename = os.path.join(output_dir, f'disparity_{fileID}.png')
        cv2.imwrite(disparity_map_filename, disparity_map)
        print(f"Disparity map saved as '{disparity_map_filename}'")

        color_code_disparity(disparity_map, fileID)

def color_code_disparity(disparity_map, fileID, output_color_map_path = 'colored_disparity'):

    outputmap_dir = os.path.join(OUTPUT_DATA_PATH, output_color_map_path)
    
    # Ensure the output directory exists
    os.makedirs(outputmap_dir, exist_ok=True)
    
    if disparity_map is None:
        print(f"Error: Could not load disparity map")
        return

    # Normalize the disparity map to the range [0, 255] for visualization
    normalized_disparity = cv2.normalize(disparity_map, None, 0, 255, cv2.NORM_MINMAX)
    normalized_disparity = np.uint8(normalized_disparity)  # Convert to 8-bit

    # Step 3: Apply a color map
    color_mapped_disparity = cv2.applyColorMap(normalized_disparity, cv2.COLORMAP_JET)

    # Step 4: Save or display the color-coded image
    outputmap_filename = os.path.join(outputmap_dir, f'colordisparity_{fileID}.png')
    cv2.imwrite(outputmap_filename, color_mapped_disparity)

# Data paths
LOCAL_DIR = os.path.dirname(os.path.abspath(__file__))
LEFT_IMAGE_PATH = os.path.join(LOCAL_DIR, "./stereo/left")
RIGT_IMAGE_PATH = os.path.join(LOCAL_DIR, "./stereo/right")
OUTPUT_DATA_PATH = os.path.join(LOCAL_DIR, "./stereo")

disparity_map = compute_disparity_maps(LEFT_IMAGE_PATH, RIGT_IMAGE_PATH, "disparity_map", "SBM")
