%% test whiski tracking

wiskData = LoadWhiskers('C:\Users\rick\Google Drive\columbia\obstacleData\sessions\runWiskTest4\runWisk.whiskers');





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