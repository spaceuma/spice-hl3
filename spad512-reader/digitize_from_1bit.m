function digitize_from_1bit(file_path, desired_bitdepth, cam_type, num_images)
% DIGITIZE_FROM_1BIT - Build n-bit grayscale images from 1-bit SPAD PNG
% frames captured during a single acquisition. 
%
%   digitize_from_1bit(file_path, desired_bitdepth, cam_type, num_images)
%
%   This function processes a sequence of 1-bit PNG frames and exports
%   combined n-bit images for SPAD cameras such as:
%     - SwissSPAD2 (Top Half, 512x256)
%     - Pi-Imaging SPAD512S (512x512)
%
%   INPUTS:
%     file_path        - Root path containing 'png/1bit/' folder with 1-bit frames
%     desired_bitdepth - Desired bit depth for output images (e.g., 4, 8, etc.)
%     cam_type         - '512S' or 'SS2TH' (to set image dimensions)
%     num_images       - (Optional) Number of output images to generate (0 = auto)
%   
%   NOTE:
%       Prior to use this script, 1bit frames need to be exported from .BIN
%       into .png frames using export_spad_frames().
%
%   EXAMPLE:
%     digitize_from_1bit('./SPAD/noon-on/50.0us', 8, '512S', 0)
%
%   Author: David Rodríguez (https://github.com/drodriguezSRL)
%   Last updated: 2025-06-16

    disp("Reading directory...⏳")

    if nargin < 4
        num_images = 0; % default: auto
    end
    
    if ~isfolder(file_path)
        error('❌ Input path "%s" does not exist.', file_path);
    end

    % Camera-specific resolution
    switch upper(cam_type)
        case '512S'
            no_rows = 512;
            no_cols = 512;
        case 'SS2TH'
            no_rows = 256;
            no_cols = 512;
        otherwise
            error('❌ Unsupported camera type: %s. Use "512S" or "SS2TH".', cam_type);
    end

    frames_per_img = 2^desired_bitdepth - 1; % e.g., 15 for 4-bit, 255 for 8-bit

    src_dir = fullfile(file_path,'png','1bit');

    if ~isfolder(src_dir)
        error('❌ Source directory "%s" does not exist. Run export_spad_frames() first.', src_dir);
    end

    content = dir(fullfile(src_dir, '*.png'));
    totnum_frames = numel(content);

    if totnum_frames < frames_per_img
        error('❌ Not enough 1-bit frames to build one %d-bit image.', desired_bitdepth);
    end

    if num_images == 0
        num_images = floor(totnum_frames / frames_per_img);
    end

    fprintf('[INFO] %d total 1bit frames found.\n', totnum_frames);
    fprintf('[INFO] %d %d-bit images will be digitized.\n', num_images, desired_bitdepth);
    
    % Output directory
    new_Pdir = fullfile(file_path, 'png', sprintf('%dbit', desired_bitdepth));
    if ~isfolder(new_Pdir)
        mkdir(new_Pdir);
    end

    colormap_nbit = gray(frames_per_img); % Generates a n-level grayscale colormap required for saving n-bit PNGs lower than 8-bit
    
    % Frame processing
    % Images will be exported 1 by 1 based on the desired_bitdepth.
    % This means that if 8-bit is selected, 256 1-bit frames will be read at a time
    wait_msg = sprintf('Saving %d-bit images...💾', desired_bitdepth);
    f = waitbar(0, wait_msg);

    frame_num = 1;
    subarray = zeros(frames_per_img, no_rows, no_cols);
     
    for i = 1:num_images
        waitbar(i/num_images,f,sprintf('Processing image %d/%d...💾', i, num_images));
    
        if i == 1
            disp('[INFO] Estimating processing time...')
            tic;
        elseif i == 2
            time1img = toc;
            digitize_time = time1img*num_images;
            dt_hours = floor(digitize_time / 3600);
            dt_rest = mod(digitize_time, 3600);
            dt_min = ceil(dt_rest / 60);
            digitize_time = sprintf('%02dh:%02dm', dt_hours, dt_min);
            disp(['[INFO] Estimated total processing time: ', digitize_time]);
        end
    
        for j = 1:frames_per_img
            if frame_num > totnum_frames
                warning('⚠️ Ran out of 1-bit frames earlier than expected.');
                break;
            end

            file_name = content(frame_num).name;
            full_file = fullfile(src_dir,file_name); 
    
            frame = imread(full_file);
    
            subarray(j,:,:) = frame; 
            
            frame_num = frame_num + 1; 
        end
        
        % Sum up frames to create n-bit image
        img = squeeze(sum(uint16(subarray),1)); 
    
        % Extract timestamp from last frame
        pattern = '_(\d+\.\d+)_'; % e.g. 1726830927.999999046
        tokens = regexp(file_name, pattern, 'tokens');
        
        if ~isempty(tokens)
            timestamp = strcat(tokens{1}{1});
        else
            timestamp = sprintf('unknown_%d', i); 
            disp('[WARNING] Timestamp appears to be empty.');
        end
        
        % Save PNG
        png_file_name = sprintf('spad%d_%s.png', desired_bitdepth, timestamp); 
        png_file_path = fullfile(new_Pdir, png_file_name);
        imwrite(img, colormap_nbit, png_file_path,'png');
        
        % For <8-bit images, avoid frame overlap
        if desired_bitdepth ~= 8 
            frame_num = frame_num + (256 - frames_per_img);
        end
    end
    close(f);
    disp('✅ All images were successfully digitized')
end
