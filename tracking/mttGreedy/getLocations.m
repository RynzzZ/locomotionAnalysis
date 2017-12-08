

% performs paw tracking

% settings
session = 'C:\Users\rick\Google Drive\columbia\obstacleData\sessions\171202_000\';
classifierBot = 'C:\Users\rick\Google Drive\columbia\obstacleData\svm\classifiers\pawBotMarker.mat';
classifierTop = 'C:\Users\rick\Google Drive\columbia\obstacleData\svm\classifiers\pawTopMarker.mat';
xMapping = 'C:\Users\rick\Desktop\github\locomotionAnalysis\xAlignment\xLinearMapping.mat';
showPotentialLocations = true;
fs = 250;

% initializations
load(xMapping, 'xLinearMapping');
load(classifierTop, 'model', 'subHgt', 'subWid');
modelTop = model;
load(classifierBot, 'model', 'subHgt', 'subWid');
modelBot = model;
load([session 'runAnalyzed.mat'], 'obsPixPositions', 'frameTimeStamps', 'rewardTimes')
if ~exist([session '\tracking'], 'dir'); mkdir([session '\tracking']); end
vidBot = VideoReader([session '\runBot.mp4']);
vidTop = VideoReader([session '\runTop.mp4']);
startFrame = find(frameTimeStamps>rewardTimes(1), 1, 'first');
anchorPtsBot = {[0 0], [0 1], [1 0], [1 1]};



%% hand label paw locations

vidFile = 'C:\Users\rick\Google Drive\columbia\obstacleData\sessions\171202_000\runBot.mp4';
vid = VideoReader(vidFile);
frameInds = 1:vid.NumberOfFrames;
labelPawLocations('C:\Users\rick\Google Drive\columbia\obstacleData\sessions\171202_000\runBot.mp4', frameInds, 500);

%% create labeled set
makeLabeledSet2('pawBot',...
                'C:\Users\rick\Google Drive\columbia\obstacleData\sessions\171202_000\tracking\runBotHandLabeledLocations.mat', ...
                'C:\Users\rick\Google Drive\columbia\obstacleData\sessions\171202_000\runBot.mp4')

viewTrainingSet('pawBot');

%% train svm

tic; trainSVM('pawBot'); toc/60


%% get potential locations for bottom
tic
close all
potentialLocationsBot = getPotentialLocationsBot(vidBot, modelBot, subHgt, subWid, obsPixPositions, startFrame, false);
save([session 'tracking\potentialLocationsBot.mat'], 'potentialLocationsBot');
toc

%% get locations for bottom
locationsBot = getLocationsBot(potentialLocationsBot, frameTimeStamps, vidBot.Width, vidBot.Height);
save([session 'tracking\locationsBot.mat'], 'locationsBot');
% showLocations(vidBot, potentialLocationsBot, locationsBot, showPotentialLocations, .02, anchorPtsBot, startFrame);

%% get potential locations for top
tic
potentialLocationsTop = getPotentialLocationsTop(vidTop, locationsBot, xLinearMapping, modelTop, subHgt, subWid, startFrame, false);
toc
save([session 'tracking\potentialLocationsTop.mat'], 'potentialLocationsTop');

% get locations for top
locationsTop = getLocationsTop(potentialLocationsTop, locationsBot, obsPixPositions, frameTimeStamps, fs);
showLocations(vidTop, potentialLocationsTop, locationsTop, showPotentialLocations, .02, anchorPtsBot, 200000);

%% make tracking vid
frameInds = find(~isnan(obsPixPositions));
makeTrackingVid(session, frameInds)




