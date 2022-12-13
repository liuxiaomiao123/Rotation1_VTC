% written by Liangying, 11/15/2022
clear;
clc;

data_path = 'D:\brainbnu\VTC\Data_Regression\Data_Regression_sham.mat';
load(data_path);
[eegpower] = CHEP_wavelet(data_path);
Regression.eeg_power = eegpower;  
%save('D:\brainbnu\VTC\Data_Regression\Data_Regression.mat', 'Regression');

[electrode, time, trial] = size(Regression.eeg); 

Regression.eeg_power_cz = zeros(20,time,trial);
Regression.eeg_power_fz = zeros(20,time,trial);

Regression.eeg_power_cz = squeeze(Regression.eeg_power(1,:,:,:));
Regression.eeg_power_fz = squeeze(Regression.eeg_power(2,:,:,:));
Regression = rmfield(Regression, 'eeg_power');  % R cannot read 4D structure
save('D:\brainbnu\VTC\Data_Regression\Data_Regression_sham.mat', 'Regression');

