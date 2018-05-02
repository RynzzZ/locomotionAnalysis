

sessions = {'180122_000', '180122_001', '180122_002', '180122_003', ...
            '180123_000', '180123_001', '180123_002', '180123_003', ...
            '180124_000', '180124_001', '180124_002', '180124_003', ...
            '180125_000', '180125_001', '180125_002', '180125_003'};

for i = 1:length(sessions)

    session = sessions{i};

    vid = VideoReader(['C:\Users\rick\Google Drive\columbia\obstacleData\sessions\' session '\runBot.mp4']);
%     locationsTable = readtable([getenv('OBSDATADIR') 'sessions\' session '\trackedFeaturesRaw.csv']); % get tracking data

    fprintf('\n%s\n', session)
    fprintf('matlab count............................ %i\n', vid.NumberOfFrames);
%     fprintf('moviepy count........................... %i\n', height(locationsTable));
    fprintf('amount predicted by duration............ %i\n', length([0:.004:vid.Duration]));
    fprintf('amount predicted by rounded duration.... %i\n', length([0:.004:round(vid.Duration*100)/100]));
end
