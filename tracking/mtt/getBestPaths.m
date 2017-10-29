% function getBestPaths(unary, pairwise)

% CURRENTLY HAS ONLY ONE OCCLUDED STATE, AND NO EXCLUSION CONSTRAINTS!!!


objectNum = size(unary{1}, 1);
labels = nan(length(unary), objectNum);
nodeScores = cell(1, length(unary));
backPointers = cell(1, length(unary)-1);

% initializations
% (pick most probable label based solely on unary potentials)
% [~, labels(1,:)] = max(unary{1}, [], 2);
% backPointers{1} = labels(1,:)';
nodeScores{1} = unary{1};


for i = 2:length(unary)
    
    nodeScores{i}   = nan(objectNum, size(unary{i},2));
    backPointers{i-1} = nan(objectNum, size(unary{i},2));
    
    for j = 1:objectNum
        
        previousScores = nodeScores{i-1}(j,:);
        currentUnary   = unary{i}(j,:)';
        
        allTransitionScores = repmat(previousScores, length(currentUnary), 1) .* ...
                              pairwise{i-1} + ...
                              repmat(currentUnary, 1, length(previousScores));
        
        [nodeScores{i}(j,:), backPointers{i-1}(j,:)] = max(allTransitionScores, [], 2);
        
    end
end


% back trace

[pathScores, labels(end,:)] = max(nodeScores{end}, [], 2);

for i = fliplr(1:length(unary)-1)
    
    labels(i,:) = backPointers{i-1}(labels(i+1,:));
    
    
end






