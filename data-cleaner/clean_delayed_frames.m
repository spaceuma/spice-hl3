close all; clear all; clc;

img_dir = '.\trajectory_G\stereo\left';
img_files = dir(fullfile(img_dir, '*.png')); % Adjust the file extension as needed

ids = zeros(length(img_files), 1); 
times = zeros(length(img_files),1);

% Loop through the files and extract the IDs
for i = 1:length(img_files)

    [~, name, ~] = fileparts(img_files(i).name); % Extract name without extension
    
    % find the numeric ID
    id_str = regexp(name, '_(\d+)$', 'tokens'); % Match the pattern *_IDnumber

    % Use regular expression to find the numeric timestamp [uncomment if
    % needed]
    pattern = 'stereo_left_([\d]+\.[\d]+)_\d+';
    %pattern = 'stereo_right_([\d]+\.[\d]+)_\d+';
    time_str = regexp(name, pattern, 'tokens');

    if ~isempty(id_str)
        times(i) = str2double(time_str{1}{1}); % Convert the extracted timestamp to a number
        ids(i) = str2double(id_str{1}{1}); % convert extracted id to a number
    else
        warning('ID not found in file name: %s', img_files(i).name);
    end
end

% Combine the files and IDs into a table for easier sorting
file_data = table({img_files.name}', ids, times, 'VariableNames', {'FileName', 'ID','Timestamps'});

% Sort the table by the ID or timestamp column
%sorted_table = sortrows(file_data, 'ID'); % by ID
sorted_table = sortrows(file_data, 'Timestamps'); % by timestamp
sorted_files = sorted_table.FileName;

%writecell(sorted_files, 'C:\Users\david\Desktop\animations\trajectory_F_sorted.csv');

%% Problem of delayed frames

% ID delayed frames
[sorted_ids, sort_idx] = sort(ids);
sorted_times_by_ids = times(sort_idx);

% check if times are increasing
times_diff = diff(sorted_times_by_ids);

% filter only positive diferences 
positive_diffs = times_diff(times_diff>0);
avg_time_per_frame = mean(positive_diffs); % average time per frame
med_time_per_frame = median(positive_diffs); % median time per frame

% find delayed frames
delay_flags = [times_diff < 0];
problematic_ids = sorted_ids(delay_flags);

% correct timestamps by interpolation
corrected_times = sorted_times_by_ids;
to_be_deleted = 0;
delete_files = zeros(size(times,1),1);

for i = 2:(length(sorted_times_by_ids)-1)
    if delay_flags(i)
        %fprintf('\n Delayed frame: %d', sorted_ids(i))
        %fprintf('\nOriginal timestamp associated with frame %d: %f', sorted_ids(i), sorted_times_by_ids(i))
        corrected_times(i) = corrected_times(i-1) + med_time_per_frame;
        %fprintf('\nNew corrected timestamp: %f', corrected_times(i))

        next_time_diff = corrected_times(i+1)-corrected_times(i);
        if next_time_diff < 0
            %fprintf('\n \nISSUE!\nNext time difference: %f ', corrected_times(i+1)-corrected_times(i))
            %fprintf('\nTimestamp associated with frame %d: %f \n', sorted_ids(i+1), corrected_times(i+1))
            to_be_deleted = to_be_deleted + 1;
            delete_files(i+1) = 1;
        end
    end
end

delete_flags = [delete_files > 0];
delete_files_ids = sorted_ids(delete_flags);

fprintf('\nNumber of frames %d', length(times))
fprintf('\nAverage time per frame %f ms', avg_time_per_frame*1e3)
fprintf('\nMedian time per frame %f ms', med_time_per_frame*1e3)
fprintf('\nFrame rate %f Hz', 1/med_time_per_frame)
fprintf('\nNumber of problematic frames %d/%d', length(problematic_ids),length(times))
fprintf('\nThat is a total of %f frames', 100*length(problematic_ids)/length(times))
fprintf('\nNumber of frames still need to be deleted: %d frames (%f)\n', to_be_deleted, 100*to_be_deleted/length(times))

%% Correct file names

id_to_corrected_time = containers.Map(sorted_ids, corrected_times);
counter = 0;

% Loop through original files to rename problematic ones
for i = 1:height(file_data)
    file_id = file_data.ID(i);
    
    % If this is a problematic ID
    if ismember(file_id, problematic_ids)
        old_name = file_data.FileName{i};
        old_full_path = fullfile(img_dir, old_name);
        
        % Get the corrected timestamp
        new_time = id_to_corrected_time(file_id);
        
        % Reconstruct new filename with interpolated timestamp
        % Assuming filename format: stereo_left_<timestamp>_<id>.png
        new_name = sprintf('stereo_left_%.6f_%d.png', new_time, file_id);
        %new_name = sprintf('stereo_right_%.6f_%d.png', new_time, file_id);
        new_full_path = fullfile(img_dir, new_name);

        % Rename the file
        movefile(old_full_path, new_full_path);
        fprintf('Renamed %s --> %s\n', old_name, new_name);
    elseif ismember(file_id, delete_files_ids)
        file_name = file_data.FileName(i);
        file_path = fullfile(img_dir, file_name{1});

        % Remove remaining delayed files
        fprintf('Deleting delayed  file: %s\n', file_name{1});
        delete(file_path);
        counter = counter + 1;
    end
end

fprintf('\nTotal number of frames deleted: %d frames (%f)\n', counter, 100*counter/length(times))

%% Quality Check
new_img_files = dir(fullfile(img_dir, '*.png'));

new_ids = zeros(length(new_img_files), 1); % Preallocate for performance
new_times = zeros(length(new_img_files),1);

% Loop through the files and extract the IDs
for i = 1:length(new_img_files)
    % Get the file name
    [~, name, ~] = fileparts(new_img_files(i).name); % Extract name without extension
    
    % Use regular expression to find the numeric ID
    id_str = regexp(name, '_(\d+)$', 'tokens'); % Match the pattern *_IDnumber

    % Use regular expression to find the numeric timestamp [uncomment if
    % needed]
    pattern = 'stereo_left_([\d]+\.[\d]+)_\d+';
    %pattern = 'stereo_right_([\d]+\.[\d]+)_\d+';
    time_str = regexp(name, pattern, 'tokens');

    if ~isempty(id_str)
        new_times(i) = str2double(time_str{1}{1}); % Convert the extracted timestamp to a number
        new_ids(i) = str2double(id_str{1}{1}); % convert extracted id to a number
    else
        warning('\nID not found in file name: %s', new_img_files(i).name);
    end
end

new_file_data = table({new_img_files.name}', new_ids, new_times, 'VariableNames', {'FileName', 'ID','Timestamps'});

% Sort the table by the ID or timestamp column
%sorted_table = sortrows(file_data, 'ID'); % by ID
sorted_table = sortrows(new_file_data, 'Timestamps'); % by timestamp
sorted_files = sorted_table.FileName;
sorted_files = struct('name', sorted_files);
frameIDs = zeros(length(sorted_files), 1);

% Extract frame IDs
for i = 1:length(sorted_files)
    tokens = regexp(sorted_files(i).name, '_(\d+)\.png$', 'tokens');
    if ~isempty(tokens)
        frameIDs(i) = str2double(tokens{1}{1});
    else
        error('\nInvalid filename format at line %d: %s', i, fileNames(i));
    end
end

% Check for misordered IDs
misorderedIdx = find(diff(frameIDs) <= 0);
if isempty(misorderedIdx)
    fprintf('\nSUCCESS!!! All frame IDs are in strictly increasing order.\n');
    %writecell(sorted_files, 'C:\Users\david\Downloads\trajectory_F\stereo\left\data.csv');
else
    fprintf('\nMisordered frame IDs detected at line(s):\n');
    for idx = misorderedIdx'
        fprintf('\nLine %d: ID %d followed by Line %d: ID %d\n', ...
            idx, frameIDs(idx), idx+1, frameIDs(idx+1));

        file_name = new_file_data.FileName(idx);
        file_path = fullfile(img_dir, file_name{1});
        
        fprintf('Deleting file...\n')

        % Remove remaining delayed files
        delete(file_path);
        counter = counter + 1;
    end
    new_file_data = table({new_img_files.name}', new_ids, new_times, 'VariableNames', {'FileName', 'ID','Timestamps'});
    % Sort the table by the ID or timestamp column
    %sorted_table = sortrows(file_data, 'ID'); % by ID
    sorted_table = sortrows(new_file_data, 'Timestamps'); % by timestamp
    sorted_files = sorted_table.FileName;
    %writecell(sorted_files, 'C:\Users\david\Downloads\trajectory_F\stereo\left\data.csv');
end

fprintf('\nFinal number of frames deleted: %d frames (%f)\n', counter, 100*counter/length(times))