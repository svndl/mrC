% This is an example for functional connectivity estimation using mrC..

%%
clear; clc;

mrCFolder = fileparts(pwd);%'/Users/kohler/code/gits';
addpath(genpath(mrCFolder));

ProjectPath = '/Volumes/Denali_4D2/Elham/EEG_Textscamble';

%% Read and prepare data from 16 group project

% indicate root folders

%sublist = extractfield(dir([ProjectPath '/nl*']),'name');% read the names of the folders in each session
ProjectPath = subfolders(ProjectPath,1);

[wPLI] = mrC.Connectivity.ConnectProject(ProjectPath);




