

%% Add latest mrC
clear;clc
mrCFolder = fileparts(fileparts(mfilename('fullpath')));%'/Users/kohler/code/git';
%mrCFolder = '/Users/bosse/svn_dev/mrC_branched/mrC/' ;
addpath(genpath(mrCFolder));

addpath(genpath('C:\Users\Elhamkhanom\Documents\Codes\Git\surfing'));% this tool can be found in github
%% Add subjects

DestPath = '/Users/kohler/code/git/mrC/Examples/ExampleData2';
AnatomyPath = fullfile(DestPath,'anatomy');
ProjectPath = fullfile(DestPath,'FwdProject');

% Pre-select ROIs
[RoiList,subIDs] = mrC.Simulate.GetRoiClass(ProjectPath,AnatomyPath);% 13 subjects with Wang atlab 
Glasser = cellfun(@(x) {x.getAtlasROIs('glass')},RoiList);
Glassnums = cellfun(@(x) x.ROINum,Glasser)>0;

%% ROI = glasser 128

% Glasser 128
Rois128_B = cellfun(@(x) x.searchROIs('roi128','glass','B'),RoiList,'UniformOutput',false);%
Rois128_B2 = cellfun(@(x) x.mergROIs2One,Rois128_B,'UniformOutput',false);%
Rois128_B = cellfun(@(x,y) x.mergROIs(y),Rois128_B,Rois128_B2,'UniformOutput',false);

% Glasser 129
Rois129_B = cellfun(@(x) x.searchROIs('roi129','glass','B'),RoiList,'UniformOutput',false);%
Rois129_B2 = cellfun(@(x) x.mergROIs2One,Rois129_B,'UniformOutput',false);%
Rois129_B = cellfun(@(x,y) x.mergROIs(y),Rois129_B,Rois129_B2,'UniformOutput',false);

% Glasser 130
Rois130_B = cellfun(@(x) x.searchROIs('roi130','glass','B'),RoiList,'UniformOutput',false);%
Rois130_B2 = cellfun(@(x) x.mergROIs2One,Rois130_B,'UniformOutput',false);%
Rois130_B = cellfun(@(x,y) x.mergROIs(y),Rois130_B,Rois130_B2,'UniformOutput',false);

% Glasser 176
Rois176_B = cellfun(@(x) x.searchROIs('roi176','glass','B'),RoiList,'UniformOutput',false);%
Rois176_B2 = cellfun(@(x) x.mergROIs2One,Rois176_B,'UniformOutput',false);%
Rois176_B = cellfun(@(x,y) x.mergROIs(y),Rois176_B,Rois176_B2,'UniformOutput',false);

RoisInd = cellfun(@(x,y) x.mergROIs(y),Rois128_B,Rois129_B,'UniformOutput',false);
RoisInd = cellfun(@(x,y) x.mergROIs(y),RoisInd,Rois130_B,'UniformOutput',false);
RoisInd = cellfun(@(x,y) x.mergROIs(y),RoisInd,Rois176_B,'UniformOutput',false);

[~,~,~,ScalpData,LIST,subIDs] = mrC.Simulate.ResolutionMatrices(ProjectPath,'rois',RoisInd,'roiType','glass','anatomyPath',AnatomyPath,'doScalpMap',true);

%% Plot the results
% first calculate average data
SD = ScalpData(cellfun(@(x) ~isempty(x),ScalpData));
ScalpData{1,end+1} = mean(cat(3,SD{:}),3);
subIDs{end+1} = 'Average over subjects';
%
SavePath = '/Users/babylab/Documents/Elham/GlasserROISim/';
for roi = 1:4
    for sub = 1:numel(subIDs)
        if ~isempty(ScalpData{sub}),
            FIG = figure;
       
%             h = text(.3,.9,[LIST{(roi-1)*3+1}(1:end-2) '  ' subIDs{sub}],'fontsize',16,'fontweight','bold');
            subplot(1,3,1),mrC.plotOnEgi(ScalpData{sub}((roi-1)*3+1,:));
            title('Left Hemi');
            axis tight;
            subplot(1,3,3),mrC.plotOnEgi(ScalpData{sub}((roi-1)*3+2,:));
            title('Right Hemi');
            axis tight;
            subplot(1,3,2),mrC.plotOnEgi(ScalpData{sub}((roi-1)*3+3,:));
            title('Bilateral');
            axis tight;
            
            TITLE = strrep(upper([subIDs{sub} '  ' LIST{(roi-1)*3+1}(1:end-2) ]),'_','-');
            
            np = get(gcf,'nextplot');
            set(gcf,'nextplot','add');
            axes('pos',[0 1 1 1],'visible','off','Tag','suptitle');
            ht=text(.5,-.1,TITLE);
            set(ht,'horizontalalignment','center','fontsize',11,'fontweight','bold');   
            
            set(FIG,'PaperPosition',[1 1 7 3.5]);
            print([SavePath LIST{(roi-1)*3+1}(1:end-2) '_' subIDs{sub}],'-dtiff','-r300');
            close all
        end
    end
end


