
% perform paw tracking for multiple sessions

sessionDirs = uigetdir2([getenv('OBSDATADIR') 'sessions\'], 'select folders to analyze');
steps = {'bot'};
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

session = '180123_002';
steps = {'bot'};
minVel = .6;
getLocations(session, steps, minVel, false);

%% show tracking for session

% settings
session = '180122_002';
showCorrected = 1;

load([getenv('OBSDATADIR') 'sessions\' session '\tracking\potentialLocationsBot.mat'])
if showCorrected
    load([getenv('OBSDATADIR') 'sessions\' session '\tracking\locationsBotCorrected.mat'])
    locationsTemp = locations.locationsCorrected;
else
    load([getenv('OBSDATADIR') 'sessions\' session '\tracking\locationsBot.mat'])
    locationsTemp = fixTrackinn(locations.locationsRaw, locations.trialIdentities);
end

vidBot = VideoReader([getenv('OBSDATADIR') 'sessions\' session '\runBot.mp4']);
anchorPtsBot = {[0 0], [1 0], [1 1], [0 1]}; % LH, LF, RF, RH // each entry is x,y pair measured from top left corner

showLocations(vidBot, find(locations.isAnalyzed), potentialLocationsBot, ...
    locationsTemp, locations.trialIdentities, 0, .02, anchorPtsBot, hsv(4));

%% exclude trials

session = '180122_002';
trials = [37 58 69];
isExcluded = [1 1 1];

load([getenv('OBSDATADIR') 'sessions\' session '\tracking\locationsBotCorrected.mat'], 'locations')
locations.isExcluded = setTrialExclusion(locations.isExcluded, locations.trialIdentities, trials, isExcluded);
save([getenv('OBSDATADIR') 'sessions\' session '\tracking\locationsBotCorrected.mat'], 'locations')



%% correct tracking

% settings
session = '180122_002';
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
%%
avgFramesPerTrial = nan(1,length(sessionDirs));

for i = 1:length(sessionDirs)
    
    % get locations
    nameInd = find(sessionDirs{i}=='\',1,'last');
    session = sessionDirs{i}(nameInd+1:end);
    load([getenv('OBSDATADIR') 'sessions\' session '\tracking\velocityInfo.mat'], 'trialVels')
    load([getenv('OBSDATADIR') 'sessions\' session '\tracking\locationsBot.mat'], 'locations')
    avgFramesPerTrial(i) = sum(locations.isAnalyzed) / length(trialVels);
    
end



