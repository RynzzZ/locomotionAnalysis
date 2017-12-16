%% test whiski tracking

wiskData = LoadWhiskers('C:\Users\rick\Google Drive\columbia\obstacleData\sessions\runWiskTest4\runWisk.whiskers');
vid = VideoReader('C:\Users\rick\Google Drive\columbia\obstacleData\sessions\runWiskTest4\runWisk.mp4');
%%
close all; figure;
im = imshow(rgb2gray(read(vid,1))); pimpFig

for i = 1:vid.NumberOfFrames
    
    % get frame
    frame = rgb2gray(read(vid, i)) - 100;
    
    % draw whiskers
    inds = find([wiskData.time]==(i-1));
    
    for j = inds
        x = round(wiskData(j).x); x = max(1, x);
        y = round(wiskData(j).y); y = max(1, y);
        linearInds = sub2ind(size(frame), y, x);
        frame(linearInds) = 255;
    end
    
    % update preview
    set(im, 'CData', frame);
    pause(.001);
    
end



%% test obs tracker on bot

vid = VideoReader('C:\Users\rick\Google Drive\columbia\obstacleData\sessions\wiskTest3\runBot.mp4');
load('C:\Users\rick\Google Drive\columbia\obstacleData\sessions\wiskTest3\runAnalyzed.mat');

xLims = [60 vid.Width-40];
yLims = [1 vid.Height];
pixThreshFactor = 3;
invertColors = false;
showTracking = true;
obsMinThickness = 10;

obsPixPositions = trackObstacles(vid, obsOnTimes, obsOffTimes, frameTimeStamps, obsPositions, obsTimes,...
                                 xLims, yLims, pixThreshFactor, obsMinThickness, invertColors, showTracking);
                             
                             
%% test obs tracker on wisk

vid = VideoReader('C:\Users\rick\Google Drive\columbia\obstacleData\sessions\wiskTest3\runWisk.mp4');
load('C:\Users\rick\Google Drive\columbia\obstacleData\sessions\wiskTest3\runAnalyzed.mat');

xLims = [160 vid.Width];
yLims = [125 215];
pixThreshFactor = 1;
invertColors = true;
showTracking = true;
obsMinThickness = 10;

obsPixPositions = trackObstacles(vid, obsOnTimes, obsOffTimes, frameTimeStamps, obsPositions, obsTimes,...
                                 xLims, yLims, pixThreshFactor, obsMinThickness, invertColors, showTracking);