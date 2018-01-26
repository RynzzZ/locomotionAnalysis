% PERFORM PAW TRACKING

% settings
session = '180122_001';
minVel = .4;
obsPrePost = [.2 .2];
velPositions = [-.08 .08] + 0.3820;
anchorPtsBot = {[0 0], [1 0], [1 1], [0 1]}; % LH, LF, RF, RH // each entry is x,y pair measured from top left corner
colors = hsv(4); % red green blue purple

% initializations
trackingDir = [getenv('OBSDATADIR') 'sessions\' session '\tracking'];
if ~exist(trackingDir, 'dir'); mkdir(trackingDir); end % make tracking directory if it doesn't already exist

xMapping = [getenv('GITDIR') 'locomotionAnalysis\xAlignment\xLinearMapping.mat'];
load(xMapping, 'xLinearMapping');

load([getenv('OBSDATADIR') 'sessions\' session '\runAnalyzed.mat'], 'obsPixPositions', 'frameTimeStamps',...
    'wheelPositions', 'wheelTimes', 'obsPositions', 'obsTimes', 'obsOnTimes', 'obsOffTimes', 'mToPixMapping')
obsPositions = fixObsPositions(obsPositions, obsTimes, obsOnTimes);

[frameInds, trialVels] = getTrialFrameInds(minVel, obsPrePost, velPositions, frameTimeStamps,...
    wheelPositions, wheelTimes, obsPositions, obsTimes, obsOnTimes, obsOffTimes);

vidTop = VideoReader([getenv('OBSDATADIR') 'sessions\' session '\runTop.mp4']);
vidBot = VideoReader([getenv('OBSDATADIR') 'sessions\' session '\runBot.mp4']);

% get mapping from meters to pixels
obsPixBins = ~isnan(obsPixPositions); % bins for frame in which obs pix position is known
obsPixNoNans = obsPixPositions(obsPixBins); % obsPixPositions without nans
wheelPosInterp = interp1(wheelTimes, wheelPositions, frameTimeStamps(obsPixBins)); % wheel positions (in meters) at frames whether obs pix positions are known
mapping = polyfit(obsPixNoNans, wheelPosInterp', 1);



%% hand label paw bot locations

vidFile = [getenv('OBSDATADIR') 'sessions\' session '\runBot.mp4'];
labelPawLocations(vidFile, frameInds, 100, anchorPtsBot, colors);


%% create bot labeled set, svm1

posEgs = 400;
negEgsPerEg = 10;
jitterNum = 0;
jitterPixels = 0;
subFrameSize1 = [45 45];
featureSetting = 'imageOnly';
paws = 1:4;
class = 'pawBot1';
maxOverlap = .5;
minBrightness = 2; % negative examples need to be minBrightness times the mean brightness of the current frame

makeLabeledSet(class,...
               [getenv('OBSDATADIR') 'sessions\' session '\tracking\runBotHandLabeledLocations.mat'], ...
               [getenv('OBSDATADIR') 'sessions\' session '\runBot.mp4'],...
               subFrameSize1, obsPixPositions, posEgs, negEgsPerEg, featureSetting, paws,...
               jitterPixels, jitterNum, maxOverlap, minBrightness);

viewTrainingSet(class);


%% create bot labeled set 2, second classifier

posEgs = 400;
negEgsPerEg = 10;
jitterNum = 8;
jitterPixels = 3;
subFrameSize2 = [45 45];
featureSetting = 'imageOnly';  % !!!

paws = [1 4; 2 3]; % every row is a class // all paws in a row belong to that class (hind vs fore paws, for examlpe)
class = 'pawBot2'; % !!!
maxOverlap = .5;
minBrightness = 2.5; % negative examples need to be minBrightness times the mean brightness of the current frame

makeLabeledSet(class,...
               [getenv('OBSDATADIR') 'sessions\' session '\tracking\runBotHandLabeledLocations.mat'], ...
               [getenv('OBSDATADIR') 'sessions\' session '\runBot.mp4'],...
               subFrameSize2, obsPixPositions, posEgs, negEgsPerEg, featureSetting, paws,...
               jitterPixels, jitterNum, maxOverlap, minBrightness);

viewTrainingSet(class);


%% train bot svm1

class = 'pawBot1';

% train bot svm and reload
trainSVM(class);
load([getenv('OBSDATADIR') 'svm\classifiers\' class], 'model', 'subFrameSize');

close all; figure; imagesc(reshape(-model.Beta, subFrameSize(1), subFrameSize(2)))

%% train bot svm2

class = 'pawBot2';
trainSVM2(class); % this is saved as [class '2']


%% train nn

class = 'pawBot2';
trainNn(class);

%% train alexnet cnn for top (transfer learning)

% settings
class = 'pawBot2';
network = 'alexNet';
% targetSize = [227 227]; prepareTrainingDataForCnn(class, targetSize); % uncomment to convert labeledFeatures.mat into folders containing images, a format appropriate for AlexNet
retrainCnn(class, network);


%% get bot potential locations


% settings
close all;
scoreThresh = -1;
showTracking = 1;
model1 = [getenv('OBSDATADIR') 'svm\classifiers\pawBot1'];
classNum = size(paws,1); % not included not paw class

% svm1
load(model1, 'model', 'subFrameSize');
model1 = model; subFrameSize1 = subFrameSize;

% svm2
% load([getenv('OBSDATADIR') 'svm\classifiers\pawBot2'], 'model', 'subFrameSize');
% model2 = model; subFrameSize2 = subFrameSize;

% nn
load([getenv('OBSDATADIR') 'svm\classifiers\pawBot2AlexNet'], 'convNetwork');
model2 = convNetwork; clear convNetwork;

% svm3 (trained on alexNet extracted features)
% load([getenv('OBSDATADIR') 'svm\classifiers\pawBot3'], 'model', 'subFrameSize');
% model2 = model; subFrameSize2 = subFrameSize;
% load([getenv('OBSDATADIR') 'svm\classifiers\pawBot2Cnn'], 'netTransfer');
% neuralNetwork = netTransfer; clear netTransfer;

% cnn
% load([getenv('OBSDATADIR') 'svm\classifiers\pawBot2Cnn'], 'netTransfer');
% model2 = netTransfer; clear netTransfer;


tic
potentialLocationsBot = getPotentialLocationsBot(vidBot, model1, model2, classNum, ...
    subFrameSize1, subFrameSize2, scoreThresh, obsPixPositions, frameInds, showTracking);
                                                  
save([getenv('OBSDATADIR') 'sessions\' session '\tracking\potentialLocationsBotAll.mat'], 'potentialLocationsBot');
fprintf('potential locations bot analysis time: %i minutes\n', toc/60)


%% get bot locations

% settings
showPotentialLocations = true;

% initializations
vidBot = VideoReader([getenv('OBSDATADIR') 'sessions\' session '\runBot.mp4']);

locationsBot = getLocationsBot(potentialLocationsBot, anchorPtsBot, frameTimeStamps, vidBot.Width, vidBot.Height, frameInds);
showLocations(vidBot, frameInds, potentialLocationsBot, fixTracking(locationsBot), showPotentialLocations, .02, anchorPtsBot, colors);
save([getenv('OBSDATADIR') 'sessions\' session '\tracking\locationsBot.mat'], 'locationsBot');



%% hand label top locations

vidFile = [getenv('OBSDATADIR') 'sessions\' session '\runTop.mp4'];
obsFrameInds = find(obsPixPositions>10 & obsPixPositions<vidTop.Width);
labelPawLocations(vidFile, obsFrameInds, 100, anchorPtsBot, colors);

%% create top labeled set, svm

posEgs = 400;
negEgsPerEg = 10;
jitterNum = 0;
jitterPixels = 0;
subFrameSize1 = [35 35];
featureSetting = 'imageOnly';
paws = 1:4;
class = 'pawTop1';
maxOverlap = .5;
minBrightness = 2.5; % negative examples need to be minBrightness times the mean brightness of the current frame

makeLabeledSet(class,...
               [getenv('OBSDATADIR') 'sessions\' session '\tracking\runTopHandLabeledLocations.mat'], ...
               [getenv('OBSDATADIR') 'sessions\' session '\runTop.mp4'],...
               subFrameSize1, obsPixPositions, posEgs, negEgsPerEg, featureSetting, paws, ...
               jitterPixels, jitterNum, maxOverlap, minBrightness);
viewTrainingSet(class);



%% create top labeled set, cnn

posEgs = 400;
negEgsPerEg = 10;
jitterNum = 8;
jitterPixels = 2;
subFrameSize2 = [35 35];
featureSetting = 'imageOnly';
paws = 1:4;
class = 'pawTop2';
maxOverlap = .5;
targetSize = [227 227];
minBrightness = 2.5; % negative examples need to be minBrightness times the mean brightness of the current frame

makeLabeledSet(class,...
               [getenv('OBSDATADIR') 'sessions\' session '\tracking\runTopHandLabeledLocations.mat'], ...
               [getenv('OBSDATADIR') 'sessions\' session '\runTop.mp4'],...
               subFrameSize2, obsPixPositions, posEgs, negEgsPerEg, featureSetting, paws, ...
               jitterPixels, jitterNum, maxOverlap, minBrightness);
viewTrainingSet(class);



%% train top svm1

class = 'pawTop1';

% train bot svm and reload
trainSVM(class);
load([getenv('OBSDATADIR') 'svm\classifiers\' class], 'model', 'subFrameSize');

close all; figure; imagesc(reshape(-model.Beta, subFrameSize(1), subFrameSize(2)))


%% train alexnet cnn for top (transfer learning)

% settings
class = 'pawTop2';
network = 'alexNet';
% targetSize = [227 227]; prepareTrainingDataForCnn(class, targetSize); % uncomment to convert labeledFeatures.mat into folders containing images, a format appropriate for AlexNet
retrainCnn(class, network);

%% get potential locations for top (svm)

% settings
scoreThresh = 0;
showTracking = 0;
classNum = size(paws,1); % not included not paw class

% initializations
load([getenv('OBSDATADIR') 'svm\classifiers\pawTop1'], 'model', 'subFrameSize');
model1 = model; clear model; subFrameSize1 = subFrameSize; clear subFrameSize;
load([getenv('OBSDATADIR') 'svm\classifiers\pawTop2AlexNet'], 'convNetwork', 'subFrameSize')
model2 = convNetwork; clear convNetwork; subFrameSize2 = subFrameSize;


tic; potentialLocationsTop = getPotentialLocationsTop(vidTop, locationsBot, model1, model2, ...
    classNum, subFrameSize1, subFrameSize2, scoreThresh, frameInds, paws, showTracking);
fprintf('potential locations top analysis time: %i minutes\n', toc/60)

save([getenv('OBSDATADIR') 'sessions\' session '\tracking\potentialLocationsTop.mat'], 'potentialLocationsTop');



%% get locations for top

% settings
showPotentialLocations = true;
fs = 250;


% fix x alignment for bottom view
locationsBotFixed = fixTracking(locationsBot);
locationsBotFixed.x = locationsBotFixed.x*xLinearMapping(1) + xLinearMapping(2);


locationsTop = getLocationsTop(potentialLocationsTop, locationsBotFixed,...
    frameInds, wheelPositions, obsPixPositions, frameTimeStamps, paws, fs);
showLocations(vidTop, frameInds, potentialLocationsTop, (locationsTop),...
    showPotentialLocations, .08, anchorPtsBot, colors, locationsBotFixed);
save([getenv('OBSDATADIR') 'sessions\' session '\tracking\locationsTop.mat'], 'locationsTop');


%% make tracking vid

makeTrackingVid(session, frameInds)




