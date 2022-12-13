function [eegpower] = CHEP_wavelet(data_path)
% adpated by Liangying, 11/14/2022

load(data_path);
ALL = Regression.eeg;
%%
chan2view = {'CZ','FZ'}; % Pick as many channels as you want

EEG.data   = ALL;
EEG.trials = size(ALL,3);
EEG.pnts   = size(ALL,2);
fs = 1000;
EEG.srate  = fs;
EEG.times = -2000:2000;
baseidx    = dsearchn(EEG.times',[-1800 -500]'); % baseline for wavelet in msec

min_freq =  2;
max_freq = 60;
num_frex = 20;

% define wavelet parameters
time = -1:1/EEG.srate:1;
frex = logspace(log10(min_freq),log10(max_freq),num_frex);
s    = logspace(log10(3),log10(10),num_frex)./(2*pi*frex);
% s    =  3./(2*pi*frex);
% s    = 10./(2*pi*frex);

% definte convolution parameters
n_wavelet            = length(time);
n_data               = EEG.pnts*EEG.trials;
n_convolution        = n_wavelet+n_data-1;
n_conv_pow2          = pow2(nextpow2(n_convolution));
half_of_wavelet_size = (n_wavelet-1)/2;
n_chanel = length(chan2view);

 % initialize
 eegpower = zeros(n_chanel,num_frex, EEG.pnts, EEG.trials); % frequencies X time X trials
 eegpower_unnormalized = zeros(n_chanel,num_frex, EEG.pnts, EEG.trials);

for c = 1:n_chanel
    % get FFT of data
    eegfft = fft(reshape(EEG.data(c,:,:),1,EEG.pnts*EEG.trials),n_conv_pow2);

    % loop through frequencies
    for fi=1:num_frex
        
        wavelet = fft( sqrt(1/(s(fi)*sqrt(pi))) * exp(2*1i*pi*frex(fi).*time) .* exp(-time.^2./(2*(s(fi)^2))) , n_conv_pow2 );
        
        % convolution
        eegconv = ifft(wavelet.*eegfft);
        eegconv = eegconv(1:n_convolution);
        eegconv = eegconv(half_of_wavelet_size+1:end-half_of_wavelet_size);
        
        % Average power over trials (this code performs baseline transform,
        
        %temppower       = mean(abs(reshape(eegconv,EEG.pnts,EEG.trials)).^2,2);
        temppower  = abs(reshape(eegconv,EEG.pnts,EEG.trials)).^2,2;
        %eegpower_unnormalized(c,fi,:, :) = temppower;
        
        baseline = mean(temppower(baseidx(1):baseidx(2),1));  % treat the first trial as baseline
        eegpower(c,fi,:, :)  = 10*log10(temppower ./baseline);
        %eegpower(fi,:, :)  = 10*log10(temppower./mean(temppower(baseidx(1):baseidx(2))));
        %eegpower2(fi,:) = temppower;
    end
end


