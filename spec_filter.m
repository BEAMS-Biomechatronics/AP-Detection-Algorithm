function [spec_filt_signal] = spec_filter(signal, params);

global fs

[b_spec, a_spec] = butter(params.filter_order, params.band_spec/(fs/2));
spec_filt_signal(:,1) = filtfilt(b_spec, a_spec, signal);