function [gen_filt_signal] = gen_filter(signal, params);

global fs

[b_gen, a_gen] = butter(params.filter_order, params.band_gen/(fs/2));
gen_filt_signal(:,1) = filtfilt(b_gen, a_gen, signal);