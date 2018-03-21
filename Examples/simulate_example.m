% This script generates an example simulated EEG with SSVEP signals
% for this script to run correctly you need three paths:
    % mrCpath: The latest mrC package
    % ProjectPath: Pointing to the mrC project folder of an SPECIFIC 
                % subject (this version of simulation package is not for group level data)
    % AnatomyPath: pointing to the folder where anatomy data is ()including
                % freesurfer files are and meshes and ROIs are (check the Example folder)
                
% Elham Barzegaran 3/14/2018
%%
clear;clc

%% Add latest mrC
mrCFolder = fileparts(pwd);%'/Users/kohler/code/gits';
addpath(genpath(mrCFolder));

%% SSVEP signal can be simulated using ModelSourceSignal with defined parameters, otherwise Roisignal function will generate a default two source SSVEP signal 
% a sample SSVEP signal...

%[outSignal, FundFreq, SF]= mrC.Simulate.ModelSeedSignal('signalType','SSVEP','signalFreq',[2 3.5 5],'signalHarmonic',{[2,0,1],[0,1,0,2],[2, 2]},'signalPhase',{[.1,0,.2],[0,.3,0,.4],[.2,.5]});

%[sensorData,masterList,subIDs] = mrC.Simulate.RoiSignal(ProjectPath,'anatomyPath',AnatomyPath,'signalArray',outSignal);

%% One subject mrC project and anatomy paths
% Example subject
% DataFolder = 'C:\Users\Elhamkhanom\Documents\My works\StanfordWorks\simulation\';
% ProjectPath{1} = fullfile(DataFolder,'Example','nl-0014_ssn2'); % example folder...
% AnatomyPath = fullfile(DataFolder,'Example','anatomy');

ProjectPath = '/Volumes/svndl/4D2/kohler/SYM_16GR/SOURCE';
ProjectPath = subfolders(ProjectPath,1); ProjectPath = ProjectPath(1:2:end); % All subjects in this project, just for the first session

AnatomyPath = '/Volumes/svndl/anatomy';

%% simulation functions
noise.mu=3;
%noise.distanceType = 'Geodesic';

[sensorData,masterList,subIDs] = mrC.Simulate.RoiSignal(ProjectPath,'anatomyPath',AnatomyPath,'roiType','func','noiseParams',noise);

%%
