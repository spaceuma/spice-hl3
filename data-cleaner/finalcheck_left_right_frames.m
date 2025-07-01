%% Left vs Right frame consistency check
% Define left and right image directories
leftDir = 'C:\Users\david\Downloads\trajectory_G\stereo\left';   % <- Change this
rightDir = 'C:\Users\david\Downloads\trajectory_G\stereo\right'; % <- Change this

% Get file lists
leftFiles = dir(fullfile(leftDir, 'stereo_left_*.png'));
rightFiles = dir(fullfile(rightDir, 'stereo_right_*.png'));

% Sort both lists by filename (assumes timestamps are ordered)
[~, leftIdx] = sort({leftFiles.name});
[~, rightIdx] = sort({rightFiles.name});
leftFiles = leftFiles(leftIdx);
rightFiles = rightFiles(rightIdx);

% Check if the number of files is equal
if length(leftFiles) ~= length(rightFiles)
    error('Mismatch in number of files: Left = %d, Right = %d', length(leftFiles), length(rightFiles));
end

% Compare each file pair
for i = 1:length(leftFiles)
    leftName = leftFiles(i).name;
    rightName = rightFiles(i).name;

    % Extract timestamp and frame ID from left file
    leftMatch = regexp(leftName, 'stereo_left_(\d+\.\d+)_(\d+)\.png', 'tokens');
    rightMatch = regexp(rightName, 'stereo_right_(\d+\.\d+)_(\d+)\.png', 'tokens');

    if isempty(leftMatch) || isempty(rightMatch)
        error('Filename format mismatch: %s or %s', leftName, rightName);
    end

    leftTimestamp = leftMatch{1}{1};
    leftID = leftMatch{1}{2};

    rightTimestamp = rightMatch{1}{1};
    rightID = rightMatch{1}{2};

    % Check if timestamp and ID match
    if ~strcmp(leftTimestamp, rightTimestamp) || ~strcmp(leftID, rightID)
        error('Mismatch at index %d:\n Left:  %s\n Right: %s', i, leftName, rightName);
    end
end

disp('✅ All timestamps and frame IDs match between left and right folders.');

%% Timestamp vs Frame ID consistency check
leftDir = 'C:\Users\david\Downloads\trajectory_F\stereo\left';   % <- Change this
rightDir = 'C:\Users\david\Downloads\trajectory_F\stereo\right'; % <- Change this

% Get file lists
leftFiles = dir(fullfile(leftDir, 'stereo_left_*.png'));
rightFiles = dir(fullfile(rightDir, 'stereo_right_*.png'));

% Sort by filename (timestamps embedded in name)
[~, sortIdx] = sort({leftFiles.name});
leftFiles = leftFiles(sortIdx);
[~, sortIdx] = sort({rightFiles.name});
rigthFiles = rightFiles(sortIdx);

% Initialize arrays for timestamps and frame IDs
leftTimestamps = zeros(length(leftFiles), 1);
leftframeIDs = zeros(length(leftFiles), 1);
rightTimestamps = zeros(length(rightFiles), 1);
rightframeIDs = zeros(length(rightFiles), 1);

for i = 1:length(leftFiles)
    leftName = leftFiles(i).name;
    leftTokens = regexp(leftName, 'stereo_left_(\d+\.\d+)_(\d+)\.png', 'tokens');

    if isempty(leftTokens)
        error('Filename does not match expected pattern: %s', leftName);
    end

    leftTimestamps(i) = str2double(leftTokens{1}{1});
    leftframeIDs(i) = str2double(leftTokens{1}{2});
end

for i = 1:length(rightFiles)
    rightName = rightFiles(i).name;
    rightToken = regexp(rightName, 'stereo_right_(\d+\.\d+)_(\d+)\.png', 'tokens');

    if isempty(rightToken)
        error('Filename does not match expected pattern: %s', rightName);
    end

    rightTimestamps(i) = str2double(rightToken{1}{1});
    rightframeIDs(i) = str2double(rightToken{1}{2});
end


% Check if timestamps are strictly increasing
if any(diff(leftTimestamps) <= 0)
    warning('Left camera timestamps are not strictly increasing.');
elseif any(diff(rightTimestamps) <= 0)
    warning('Right camera timestamps are not strictly increasing.');
else
    disp('✅ Both camera timestamps are strictly increasing.');
end

% Check if frameIDs are strictly increasing
if any(diff(leftframeIDs) <= 0)
    warning('Left frame IDs are not strictly increasing.');
elseif any(diff(rightframeIDs) <= 0)
    warning('Right frame IDs are not strictly increasing.');
else
    disp('✅ Borth camera frame IDs are strictly increasing.');
end

% Check if timestamps and frameIDs increase together
if ~issortedrows([leftTimestamps leftframeIDs])
    warning('Left camera timestamps and frame IDs are not increasing together consistently.');
elseif ~issortedrows([rightTimestamps rightframeIDs])
    warning('Right camera timestamps and frame IDs are not increasing together consistently.');
else
    disp('✅ Frame IDs are consistent with increasing timestamps in both cameras.');
end
