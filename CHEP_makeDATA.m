function CHEP_makeDATA(cheps_path, data_path)
% This is a preprocessing script for CHEPs that creates DATA variable
% for other scripts such as CHEP_wavelet and CHEP_compare_traces

events2remove = []; 
% If you have run it and some events look like shit put them here to remove from average

%temp      = uigetdir;
temp      = data_path;
temp1     = regexp(temp,'\','split');
file      = temp1{end};
file2save = ['DATA_' file(1:end-4)];
temp2     = strfind(temp,'\');
directory = temp(1:temp2(end));

%savedir   = temp(1:temp2(4));
%savedir = 'D:\brainbnu\VTC\Data_Regression\0K783I\CHEPS_06232022';
savedir = cheps_path;
cd(directory)

only2chans = 1;
save2file  = 1;

%Filtering 

lowpass  = 30; % Hz
highpass = 0.5; % Hz

%Epoching

window = [-2 2]; % Seconds -- make at least [-2 2] for tf decomposition

%Manual check epochs for artifact

manual_check = 0;

%Reference?

ref_none = 1; % No change 
avg_ref  = 0;
mastoid  = 0; % [29, 47] is bilateral mastoid for example
other    = 0; % Put in reference channel

 
%% 
EEG           = mff_import(file);
%%
EEG           = eeg_checkset( EEG );
num_chans     = size(EEG.data,1);
fs            = EEG.srate;
pts           = abs(window(1)*fs)+(window(2)*fs)+1;
data          = EEG.data;
channels      = {'1','2','3','CFZ','FP2','FZ','7','8','9','FP1','11','F3','13','14','15','16','17', ...
    'F7','19','C3','21','22','23','T7','25','26','27','P3','LM','P7','31','32','33','PZ','O1', ...
    '36','OZ','38','O2','40','41','P4','43','P8','45','46','RM','48','49','C4','51','T8','53','54','55', ...
    '56','57','F8','59','F4','61','62','63','64','CZ','HR','RR'}; % Check if RR was collected as 67th channel

if only2chans
    chan_labels = {'CZ','FZ'};
end

% Reference data
if avg_ref
    data_ref      = reref(data);
    file2save     = [file2save '_ref_avg'];
    chan_labels   = channels;
    chans2lookat  = [6,63];
elseif mastoid
    data_ref      = reref(data,[29,47]);
    temp          = 1:size(data,1);
    temp(29)      = [];
    temp(46)      = []; % 1-minus original channel due to previous deletion
    chans         = temp;
    for i = 1:length(chans)
        chan_labels{i} = channels{chans(i)};
    end
    file2save     = [file2save '_ref_mast'];
    chans2lookat  = [6,63];
elseif other
    data_ref = reref(data,other);
    temp          = 1:65;
    temp(other) = [];
    chans         = temp;
    for i = 1:length(chans)
        chan_labels{i} = channels{chans(i)};
    end
    chans2lookat  = [6,63];
    file2save     = [file2save '_ref' num2str(other)];
else
    data_ref = data;
end


for i = 1:size(EEG.event,2)
events(i,1)     = EEG.event(i).latency;
event_type{i,1} = EEG.event(i).type;
end

% Remove non-DI events

%%temp   = contains(event_type,'DI');  % no contains function in matlab2014
%tmp = strfind(event_type, 'DI');
%indx = find(~cellfun(@isempty, tmp));
%events = events(indx);
%%events = events(temp);
%temp3  = diff(events);
%temp4  = find(temp3 > 100 & temp3 < 500);

%LIFU_events = events(temp4);
%CHEP_events = events(temp4+1);

tmp  = strcmp(event_type,'DIN4');
CHEP_events = events(tmp);

% LIFU_events(events2remove) = [];
% CHEP_events(events2remove) = [];

%filtering    
[b,a] = butter(3,[highpass/(fs/2) lowpass/(fs/2)],'bandpass');
    for c = 1:size(data_ref,1)
    data_filt(c,:)  = filtfilt(b,a,double(data_ref(c,:)));
    end
    
% epoch data
for c = 1:size(data_filt,1)
for i = 1:length(CHEP_events)
    data_epoch(c,:,i)  = data_filt(c,CHEP_events(i)+(window(1)*fs):CHEP_events(i)+(window(2)*fs));    
end
end

% baseline correct
for c = 1:size(data_epoch,1)
for i = 1:size(data_epoch,3)
    data_bc(c,:,i) = data_epoch(c,:,i)-mean(data_epoch(c,1:abs(window(1)*fs),i));
end
end

%% Black out events2remove
for i = 1:length(events2remove)
    data_bc(:,:,events2remove(i)) = NaN;
end
%%

xline = linspace(window(1)*fs,window(2)*fs,size(data_epoch,2));

if manual_check
    for f = 1:size(data_epoch,2)
    figure
    set(gcf,'position',[50 50 1200 800])
    plot(xline,squeeze(data_bc(2,:,f)))
    reject(f,1) = getkeywait(10);
    close gcf
    end
else
end

%% Figures
cd(savedir)
mkdir('EEG_figures')
fig_dir = [savedir, '\EEG_figures'];

data_avg = squeeze(nanmean(data_bc,3));
if only2chans
xline = linspace(window(1)*fs,window(2)*fs,size(data_avg,2));
% set(gcf,'position',[0 0 600 600])
    for f = 1:2
    blah  = max(max(data_bc(f,:,:)))*1.5;
    figure
    subplot(211)
    plot(xline,data_avg(f,:))
    xlim([window(1)*fs window(2)*fs])
    title(chan_labels{f})
    subplot(212)
    imagesc(xline,1:size(data_bc,3),squeeze(data_bc(f,:,:))',[(blah*-1)/2 blah/2])
    set(gca,'ydir','normal')
    xlabel('Time (msec)')
    ylabel('Trial #')
    colormap jet
    
    savefig([fig_dir, '\fig',num2str(f)])
    end

else
    for i = 1:size(data_avg,1)
    subplot(8,9,i)
    plot(xline,data_avg(i,:))
    title(chan_labels{i})
    xlim([window(1)*fs window(2)*fs])
    end
axcopy % This allows to click on trace to enlarge

blah  = max(max(data_bc(chans2lookat(2),:,:)))*1.5;
figure
    subplot(211)
    plot(xline,data_avg(chans2lookat(2),:))
    xlim([window(1)*fs window(2)*fs])
    title(chan_labels{chans2lookat(2)})
    subplot(212)
    imagesc(xline,1:size(data_bc,3),squeeze(data_bc(chans2lookat(2),:,:))',[(blah*-1)/2 blah/2])
    set(gca,'ydir','normal')
    xlabel('Time (msec)')
    ylabel('Trial #')
    colormap jet
    
    savefig([fig_dir, '\FZ.fig']);
end

% Make all DATA files same number of events
if only2chans == 1
DATA = data_bc(1:2,:,:);
DATA(:,:,events2remove) = [];
else
DATA = data_bc(chans2lookat,:,:);
DATA(:,:,events2remove) = [];
end
    


%% Save data
cd(savedir)
mkdir('EEG_figures')
fig_dir = [savedir, 'EEG_figures'];
saveallfigs(['CHEP_raster_' temp1{end}(1:end-4) '_'],fig_dir)
if save2file
cd(savedir)
if only2chans == 0
save(file2save,'DATA','window','fs','xline','chan_labels','lowpass','highpass','events2remove')
else
save(file2save,'DATA','EEG','window','fs','xline','chan_labels','lowpass','highpass','events2remove') 
end
else
end


