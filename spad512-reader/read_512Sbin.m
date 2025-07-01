function frames = read_512Sbin(full_filename)
% READ_512SBIN - Load binary SPAD data from a 512S camera file.
%
%   frames = read_512Sbin(full_filename)
%
%   Reads a binary file containing 1-bit frame data captured with a
%   Pi-Imaging SPAD 512S camera. The function assumes each frame is 512x512
%   pixels and that 256 frames are packed sequentially in the file.
%
%   Parameters:
%     full_filename - Full path to a .bin file.
%
%   Returns:
%     frames - 3D logical array (512x512x256) of binary image frames.
%
%   Notes:
%     - The last 4 bytes of the file are discarded (likely metadata or footer).
%     - Data is unpacked bitwise from uint8 blocks into binary frames.
%
%   Example:
%     frames = read_512Sbin('my_data/acq_01_00.00_00123.bin');
%
%   Author: David Rodríguez (https://github.com/drodriguezSRL)
%   Last updated: 2025-06-15

    % Constants 
    img_width = 512;
    img_height = 512;
    frames_per_bin = 256;
    frame_area = img_width * img_height;
    
    % Check input
    if ~isfile(full_filename)
        error('❌ File "%s" not found.', full_filename);
    end
    
    % Read file
    fileID = fopen(full_filename);
    if fileID == -1
        error('❌ Failed to open file: %s', full_filename);
    end
    
    A = fread(fileID, '*uint8');
    fclose(fileID);
    
    % Remove the last 4 bytes
    A = A(1:end-4);
    
    % Initialize the datamap
    datamap = zeros(img_width,img_height,frames_per_bin);
    
    % Determine the number of frames
    nr_images = length(A) * 8 / (img_width * img_height); 
    
    % Loop through each image and decode each frame
    for i = 0:(nr_images-1)
        img_index_old = i*frame_area/8 + 1; 
        img_index = ((i+1)*frame_area)/8; 
        
        dataint = A(img_index_old:img_index); 
        
        % Convert uint8 values to binary strings and reshape into 1-bit image
        bits = reshape(dec2bin(dataint, 8)' - '0', [img_width,img_height]);
        bits = imrotate(bits, -90); % rotate image 180 deg
    
        % Add bin frame to datamap
        datamap(:,:,i+1) = bits; 
    end    
    frames = datamap;
end