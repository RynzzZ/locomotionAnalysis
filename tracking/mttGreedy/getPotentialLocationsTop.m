function potentialLocationsTop = getPotentialLocationsTop(vid, locationsBot, xLinearMapping, model, subHgt, subWid, startFrame, showTracking)

% !!! need to document


% settings
overlapThresh = .5;
scoreThresh = 1;
yMin = 80; % all pixels below yMin (at the top of the frame) are set to zero in the filtered frame
circRoiPts = [36 172; 224 122; 386 157];
xMaskWidth = 15;


% initializations
xMaskHalfWidth = floor(xMaskWidth/2);
sampleFrame = rgb2gray(read(vid,startFrame));
totalFrames = vid.NumberOfFrames;
kernel = reshape(model.w, subHgt, subWid);
% wheelMask = double(getWheelMask(circRoiPts, [vid.Height vid.Width]));
wheelMask = getWheelMask(circRoiPts, [vid.Height vid.Width]);
figure; imagesc(kernel);
bg = getBgImage(vid, 1000, true);


% !!! fix x alignment for bottom view
locationsBot.x = round(locationsBot.x*xLinearMapping(1) + xLinearMapping(2));


% prepare figure
if showTracking

    figure('position', [680 144 698 834], 'menubar', 'none', 'color', 'black'); colormap gray

    rawAxis = subaxis(3,1,1, 'spacing', 0, 'margin', 0);
    rawIm = image(sampleFrame, 'parent', rawAxis, 'CDataMapping', 'scaled');
    set(gca, 'visible', 'off');
    hold on; scatterPtsAll = scatter(rawAxis, 0, 0, 100, 'filled', 'red');
    
    maskAxis = subaxis(3,1,2, 'spacing', 0, 'margin', 0);
    maskIm = image(sampleFrame, 'parent', maskAxis, 'CDataMapping', 'scaled');
    set(gca, 'visible', 'off');
    
    predictAxis = subaxis(3,1,3, 'spacing', 0.01, 'margin', .01);
    predictIm = image(sampleFrame, 'parent', predictAxis, 'CDataMapping', 'scaled');
    set(gca, 'visible', 'off');
end


potentialLocationsTop = struct();

for i = startFrame:totalFrames
    
    disp(i/totalFrames)
    
    % get frame and subframes
    frame = rgb2gray(read(vid,i));
    frame = frame - bg;
    frame = getFeatures(frame);
    frameMasked = frame .* wheelMask; % mask wheel
    frameMasked(1:yMin,:) = 0;        % make top of frame
    
    % make x positions out of range
    xMask = uint8(zeros(size(frame)));
    
    for j = 1:4
        if ~isnan(locationsBot.x(i,j))
            
            % get mask indices for single paw
            inds = locationsBot.x(i,j)-xMaskHalfWidth : locationsBot.x(i,j)+xMaskHalfWidth;
            inds(inds<1) = 1;
            inds(inds>vid.Width) = vid.Width;
            
            % incorporate paw mask into mask
            xMask(:,inds) = 1;
        end
    end
    frameMasked = frameMasked .* xMask;
    
    
    % filter with svm and apply non-maxima suppression
    frameFiltered = (conv2(double(frameMasked), kernel, 'same') - model.rho);
    frameFiltered(frameFiltered < scoreThresh) = 0;
%     frameFiltered(1:yMin,:) = 0;
%     frameFiltered = frameFiltered .* wheelMask;
    [x, y, scores] = nonMaximumSupress(frameFiltered, [subHgt subWid], overlapThresh);
        
    
    % store data
    potentialLocationsTop(i).x = x;
    potentialLocationsTop(i).y = y;
    potentialLocationsTop(i).scores = scores;
    
    
    if showTracking
        
        % put lines in top frame
        for j = 1:4
            if ~isnan(locationsBot.x(i,j))
                frame(:,locationsBot.x(i,j)) = 255;
            end
        end
        
        % update figure
        set(rawIm, 'CData', frame);
        set(maskIm, 'CData', frameMasked);
        set(predictIm, 'CData', frameFiltered)
        set(scatterPtsAll, 'XData', x, 'YData', y);
        
        % pause to reflcet on the little things...
        pause(.1);
    end
end

close all



