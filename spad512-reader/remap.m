function remap(img_path, output_dir)
% REMAP - Remaps 4bit frames to 8bit colormap PNGs.
%
%   remap(img_path)
%
%   Parameters:
%     img_path  - Full path to the directory containing 4bit images
%     output_dir - Full path to the output directory for PNG images
%
%   Example:
%     remap('C:\Data\Acquisition1\png\4bit', 'C:\Data\PNGOutput')
%
%   Author: David Rodríguez (https://github.com/drodriguezSRL)
%   Last updated: 2025-06-16
    
    DEFAULT_BIT_DEPTH_OUT = 8;
    MEMORY_THRESHOLD = 0.5;

    if nargin < 2
        output_dir = fullfile(img_path, 'remap');
    end

    disp("Reading directory...⏳")

    if ~isfolder(img_path) 
        error('❌ Input directory "%s" does not exist.', file_path);
    end

    img_files = dir(fullfile(img_path, '*.png')); 
    num_imgs = numel(img_files);
    first_img = imread(fullfile(img_path, img_files(1).name));
    
    % Threshold for memory usage in bytes (e.g., use 50% of available memory)
    memory_threshold = MEMORY_THRESHOLD * check_memory();
    
    colormap_8bit = gray(2^DEFAULT_BIT_DEPTH_OUT);
    
    img_array = first_img;
    
    if ~exist(output_dir, 'dir')
        mkdir(output_dir);
    end
    
    disp("[INFO] Building array of images...hold on")
    k = 1;
    batch_size = 100;
    for i = 100:batch_size:num_imgs
        img = imread(fullfile(img_path, img_files(i).name));
    
        img_array = cat(3, img_array, img); 
    
        if whos('img_array').bytes > memory_threshold
            disp("[WARNING] Ouchy, we went over the memory threshold...wait a sec while I free up some ")
    
            img_array = uint8(img_array .* 16);  
    
            for j = 1:size(img_array,3)
                disp("[INFO] I'm gonna have to remapped some images first...")
                
                png_file_name = img_files(k).name;
                png_file_path = fullfile(output_dir, png_file_name);
                imwrite(img_array(:,:,j), colormap_8bit, png_file_path,'png');
    
                k = k + batch_size;
            end
    
            clear img_array;
            img_array = [];
    
            disp("[INFO] Ok, we are back in business!")
        end
    end
    
    disp("[INFO] Saving the rest of remapped images...💾")
    
    if ~isempty(img_array)
        img_array = uint8(img_array .* 16); 
        for j = 1:size(img_array,3)          
            png_file_name = img_files(k).name;
            png_file_path = fullfile(output_dir, png_file_name);
            imwrite(img_array(:,:,j), colormap_8bit, png_file_path,'png');
            
            k = k + batch_size;
        end
    end
    disp("✅ I'm all done!")
    
    function available_memory = check_memory()
        [~, systemview] = memory();
        available_memory = systemview.PhysicalMemory.Available;
    end
end