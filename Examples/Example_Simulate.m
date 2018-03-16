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
mrCpath = 'C:\Users\Elhamkhanom\Documents\Codes\Git\mrC'; % mrcpath
CurrentFolder = pwd; 
addpath(genpath(mrCpath));

%% One subject mrC project and anatomy paths
ProjectPath{1} = fullfile(CurrentFolder,'Example','nl-0014_ssn2'); % example folder...
AnatomyPath = fullfile(CurrentFolder,'Example','anatomy');
%% SSVEP signal can be simulated using ModelSourceSignal with defined parameters, otherwise Roisignal function will generate a default two source SSVEP signal 
% a sample SSVEP signal...
[ROIsig, FundFreq, SF]= mrC.Simulate.ModelSourceSignal('srcType','SSVEP','srcFreq',[2 3.5 5],'srcHarmonic',{[2,0,1],[0,1,0,2],[2, 2]},'srcPhase',{[.1,0,.2],[0,.3,0,.4],[.2,.5]});


%% simulation functions
noise.mu=3;
noise.distanceType = 'Geodesic';
[sensorData,masterList,subIDs] = mrC.Simulate.RoiSignal(ProjectPath,'anatomyPath',AnatomyPath,'noiseParams',noise);
%[sensorData,masterList,subIDs] = mrC.Simulate.RoiSignal(ProjectPath,'anatomyPath',AnatomyPath,'signalArray',ROIsig,'mu',noise.mu);


