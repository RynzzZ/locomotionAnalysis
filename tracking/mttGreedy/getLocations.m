

% performs paw tracking

% settings
session = 'C:\Users\rick\Google Drive\columbia\obstacleData\sessions\171202_000\';
xMapping = 'C:\Users\rick\Desktop\github\locomotionAnalysis\xAlignment\xLinearMapping.mat';

% initializations
load(xMapping, 'xLinearMapping');
load([session 'runAnalyzed.mat'], 'obsPixPositions', 'frameTimeStamps', 'rewardTimes')
frameInds = find(~isnan(obsPixPositions));
anchorPtsBot = {[0 0], [0 1], [1 0], [1 1]};



%% hand label paw bot locations

vidFile = 'C:\Users\rick\Google Drive\columbia\obstacleData\sessions\171202_000\runBot.mp4';
vid = VideoReader(vidFile);
labelPawLocations(vidFile, frameInds, 500);


%% create bot labeled set, paw vs other

posEgs = 500;
negEgsPerEg = 5;
subFrameSize = [50 50];
includeLocation = false;
paws = 1:4;
class = 'pawBot';

makeLabeledSet(class,...
               'C:\Users\rick\Google Drive\columbia\obstacleData\sessions\171202_000\tracking\runBotHandLabeledLocations.mat', ...
               'C:\Users\rick\Google Drive\columbia\obstacleData\sessions\171202_000\runBot.mp4',...
               subFrameSize, obsPixPositions, posEgs, negEgsPerEg, includeLocation, paws)

viewTrainingSet(class);


%% train bot svm1

class = 'pawBot';

% train bot svm and reload
trainSVM(class);
load(['C:\Users\rick\Google Drive\columbia\obstacleData\svm\classifiers\' class], 'model', 'subFrameSize');

close all; figure; imagesc(reshape(-model.Beta, subFrameSize(1), subFrameSize(2)))

%% train bot second classifier

class = 'pawBot';

% train bot svm and reload
trainSecondClassifier(class); % this is saved as [class '2']


%% get bot potential locations


% settings
scoreThresh = 0;
showTracking = false;
model1 = 'C:\Users\rick\Google Drive\columbia\obstacleData\svm\classifiers\pawBot';
model2 = 'C:\Users\rick\Google Drive\columbia\obstacleData\svm\classifiers\pawBot2';

% initializations
load(model1, 'model', 'subFrameSize');
model1 = model; subFrameSize1 = subFrameSize;
load(model2, 'model', 'subFrameSize');
model2 = model; subFrameSize2 = subFrameSize;
vidBot = VideoReader([session '\runBot.mp4']);

tic; potentialLocationsBot = getPotentialLocationsBot(vidBot, model1, model2, subFrameSize1, subFrameSize2,...
                                                      scoreThresh, obsPixPositions, frameInds, showTracking);
save([session 'tracking\potentialLocationsBot.mat'], 'potentialLocationsBot');
fprintf('potential locations bot analysis time: %i minutes\n', toc/60)


%% get bot locations

% settings
showPotentialLocations = true;

% initializations
vidBot = VideoReader([session '\runBot.mp4']);

locationsBot = getLocationsBot(potentialLocationsBot, frameTimeStamps, vidBot.Width, vidBot.Height, frameInds);
save([session 'tracking\locationsBot.mat'], 'locationsBot');
showLocations(vidBot, frameInds, potentialLocationsBot, fixTracking(locationsBot), showPotentialLocations, .02, anchorPtsBot);


%% hand label top locations

vidFile = 'C:\Users\rick\Google Drive\columbia\obstacleData\sessions\171202_000\runTop.mp4';
vid = VideoReader(vidFile);
labelPawLocations(vidFile, frameInds, 200);


%% create top labeled set, paw vs other

posEgs = 400;
negEgsPerEg = 5;
subFrameSize = [40 40];
includeLocation = false;
paws = 1:4;
class = 'pawTop';

makeLabeledSet(class,...
               'C:\Users\rick\Google Drive\columbia\obstacleData\sessions\171202_000\tracking\runTopHandLabeledLocations.mat', ...
               'C:\Users\rick\Google Drive\columbia\obstacleData\sessions\171202_000\runTop.mp4',...
               subFrameSize, obsPixPositions, posEgs, negEgsPerEg, includeLocation, paws)

viewTrainingSet(class);


%% train top svm1

class = 'pawTop';

% train bot svm and reload
trainSVM(class);
load(['C:\Users\rick\Google Drive\columbia\obstacleData\svm\classifiers\' class], 'model', 'subFrameSize');

close all; figure; imagesc(reshape(-model.Beta, subFrameSize(1), subFrameSize(2)))

%% train top second classifier

class = 'pawTop';

% train bot svm and reload
trainSecondClassifier(class); % this is saved as [class '2']


%% get potential locations for top

% settings
scoreThresh = 1;
showTracking = false;
model = 'C:\Users\rick\Google Drive\columbia\obstacleData\svm\classifiers\pawTop';

% initializations
load(model, 'model', 'subFrameSize');
vidTop = VideoReader([session '\runTop.mp4']);

tic; potentialLocationsTop = getPotentialLocationsTop(vid, locationsBot, xLinearMapping, model, subFrameSize, scoreThresh,...
                                                      frameInds, showTracking);
save([session 'tracking\potentialLocationsTop.mat'], 'potentialLocationsTop');
fprintf('potential locations top analysis time: %i minutes\n', toc/60)

%% get locations for top

% settings
fs = 250;

locationsTop = getLocationsTop(potentialLocationsTop, locationsBot, xLinearMapping, frameInds, obsPixPositions, frameTimeStamps, fs);
% showLocations(vidTop, frameInds, potentialLocationsTop, (locationsTop), showPotentialLocations, .02, anchorPtsBot);
save([session 'tracking\locationsTop.mat'], 'locationsTop');

% make tracking vid

makeTrackingVid(session, frameInds)




