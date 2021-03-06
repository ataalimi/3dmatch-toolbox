% Script to generate a correspondence dataset from RGB-D reconstructions
% Refer to: http://3dmatch.cs.princeton.edu/#keypoint-matching-benchmark
%
% ---------------------------------------------------------
% Copyright (c) 2016, Andy Zeng
% 
% This file is part of the 3DMatch Toolbox and is available 
% under the terms of the Simplified BSD License provided in 
% LICENSE. Please retain this notice and LICENSE if you use 
% this file (or any portion of it) in your project.
% ---------------------------------------------------------

% Path to scene data
dataPath = '../../data/test';
testScenes = {'7-scenes-redkitchen', ...
             'sun3d-home_at-home_at_scan1_2013_jan_1', ...
             'sun3d-home_md-home_md_scan9_2012_sep_30', ...
             'sun3d-hotel_uc-scan3', ...
             'sun3d-hotel_umd-maryland_hotel1', ...
             'sun3d-hotel_umd-maryland_hotel3', ...
             'sun3d-mit_76_studyroom-76-1studyroom2', ...
             'sun3d-mit_lab_hj-lab_hj_tea_nov_2_2012_scan1_erika'};

% Total number of comparisons in the correspondence dataset
numComparisons = 10000;

% Local TDF voxel grid parameters
voxelGridPatchRadius = 15; % in voxels
voxelSize = 0.01; % in meters
voxelMargin = voxelSize * 5;

% Make test scene frame lists
sceneDataList = cell(length(testScenes),1);
for sceneIdx = 1:length(testScenes)
    tmpSceneData.name = testScenes{sceneIdx};
    tmpSceneData.frameList = {};
    frameListIdx = 1;
    scenePath = fullfile(dataPath,tmpSceneData.name);
    seqDir = dir(fullfile(scenePath,'seq-*'));
    for seqIdx = 1:length(seqDir)
        seqName = seqDir(seqIdx).name;
        frameDir = dir(fullfile(scenePath,seqName,'frame-*.depth.png'));
        for frameIdx = 1:length(frameDir)
            framePath = fullfile(scenePath,seqName,frameDir(frameIdx).name(1:end-10));
            tmpSceneData.frameList{frameListIdx,1} = framePath;
            frameListIdx = frameListIdx+1;
        end
    end
    tmpSceneData.camK = dlmread(fullfile(scenePath,'camera-intrinsics.txt'));
    sceneDataList{sceneIdx} = tmpSceneData;
end

% Generate testing correspondences
validationData = {};
validationLabels = {};
while(size(validationData,1) < numComparisons)
    sampleIdx = size(validationData,1)+1;
    fprintf('Samples: %d/%d \n',sampleIdx,numComparisons);
    
    maxTries = 100;
    [p1,p2] = getMatchPair(sceneDataList,maxTries,voxelGridPatchRadius,voxelSize,voxelMargin);
    [p3,p4] = getNonMatchPair(sceneDataList,maxTries,voxelGridPatchRadius,voxelSize,voxelMargin);
    
    % Visualize
    subplot(2,2,1); imshow(p1.colorPatch);
    subplot(2,2,2); imshow(p2.colorPatch);
    subplot(2,2,3); imagesc(p1.depthPatch); axis equal; axis tight;
    subplot(2,2,4); imagesc(p2.depthPatch); axis equal; axis tight;

    validationData{sampleIdx,1} = p1;
    validationData{sampleIdx,2} = p2;
    validationLabels{sampleIdx} = 1;
    
    validationData{sampleIdx+1,1} = p3;
    validationData{sampleIdx+1,2} = p4;
    validationLabels{sampleIdx+1} = 0;
end

% Shuffle ordering of comparisons
shuffleIdx = randsample(numComparisons,numComparisons,'false');
data = {};
labels = {};
for dataIdx = 1:numComparisons
    data{dataIdx,1} = validationData{shuffleIdx(dataIdx),1};
    data{dataIdx,2} = validationData{shuffleIdx(dataIdx),2};
    labels{dataIdx,1} = validationLabels{shuffleIdx(dataIdx)};
end

% Save validation set
save('my-corres-dataset.mat','data','labels','-v7.3');
dlmwrite('my-corres-dataset-gt.log',[numComparisons;cell2mat(labels)]);
