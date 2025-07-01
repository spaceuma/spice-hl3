@echo off

if "%1"=="" (
    echo Please provide a target folder as an argument.
    exit /b
)

set "target_folder=%1"

python SPAD_1bit_capture.py -b 1 -i 256 -e 0.1 -f "%target_folder%"
python SPAD_1bit_capture.py -b 1 -i 256 -e 0.2 -f "%target_folder%"
python SPAD_1bit_capture.py -b 1 -i 256 -e 0.5 -f "%target_folder%"
python SPAD_1bit_capture.py -b 1 -i 256 -e 1 -f "%target_folder%"
python SPAD_1bit_capture.py -b 1 -i 256 -e 1.2 -f "%target_folder%"