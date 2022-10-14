function [gen_filt_data, spec_filt_data, raw_data, rms_gen, rms_spec, idx] = get_data(data_to_use, params) 

%%% loads the signal with the orignal signal name
%%% filters it and returns a signal "data_filt" with the first column filtered with a butterworth BP with "specific" parameters, and second column a BP with the "generic" parameters
%%% and retturns the indexes of the first and last element of the filtered signal to study (usually 1 and length(filt_data))

global fs
rms_window = params.rms_window*fs;
MovRMS = dsp.MovingRMS(rms_window);

load([data_to_use.file + '.mat'], data_to_use.name);

raw_data = eval(data_to_use.name); %% gets the nemrical values for the variable name stated

%% set the delimitations for the raw data
if isempty(data_to_use.start)
    strt = 1;
else
    strt = data_to_use.start*fs + 1;
end

if isempty(data_to_use.end)
    stp = length (raw_data);
elseif data_to_use.end*fs > length(raw_data)
    stp = length(raw_data);
else
    stp = data_to_use.end*fs;
end

raw_data = raw_data(strt:stp);

%% filter the signal in both generic and specific ways
[b_gen, a_gen] = butter(params.filter_order, params.band_gen/(fs/2));
[b_spec, a_spec] = butter(params.filter_order, params.band_spec/(fs/2));

%%% IF THE SIGNAL IS ALREADY FILTERED, COMMENT FIRST TWO LINES AND
%%% UNCOMMENT THE THRID AND FOURTH ONES
gen_filt_data(:,1) = filtfilt(b_gen, a_gen, raw_data);
spec_filt_data(:,1) = filtfilt(b_spec, a_spec, raw_data);
% gen_filt_data(:,1) = raw_data;
% spec_filt_data(:,1) = raw_data;
idx = [strt, stp];

rms_gen = MovRMS(gen_filt_data);
rms_gen(1:rms_window) = 0;
rms_gen = circshift(rms_gen, - round(rms_window/2));
rms_gen(rms_gen > mean(rms_gen)) = mean(rms_gen);

rms_spec = MovRMS(gen_filt_data);
rms_spec(1:rms_window) = 0;
rms_spec = circshift(rms_gen, - round(rms_window/2));
rms_spec(rms_spec > mean(rms_spec)) = mean(rms_spec);


%% Plot signals
% time = [1:length(gen_filt_data)]/fs;
% figure; plot(time, gen_filt_data, 'b');
% hold on;
% plot(time, rms_gen, 'r');
% a = 1;