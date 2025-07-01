close all; clear all; clc;
% Set folder paths
targetFolder = 'C:\Users\david\Downloads\trajectory_G\stereo\right';
refFolder = 'C:\Users\david\Downloads\trajectory_G\stereo\left';

% Get list of left and right files
targetFiles = dir(fullfile(targetFolder, 'stereo_right_*.png'));
refFiles = dir(fullfile(refFolder, 'stereo_left_*.png'));

% Create a map for reference image timestamps to filenames
refTimestamps = containers.Map();
for i = 1:length(refFiles)
    name = refFiles(i).name;
    % Extract timestamp from filename
    %tokens = regexp(name, 'stereo_right_(\d+\.\d+)_\d+\.png', 'tokens');
    tokens = regexp(name, 'stereo_left_(\d+\.\d+)_\d+\.png', 'tokens');
    if ~isempty(tokens)
        timestamp = tokens{1}{1};
        refTimestamps(timestamp) = name;
    end
end

counter = 0;
% Process target files
for i = 1:length(targetFiles)
    targetName = targetFiles(i).name;
    targetPath = fullfile(targetFolder, targetName);
    
    % Extract timestamp and frame ID from left file
    %tokens = regexp(targetName, 'stereo_left_(\d+\.\d+)_(\d+)\.png', 'tokens');
    tokens = regexp(targetName, 'stereo_right_(\d+\.\d+)_(\d+)\.png', 'tokens');
    if isempty(tokens)
        fprintf('Skipping malformed file: %s\n', targetName);
        continue;
    end
    
    targetTimestamp = tokens{1}{1};
    targetFrameID = tokens{1}{2};
    
    if isKey(refTimestamps, targetTimestamp)
        % Check frame ID of the matching right file
        refName = refTimestamps(targetTimestamp);
        %tokensRef = regexp(refName, 'stereo_right_(\d+\.\d+)_(\d+)\.png', 'tokens');
        tokensRef = regexp(refName, 'stereo_left_(\d+\.\d+)_(\d+)\.png', 'tokens');
        refFrameID = tokensRef{1}{2};
        
        if ~strcmp(targetFrameID, refFrameID)
            fprintf('Warning: Frame ID mismatch for timestamp %s (target: %s, ref: %s)\n', ...
                targetTimestamp, targetFrameID, refFrameID);
        end
    else
        % Delete unmatched target file
        fprintf('Deleting unmatched target file: %s\n', targetName);
        delete(targetPath);
        counter = counter + 1;
    end
end

fprintf('Total number of deleted files from target: %d\n', counter)