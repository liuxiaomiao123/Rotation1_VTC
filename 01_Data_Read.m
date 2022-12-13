% written by Liangying, 11/3/2022
clear;
clc;

%% ------------------------------ Data Arrangment ------------------------------- %%
rawEEG_dir = 'D:\brainbnu\VTC\EEG_Data';
arrDATA_dir = 'D:\brainbnu\VTC\Data_Regression';
Data_arr = 0;

if Data_arr
    cd(rawEEG_dir);
    subs = dir;
    subs_name = extractfield(subs, 'name');
    subs_name = subs_name(1,3:end)'; % delete . and .. names
    subs_num = length(subs_name);
    ROI_type = 'Anterior Insula';
    
    for isub = 1:subs_num
        sub_path = fullfile(rawEEG_dir, subs_name{isub});
        file = dir([sub_path, '\CHEPS*']);
        if isempty(file)
            continue;
        end
        [n,m] = size(file);
        for i = 1:n
            cheps_name = file(i).name;
            cheps_path = fullfile(sub_path, cheps_name);
            flag = Find_ROI_File(ROI_type, cheps_path);
            if flag
                eeg_file = fullfile(cheps_path, 'EEG');
                behav_file = fullfile(cheps_path, 'Behav');
                mkdir(arrDATA_dir, subs_name{isub});
                mkdir(fullfile(arrDATA_dir, subs_name{isub}), cheps_name);
                arr_cheps_path = fullfile(arrDATA_dir, subs_name{isub}, cheps_name);
                copyfile(eeg_file,[arr_cheps_path,'\EEG']);
                copyfile(behav_file,[arr_cheps_path, '\Behav']);
            end
        end
    end
end


%% ------------------------------ Data Read ------------------------------- %%
% read EEG and Behav data
cd(arrDATA_dir)
subs = dir;
subs_name = extractfield(subs, 'name');
subs_name = subs_name(1,3:end)'; % delete . and .. names
subs_num = length(subs_name);
threshold = 26;
trials = 40;

for isub = 27:subs_num
    sub_path = fullfile(arrDATA_dir, subs_name{isub});
    file = dir([sub_path, '\CHEPS*']);
    if isempty(file)
        continue;
    end
    [n,m] = size(file);
    for i = 1:n
        cheps_name = file(i).name;
        cheps_path = fullfile(sub_path, cheps_name);
        eeg_file = fullfile(cheps_path, 'EEG');
        behav_file = fullfile(cheps_path, 'Behav');
        %cd(eeg_file);
        eeg_data_file = dir([eeg_file, '\*.mff']);
        eeg_data_file = fullfile(eeg_file,eeg_data_file.name);
        CHEP_makeDATA(cheps_path,eeg_data_file);  % epoching EEG data
        
        indx = Find_MissingData(cheps_path,behav_file,threshold,trials);
        if indx ~= -1
            cd(cheps_path);
            tmp = dir('DATA_eeg*');
            load(tmp.name);
            DATA(:,:,indx') = [];  % delete corresponding EEG data for missing behav trials
            save(['Delete_', tmp.name], 'DATA');
        end
    end
end


