function digitize_from_4bit(file_path, desired_bitdepth, num_images)
% DIGITIZE_FROM_4BIT - Build n-bit grayscale images from 4-bit SPAD PNG
% frames.

%   digitize_from_4bit(file_path, desired_bitdepth, num_images)
%
%   INPUTS:
%     file_path        - Path containing 'png/4bit/' folder with 4-bit PNGs
%     desired_bitdepth - Desired bit depth for output images (must be >4)
%     num_images       - (Optional) Number of output images (0 = auto)
%   
%   NOTES:
%     - Works with 4-bit iamges as input.
%     - Requires input images to follow naming with timestamp pattern
%     - Output saved in `.../png/[desired_bitdepth]/`
%
%   EXAMPLE:
%     digitize_from_4bit('./SPAD/noon-on/50.0us', 8, 0)
%
%   Author: David Rodríguez (https://github.com/drodriguezSRL)
%   Last updated: 2025-06-16

    DEFAULT_BIT_DEPTH_IN = 4;
    no_rows=512;
    no_cols=512;

    if nargin < 3
        num_images = 0; % auto
    end
    
    if desired_bitdepth < DEFAULT_BIT_DEPTH_IN
        error('❌ Desired bit depth (%d) cannot be less than input bit depth (%d).', desired_bitdepth, DEFAULT_BIT_DEPTH_IN);
    end

    disp("Reading directory...⏳")

    if ~isfolder(file_path)
        error('❌ Input path "%s" does not exist.', file_path);
    end

    src_dir = fullfile(file_path,'png','4bit');
    content = dir(fullfile(src_dir, '*.png'));
    totnum_frames = numel(content);

    frames_per_img = (2^desired_bitdepth)/(2^DEFAULT_BIT_DEPTH_IN);

   
    if num_images == 0
        num_images = totnum_frames/frames_per_img;
    end

    fprintf('[INFO] %d total 4bit images found.\n', totnum_frames);
    fprintf('[INFO] %d %d-bit images will be digitized.\n', num_images, desired_bitdepth);

    % Output directory
    new_Pdir = fullfile(file_path, 'png', sprintf('%dbit', desired_bitdepth));
    if ~isfolder(new_Pdir)
        mkdir(new_Pdir);
    end

    colormap_nbit = gray(2^desired_bitdepth); 

    % Frame processing
    % Images will be exported 1 by 1 based on the desired_bitdepth.
    % This means that if 8-bit is selected, 16 4-bit images will be read at a time

    wait_msg = sprintf('Saving %d-bit images...💾', desired_bitdepth);
    f = waitbar(0, wait_msg);

    frame_num = 1;
    subarray = zeros(frames_per_img, no_rows, no_cols); 
     
    for i = 1:num_images
        waitbar(i/num_images,f,sprintf('Processing image %d/%d...💾', i, num_images));
    
        if i == 1
            disp('[INFO] Estimating total digitization time...')
            tic;
        elseif i == 2
            time1img = toc;

            digitize_time = time1img*num_images;
            dt_hours = floor(digitize_time / 3600);
            dt_rest = mod(digitize_time, 3600);
            dt_min = ceil(dt_rest / 60);
            digitize_time = sprintf('%02dh:%02dm', dt_hours, dt_min);
            disp(['[INFO] Estimated time to digitize requested images: ', digitize_time]);
        end
    
        for j = 1:frames_per_img
            file_name = content(frame_num).name;
            full_file = fullfile(src_dir,file_name); 
    
            frame = imread(full_file);
            
            subarray(j,:,:) = frame; 
    
            frame_num = frame_num + 1; 
        end
        
        % Sum up frames to create n-bit image
        img = squeeze(sum(uint16(subarray),1)); 
    
        % Define what info from original file names you would like to extract 
        % and used as part of the the new file names.
 
        pattern = '_(\d+\.\d+)_'; % e.g. 1726830927.999999046
        tokens = regexp(file_name, pattern, 'tokens'); 
        
        if ~isempty(tokens)
            timestamp = strcat(tokens{1}{1}); 
        else
            timestamp = sprintf('unknown_%d', i); 
            disp('[WARNING] Timestamp appears to be empty.');
        end
        
        % Save n-bit PNG file
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
