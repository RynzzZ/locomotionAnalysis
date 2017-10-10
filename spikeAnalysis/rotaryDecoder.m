function [positions, times] = rotaryDecoder(aTimes, aStates, bTimes, bStates, encoderSteps, wheelRad, targetFs)

    % converts quadrature input from rotary encoder into real world positional units (m)
    % uses a lookup table method, where every encoder input is represented
    % as a transition of a 2 bit state to another 2 bit state (the two bits
    % being the states of the two encoder channels). this 4 bit code is
    % used to index into a lookup table that tells whether the encoder has
    % moved forward, back, or stayed stationary
    %
    % input        aTimes, bTimes:   times of state shifts in the A and B channels from the rotary encoder
    % 	           aStates, bStates: levels of A and B rotary encoder at times of state shifts
    %              encoderSteps:     number of steps per rotation in rotary encoder
    %              wheelRad:         radus or wheel, or timing pulley, attached to encoder
    %              targetFs:         sampling frequency with which data are interpolated (see interData)
    %
    % output       positions:        position of wheel in meters
    %              times:            times of all position values
    

    tic
    
    % convert inputs to row vectors
    aTimes = aTimes(:)';
    bTimes = bTimes(:)';
    aStates = logical(aStates(:))';
    bStates = logical(bStates(:))';
    
    % sort encoder events by time of occurence
    times = [aTimes bTimes];
    [times, sortInds] = sort(times);

    % create identities vector, where each element represents whether encoder A (0) or B (1) has changed state
    % this is the most economical representation of the encoder data, because the states can be inferred at all times if you known the starting state of both channels and the times at which those channels change
    identities = [zeros(1, length(aTimes)) ones(1, length(bTimes))];
    identities = identities(sortInds);

    deltas = nan(size(times)); % records whether encoder moves backwards (-1), forwards (1), or stays stationing (0)
    lookUp = [0,-1,1,0,1,0,0,-1,-1,0,0,1,0,1,-1,0];

    prevState = [~aStates(1) ~bStates(1)]; % the initial state of encoders A and B

    for i = 1:round(length(identities))

        currentState = prevState;
        currentState(identities(i)+1) = ~prevState(identities(i)+1);
        lookupInd = [prevState currentState];
        deltas(i) = lookUp(bin2dec(num2str(lookupInd))+1);
        prevState = currentState;

    end

    % convert to real-world units (m)
    mmPerTic = (2*wheelRad*pi) / encoderSteps;
    positions = cumsum(deltas) * (mmPerTic / 1000);
    
    decodingTime = toc/60; % minutes
    fprintf('rotary decoding time: %f minutes\n', decodingTime)
    
    % interpolate
    [times, positions] = interpData(times, positions, targetFs);
    
end











