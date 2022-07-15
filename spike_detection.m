function [detected_spikes] = spike_detection(reference_spike,detection_params, gen_filt_data, spec_filt_data, rms_gen, previous_spikes)

%% detected_spikes.gen_values are the values in the generic signal of the spikes detected. Each row is one spike
%% detected_spikes.spec_values are the values in the specific signal of the spikes detected. Each row is one spike
%% detected_spikes.times contains the times corresponding to those values. Each row is one spike
%% detected_spikes.center contains the location (not time value) of the center of the spikes (the top of the correlation with the template) in a column vector

global fs 
max_amp = rms_gen*detection_params.max_amp_rms_ratio;
min_amp = rms_gen*detection_params.min_amp_rms_ratio;
detected_spikes = [];
tmplt_len = length(reference_spike.values);

%% Normalized correlation between template and signal, so same shape (width and relative heights of the points)
tmp_gen_filt_data = [zeros(ceil(tmplt_len/2),1); gen_filt_data; zeros(tmplt_len,1)]; %% padding with zeros for the correlation that is 'normalized', so requires manual padding
norm_corr_coeffs = [];

norm_reference_spike = reference_spike.values/norm(reference_spike.values);

disp('Normalized crosscorrelation')
parfor i = 1 : size(gen_filt_data, 1)
    block = tmp_gen_filt_data(i:i+tmplt_len-1);
    block = block/norm(block);
    norm_corr_coeffs(i,:) = sum(block.*norm_reference_spike);
end

%% we keep only the peaks with a correlation greater than the threshold
%%%%% note that we could add a minimum distance threshold between the peaks in the findpeaks function
[amps, locs] = findpeaks(abs(norm_corr_coeffs), 'MinPeakHeight', detection_params.generic_norm_xcorr_thresh, 'MinPeakDistance', detection_params.min_dist_2_spikes*fs); %% first the value of the peak, then its location. Both column vectors
%% add a minimum prominence or a minimal time between peaks, otherwise multiple instances


%% Remove spikes to close (superposing) to previously detected spikes with other templates or within this detection (for the latter, the one with the highest correlation is kept)
to_remove = []; %% ids of spikes to delete
for i_spike = 1:length(locs)
    if i_spike ~= length(locs) && (locs(i_spike + 1) - locs(i_spike)) <= detection_params.min_dist_2_spikes*fs + max(detection_params.generic_template_width)*fs
        if amps(i_spike + 1) > amps(i_spike + 1)
            to_remove = [to_remove; i_spike]; %% the spike is too close to its folowing neighbour and smaller correlation
        else 
            to_remove = [to_remove; i_spike+1]; %% the spike is too close to its folowing neighbour but bigger correlation
        end
    elseif any(previous_spikes + detection_params.min_dist_2_spikes*fs > locs(i_spike) & previous_spikes < locs(i_spike))
        to_remove = [to_remove; i_spike]; %% the spike is too close to a previously detected spike with another template (we try first if closer comming from behind)
    elseif any(locs(i_spike) > previous_spikes - detection_params.min_dist_2_spikes*fs & previous_spikes > locs(i_spike))
        to_remove = [to_remove; i_spike]; %% the spike is too close to a previously detected spike with another template (we try comming upfront)
    end
end
locs(to_remove) = []; %% we remove the spikes to close


%% Englobe the spikes in a rough time frame matrix based on their peaks in correlation 
detected_spikes.gen_values = [];
detected_spikes.times = [];
time = [1:length(gen_filt_data)]/fs; %% in case of delete of the plots above

%% remove spikes too much on the edges of the signal
to_remove = [];
parfor i = 1:length(locs)
    val = zeros(1, length(detection_params.spike_duration));
    if locs(i)-ceil(detection_params.spike_duration *fs) < 1
        to_remove = [to_remove i];
    elseif locs(i)+ceil(detection_params.spike_duration *fs) > length(spec_filt_data)
        to_remove = [to_remove i];
    end
end
locs(to_remove) = [];

%% useful values for right after
tmp_center = floor(detection_params.spike_duration*fs/2);
parfor i = 1:length(locs)
        raw_values = gen_filt_data(locs(i)-ceil(detection_params.spike_duration *fs/2):locs(i)+floor(detection_params.spike_duration *fs/2));
        raw_values = raw_values - mean(raw_values);
        raw_center_val = raw_values(tmp_center);
        if raw_center_val <= 0 %% the mono phasic spike points upwards
            raw_values = -raw_values; %% so spike_val should not be used to save the values in the end but just for the computation, or should be re-reversed before it
        end
        [tops_amps, tops_locs, tops_width, tops_promi] = findpeaks(raw_values);
        tops_amps = tops_amps';
        tops_locs = tops_locs';
        tops_width = tops_width';
        tops_promi = tops_promi';

        [spike_center_promi, noneed] = max(tops_promi(tops_locs <= tmp_center + floor(reference_spike.width * fs /2) & tops_locs >= tmp_center - floor(reference_spike.width * fs /2)));
        spike_center_loc = tops_locs(tops_promi == spike_center_promi);
        locs(i) = locs(i) + (spike_center_loc - (tmp_center));
end

%% Put a minimum/maximum amplitude criteria to continue as selected
to_remove = [];
parfor i = 1:length(locs)
    gen_values(i,:) = gen_filt_data(locs(i)-ceil(detection_params.spike_duration *fs/2):locs(i)+floor(detection_params.spike_duration *fs/2));
    spike_rough_amp = max(gen_values(i,:)) - min(gen_values(i,:));
    if spike_rough_amp < min_amp(locs(i)) || spike_rough_amp > max_amp(locs(i))
        to_remove = [to_remove i];
    end
    spec_values(i,:) = spec_filt_data(locs(i)-ceil(detection_params.spike_duration *fs/2):locs(i)+floor(detection_params.spike_duration *fs/2));
    times(i,:) = time(locs(i)-ceil(detection_params.spike_duration *fs/2):locs(i)+floor(detection_params.spike_duration *fs/2));
    center(i,:) = locs(i);
    rough_amp(i, :) = spike_rough_amp;
    type = reference_spike.type;
    original_template_width = reference_spike.width; 
end
gen_values(to_remove, :) = [];
spec_values(to_remove, :) = [];
times(to_remove, :) = [];
center(to_remove, :) = [];
rough_amp(to_remove, :) = [];

%% Store the spikes in a structure element
% disp('spikes detected : ' + string(length(center)))
detected_spikes.gen_values = gen_values;
detected_spikes.spec_values = spec_values;
detected_spikes.times = times;
detected_spikes.center = center;
detected_spikes.rough_amp = rough_amp;
detected_spikes.type = 1; %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% change if multiple templates
detected_spikes.original_template_width = detection_params.generic_template_width;


%% Plot the results
% figure; plot(time, gen_filt_data, 'b'); hold on; plot(time, norm_corr_coeffs, 'g'); 
% for i_spike = 1 : size(detected_spikes.gen_values, 1)
%     plot(detected_spikes.times(i_spike,:), detected_spikes.gen_values(i_spike,:), 'r');
% end
% title('First detection with generic template - B: gen filt data - R: spikes - G: norm xcorr coeff');ylim([-20, 20]);
% xlabel('Time (s)');
% ylabel('Amplitude (µV)');