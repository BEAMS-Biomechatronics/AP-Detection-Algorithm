function [detected_spikes] = cluster_spike_detection (clusters, spec_filt_data, detection_params, gen_filt_data, rms_spec, previous_spikes, original_template);

%% We detect the spikes based on the centroids of the clusters as template, using the specific signal this time.

%% spec_detected_spikes.spec_values are the values in the specific signal of the spikes detected. Each row is one spike
%% spec_detected_spikes.gen_values are the values in the generic signal of the spikes detected. Each row is one spike
%% spec_detected_spikes.times contains the times corresponding to those values. Each row is one spike
%% spec_detected_spikes.center contains the location (not time value) of the center of the spikes (the top of the correlation with the template) in a column vector
%% spec_detected_spikes.cluster_idx is a column vector containing the ID of the associated cluster for each spike detected

global fs
time_margin = detection_params.time_margin * fs;
max_amp = rms_spec*detection_params.max_amp_rms_ratio;
min_amp = rms_spec*detection_params.min_amp_rms_ratio;

%% Normalized correlation between template and signal, so same shape (width and relative heights of the points)
locs = [];
amps = [];
spec_detected_spikes.cluster_idx = [];
norm_corr_coeffs = [];
for n_cluster = 1: size(clusters.centroids, 1)
    reference_spike = clusters.centroids(n_cluster,:)'; %% we would like a column matrix for the template to mirror the code in the first generic detection
    tmplt_len = length(reference_spike);
    tmp_spec_filt_data = [zeros(ceil(tmplt_len/2),1); spec_filt_data; zeros(tmplt_len,1)]; %% padding with zeros for the correlation that is 'normalized', so requires manual padding

    norm_reference_spike = reference_spike/norm(reference_spike);

    disp('Specific cluster detection - Cluster ' + string(n_cluster))
    parfor i = 1 : size(spec_filt_data, 1)
        block = tmp_spec_filt_data(i:i+tmplt_len-1);
        block = block/norm(block);
        norm_corr_coeffs(i,n_cluster) = sum(block.*norm_reference_spike);
    end
end

%% combine all the data to avoid peak superpositions from different templates
[glob_norm_corr_coeffs, cluster_idx] = max(abs(norm_corr_coeffs), [], 2); %% takes the maximum of the absolute individual correlations of the cluster and the ID of the cluster frow which each max comes

%% we keep only the peaks with a correlation greater than the threshold
%%%%% note that we could add a minimum distance threshold between the peaks in the findpeaks fucntion
[tmp_amps, tmp_locs] = findpeaks(glob_norm_corr_coeffs, 'MinPeakHeight', detection_params.specific_norm_xcorr_thresh, 'MinPeakDistance', detection_params.min_dist_2_spikes*fs + max(detection_params.generic_template_width)*fs); %% minimum distance between two tops = min width + distance in between them


%% we remove the spikes closer than a time margin to other spikes (in peak temporal distance) to avoid duplicates
% i_spike = 1;
% while i_spike <= length(tmp_locs)
%     if ~isnan(locs(locs-time_margin < tmp_locs(i_spike) & tmp_locs(i_spike) < locs +time_margin))
%         tmp_locs(i_spike) =[];
%         tmp_amps(i_spike) =[];
%         i_spike = i_spike
%     else 
%         i_spike = i_spike +1;
%     end
% end
locs = [locs;tmp_locs];
amps = [amps; tmp_amps];
spec_detected_spikes.cluster_idx(end+1:end+length(tmp_locs), 1) = cluster_idx(tmp_locs);

%% Lets order them by time occurence for the following steps
tmp_spikes = [locs, amps];
tmp_spikes = sortrows(tmp_spikes);
locs = tmp_spikes(:,1);
amps = tmp_spikes(:,2);

%% Remove spikes to close (superposing) to previously detected spikes with other templates (within this detection already made in the findpeaks with the minpeakdistance)
to_remove = []; %% ids of spikes to delete
for i_spike = 1:length(locs)
    if any(previous_spikes + detection_params.min_dist_2_spikes*fs + max(detection_params.generic_template_width)*fs > locs(i_spike) & previous_spikes < locs(i_spike))
        to_remove = [to_remove; i_spike]; %% the spike is too close to a previously detected spike with another template (we try first if closer comming from behind)
    elseif any(locs(i_spike) > previous_spikes - detection_params.min_dist_2_spikes*fs - max(detection_params.generic_template_width)*fs & previous_spikes > locs(i_spike))
        to_remove = [to_remove; i_spike]; %% the spike is too close to a previously detected spike with another template (we try comming upfront)
    end
end
locs(to_remove) = []; %% we remove the spikes to close


%% Englobe the spikes in a time frame matrix based on their peaks and put a minimum/maximum amplitude criteria to continue as selected
spec_detected_spikes.spec_values = [];
spec_detected_spikes.times = [];
time = [1:length(spec_filt_data)]/fs; %% in case of delete of the plots above

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
        raw_values = spec_filt_data(locs(i)-ceil(detection_params.spike_duration *fs/2):locs(i)+floor(detection_params.spike_duration *fs/2));
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

        [spike_center_promi, noneed] = max(tops_promi(tops_locs <= tmp_center + floor(original_template.width * fs /2) & tops_locs >= tmp_center - floor(original_template.width * fs /2)));
        spike_center_loc = tops_locs(tops_promi == spike_center_promi);
        locs(i) = locs(i) + (spike_center_loc - (tmp_center));
end

%% Put a minimum/maximum amplitude criteria to continue as selected
to_remove = [];
parfor i = 1:length(locs)
    spec_values(i,:) = spec_filt_data(locs(i)-ceil(detection_params.spike_duration *fs/2):locs(i)+floor(detection_params.spike_duration *fs/2));
    spike_rough_amp = max(spec_values(i,:)) - min(spec_values(i,:));
    if spike_rough_amp < min_amp(locs(i)) || spike_rough_amp > max_amp(locs(i))
        to_remove = [to_remove i];
    end
    gen_values(i,:) = gen_filt_data(locs(i)-ceil(detection_params.spike_duration *fs/2):locs(i)+floor(detection_params.spike_duration *fs/2));
    times(i,:) = time(locs(i)-ceil(detection_params.spike_duration *fs/2):locs(i)+floor(detection_params.spike_duration *fs/2));
    center(i,:) = locs(i);
    rough_amp(i, :) = spike_rough_amp;
    type = original_template.type;
    original_template_width = original_template.width; 
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
detected_spikes.type = original_template.type; %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% change if multiple templates
detected_spikes.original_template_width = original_template.width;

%% Plot the results
% figure; plot(time, spec_filt_data, 'b'); hold on;
% for i_spike = 1 : size(spec_detected_spikes.gen_values, 1)
%     plot(spec_detected_spikes.times(i_spike,:), spec_detected_spikes.gen_values(i_spike,:), 'r');
% end
% title('Second detection with specific template - B: gen filt data - R: spikes');
% xlabel('Time (s)'); ylabel('Amplitude (µV)');
% ylim([-40, 40]);