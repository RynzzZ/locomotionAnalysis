% global settings for paper

% sizes
% figHgt = 3.75;  % inches
% font = 'Calibri';
% fontSize = 12;

% global
axisColor = [.15 .15 .15];  % use this for black
obsColor = [188 125 181] / 255;
obsAlpha = .15;
waterColor = [48 135 227]*.75 / 255;
ctlStepColor = [.5 .5 .5];
barProperties = {'scatterAlpha', .5, 'barAlpha', .4, 'labelSizePerFactor', .1, ...
                 'lineThickness', 2, 'scatterColors', 'lines', 'connectDots', true, ...
                 'lineAlpha', .05};


% step type colors (leading, lagging, fore, hind)
stepSaturation = .9;
stepColors = hsv2rgb([.65 stepSaturation 1;
                      .55 stepSaturation 1;
                      .02 stepSaturation 1;
                      .12 stepSaturation 1]);  % LF, TF, LH, TH


% sensory dependence colors
% colorWisk = [51 204 255]/255;
% colorVision = [255 221 21]/255;
colorWisk = hsv2rgb([.05 1 1]);
colorVision = obsColor;
colorNone = [.2 .2 .2];
% both = mean([colorWisk;colorVision],1);
both = hsv2rgb(mean([rgb2hsv(colorWisk); rgb2hsv(colorVision)],1));
sensColors = [both; colorWisk; colorVision; colorNone];


% big little step colors
% decisionColors = [0 0.447 0.741; 0.850 0.325 0.098]; % first entry is small step, second is big step
decisionColors = flipud(colorme(2, 'offset', .2, 'showSamples', false)); % first entry is small step, second is big step
preDecisionColor = hsv2rgb(mean(rgb2hsv(decisionColors),1));% preDecisionColor(3) = 1;
modelColor = hsv2rgb(mean(rgb2hsv(decisionColors),1));


% video contast
contrast = [0 .75];


% contact color (paw, whiskers)
contactColor = [1 .2 .2];





