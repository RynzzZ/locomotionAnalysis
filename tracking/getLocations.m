function getLocations(session, steps, minVel, makeVid)

% performs paw tracking for a single session!
% if makeVid is true, it also automatically makes a video of the tracking



% settings
obsPrePost = [.2 .2]; % include this many meters before and after obs turns on
velPositions = [-.08 .08] + 0.3820; % compute trials velocity between these obstacle positions
anchorPtsBot = {[0 0], [1 0], [1 1], [0 1]}; % LH, LF, RF, RH // each entry is x,y pair measured from top left corner
colors = hsv(4); % red green blue purple



% initializations
trackingDir = [getenv('OBSDATADIR') 'sessions\' session '\tracking'];
if ~exist(trackingDir, 'dir'); mkdir(trackingDir); end % make tracking directory if it doesn't already exist

xMapping = [getenv('GITDIR') 'locomotionAnalysis\xAlignment\xLinearMapping.mat'];
load(xMapping, 'xLinearMapping');

load([getenv('OBSDATADIR') 'sessions\' session '\runAnalyzed.mat'], 'obsPixPositions', 'frameTimeStamps',...
    'wheelPositions', 'wheelTimes', 'obsPositions', 'obsTimes', 'obsOnTimes', 'obsOffTimes', 'mToPixMapping', 'targetFs')
obsPositions = fixObsPositions(obsPositions, obsTimes, obsOnTimes);

[frameInds, trialIdentities, trialVels] = getTrialFrameInds(minVel, obsPrePost, velPositions, frameTimeStamps,...
    wheelPositions, wheelTimes, obsPositions, obsTimes, obsOnTimes, obsOffTimes);

mToPixFactor = median(mToPixMapping(:,1)); % get mapping from meters to pixels

vidBot = VideoReader([getenv('OBSDATADIR') 'sessions\' session '\runBot.mp4']);
vidTop = VideoReader([getenv('OBSDATADIR') 'sessions\' session '\runTop.mp4']);
wheelPoints = getWheelPoints(vidTop);


% potential locations bot
if any(strcmp('potBot', steps))
    
    % settings
    scoreThresh = 0;
    showTracking = 0;
    
    % svm1
    load([getenv('OBSDATADIR') 'tracking\classifiers\pawBot1'], 'model', 'subFrameSize');
    model1 = model; clear model; subFrameSize1 = subFrameSize; clear subFrameSize;
    load([getenv('OBSDATADIR') 'tracking\classifiers\pawBot2AlexNet (fore vs hind).mat'], 'convNetwork', 'subFrameSize');
    model2 = convNetwork; clear convNetwork; subFrameSize2 = subFrameSize; clear subFrameSize;
    classNum = model2.Layers(end).OutputSize - 1; % not including NOT PAW class
    
    % find paws
    tic; potentialLocationsBot = getPotentialLocationsBot(vidBot, model1, model2, classNum, ...
        subFrameSize1, subFrameSize2, scoreThresh, obsPixPositions, frameInds, trialIdentities, showTracking);

    % save results
    save([getenv('OBSDATADIR') 'sessions\' session '\tracking\potentialLocationsBot.mat'], 'potentialLocationsBot');
    save([getenv('OBSDATADIR') 'sessions\' session '\tracking\velocityInfo.mat'], 'trialVels', 'minVel', 'velPositions');
    fprintf('%s: potentialLocationsBot analyzed in %.1f minutes\n', session, (toc/60))
end


% locations bot
if any(strcmp('bot', steps))
    
    % get bot locations
    showPotentialLocations = 1;
    
    % initializations
    if ~exist('potentialLocationsBot', 'var') % load potentialLocations if it was not already computed above
        load([getenv('OBSDATADIR') 'sessions\' session '\tracking\potentialLocationsBot.mat'])
    end
    

    locations = getLocationsBot(potentialLocationsBot, anchorPtsBot, frameTimeStamps, vidBot.Width, vidBot.Height);
    save([getenv('OBSDATADIR') 'sessions\' session '\tracking\locationsBot.mat'], 'locations');
    fprintf('%s: locationsBot analyzed\n', session)
    
%     showLocations(vidBot, locations.isAnalyzed, ...
%         potentialLocationsBot, find(locations.locationsRaw), showPotentialLocations, .02, anchorPtsBot, colors);
end


% potential locations top
if any(strcmp('potTop', steps))
    
    % get potential locations for top (svm)
    scoreThresh = 0;
    showTracking = 0;

    % initializations
    load([getenv('OBSDATADIR') 'sessions\' session '\tracking\locationsBotCorrected.mat'], 'locations')
    load([getenv('OBSDATADIR') 'tracking\classifiers\pawTop1'], 'model', 'subFrameSize');
    model1 = model; clear model; subFrameSize1 = subFrameSize; clear subFrameSize;
    load([getenv('OBSDATADIR') 'tracking\classifiers\pawTop2AlexNet'], 'convNetwork', 'subFrameSize')
    model2 = convNetwork; clear convNetwork; subFrameSize2 = subFrameSize;
    classNum = model2.Layers(end).OutputSize - 1; % not including NOT PAW class


    tic;
    potentialLocationsTop = getPotentialLocationsTop(vidTop, locations, model1, model2, ...
        classNum, subFrameSize1, subFrameSize2, scoreThresh, showTracking);
    save([getenv('OBSDATADIR') 'sessions\' session '\tracking\potentialLocationsTop.mat'], 'potentialLocationsTop');
    fprintf('%s: potentialLocationsTop analyzed in %.1f minutes\n', session, toc/60)
end


% locations top
if any(strcmp('top', steps))
    
    % settings
    showPotentialLocations = 0;
    fs = 250;

    % fix x alignment for bottom view
    locationsBotFixed = fixTracking(locations);
    locationsBotFixed.x = locationsBotFixed.x*xLinearMapping(1) + xLinearMapping(2);


    locations = getLocationsTop(potentialLocationsTop, locationsBotFixed,...
        frameInds, wheelPositions, wheelTimes, targetFs, mToPixFactor, obsPixPositions, frameTimeStamps, 1:4, fs, wheelPoints);
    save([getenv('OBSDATADIR') 'sessions\' session '\tracking\locationsTop.mat'], 'locations');
    fprintf('%s: locationsTop analyzed\n', session)
    
    % showLocations(vidTop, frameInds, potentialLocationsTop, fixTracking(locationsTop),...
    %     showPotentialLocations, .02, anchorPtsBot, colors, locationsBotFixed);
end


% make tracking vid
if makeVid; makeTrackingVid(session, frameInds); end




