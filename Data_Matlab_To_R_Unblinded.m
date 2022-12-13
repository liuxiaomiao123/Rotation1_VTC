% written by Liangying, 11/18/2022
clear;
clc;

arrDATA_dir = 'D:\brainbnu\VTC\Data_Regression';
subjlist = fullfile(arrDATA_dir, 'Subs.txt');

fid = fopen(subjlist); 
sublist = {}; 
cntlist = 1;
while ~feof(fid)
    linedata = textscan(fgetl(fid), '%s');
    sublist(cntlist,:) = linedata{1}; 
    cntlist = cntlist + 1; 
end
fclose(fid);

subs = sublist(:,1);
AI = sublist(:,2);
sham = sublist(:,3);

group = 'sham';  % AI or sham trials

Regression.behav = [];
Regression.eeg = [];
Regression.sub = [];   
Regression.cheps = [];

for isub = 1:length(sublist)
    sub_path = fullfile(arrDATA_dir, sublist{isub});
    if strcmp(group, 'AI')
        cheps_name = ['CHEPS_', AI{isub}];
    else
        cheps_name = ['CHEPS_', sham{isub}];
    end
    cheps_path = fullfile(sub_path, cheps_name);
    cd(cheps_path);
    
    if ~isempty(dir('Delete*'))
        data_eeg = dir('Delete*');
        load(data_eeg.name);
        data_eeg = DATA;
    else
        data_eeg = dir('DATA_eeg*');
        load(data_eeg.name);
        data_eeg = DATA;
    end
     data_behav = dir('DATA_behav*');
     load(data_behav.name);
     data_behav = DATA;  
     if size(data_eeg,3) ~= length(data_behav)  % some subjects have 41 trials for eeg and I don't know why
        continue;
     end
     
     n = length(data_behav);
     Regression.behav = [Regression.behav; data_behav];
     Regression.eeg = cat(3, Regression.eeg, data_eeg);
     Regression.sub = [Regression.sub; repmat(subs{isub}, [n,1])];   % repelem for matlab>2014, my matlab version is too old
     Regression.cheps = [Regression.cheps; repmat(cheps_name, [n,1])];
end

save([arrDATA_dir, '\Data_Regression_', group, '.mat'], 'Regression');

