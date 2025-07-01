function export_spad_frames(file_path, output_dir)
% EXPORT_SPAD_FRAMES - Converts SPAD binary files to 1-bit PNG frames.
%
%   export_spad_frames(inputDir, outputDir)
%
%   Parameters:
%     file_path  - Full path to the directory containing .bin files
%     output_dir - Full path to the output directory for PNG images
%
%   This function reads all .bin files produced by the Pi-Imaging SPAD 512S
%   camera and extracts 1-bit frames, saving each as a PNG image. It assumes
%   the helper function `read_512Sbin.m` is available in the path.
%
%   Example:
%     export_spad_frames('C:\Data\Acquisition1', 'C:\Data\PNGOutput')
%
%   Author: David Rodríguez (https://github.com/drodriguezSRL)
%   Last updated: 2025-06-15

    if nargin < 2
        output_dir = fullfile(file_path, 'png', '1bit');
    end
    
    disp("Reading directory...⏳")
    
    if ~exist(file_path, 'dir') 
        error('❌ Input directory "%s" does not exist.', file_path);
    end
    
    if ~exist(output_dir, 'dir')
        mkdir(output_dir);
    end

    file_pattern = fullfile(file_path, '*.bin');
    file_list = dir(file_pattern);
    
    if isempty(file_list)
        error('❌ No .BIN files found in directory "%s".', file_path);
    end

    fprintf('Found %d .BIN files.\n', numel(file_list));

    f = waitbar(0, "Processing .BIN files...📸");

    for k= 1:numel(file_list)
        text = "Digitizing frame: " + string(k) + "/" + string(numel(file_list));
        waitbar(k/numel(file_list), f, text);

   
        full_filename = fullfile(file_path, file_list(k).name);
        
        % Extract timestamps from metadata
        timestamp = extract_timestamp(file_list(k));
        
        if isempty(timestamp)
            disp('[WARNING] Timestamp appears to be empty.')
            timestamp = sprintf('unknown_%d', k); 
        end
    
        % Extract individual frames within each .BIN file
        frames_subarray = read_512Sbin(full_filename);
        frames_subarray = permute(frames_subarray, [3 2 1]);

        % Export binary frames 
        for frame = 1:size(frames_subarray,1) 
            bin_img = squeeze(frames_subarray(frame,:,:));   
            
            % Convert frame to logical array so that binary frames can be
            % saved without normalization with imwrite.
            bin_img = logical(bin_img);
            
            bin_file_name = sprintf('spad_%s_frame%d.png', timestamp, frame); 
            bin_file_path = fullfile(output_dir, bin_file_name);
            imwrite(bin_img, bin_file_path, 'png');
        end
    end

    close(f);
    fprintf('✅ Export complete. Binary frames exported succesfully and saved to %s\n', output_dir);

    function timestamp = extract_timestamp(file)
        unixEpoch = datenum('01-Jan-1970 00:00:00');
        dt = file.datenum;
        timestamp = (dt - unixEpoch) * 86400; 
        timestamp = sprintf('%.9f', timestamp);
    end
end