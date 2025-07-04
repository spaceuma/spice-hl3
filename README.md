# SPICE-HL3: Single-Photon, Inertial, and Stereo Camera dataset for Exploration of High-Latitude Lunar Landscapes <!-- omit in toc -->
This repository contains all the suplementary material used during the acquisition and processing of the [SPICE-HL3 dataset](https://zenodo.org/records/13970078?preview=1). 

All the details about this dataset can be found in the associated manuscript.

[![arXiv](https://img.shields.io/badge/arXiv-1234.56789-b31b1b.svg)](https://arxiv.org/abs/2506.22956)
[![Static Badge](https://img.shields.io/badge/YouTube-video-red?style=flat)](https://youtu.be/d7sPeO50_2I)
[![Static Badge](https://img.shields.io/badge/Zenodo-dataset-blue)](https://zenodo.org/records/13970078?preview=1)


![spice-hl3_cover ](/img/dataset_cover.png)

Authors:
- David Rodríguez Martínez [![orcid](https://orcid.org/sites/default/files/images/orcid_16x16.png)](https://orcid.org/0000-0003-4817-9225)
- Dave van der Meer [![orcid](https://orcid.org/sites/default/files/images/orcid_16x16.png)](https://orcid.org/0000-0002-7892-9704)
- Junlin Song [![orcid](https://orcid.org/sites/default/files/images/orcid_16x16.png)](https://orcid.org/0000-0001-9690-7253)
- Abishek Bera [![orcid](https://orcid.org/sites/default/files/images/orcid_16x16.png)](https://orcid.org/0000-0002-0196-5969)
- C.J Pérez del Pulgar [![orcid](https://orcid.org/sites/default/files/images/orcid_16x16.png)](https://orcid.org/0000-0001-5819-8310)
- Miguel Angel Olivares-Mendez [![orcid](https://orcid.org/sites/default/files/images/orcid_16x16.png)](https://orcid.org/0000-0001-8824-3231)

Cite this dataset:
> Rodríguez-Martínez, D., van der Meer, D., Song, J., Bera, A., Pérez del Pulgar, C., & Olivares-Mendez, M. A. (2025). SPICE-HL3: Single-Photon, Inertial, and Stereo Camera dataset for Exploration of High-Latitude Lunar Landscapes. https://doi.org/10.48550/arXiv.2506.22956.

```
@article{rodriguez2025spicehl3,
  title={{SPICE}-{HL3}: Single-Photon, Inertial, and Stereo Camera dataset for Exploration of High-Latitude Lunar Landscapes},
  author = {Rodríguez-Martínez, David and van der Meer, Dave and Song, Junlin and Bera, Abishek and Pérez del Pulgar, C.J. and Olivares-Mendez, Miguel Angel},
  doi = {10.48550/arXiv.2506.22956},
  url = {https://arxiv.org/abs/2506.22956},
  year = {2025}
}
```

## Updates <!-- omit in toc -->

- (2025-Jul-01) Leaderboard created.
- (2025-Jul-01) Public release of git repository.
- (2025-Jun-16) Creation of git repository.
- (2024-Dec-01) Dataset uploaded to Zenodo in restricted mode.
- (2024-Sep-10) Lunalab testing campaign.

## Contents <!-- omit in toc -->
- [SPAD512S Data Acquisition](#spad512s-data-acquisition)
- [SPAD512S Data Reader](#spad512s-data-reader)
  - [Data structure](#data-structure)
  - [Compatibility](#compatibility)
- [Fixing ROS2 and HW-sync issues](#fixing-ros2-and-hw-sync-issues)
- [Data processing and evaluation](#data-processing-and-evaluation)
  - [Using ORB-SLAM3 on SPICE-HL3 data](#using-orb-slam3-on-spice-hl3-data)
- [Leaderboard](#leaderboard)
  - [Submitting your results](#submitting-your-results)
- [References](#references)
- [Licensing](#licensing)

## SPAD512S Data Acquisition

As the SPAD512S GUI lacks native support for setting a fixed frame rate (i.e., capture X number of frames every Y ms), we developed a series of scripts to programmatically enable this functionality. 

In particular, the scripts used were:
- [*SPAD_1bit_capture.py*](/spad512-acquisition/SPAD_1bit_capture.py): capture a predefined number of frames at a given batch rate.
- [*SPAD_1bit_cont.py*](/spad512-acquisition/SPAD_1bit_cont.py): capture a continuous stream of binary frames at a given batch rate.
- [*multiexposure_launcher_SPAD.bat*](/spad512-acquisition/multiexposure_launcher_SPAD.bat): call the `SPAD_1bit_capture.py` script to acquire binary frames at five different exposure times (to be used on Windows).

## SPAD512S Data Reader
This section contains a series of MATLAB scripts designed to read and export data acquired with [Pi-Imaging SPAD512S](https://piimaging.com/spad-512/) single-photon camera. It contains the following scripts:

- [*export_spad_frames.m*](/spad512-reader/export_spad_frames.m): This function reads all the .BIN files saved during a single acquisition and extracts and exports each 1-bit frame acquired as individual .PNG images.
- [*digitize_from_1bit.m*](/spad512-reader/digitize_from_1bit.m): Once the 1-bit frames have been exported to PNG, this script can build up n-bit .PNG images out of those 1-bit frames. The required bit depth needs to be explicitly defined as an argument. 
- [*digitize_from_4bit.m*](/spad512-reader/digitize_from_4bit.n): Similarly, this script can integrate 4-bit .PNG images to export images of a desired bit depth (always > 4bit). 
- [*read_512Sbin.m*](/spad512-reader/read_512sbin.m): This is a function required by `export_spad_frames()`. This function contains the necessary code to extract and reconstruct the data from a .BIN file so that single 1-bit frames can be exported. This script is based on the `python_tcp_stream_binary_intensity1bit.py` file available in the SPAD512S system documentation[[1]](#references).
- [*remap.m*](/spad512-reader/remap.m): This is a simple MATLAB function meant to remap n-bit .PNG images into an 8-bit colormap.


>[!NOTE]
> For additional information on any of these funtions, simply run `help [function_name]` in the command window. 

### Data structure
The previous scripts have been updated to work with any data structure given the appropriate updates (check function help text for more info). As is, however, the scripts are designed to work with the data structure created by default when images are recorded through Pi-Imaging's camera GUI. 

> [!NOTE]
> The scripts associated with the SPAD512S Data Reader are meant to work based on 1-bit or 4-bit native frame acquisitions.  

From the SPAD512S, data is saved by default based on the following directory structure:
```
> ...
    > data
        > intensity_images
            > acq0000X
                > RAW00000.bin
                > RAW00001.bin
                > ...
```

`RAW0000X.BIN` are binary files containing a maximum of 1000 1-bit frames (i.e., ~32MB). Multiple .BIN files will be saved during longer acquisitions. 

The scripts are designed to work regardless of the number of .BIN files saved but always within single acquisitions (i.e., the file path to the `acq0000X` folder of choice needs to be passed as an argument to the function `export_spad_frames()`). The scripts will need to be updated for them to read data from multiple acquisitions at once (i.e., from multiple `acq0000X` folders). 

### Compatibility

These scripts were tested on both MATLAB [R2023a](https://ch.mathworks.com/products/new_products/release2023a.html) and [R2024a](https://ch.mathworks.com/products/new_products/latest_features.html).

## Fixing ROS2 and HW-sync issues

Due to ROS2-related issues and potential hardware synchronization limitations, some raw captured data contained frames affected by partial delays or mismatched timestamps between the left and right cameras. To correct and clean the data, we used the following scripts, which we are sharing openly so that anyone can re-create the dataset from the raw data contained in the rosbags or to review how the data was processed prior to publication.

The raw data frames captured by the ZED2 stereo camera were processed following these steps:

1. Run the [*stereo_file_matching.m*](/data-cleaner/stereo_file_matching.m) script to remove all left-to-right mismatched frames, and viceversa. Just swap target and reference. Output `left/data` and `right/data` folders with equal number of frames.
2. Run the [*clean_delayed_frames.m*](/data-cleaner/clean_delayed_frames.m) script on the left and right data folders filter out all heavily delayed frames. Output data folders with sequentially timestampped frames.
3. Run the [*reID_frames.m*](/data-cleaner/reID_frames.m) script to, as the name suggest, reID all frames.
4. Finally, conduct a quality check with [*finalcheck_left_right_frames.m*](/data-cleaner/finalcheck_left_right_frames.m) to confirm all timestamps associated with left camera frames have matching right camera frames.

## Data processing and evaluation

- [*disparity.py*](/data-processing/disparity.py): computes disparity maps for multiple stereo image and saves the output as PNG images.

### Using ORB-SLAM3 on SPICE-HL3 data 

For details on how to adapt and run this dataset through ORB-SLAM3, check this implementation [2](#references), specifically the [Adapting my own data](https://github.com/drodriguezSRL/ORBSLAM3_implementation/blob/main/HOW.md#phase-5-adapting-my-own-data) section of the implementation log book. 

## Leaderboard

This is a public leaderboard showcasing the performance of various Visual Odometry and SLAM methods evaluated on different trajectories from the SPICE-HL3 dataset. The goal is to provide a centralized, transparent comparison of state-of-the-art approaches using consistent benchmarks.

### Submitting your results

To have your results included in the leaderboard, please open a new issue titled "_Leaderboard Submission_" and include the following details:
```
- Method name
- Sensor configuration (e.g., monocular, stereo, RGB, SPAD, stereo-inertial, etc.)
- Evaluated trajectory(ies)
- Absolute Trajectory Error (ATE) per trajectory:
  -  RMSE [cm]
  -  Max error [cm]
- Reference (arXiv, conference, or journal publication describing your method )
```

Once submitted, your entry will be reviewed and added to the leaderboard. We encourage reproducibility and transparency, feel free to include any links to code, pre-trained models, or logs. If the data provided with SPICE-HL3 has been preprocessed in any way, please include details as to the methods used.  

>[!IMPORTANT]
> Note that ATE must be computed using alignment based on the initial estimated pose (no global SE(3) alignment such as Horn's).

> [!NOTE]
> To ensure fairness and comparability between methods evaluated on different subsets of the dataset, the ranking is based on a globally weighted average ATE, where each trajectory's contribution is weighted by its length. If a method fails to produce a valid estimated trajectory on a given sequence, a **penalty RMSE of 1 m and max ATE of 5 m** are applied for that trajectory, weighted by its length. This ensures that methods are fairly penalized for non-robust behavior.

### Fast Sequences SPICE-HL3 Leaderboard <!-- omit in toc -->

| Rank | Method | Sensor | Trj_A | Trj_B | Trj_C | Trj_D | Trj_E | Trj_F | Trj_G | avATE RMSE [cm] | avATE Max [cm] |
|------|--------|--------|-------|-------|-------|-------|-------|-------|-------|-----------------|----------------|
| 1 :fire: | **Wheel Odometry** | WODO | :heavy_minus_sign: | 34.66 (63.91) | 124.87 (213.86) | 85.40 (123.33) | :x: | :heavy_minus_sign: | :heavy_minus_sign: | 140.70 | 442.36 |
| 2 | [**RTAB-Map**]( https://arxiv.org/abs/2403.06341) | Stereo | :heavy_minus_sign: | 64.77 (97.44)| :x: | :x: | 29.12 (35.29) | 64.50 (95.65) | 145.56 (202.12) | 253.50 | 965.61 |
| 3 | [**ORB-SLAM3**](https://ieeexplore.ieee.org/document/9440682) | Stereo | :heavy_minus_sign: | 83.72 (135.86) | 83.23 (135.47) | :x: | 17.31 (31.72) | :x: | :x: | 841.15 | 4161.01 |
| 4 | [**ORB-SLAM3**](https://ieeexplore.ieee.org/document/9440682) | Mono | :heavy_minus_sign: | 100.27 (168.82) | 94.04 (159.92) | :x: | :x: | :x: | :x: | 859.51 | 4247.57 |
| 5 | **Inertial Odometry (naive)** | IMU | :heavy_minus_sign: | 473.97 (1183.15) | 928.11 (2341.06) | 816.84 (2384.15) | :x: | :x: | :x: | 938.21 | 4265.62 |

:heavy_minus_sign: : Denotes trajectories that have not been evaluated.

:x: : Describe trajectories in which localization is lost and unrecovered; the method fails to provide a final estimate. 

## References
1. [SPAD512S System Documentation](https://piimaging.com/doc-spad512s)
2. [ORB-SLAM3 Dockerized Implementation](https://github.com/drodriguezSRL/ORBSLAM3_implementation)

## Licensing

The code is released under the [MIT License](LICENSE.txt).




