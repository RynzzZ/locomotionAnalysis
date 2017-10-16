function spikeAnalysis(dataDir)

    % performs low-level analysis on raw spike files:
    %
    % iterates through all data forlders in dataDir and performs several low-level computations on the spike data in run.mat
    % it converts the wheel and obstacle rotary encoder channels into positional units, and the commands to the stepper motor to positional units
    % it also converts the reward channel from analog to digital (this digital input was recorded on an analog channel because I ran out of spike digital inputs)
    % it then saves these data to runAnalyzed.mat in each folder, along with the other non-processed spike channels ()
    %
    % input      dataDir: directory containing all of the data folders // must ONLY contain data session folders


    % settings
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
        
        analyzeSpike = ~any(cellfun(@(s) strcmp(s, 'runAnalyzed.mat'), {sessionFiles.name}));
        analyzeVid = ~any(cellfun(@(s) strcmp(s, 'frameTimeStamps.mat'), {sessionFiles.name})) &&...
                                exist([sessionDir '\run.csv'], 'file');

        if analyzeSpike || analyzeVid
            fprintf('\nANALYZING %s\n\n', dataFolders(i).name);
        end
        
        if analyzeSpike

            % load data
            load([sessionDir '\run.mat']);

            % find reward times
            minRewardInteveral = 1;
            rewardInds = find(diff(reward.values>2)==1);
            rewardTimes = reward.times(rewardInds);
            rewardTimes = rewardTimes(logical([diff(rewardTimes) > minRewardInteveral; 1])); % remove reward times occuring within minRewardInteveral seconds of eachother

            % decode stepper motor
            fprintf('  decoding stepper motor commands...\n')
            if ~isempty(stepDir.times)
                [motorPositions, motorTimes] = motorDecoder(stepDir.level, stepDir.times, step.times, targetFs);
            else
                motorPositions = [];
                motorTimes = [];
            end

            % decode obstacle position (from rotary encoder on stepper motor track)
            fprintf('  decoding obstacle position...\n')
            if ~isempty(obEncodA.times)
                [obsPositions, obsTimes] = rotaryDecoder(obEncodA.times, obEncodA.level,...
                                                             obEncodB.times, obEncodB.level,...
                                                             obEncoderSteps, obsRad, targetFs);
            else
                obsPositions = [];
                obsTimes = [];
            end

            % decode wheel position
            fprintf('  decoding wheel position...\n')
            [wheelPositions, wheelTimes] = rotaryDecoder(whEncodA.times, whEncodA.level,...
                                                         whEncodB.times, whEncodB.level,...
                                                         whEncoderSteps, wheelRad, targetFs);

            % save data
            save([sessionDir '\runAnalyzed.mat'], 'rewardTimes',...
                                                  'motorPositions', 'motorTimes',...
                                                  'obsPositions', 'obsTimes',...
                                                  'wheelPositions', 'wheelTimes',...
                                                  'targetFs');
        end

                                              
                                              
        % compute frame timeStamps if video was collected and not already analyzed
        
        if analyzeVid
            
            % load data
            load([sessionDir '\run.mat'], 'exposure')

            % get camera metadata and spike timestamps
            metadata = dlmread([sessionDir '\run.csv']); % columns: bonsai timestamps, point grey counter, point grey timestamps (uninterpretted)
            frameCounts = metadata(:,2);
            timeStampsFlir = flirTimeStampDecoderFLIR(metadata(:,3));

            if length(exposure.times) >= length(frameCounts)
                timeStamps = getFrameTimes(exposure.times, timeStampsFlir, frameCounts);
            else
                disp([  'session ' dataFolders(i).name ' has more frames than exposure TTLs... saving empty frameTimeStamps.mat'])
                timeStamps = [];
            end
            save([sessionDir '\frameTimeStamps.mat'], 'timeStamps')
        end
    end
end