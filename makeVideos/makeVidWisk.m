function makeVidWisk(session, obsPosRange, playBackSpeed, trialProportion, trialLabels, trialInds)

% !!! needs further documentation

% edits a video of mouse jumping over obstacles s.t. obstacle trials are
% kept and everything else is edited out. obsPosRange is in m and defines
% the start and end position of the obstacle along the track that each
% trial should include.


% settings
dataDir = 'C:\Users\Rick\Google Drive\columbia\obstacleData\sessions\';
editedDir = 'C:\Users\Rick\Google Drive\columbia\obstacleData\editedVid\';
maxTrialTime = 1.5; % trials exceeding maxTrialTime will be trimmed to this duration (s)
wiskScaling = 18/52;
corrFrames = 50; % use this many random frames to determine best position for whisker frame on background frame
border = 5; % thickness (pixels) to draw around the wisk frame


% initializations
vidTop = VideoReader([dataDir session '\runTop.mp4']);
vidBot = VideoReader([dataDir session '\runBot.mp4']);
vidWisk = VideoReader([dataDir session '\runWisk.mp4']);
vidWeb = VideoReader([dataDir session '\webCam.avi']);


frameDim = round([vidTop.Height + vidBot.Height, vidBot.Width + (vidWeb.Width * (vidBot.Height/vidWeb.Height))]);
% wiskDim = round([vidTop.Height, vidWisk.Width * (vidTop.Height / vidWisk.Height)]);
webDim = [vidBot.Height, frameDim(2) - vidBot.Width];

load([dataDir session '\runAnalyzed.mat'], 'obsPixPositions', 'obsPositions', 'obsTimes');
vidSetting = 'MPEG-4';

fps = round(vidTop.FrameRate * playBackSpeed);
maxFps = 150; % fps > 150 can be accomplished using 'Motion JPEG AVI' as second argument to VideoWriter, but quality of video is worse

if fps>maxFps
    fprintf('WARNING: changing video mode to ''Motion JPEG AVI'' to acheive requested playback speed\n');
    vidSetting = 'Motion JPEG AVI';
end

vidWriter = VideoWriter(sprintf('%s%sspeed%.2f', editedDir, session, playBackSpeed), vidSetting);
set(vidWriter, 'FrameRate', fps)
if strcmp(vidSetting, 'MPEG-4'); set(vidWriter, 'Quality', 50); end
open(vidWriter)

load([dataDir session '\runAnalyzed.mat'], 'obsPositions', 'obsTimes',...
                                           'wheelPositions', 'wheelTimes',...
                                           'obsOnTimes', 'obsOffTimes',...
                                           'frameTimeStamps', 'frameTimeStampsWisk', 'webCamTimeStamps',...
                                           'touchSig', 'touchSigTimes');

obsPositions = fixObsPositions(obsPositions, obsTimes, obsOnTimes); % correct for drift in obstacle position readings

% get position where wisk frame should overlap with runTop frame
xWiskPos = nan(1,corrFrames);
yWiskPos = nan(1,corrFrames);

for i = 1:corrFrames
    
    validFrame = false;
    
    while ~validFrame
    
        runInd = randi(vidTop.NumberOfFrames);
        isMouseOnWheel = frameTimeStamps(runInd) > obsOnTimes(1);
        [minDif, wiskInd] = min(abs(frameTimeStamps(runInd) - frameTimeStampsWisk));
        areFramesMatched = minDif < .05;
        
        if isMouseOnWheel && areFramesMatched
            validFrame = true;
        end
    end
    
    frameTop = rgb2gray(read(vidTop, runInd));
    frameWisk = rgb2gray(read(vidWisk, wiskInd));
    [yWiskPos(i), xWiskPos(i)] = getWiskFramePosition(frameTop, frameWisk, wiskScaling);
end

xWiskPos = round(mean(xWiskPos));
yWiskPos = round(mean(yWiskPos));


% edit video
w = waitbar(0, 'editing video...');

