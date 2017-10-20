function spikeAnalysis2(dataDir, varsToOverWrite)

    % performs preliminary analysis on spike data and save in runAnalyzed.mat


    % settings
    targetFs = 1000; % frequency that positional data will be resampled to
    minRewardInteveral = 1;

    % rig characteristics
    whEncoderSteps = 2880; % 720cpr * 4
    wheelRad = 95.25; % mm
    obEncoderSteps = 1000; % 250cpr * 4
    obsRad = 96 / (2*pi); % radius of timing pulley driving belt of obstacles platform

    % if no variables to overwrite are specified, set to default
    if nargin==1
        varsToOverWrite = {' '};
    end

    % find all data folders in dataDir
    dataFolders = dir(dataDir);
    dataFolders = dataFolders(3:end); % remove current and parent directory entries
    dataFolders = dataFolders([dataFolders.isdir]); % keep only folders




    % iterate over data folders and analyze those that have not been analyzed
    for i = 1:length(dataFolders)

        
        % load or initialize data structure
        sessionDir = [dataDir '\' dataFolders(i).name '\'];
        
        if exist([sessionDir 'runAnalyzed.mat'])
            varStruct = load([sessionDir 'runAnalyzed.mat']);
        else
            varStruct = struc();
        end
        varNames = fieldnames(varStruct);
        


        % analyze reward times
        if analyzeVar('rewardTimes', varNames, varsToOverWrite)
            
            fprintf('%s: getting reward times\n', dataFolders(i).name)
            load([sessionDir 'run.mat'], 'reward')
                        
            % find reward times
            rewardInds = find(diff(reward.values>2)==1);
            rewardTimes = reward.times(rewardInds);

            % remove reward times occuring within minRewardInteveral seconds of eachother
            rewardTimes = rewardTimes(logical([diff(rewardTimes) > minRewardInteveral; 1]));

            % save values
            varStruc.rewardTimes = rewardTimes;
        end
        
        
        
        
        % decode stepper motor commands
        if analyzeVar('motorPositions', varNames, varsToOverWrite) ||...
           analyzeVar('motorTimes', varNames, varsToOverWrite)
            
            load([sessionDir 'run.mat'], 'step', 'stepDir')
            
            % decode stepper motor
            if ~isempty(stepDir.times)
                fprintf('%s: decoding stepper motor commands\n', dataFolders(i).name)
                [motorPositions, motorTimes] = motorDecoder(stepDir.level, stepDir.times, step.times, targetFs);
            else
                motorPositions = [];
                motorTimes = [];
            end
            
            % save values
            varStruc.motorPositions = motorPositions;
            varStruc.motorTimes = motorTimes;
        end
        
        
        
        
        % decode obstacle position (based on obstacle track rotary encoder)
        if analyzeVar('obsPositions', varNames, varsToOverWrite) ||...
           analyzeVar('obsTimes', varNames, varsToOverWrite)
            
            load([sessionDir 'run.mat'], 'obEncodA', 'obEncodB')
            
            if ~isempty(obEncodA.times)
                fprintf('%s: decoding obstacle position\n', dataFolders(i).name)
                [obsPositions, obsTimes] = rotaryDecoder(obEncodA.times, obEncodA.level,...
                                                             obEncodB.times, obEncodB.level,...
                                                             obEncoderSteps, obsRad, targetFs);
            else
                obsPositions = [];
                obsTimes = [];
            end
            
            % save values
            varStruc.obsPositions = obsPositions;
            varStruc.obsTimes = obsTimes;
        end
        
        
        
        
        % decode wheel position
        if analyzeVar('wheelPositions', varNames, varsToOverWrite) ||...
           analyzeVar('wheelTimes', varNames, varsToOverWrite)
            
            fprintf('%s: decoding wheel position\n', dataFolders(i).name)
            load([sessionDir 'run.mat'], 'whEncodA', 'whEncodB')
            
            [wheelPositions, wheelTimes] = rotaryDecoder(whEncodA.times, whEncodA.level,...
                                                         whEncodB.times, whEncodB.level,...
                                                         whEncoderSteps, wheelRad, targetFs);
            % save values
            varStruc.wheelPositions = wheelPositions;
            varStruc.wheelTimes = wheelTimes;
        end
        
        
        
        
        % get obstacle on and off times
        % (ensuring that first event is obs turning ON and last is obs turning OFF)
        if analyzeVar('obsOnTimes', varNames, varsToOverWrite) ||...
           analyzeVar('obsOffTimes', varNames, varsToOverWrite)
       
            fprintf('%s: getting obstacle on and off times\n', dataFolders(i).name)
            load([sessionDir 'run.mat'], 'obsOn')
       
            firstOnInd  = find(obsOn.level, 1, 'first');
            lastOffInd  = find(~obsOn.level, 1, 'last');
            
            obsOn.level = obsOn.level(firstOnInd:lastOffInd);
            obsOn.times = obsOn.times(firstOnInd:lastOffInd);
            
            obsOnTimes  =  obsOn.times(logical(obsOn.level));
            obsOffTimes = obsOn.times(logical(~obsOn.level));
            
            % save values
            varStruc.obsOnTimes = obsOnTimes;
            varStruc.obsOffTimes = obsOffTimes;
            
        end
        
        
        
        
        % save results
        save([sessionDir 'runAnalyzed.mat'], '-struct', 'varStruct')
        fprintf('----------\n')
    end
    
    
    
    
    % ---------
    % FUNCTIONS
    % ---------
    
    function analyze = analyzeVar(var, varNames, varsToOverWrite)

        analyze = ~any(strcmp(varNames, var)) || strcmp(varsToOverWrite, var);
        
    end

    
    
    
    
    
    
    
    
end


