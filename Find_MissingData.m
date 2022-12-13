function [indx] = Find_MissingData(cheps_path,Behav_path, threshold, trials)
% written by Liangying, 11/4/2022

cd(Behav_path);
tmp = dir;
tmp(1:2,:) = [];
behav_data = struct2table(tmp);
behav_data = sortrows(behav_data, 'date');
behav_data = table2cell(behav_data);
[n,m] = size(behav_data);

if n < trials
    time = behav_data(:,2);
    for i = 1:length(time)
        time{i,1} = time{i,1}(end-8:end);   % cannot recognize Chinese date, otherwise skip this step
    end
    
    latency = zeros(length(time)-1,1);
    for i = 1:length(time)-1
        tmp = datestr(datenum(time{i+1,1}, 'hh:mm:ss')-datenum(time{i,1}, 'hh:mm:ss'), 'ss'); % 'dd-mm-yyyy hh:mm:ss'
        latency(i,1) = str2num(tmp);
    end
    indx = find(latency >= threshold) + 1;    % trials that need to be deleted
else 
    indx = -1;
end

load(behav_data{end,1});
s = regexp(cheps_path, '\', 'split');
new_name = ['DATA_behav_',s{1,end-1}, '_', s{1,end}(end-8:end),'.mat'];  
%eval('[s{1,end-1}, ''_'', s{1,end}, ''_Behav'']') = DATA;   % use " instead of '
save(fullfile(cheps_path, new_name), 'DATA');



