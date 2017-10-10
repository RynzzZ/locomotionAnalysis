
% performs low-level analysis on raw spike files:
%
% iterates through all data forlders in dataDir and performs several low-level computations on the spike data in run.mat
% it converts the wheel and obstacle rotary encoder channels into positional units, and the commands to the stepper motor to positional units
% it also converts the reward channel from analog to digital (this digital input was recorded on an analog channel because I ran out of spike digital inputs)
% it then saves these data to runAnalyzed.mat in each folder, along with the other non-processed spike channels ()


% settings
dataDir = 'C:\Users\Rick\Google Drive\columbia\obstacleData';
targetFs = 1000; % frequency that positional data will be resampled to


% rig characteristics
whEncoderSteps = 2880; % 720cpr * 4
wheelRad = 95.25; % mm
obEncoderSteps = 1000; % 250cpr * 4
obsRad = 96 / (2*pi); % radius of timing pulley driving belt of obstacles platform


% find all data folders
dataFolders = dir(dataDir);
dataFolders = dataFolders(3:end); % remove current and parent directory entries
dataFolders = dataFolders([dataFolders.isdir]); % keep only folders


% iterate over data folders and analyze those that have not been analyzed
for i = 1:length(dataFolders)
    
    sessionDir = [dataDir '\' dataFolders(i).name];
    sessionFiles = dir(sessionDir);
    
    % determine whether runAnalyzed.mat was already created
    previouslyAnalyzed = sum( cellfun(@(s) ~isempty(strfind(s, 'Analyzed.mat')), {sessionFiles.name})) > 0;
    
    if ~previouslyAnalyzed
        
        fprintf('analyzing %s...\n', dataFolders(i).name);
        
        % load data
        load([sessionDir '\run.mat']);
        
        % find reward times
        rewardInds = find(diff(reward.values>3)==1);
        rewardTimes = reward.times(rewardInds);
        rewardTimes = rewardTimes(logical([diff(rewardTimes)>22; 1])); % remove reward times occuring within 1 second of eachother
        
        % decode stepper motor
        [motorPositions, motorTimes] = motorDecoder(stepDir.level, stepDir.times, step.times, targetFs);
        
        % decode obstacle position (from rotary encoder on stepper motor track)
        [obsPositions, obsTimes] = rotaryDecoder(obEncodA.times, obEncodA.level,...
                                                     obEncodB.times, obEncodB.level,...
                                                     obEncoderSteps, obsRad, targetFs);
        
        % decode wheel position
        [wheelPositions, wheelTimes] = rotaryDecoder(whEncodA.times, whEncodA.level,...
                                                     whEncodB.times, whEncodB.level,...
                                                     whEncoderSteps, wheelRad, targetFs);
        
        % save data
        save([sessionDir '\runAnalyzed.mat'], 'rewardTimes',...
                                              'motorPositions', 'motorTimes',...
                                              'obsPositions', 'obsTimes',...
                                              'wheelPositions', 'wheelTimes');
        fprintf('\n');
        
    end    
end