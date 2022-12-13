% written by Liangying, 11/4/2022
clear;
clc;

arrDATA_dir = 'D:\brainbnu\VTC\Data_Regression';
bad_subjects = ['MJIWZA','TOVAWM','XX90XO','Y7ZFDS'];   % subjects with abnormal eeg data 

cd(arrDATA_dir)
subs = dir;
subs_name = extractfield(subs, 'name');
subs_name = subs_name(1,3:end)'; % delete . and .. names
subs_num = length(subs_name);

Regression.behav = [];
Regression.eeg = [];
Regression.sub = [];   
Regression.cheps = [];


for isub = 1:subs_num
    if ~isempty(strfind(bad_subjects, subs_name{isub})) 
        continue;
    end
    sub_path = fullfile(arrDATA_dir, subs_name{isub});
    file = dir([sub_path, '\CHEPS*']);
    if isempty(file)
        continue;
    end
    [n,m] = size(file);
    
    i = randi([1,n]);   % randomly pick one of the cheps per subject due to double-blind experiments
    cheps_name = file(i).name;
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
     Regression.sub = [Regression.sub; repmat(subs_name{isub}, [n,1])];   % repelem for matlab>2014, my matlab version is too old
     Regression.cheps = [Regression.cheps; repmat(cheps_name, [n,1])];
end

save([arrDATA_dir, '\Data_Regression.mat'], 'Regression');