function showTrackingDLC(session, vidDelay)

% settings
startFrame = 22635; % 20763, 
circSize = 150;
vidSizeScaling = 1.25;
colorMap = 'hsv';
connectedFeatures = {{'gen', 'tailBase', 'tailMid'}, {'tailBaseTop', 'tailMidTop'}}; % features that are connected within a view (not across views)


% get videos
vidBot = VideoReader([getenv('OBSDATADIR') 'sessions\' session '\runBot.mp4']);
vidTop = VideoReader([getenv('OBSDATADIR') 'sessions\' session '\runTop.mp4']);

% get locations data and convert to 3d matrix
[locations, features, featurePairInds, isInterped] = fixTrackingDLC(session);
% save([getenv('OBSDATADIR') 'sessions\' session '\trackingFixed.mat'], 'locations', 'features', 'featurePairInds') % temp


% set up figure
hgt = (vidBot.Height+vidTop.Height);
fig = figure('units', 'pixels', 'position', [600 400 vidBot.Width*vidSizeScaling hgt*vidSizeScaling],...
    'menubar', 'none', 'color', 'black', 'keypressfcn', @changeFrames);
colormap gray
imPreview = image(zeros(hgt, vidBot.Width), 'CDataMapping', 'scaled'); hold on;
imAxis = gca;
set(imAxis, 'visible', 'off', 'units', 'pixels',...
    'position', [0 0 vidBot.Width*vidSizeScaling hgt*vidSizeScaling]);

% set colors s.t. matching features in top and bot view have same color
cmap = eval(sprintf('%s(%i);', colorMap, length(features)));
for i = 1:size(featurePairInds,1)
    cmap(featurePairInds(i,2),:) = cmap(featurePairInds(i,1),:);
end


% set up lines joining same featres in top and bot
lines = cell(size(featurePairInds,1),1);
for i = 1:length(lines)
    lines{i} = line([0 0], [0 0], 'color', cmap(featurePairInds(i),:));
end

% set up lines joing features within a view
connectedFeatureInds = cell(1,length(connectedFeatures));
for i = 1:length(connectedFeatures)
    connectedFeatureInds{i} = nan(1,length(connectedFeatures{i}));
    for k = 1:length(connectedFeatures{i})
        connectedFeatureInds{i}(k) = find(ismember(features, connectedFeatures{i}(k)));
    end
end

for i = 1:length(connectedFeatures)
    linesConnected{i} = line([0 0], [0 0], 'color', [1 1 1]);
end

% set up scatter points
scatterLocations = scatter(imAxis, zeros(1,length(features)), zeros(1,length(features)),...
    circSize, cmap, 'linewidth', 3); hold on

% set state variables
currentFrame = startFrame;
playing = true;
paused = false;


% main loop
while playing
    while paused; pause(.001); end
    updateFrame(1);
end
close(fig)






% keypress controls
function changeFrames(~,~)
    
    key = double(get(fig, 'currentcharacter'));
    
    if ~isempty(key) && isnumeric(key)
        
        % LEFT: move frame backward
        if key==28                      
            pause(.001);
            paused = true;
            updateFrame(-1);
        
        % RIGHT: move frame forward
        elseif key==29                  
            pause(.001);
            paused = true;
            updateFrame(1);
        
        % 'f': select frame
        elseif key==102                  
            pause(.001);
            paused = true;
            input = inputdlg('enter frame number');
            currentFrame = str2num(input{1});
            updateFrame(0);
            
        % ESCAPE: close window
        elseif key==27                  
            playing = false;
            paused = false;
        
        % OTHERWISE: toggle pausing
        else                            
            paused = ~paused;
        end
    end
end



% update frame preview
function updateFrame(frameStep)
    
    currentFrame = currentFrame + frameStep;
    if currentFrame > vidBot.NumberOfFrames; currentFrame = 1;
    elseif currentFrame < 1; currentFrame = vidBot.NumberOfFrames; end
    
    % get frame and sub-frames
    frameBot = rgb2gray(read(vidBot, currentFrame));
    frameTop = rgb2gray(read(vidTop, currentFrame));
    frame = cat(1, frameTop, frameBot);
    
	% add frame number
    frame = insertText(frame, [size(frame,2) size(frame,1)], ...
        sprintf('session %s, frame %i', session, currentFrame),...
        'BoxColor', 'black', 'AnchorPoint', 'RightBottom', 'TextColor', 'white');
    
    % update figure
    set(imPreview, 'CData', frame);
    
    % update vertical lines
    for j = 1:length(lines)
        set(lines{j}, ...
            'xdata', [locations(currentFrame, 1, featurePairInds(j,1)) locations(currentFrame, 1, featurePairInds(j,2))], ...
            'ydata', [locations(currentFrame, 2, featurePairInds(j,1)) locations(currentFrame, 2, featurePairInds(j,2))])
    end
    
    % lines connecting within view features
    for j = 1:length(connectedFeatures)
        set(linesConnected{j}, 'xdata', locations(currentFrame,1,connectedFeatureInds{j}), ...
            'ydata', locations(currentFrame,2,connectedFeatureInds{j}));
    end

    % upate scatter positions
    set(scatterLocations, 'XData', locations(currentFrame,1,:), ...
        'YData', locations(currentFrame,2,:), ...
        'SizeData', ones(1,length(features))*circSize - (ones(1,length(features)).*isInterped(currentFrame,:))*circSize*.9);

    % pause to reflcet on the little things...
    pause(vidDelay);
end



end