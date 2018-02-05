
% perform paw tracking for multiple sessions

sessionDirs = uigetdir2([getenv('OBSDATADIR') 'sessions\'], 'select folders to analyze');
%%
steps = {'potTop', 'top'};
minVel = .4;

for i = 1:length(sessionDirs)
    
    % get locations
    nameInd = find(sessionDirs{i}=='\',1,'last');
    try
        getLocations(sessionDirs{i}(nameInd+1:end), steps, minVel, false);
    catch
        fprintf('FAILED TO ANALYZE %s\n', sessionDirs{i}(nameInd+1:end));
    end
    
end

%% test getLocations on single session

session = '180122_000';
steps = {'potTop'};

showTracking = true;
minVel = .4; % minVel only applies to potentialLocationsBot analysis // subsequent stages analyze whatever has already been analyzed in potentialLocationsBot
getLocations(session, steps, minVel, showTracking);

%% show tracking for session

% settings
session = '180122_000';
view = 'Top';
showCorrected = 0;
frameDelay = .04;

load([getenv('OBSDATADIR') 'sessions\' session '\tracking\potentialLocations' view '.mat'])
if showCorrected
    load([getenv('OBSDATADIR') 'sessions\' session '\tracking\locations' view 'Corrected.mat'])
    locationsTemp = locations.locationsCorrected;
else
    load([getenv('OBSDATADIR') 'sessions\' session '\tracking\locations' view '.mat'])
    locationsTemp = fixTracking(locations.locationsRaw, locations.trialIdentities);
end

vid = VideoReader([getenv('OBSDATADIR') 'sessions\' session '\run' view '.mp4']);
anchorPtsBot = {[0 0], [1 0], [1 1], [0 1]}; % LH, LF, RF, RH // each entry is x,y pair measured from top left corner


showLocations(vid, find(locations.isAnalyzed), eval(['potentialLocations' view]), ...
    locationsTemp, locations.trialIdentities, 1, frameDelay, anchorPtsBot, hsv(4));

%% exclude trials

session = '180123_000';
trials = [];

setTrialExclusion(session, trials);


%% correct tracking

% settings
session = '180123_000';
view = 'Bot';
frameDelay = .025;

outputFile = [getenv('OBSDATADIR') 'sessions\' session '\tracking\locations' view 'Corrected.mat'];
if exist(outputFile, 'file')
    load(outputFile, 'locations')
else
    load([getenv('OBSDATADIR') 'sessions\' session '\tracking\locations' view '.mat'], 'locations')
end

vid = VideoReader([getenv('OBSDATADIR') 'sessions\' session '\run' view '.mp4']);
frameInds = find(locations.isAnalyzed);
anchorPts = {[0 0], [1 0], [1 1], [0 1]}; % LH, LF, RF, RH

correctTracking(outputFile, vid, locations, frameInds, frameDelay, anchorPts);

%% get avg trial stats

sessionDirs = uigetdir2([getenv('OBSDATADIR') 'sessions\'], 'select folders to analyze');
avgFramesPerTrial = nan(1,length(sessionDirs));

for i = 1:length(sessionDirs)
    
    % get locations
    nameInd = find(sessionDirs{i}=='\',1,'last');
    session = sessionDirs{i}(nameInd+1:end);
    load([getenv('OBSDATADIR') 'sessions\' session '\tracking\velocityInfo.mat'], 'trialVels')
    load([getenv('OBSDATADIR') 'sessions\' session '\tracking\locationsBot.mat'], 'locations')
    avgFramesPerTrial(i) = sum(locations.isAnalyzed) / length(trialVels);
    
end



