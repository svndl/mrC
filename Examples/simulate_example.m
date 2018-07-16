% This script generates an example simulated EEG with SSVEP signals
% for this script to run correctly you need three paths:
    % mrCpath: The latest mrC package
    % ProjectPath: Pointing to the mrC project folder of an SPECIFIC 
                % subject (this version of simulation package is not for group level data)
    % AnatomyPath: pointing to the folder where anatomy data is ()including
                % freesurfer files are and meshes and ROIs are (check the Example folder)
                
% Elham Barzegaran 3/14/2018
% Latest Modification: 7/16/2018

%% Add latest mrC
clear;clc
mrCFolder = fileparts(fileparts(mfilename('fullpath')));%'/Users/kohler/code/git';
addpath(genpath(mrCFolder));

addpath(genpath('C:\Users\Elhamkhanom\Documents\Codes\Git\surfing'));% this tool can be found in github

%% One subject mrC project and anatomy paths
DestPath = fullfile(mrCFolder,'Examples','ExampleData');

ProjectPath ='/Volumes/svndl/mrC_Projects/kohler/SYM_RT_LOCKED/SOURCE';
% This is to make a portable copy of the project data (both anatomy and forward)
[ProjectPath, AnatomyPath]  = mrC.Simulate.PrepareProjectSimulate(ProjectPath,DestPath ,'FwdFormat','mat');

ProjectPath = '/Volumes/svndl/mrC_Projects/kohler/SYM_16GR/SOURCE';
% This is to make a portable copy of the project data (both anatomy and forward)
[ProjectPath, AnatomyPath]  = mrC.Simulate.PrepareProjectSimulate(ProjectPath,DestPath ,'FwdFormat','mat');


ProjectPath = '/Volumes/svndl/mrC_Projects/Att_disc_annulus/Source';
% This is to make a portable copy of the project data (both anatomy and forward)
[ProjectPath, AnatomyPath]  = mrC.Simulate.PrepareProjectSimulate(ProjectPath,DestPath ,'FwdFormat','mat');

%% Example subject
% 16 subject have wang atlas ROIs

 AnatomyPath = fullfile(DestPath,'anatomy');
 ProjectPath = fullfile(DestPath,'FwdProject');

% Pre-select ROIs
[RoiList,subIDs] = mrC.Simulate.GetRoiClass(ProjectPath,AnatomyPath);% 13 subjects with Wang atlab 
Wangs = cellfun(@(x) {x.getAtlasROIs('wang')},RoiList);
Wangnums = cellfun(@(x) x.ROINum,Wangs)>0;

%% SSVEP signal can be simulated using ModelSourceSignal with defined parameters, otherwise Roisignal function will generate a default two source SSVEP signal 
% a simple SSVEP signal...

[outSignal, FundFreq, SF]= mrC.Simulate.ModelSeedSignal('signalType','SSVEP','signalFreq',[2 3.5],'signalHarmonic',{[2,0,1],[1,1,0]},'signalPhase',{[.1,0,.2],[0,.3,0]});

%% simulation functions
noise.mu=3;
RoisV2 = cellfun(@(x) x.searchROIs('V2d','wang'),RoiList,'UniformOutput',false);% % wang ROI

[EEGData,EEGAxx,sourceDataOrigin,masterList,subIDs] = mrC.Simulate.SimulateProject(ProjectPath,'anatomyPath',AnatomyPath,'signalArray',outSignal,'noiseParams',noise,'rois',RoisV2,'SavePath',savepath,'cndNum',1);














