

% settings
trainTestValPortions = [.6 .2 .2];
imgDir = 'C:\Users\rick\Desktop\trainingExamples\poseRegression\';


% initializations
% imgs = imageDatastore([imgDir 'imgs'],...
%     'IncludeSubfolders', true, 'FileExtensions', '.tif');
% [trainImages, testImages, valImages] = splitEachLabel(imgs, ...
%     trainTestValPortions(1), trainTestValPortions(2), trainTestValPortions(3), 'randomized');
load([imgDir 'pawLocations.mat'], 'features', 'locations')
%%

net = alexnet; % load alexNet

% get alexNet conv layers, and add new fully connected layers
layersTransfer = net.Layers(1:16);
numOutputs = size(locations,2);
learningRateFactor = 10;
layers = [layersTransfer
          fullyConnectedLayer(4096, 'WeightLearnRateFactor', 20, 'BiasLearnRateFactor', learningRateFactor)
          reluLayer
          dropoutLayer(.5)
          fullyConnectedLayer(4096, 'WeightLearnRateFactor', 20, 'BiasLearnRateFactor', learningRateFactor)
          reluLayer
          dropoutLayer(.5)
          fullyConnectedLayer(numOutputs, 'WeightLearnRateFactor', 20, 'BiasLearnRateFactor', learningRateFactor)
          regressionLayer];


% set training parameters
miniBatchSize = 32;
numIterationsPerEpoch = floor(size(locations,1)/miniBatchSize);
options = trainingOptions('sgdm',...
    'MiniBatchSize', miniBatchSize,...
    'MaxEpochs', 4,...
    'InitialLearnRate', 1e-4,...
    'Verbose', true,...
    'Plots', 'training-progress');

% train!
convNetwork = trainNetwork(features, locations, layers, options);
save([getenv('OBSDATADIR') 'tracking\classifiers\botPoseRegressor.mat'], 'convNetwork')

% classify
predictedLabels = classify(convNetwork, testImages);
fprintf('test accuracy: %f\n', mean(predictedLabels == testImages.Labels));

