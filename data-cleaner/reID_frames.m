% Define the folder containing the images
imageFolder = 'C:\Users\david\Downloads\trajectory_F\stereo\left'; % <- Change this to your actual folder path

% Get list of image files matching the pattern
imageFiles = dir(fullfile(imageFolder, 'stereo_left_*.png'));
%imageFiles = dir(fullfile(imageFolder, 'stereo_right_*.png'));

% Sort files by name (assumes names are timestamp-ordered)
[~, sortedIdx] = sort({imageFiles.name});
imageFiles = imageFiles(sortedIdx);

counter = 0;
% Rename files with new frame IDs starting from 0
for newID = 0:length(imageFiles)-1
    oldName = imageFiles(newID + 1).name;
    
    % Extract timestamp

    tokens = regexp(oldName, 'stereo_left_(\d+\.\d+)_(\d+)\.png', 'tokens');
    %tokens = regexp(oldName, 'stereo_right_(\d+\.\d+)_(\d+)\.png', 'tokens');
    
    oldID = tokens{1}{2};
    if isempty(tokens)
        warning('Filename does not match pattern: %s', oldName);
        continue;
    end
    timestamp = tokens{1}{1};
    
    % Build new filename
    if ~strcmp(oldID, string(newID))
        newName = sprintf('stereo_left_%s_%d.png', timestamp, newID);
        %newName = sprintf('stereo_right_%s_%d.png', timestamp, newID);
    
        % Perform renaming
        movefile(fullfile(imageFolder, oldName), fullfile(imageFolder, newName));
        counter = counter + 1;
    end
end

disp('Renaming complete.');
fprintf("Total number of frames re-ID'ed: %d\n", counter )

