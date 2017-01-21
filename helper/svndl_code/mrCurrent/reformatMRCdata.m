function outData=reformatMRCdata(gD)
% function outData=reformatMRCdata(gD)
% mrCurrent can dump a bunch of data in the workspace but it is not very
% conveniently-organized. This function will return a large matrix with
% subs x conds x ROIs x timePoints for the common ROIs
% It will also return things like the ROI, cond  and sub names in
% differenta
% You should pass in gD which will be in the workspace when you export data from mrCurrent

% Analyze gD structure for CRF data. 

outData.waveFormFormat='subs x conds x ROIs x time';
outData.subNames=fieldnames(gD);
outData.nSubs=length(outData.subNames);

% gD is not stored in a very convenient way - each subject is a separate
% fieldname which makes it hard to iterate through them. 
% Make a new structure which contains the info in gD but ordered
% differently

for thisSub=1:outData.nSubs
    rawData{thisSub}=gD.(outData.subNames{thisSub});
end

% Now get the condition names. We have to assume that these are the same
% for each subjects as they were parsed by mrCurrent
outData.condNames=fieldnames(rawData{1});
outData.nConds=length(outData.condNames);

% ExptName
outData.exptName=fieldnames(rawData{1}.(outData.condNames{1}).ROI);
outData.exptName=outData.exptName{1};

% Get a list of ROIs in the first subject
finalROIList=fieldnames(rawData{1}.(outData.condNames{1}).ROI.(outData.exptName).Wave.none.Bilat);
for thisSub=1:outData.nSubs
   thisSubROIList=fieldnames(rawData{thisSub}.(outData.condNames{1}).ROI.(outData.exptName).Wave.none.Bilat);
   finalROIList=intersect(thisSubROIList,finalROIList);
end

outData.commonROIList=finalROIList;
outData.nROIs=length(outData.commonROIList);

% Extract a big matrix of waveforms for each subject x condition x ROI

for thisSub=1:outData.nSubs
    disp(thisSub);
    for thisCond=1:outData.nConds
        disp(thisCond);
        for thisROI=1:outData.nROIs
            disp(thisROI);
            outData.waveForm(thisSub,thisCond,thisROI,:)=rawData{thisSub}.(outData.condNames{thisCond}).ROI.(outData.exptName).Wave.none.Bilat.(outData.commonROIList{thisROI});
        end
    end
end


    