for i = 1 : round(1/trialProportion) : length(obsOnTimes)
    
    % find trial indices
    startInd = find(obsTimes>obsOnTimes(i)  & obsPositions>=obsPosRange(1), 1, 'first');
    endInd   = find(obsTimes<obsOffTimes(i) & obsPositions<=obsPosRange(2), 1, 'last');
    
    % get frame indices
    endTime = min(obsTimes(startInd)+maxTrialTime, obsTimes(endInd));
    frameInds = find(frameTimeStamps>obsTimes(startInd) & frameTimeStamps<endTime);
    
    % get webCame frame indices
    webFrameInds = find(webCamTimeStamps>obsTimes(startInd) & webCamTimeStamps<endTime);
    webFrames = read(vidWeb, [webFrameInds(1) webFrameInds(end)]);
    webFrames = squeeze(webFrames(:,:,1,:)); % collapse color dimension

    % interpolate webFrames to number of inds in frameInds
    webFramesInterp = interp1(webCamTimeStamps(webFrameInds), 1:length(webFrameInds), frameTimeStamps(frameInds), 'nearest', 'extrap');
    
    if isempty(frameInds) % if a block has NaN timestamps (which will happen when unresolved), startInd and endInd will be the same, and frameInds will be empty
        fprintf('skipping trial %i\n', i)
    else
        
        for j = 1:length(frameInds)
            
            frame = uint8(zeros(frameDim));
            
            % top
            frameTop = rgb2gray(read(vidTop, frameInds(j)));
            frame(1:vidTop.Height, 1:vidTop.Width) = frameTop;
            
            % bot
            frameBot = rgb2gray(read(vidBot, frameInds(j)));
            frame(vidTop.Height+1:end, 1:vidBot.Width) = frameBot;
            
            % wisk
            [timeDif, wiskFrameInd] = min(abs(frameTimeStampsWisk - frameTimeStamps(frameInds(j))));
            if timeDif < .01 % only write wisk frame if it is temporally close to run frame
                frameWisk = rgb2gray(read(vidWisk, wiskFrameInd));
                frameWisk = imresize(frameWisk, wiskScaling);
                frameWisk([1:border, end-border:end], :) = 255;
                frameWisk(:, [1:border, end-border:end]) = 255;
                frame(yWiskPos:yWiskPos+size(frameWisk,1)-1, xWiskPos:xWiskPos+size(frameWisk,2)-1) = frameWisk;
%                 frame(1:vidTop.Height, [vidTop.Width+1:vidTop.Width+wiskDim(2)] + round(webDim(2)/2)-wiskDim(2)/2) = frameWisk;
            end
%             if frameInds(j)>15000; keyboard; end
            
            % webCam
            frameWeb = webFrames(:,:,webFramesInterp(j));
            frameWeb = imresize(frameWeb, webDim);
            frame(vidTop.Height+1:end, vidBot.Width+1:end) = frameWeb;          
            
            % add trial info text
            frame = insertText(frame, [size(frame,2) size(frame,1)], num2str(i),...
                               'BoxColor', 'black', 'AnchorPoint', 'RightBottom', 'TextColor', 'white');
            
            % add trial condition info
            if exist('trialLabels', 'var')
                if trialInds(i)==1
                    boxColor = 'yellow';
                    textColor = 'white';
                else
                    boxColor = 'blue';
                    textColor = 'black';
                end
                frame = insertText(frame, [size(frame,2), 0], trialLabels{trialInds(i)},...
                                   'BoxColor', boxColor, 'anchorpoint', 'RightTop', 'textcolor', textColor);
                frame = insertText(frame, [size(frame,2), size(frameTop,1)+size(frameBot,1)], trialLabels{trialInds(i)},...
                                   'BoxColor', boxColor, 'anchorpoint', 'RightTop', 'textcolor', textColor);
            end
            
            % change color of frame if touching
            currentTouch = interp1(touchSigTimes, touchSig, frameTimeStamps(frameInds(j)));
            if currentTouch
                frame(:,:,3) = frame(:,:,1)*.2;
            end
                       
            % add lines at obstacle positions
            if ~isnan(obsPixPositions(frameInds(j)))
                
                % bottom view
                yInds = size(frameTop,1)+1 : size(frameTop,1)+size(frameBot,1);
                xInds = max(1, round((-6:6) + obsPixPositions(frameInds(j))));
                xInds = xInds(xInds<=size(frame,2)); % make sure adding the line doesn't increase the width of the frame
                frame(yInds, xInds, :) = 255;
                
                % top view
%                 yInds = topObsXPos(1) : topObsXPos(2);
%                 frame(yInds, xInds, :) = 255;
            end

            % write frame to video
            try; writeVideo(vidWriter, frame); catch; keyboard; end
        end

        % add blank frame between trials
        writeVideo(vidWriter, zeros(size(frame)));
    end
    
    % update waitbar
    waitbar(i/length(obsOnTimes))
    
end


close(w)
close(vidWriter)

