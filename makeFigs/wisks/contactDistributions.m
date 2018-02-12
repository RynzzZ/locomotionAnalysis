


% temp
sessions = {'180122_001', '180122_002', '180122_003', ...
            '180123_001', '180123_002', '180123_003', ...
            '180124_001', '180124_002', '180124_003', ...
            '180125_001', '180125_002', '180125_003'};


% settings
wiskTouchThresh = -.75; % if wiskTouchSignal surpasses wiskTouchThresh, then wiskTouchPixels are drawn on wisk frame to show points of contact

% initializations
sessionInfo = readtable([getenv('OBSDATADIR') 'sessions\sessionInfo.xlsx']);
data(length(sessions)) = struct(); % stores trial data for all sessions



%% iterate through sessions

for i = 1:length(sessions)
    
    disp(sessions{i})
    
    % load session data
    load([getenv('OBSDATADIR') 'sessions\' sessions{i} '\runAnalyzed.mat'],...
            'obsPixPositions', 'frameTimeStamps',...
            'obsPositions', 'obsTimes',...
            'obsOnTimes', 'obsOffTimes',...
            'obsLightOnTimes', 'obsLightOffTimes',...
            'wiskTouchSignal', 'frameTimeStampsWisk', 'nosePos');
    vidWisk = VideoReader([getenv('OBSDATADIR') 'sessions\' sessions{i} '\runWisk.mp4']);
    obsPositions = fixObsPositions(obsPositions, obsTimes, obsPixPositions, frameTimeStamps, obsOnTimes, obsOffTimes, nosePos(1));
    
    
    % convert wisk contacts to z scores
    realInds = ~isnan(wiskTouchSignal);
    normedReal = zscore(wiskTouchSignal(realInds));
    wiskTouchSignal = nan(size(wiskTouchSignal));
    wiskTouchSignal(realInds) = normedReal;
    
    
    % get pix position of first contact for all trial
    contactPositions = nan(length(obsOnTimes), 1);
    data(i).contactFramesWisk = uint8(nan(vidWisk.Height, vidWisk.Width, length(obsOnTimes)));
    
    for j = 1:length(obsOnTimes)
        
        % get position of first contact
        contactIndWisk = find(frameTimeStampsWisk>obsOnTimes(j) & wiskTouchSignal>wiskTouchThresh, 1, 'first');
        contactTime = frameTimeStampsWisk(contactIndWisk);
        % !!! upsample to increase resolution?
        
        if ~isempty(contactTime)
            
            contactIndTop = find(abs(frameTimeStamps-contactTime)<.002);
            
            if ~isempty(contactIndTop)
                contactPositions(j) = obsPositions(find(obsTimes>=contactTime,1,'first')); % for some reason it doesn't work if i take the pixPosition and use the linear mapping to bring that back to meters...
                data(i).contactFramesWisk(:,:,j) = rgb2gray(read(vidWisk, contactIndWisk));
                
                % set to nan trials in which detected position is unreasonable
                if contactPositions(j)>0 || contactPositions(j)<-.015
                    contactPositions(j) = nan;
                end
            end
        end
    end
    
        
    % store data
    sessionInfoBin = find(strcmp(sessionInfo.session, sessions{i}));
    data(i).mouse = sessionInfo.mouse{sessionInfoBin};
    data(i).contactPositions = contactPositions;
    
end



%% plot results
close all; figure('color', [1 1 1], 'menubar', 'none');

% get all contact positions
allContactPositions = {data.contactPositions};
allContactPositions = cat(1, allContactPositions{:});

% get average contact frame
allContactFrames = {data.contactFramesWisk};
allContactFrames = cat(3, allContactFrames{:});
meanFrame = uint8(mean(allContactFrames,3));

% convert to real world units
histogram(allContactPositions*1000, 50, 'normalization', 'probability'); hold on

% pimp fig
set(gca, 'box', 'off', 'xdir', 'reverse')
ax = gca;
ax.YAxis.Visible = 'off';
xlabel('distance from nose (mm)')

%% show all contact frames

% settings
rows = 5;
cols = 8;

imPreview = nan(rows*vidWisk.Height, cols*vidWisk.Width);
imInds = randperm(size(allContactFrames,3), rows*cols);
imInd = 1;

for i = 1:rows
    for j = 1:cols
        y = (i-1)*vidWisk.Height + 1;
        x = (j-1)*vidWisk.Width + 1;
        imPreview(y:y+vidWisk.Height-1, x:x+vidWisk.Width-1) = allContactFrames(:,:,imInds(imInd));
        imInd = imInd+1;
    end
end

figure;
imshow(uint8(imPreview))
pimpFig;








