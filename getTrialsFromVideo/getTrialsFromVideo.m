function getTrialsFromVideo
    
    % user settings
    timePre = .5;
    timePost = .5;
    fs = 150;
    outputSpeed = .1;
    trialBuffer = 3; % disallow trials this many seconds within one another
    zScoreThresh = 6;

    % other variables
    currentFrame = 2;
    [file,path] = uigetfile('video\*.*', 'Select video file to analyze...');
    vid = VideoReader([path file]);
    mask = ones(vid.Height,vid.Width);

    playing = true;
    diffHistory = [0 nan(1,vid.NumberOfFrames-1)];
    prevFrame = rgb2gray(read(vid,1));
    
    
    % set up figure
    close all
    previewFig = figure('Position', [100, 100, 400, 400], 'menubar', 'none');
    pimpFig;
    vidPreview = subaxis(1, 1, 1, 'spacing', 0.01, 'margin', .05);
    frame = read(vid,1);
    imPreview = imshow(rgb2gray(frame));
    
    
    if exist('prevSettings.mat')
        load('prevSettings.mat', 'roiPositions');
        roi = impoly(vidPreview, roiPositions);
    else
        roi = impoly(vidPreview);
    end
    
    mask = createMask(roi);
    addNewPositionCallback(roi, @updateRois);
    
    % set up buttons
    uicontrol('Style', 'pushbutton', 'String', 'start analysis', 'Position', [0 0 100 20], 'Callback', @startAnalysis);
    uicontrol('Style', 'pushbutton', 'String', 'close', 'Position', [100 0 100 20], 'Callback', @closeAll);
    
    % preview analysis
    while playing
        % get and show frame
        frame = rgb2gray(read(vid,currentFrame));
        set(imPreview, 'Cdata', frame);
        prevFrame = frame;
        if currentFrame<vid.NumberOfFrames; currentFrame=currentFrame+1; else; currentFrame = 1; end
        pause(.01);
    end
    close all;
    
    
    % ---------
    % FUNCTIONS
    % ---------
    
    function closeAll(~,~)
        playing = false;
    end

    function updateRois(~)
        mask = createMask(roi);
    end

    function startAnalysis(~,~)
        
        % save roi position
        roiPositions = getPosition(roi);
        save('prevSettings.mat', 'roiPositions');
        
        
        playing = false;
        close(previewFig)
        
        % get all frame differences
        f=1;
        prevFrame = rgb2gray(read(vid,f));
        w = waitbar(0, 'calculating frame differences...');
        while f<vid.NumberOfFrames
            f=f+1;
            frame = rgb2gray(read(vid,f));
            pixelDifs = double(frame).*double(mask) - double(prevFrame).*double(mask);
            frameDif =  sum(abs(pixelDifs(:))) / sum(mask(:));
            diffHistory(f) = frameDif;
            prevFrame = frame;
            waitbar(f/vid.NumberOfFrames)
        end
        close(w)
        
        % get trial start times
        trialStartInds = find(zscore(diffHistory)>zScoreThresh);
        trialStartInds = trialStartInds(logical([1 diff(trialStartInds/fs)>trialBuffer])); % remove trial start times that are too close together
        fprintf('number of trials found: %i\n', length(trialStartInds));
        
        % create video
        writerobj = VideoWriter(['edited_video\' file(1:find(file=='.',1,'first')-1) 'Edited'], 'MPEG-4');
        set(writerobj, 'FrameRate', round(fs*outputSpeed))
        open(writerobj);
        
        w = waitbar(0, 'writing video...');
        % write video to file
        for t = 1:length(trialStartInds)
            for f = round(trialStartInds(t)-timePre*fs):round(trialStartInds(t)+timePost*fs)
                frame = read(vid,f);
                frame = insertText(frame, [0 0], ['trial: ' num2str(t)]);
                writeVideo(writerobj, frame)
            end
            % add blank frame
            writeVideo(writerobj, zeros(size(frame)))
            waitbar(t/length(trialStartInds))
        end
        
        % close windows
        close(w)
        close all
        close(writerobj)
    end
end

