% This script generates an example simulated EEG with SSVEP signals
% for this script to run correctly you need three paths:
    % mrCpath: The latest mrC package
    % ProjectPath: Pointing to the mrC project folder of an SPECIFIC 
                % subject (this version of simulation package is not for group level data)
    % AnatomyPath: pointing to the folder where anatomy data is ()including
                % freesurfer files are and meshes and ROIs are (check the Example folder)
                
% Elham Barzegaran 3/14/2018

%% Add latest mrC
clear;clc
mrCFolder = fileparts(pwd);%'/Users/kohler/code/gits';
addpath(genpath(mrCFolder));

addpath(genpath('/Users/kohler/code/git/surfing'));
%% SSVEP signal can be simulated using ModelSourceSignal with defined parameters, otherwise Roisignal function will generate a default two source SSVEP signal 
% a sample SSVEP signal...

%[outSignal, FundFreq, SF]= mrC.Simulate.ModelSeedSignal('signalType','SSVEP','signalFreq',[2 3.5 5],'signalHarmonic',{[2,0,1],[0,1,0,2],[2, 2]},'signalPhase',{[.1,0,.2],[0,.3,0,.4],[.2,.5]});
%[sensorData,masterList,subIDs] = mrC.Simulate.SimulateProject(ProjectPath,'anatomyPath',AnatomyPath,'signalArray',outSignal);

%% One subject mrC project and anatomy paths

ProjectPath = '/Volumes/svndl/mrC_Projects/kohler/SYM_16GR/SOURCE';

% This is to make a portable copy of the project data (both anatomy and project)
[ProjectPath, AnatomyPath]  = mrC.Simulate.PrepareProjectSimulate(ProjectPath,[],'FwdFormat','mat');

%% Example subject
% 10 subject in SYM_16 project have wang atlas ROIs

 AnatomyPath = '/Users/kohler/code/git/mrC/Examples/ExampleData/anatomy';
 ProjectPath = '/Users/kohler/code/git/mrC/Examples/ExampleData/FwdProject';

 %% Pre-select ROIs
[RoiList,RoiListC,subIDs] = mrC.Simulate.GetRoiList(ProjectPath,AnatomyPath,'wang');% 13 subjects with Wang atlab 
 
%% simulation functions
noise.mu=3;
% noise.distanceType = 'Geodesic';

[sensorData,masterList,subIDs] = mrC.Simulate.SimulateProject(ProjectPath,'anatomyPath',AnatomyPath,'roiType','wang','noiseParams',noise,'roiList',RoiList([31 10])');














