function [flag] = Find_ROI_File(ROItype, path)
% written by Liangying, 11/3/2022

%path = 'D:\brainbnu\VTC\EEG_Data\BUPKP9\CHEPS_03252022';
path = fullfile(path, 'Redcap\');
cd(path);
behav_csv = dir([path, '*.csv']);
behav_csv = behav_csv.name;
behav_data = readtable(behav_csv);
ROItype_cheps= behav_data.WhatBrainRegionIsBeingTargeted_;

if strcmp(ROItype_cheps, ROItype)
    flag = 1;
else 
    flag = 0;
end