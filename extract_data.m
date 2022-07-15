function [data_spikes, data_window] = extract_data_multi(detected_spikes, generic_templates, params, gen_filt_data, rms_spec)

%% returns data from the spikes such as amplitude range, effective starting and ending, duration, type (mono-phasic, bi-phasic, ...),
%% the total frequency of detection and of each template, the energy (frequency * amplitude * width), etc.

global fs;
max_amp = rms_spec*params.max_amp_rms_ratio;
min_amp = rms_spec*params.min_amp_rms_ratio;

margin = min(params.generic_template_width) * fs *1/3; %% margin that we will suppose the starting/ending points might be close to the perfect starting/ending points
i_spike = 1; %% count of processed spikes
spk_len = length(detected_spikes(1).spec_values(1, :)); %% length of the amplitude/time values of a spike
for tmplt = 1:length(detected_spikes)
    if detected_spikes(tmplt).type == 1 %% should be the monophasic
        
        tmp_center = floor(params.spike_duration*fs/2);
        parfor i = 1:size(detected_spikes(tmplt).center, 1)
            try
            save(i) = false;
            spike_val = detected_spikes(tmplt).spec_values(i, :) - mean(detected_spikes(tmplt).spec_values(i, :));
            spike_center_val = spike_val(tmp_center);
            rough_amp = max(spike_val) - min(spike_val); %% rough estimation of the amplitude of the spike with the full window, to define minimum prominence in the findpeak accordint to it
            if spike_center_val <= 0 %% the mono phasic spike points upwards
                spike_val = -spike_val; %% so spike_val should not be used to save the values in the end but just for the computation, or should be re-reversed before it
            end
            [tops_amps, tops_locs, tops_width, tops_promi] = findpeaks(spike_val, 'MinPeakProminence', 0.1*rough_amp);
            [botms_amps, botms_locs, botms_width, botms_promi] = findpeaks(-spike_val, 'MinPeakProminence', 0.1*rough_amp);
            tops_amps = tops_amps';
            tops_locs = tops_locs';
            tops_width = tops_width';
            tops_promi = tops_promi';
            botms_amps = botms_amps';
            botms_locs = botms_locs';
            botms_width = botms_width';
            botms_promi = botms_promi';
            botms_amps = -botms_amps;
            
            
            %% Define the starting and ending points of the spikes. One case if the spikes is oriented upwards, another if downwards
            %% find the highest peak within the main impulsion range
            [spike_center_promi, noneed] = max(tops_promi(tops_locs <= tmp_center + floor(detected_spikes(tmplt).original_template_width * fs /2) & tops_locs >= tmp_center - floor(detected_spikes(tmplt).original_template_width * fs /2)));
            spike_center_loc = tops_locs(tops_promi == spike_center_promi);

            locs_front = [tops_locs(tops_locs < spike_center_loc), tops_promi(tops_locs < spike_center_loc); botms_locs(botms_locs < spike_center_loc), botms_promi(botms_locs < spike_center_loc)];
            locs_front = sortrows(locs_front, 'descend');
            iteration = 5;
            while isempty(locs_front)
                [tops_amps, tops_locs, tops_width, tops_promi] = findpeaks(spike_val, 'MinPeakProminence', 0.1*rough_amp/5*iteration);
                [botms_amps, botms_locs, botms_width, botms_promi] = findpeaks(-spike_val, 'MinPeakProminence', 0.1*rough_amp/5*iteration);
                tops_amps = tops_amps';
                tops_locs = tops_locs';
                tops_width = tops_width';
                tops_promi = tops_promi';
                botms_amps = botms_amps';
                botms_locs = botms_locs';
                botms_width = botms_width';
                botms_promi = botms_promi';
                botms_amps = -botms_amps;

                if ~isempty(tops_locs) && ~isempty(tops_locs < spike_center_loc) && ~isempty(botms_locs) && ~isempty(botms_locs < spike_center_loc)
                    locs_front = [tops_locs(tops_locs < spike_center_loc), tops_promi(tops_locs < spike_center_loc); botms_locs(botms_locs < spike_center_loc), botms_promi(botms_locs < spike_center_loc)];
                    locs_front = sortrows(locs_front, 'descend');
                end
                iteration = iteration - 1;
                if iteration == -1
                    locs_front = [1, 0];
                end
            end
            locs_back = [tops_locs(tops_locs > spike_center_loc), tops_promi(tops_locs > spike_center_loc); botms_locs(botms_locs > spike_center_loc), botms_promi(botms_locs > spike_center_loc)];
            locs_back = sortrows(locs_back, 'ascend');
            iteration = 5;
            while isempty(locs_back) 
                [tops_amps, tops_locs, tops_width, tops_promi] = findpeaks(spike_val, 'MinPeakProminence', 0.1*rough_amp/5*iteration);
                [botms_amps, botms_locs, botms_width, botms_promi] = findpeaks(-spike_val, 'MinPeakProminence', 0.1*rough_amp/5*iteration);
                tops_amps = tops_amps';
                tops_locs = tops_locs';
                tops_width = tops_width';
                tops_promi = tops_promi';
                botms_amps = botms_amps';
                botms_locs = botms_locs';
                botms_width = botms_width';
                botms_promi = botms_promi';
                botms_amps = -botms_amps;
                if ~isempty(tops_locs) && ~isempty(tops_locs > spike_center_loc) && ~isempty(botms_locs) && ~isempty(botms_locs > spike_center_loc)
                    locs_back = [tops_locs(tops_locs > spike_center_loc), tops_promi(tops_locs > spike_center_loc); botms_locs(botms_locs > spike_center_loc), botms_promi(botms_locs > spike_center_loc)];
                    locs_back = sortrows(locs_back, 'ascend');
                end
                iteration = iteration - 1;
                if iteration ==-1
                    locs_back = [length(spike_val), 0];
                end
            end
            i_start = 1;
            done = false;
            start_loc = locs_front(1); %% by default if no better solution
            while ~done & i_start < size(locs_front)
                if locs_front(i_start, 2) < locs_front(i_start+1, 2)
                    done = true;
                    start_loc = locs_front(i_start, 1);
                end
                i_start = i_start +1;
            end
            i_end = 1;
            done = false;
            end_loc = locs_back(1); %% by default if no better solution
            while ~done & i_end < size(locs_back)
                if locs_back(i_end, 2) < locs_back(i_end+1, 2) %% if the prominence of the following extremum is greater, we stop there
                    done = true;
                    end_loc = locs_back(i_end, 1);
                end
                i_end = i_end +1;
            end
%             timme = [1:length(spike_val)]/fs; figure; plot(timme, spike_val, 'b'); hold on; plot(timme(start_loc), spike_val(start_loc), 'r*'); plot(timme(end_loc), spike_val(end_loc), 'g*');

            %% check criteria on amplitude, duration etc (udration not implemented yet since cannot be longer than the frame, but might be in the future
            short_val = detected_spikes(tmplt).spec_values(i, start_loc : end_loc);
            pad_len = spk_len - (end_loc - start_loc); %% how much nan values we will pad the values with to be consistent
            values(i, :) = padarray(short_val, [0, pad_len], nan, 'post'); %% padding with nan values
            amplitude(i, :) = max(values(i, :)) - min(values(i, :));
            if amplitude(i, :) >= min_amp(detected_spikes(tmplt).center(i)) & amplitude(i , :) <= max_amp(detected_spikes(tmplt).center(i))
                save(i) = true;
            end

            %% Save everything (amplitude and normal values already in) if the spike meets the criteria (otherwise removed afterwards)
            short_val_av = spike_val(start_loc : end_loc) - mean(spike_val(start_loc : end_loc)); %% put nan values for spaces not used as part of the spike but allows to work with matrixes composed of rows of same lengths
            values_averaged(i, :) = padarray(short_val_av, [0, pad_len], nan, 'post');
            center_loc(i, 1) = spike_center_loc + round(detected_spikes(tmplt).times(i, 1) * fs) -1; %% put the spike back in temporal context of the whole signal
            center_time(i, 1)= center_loc(i,1)/fs; %% put the spike back in temporal context of the whole signal and in time
            short_times = detected_spikes(tmplt).times(i, start_loc: end_loc);
            times(i, :) = padarray(short_times, [0, pad_len], nan, 'post');
            template(i, :) = tmplt;
            type(i, :) = detected_spikes(tmplt).type;
            duration(i, 1) = (end_loc - start_loc)/fs; %% duration of the effective spike
%             if mod(i, 5000) == 0
%                disp('Spikes processed : ' + string(i));
%             end

            catch
            end
        end
    elseif detected_spikes(tmplt).type == 2 %% should be the biphasic template
        tmp_center = floor(params.spike_duration*fs/2);
        for i = 1:size(detected_spikes(tmplt).center, 1)
            spike_val = detected_spikes(tmplt).spec_values(i, :) - mean(detected_spikes(tmplt).spec_values(i, :));
            
            %% check the orientation of the spike, if the same as the template (upwards phase followed by downwards phase), the correlation should be positive
            if max(xcorr(generic_templates(:, tmplt), spike_val)) > max(xcorr(-generic_templates(:, tmplt), spike_val))
                [tops_amps, tops_locs] = findpeaks(spike_val);
                [botms_amps, botms_locs] = findpeaks(-spike_val);
                botms_amps = -botms_amps;
                tops_amps = [spike_val(1), tops_amps, spike_val(end)];
                tops_locs = [1, tops_locs, length(spike_val)];
                botms_amps = [spike_val(1), botms_amps, spike_val(end)];
                botms_locs = [1, botms_locs, length(spike_val)];
                neg_abs_spike_val = -abs(spike_val);
                [noneed, zeros_loc] = findpeaks(neg_abs_spike_val); %% the tops of the negative absolute values of the spike are the values closest to zero (since 'find(spike_val == 0)' was to precise and 0.001 was not accepted)
                [noneed, spike_center_idx] = min(abs(zeros_loc - tmp_center));
                spike_center_loc = zeros_loc(spike_center_idx);
                %% begining and ending of the bipahasic are the bottom closest to the start and top closest to the end of the first and second impulsions respectively
                [noneed, start_idx] = min(abs(botms_locs - (tmp_center - detected_spikes(tmplt).original_template_width * fs)));
                start_loc = botms_locs(start_idx);
                end_idx = find(tops_locs >= tmp_center + floor(detected_spikes(tmplt).original_template_width * fs /2) - margin);
                end_idx = end_idx(1);
                end_loc = tops_locs(end_idx);
            else %% if the spike is oriented in the opposit directions, flip it first, process the same way, and flip it back
                spike_val = - spike_val;
                [tops_amps, tops_locs] = findpeaks(spike_val);
                [botms_amps, botms_locs] = findpeaks(-spike_val);
                botms_amps = -botms_amps;
                tops_amps = [spike_val(1), tops_amps, spike_val(end)];
                tops_locs = [1, tops_locs, length(spike_val)];
                botms_amps = [spike_val(1), botms_amps, spike_val(end)];
                botms_locs = [1, botms_locs, length(spike_val)];
                neg_abs_spike_val = -abs(spike_val);
                [noneed, zeros_loc] = findpeaks(neg_abs_spike_val); %% the tops of the negative absolute values of the spike are the values closest to zero (since 'find(spike_val == 0)' was to precise and 0.001 was not accepted)
                [noneed, spike_center_idx] = min(abs(zeros_loc - tmp_center));
                spike_center_loc = zeros_loc(spike_center_idx);
                %% begining and ending of the bipahasic are the bottom closest to the start and top closest to the end of the first and second impulsions respectively
                [noneed, start_idx] = min(abs(botms_locs - (tmp_center - detected_spikes(tmplt).original_template_width * fs)));
                start_loc = botms_locs(start_idx);
                end_idx = find(tops_locs >= tmp_center + floor(detected_spikes(tmplt).original_template_width * fs /2) - margin);
                end_idx = end_idx(1);
                end_loc = tops_locs(end_idx);   
                spike_val = - spike_val; %% flip it over again to its original state
            end

            %% check criteria on amplitude, duration etc (udration not implemented yet since cannot be longer than the frame, but might be in the future
            data_spikes.values(i_spike, 1:length(spike_val)) = nan;
            data_spikes.values(i_spike, start_loc: end_loc) = detected_spikes(tmplt).spec_values(i, start_loc : end_loc);
            data_spikes.amplitude(i_spike , :) = max(data_spikes.values(i_spike , :)) - min(data_spikes.values(i_spike , :));
            if data_spikes.amplitude(i_spike , :) >= min_amp(detected_spikes(tmplt).center(i)) & data_spikes.amplitude(i_spike , :) <= max_amp(detected_spikes(tmplt).center(i))
                save = true;
            end
            

            %% Save everything (amplitude and normal values already in) if the spike meets the criteria
            if save
                data_spikes.values_averaged(i_spike, 1:length(spike_val)) = nan; %% put nan values for spaces not used as part of the spike but allows to work with matrixes composed of rows of same lengths
                data_spikes.values_averaged(i_spike, start_loc: end_loc) = spike_val(start_loc : end_loc) - mean(spike_val(start_loc : end_loc));
                data_spikes.center_loc(i_spike , :) = spike_center_loc + round(detected_spikes(tmplt).times(i, 1) * fs) -1; %% put the spike back in temporal context of the whole signal
                data_spikes.center_time(i_spike , :)= data_spikes.center_loc(i_spike)/fs; %% put the spike back in temporal context of the whole signal and in time
                data_spikes.times(i_spike, 1:start_loc-1) = nan;
                data_spikes.times(i_spike, start_loc: end_loc) = detected_spikes(tmplt).times(i, start_loc: end_loc);
                data_spikes.times(i_spike, end_loc:length(spike_val)) = nan;
                data_spikes.template(i_spike , :) = tmplt;
                data_spikes.duration(i_spike, 1) = length(data_spikes.times(~isnan(data_spikes.times(i_spike, :))))/fs; %% duration of the effective spike
                save = false;
                if mod(i_spike, 5000) == 0
                    disp('Spikes processed : ' + string(i_spike));
                end
                i_spike = i_spike +1;
            end
        end
    end
end

%% delete all that sould not be saved due to lack in conditions
center_loc(~save, :) = [];
values(~save, :) = [];
values_averaged(~save, :) = [];
amplitude(~save, :) = [];
center_time(~save, :) = [];
times(~save, :) = [];
template(~save, :) = [];
duration(~save, :) = [];

%% sort everything temporally
[data_spikes.center_loc, sort_idx] = sortrows(center_loc);
data_spikes.values_averaged = values_averaged(sort_idx, :);
data_spikes.values = values(sort_idx, :);
data_spikes.amplitude = amplitude(sort_idx, :);
data_spikes.center_time = center_time(sort_idx, :);
data_spikes.times = times(sort_idx, :);
data_spikes.template = template(sort_idx, :);
data_spikes.duration = duration(sort_idx, :);

data_spikes.tot_mean_duration = mean(data_spikes.duration); %% total mean duration
data_spikes.tot_mean_amplitude = mean(data_spikes.amplitude); %% total mean amplitude


%% spikes frequency, mean duration, mean amplitude and energy with sliding window
window = params.extract_window*fs; %% duration in sec x fs
step = params.extract_step*fs; %% steps of the sliding window in sec x fs
n_max = ceil((length(gen_filt_data) - window) / step);
data_window.window_length = window; 
data_window.step_length = step;
for n_steps = 1:n_max
    start_idx = 1 + (n_steps - 1) * step;
    end_idx = start_idx + window;
    if end_idx > length(gen_filt_data)
        end_idx = length(gen_filt_data);
    end
    wdw_spikes = find(data_spikes.center_loc >= start_idx & data_spikes.center_loc <= end_idx); %% spikes in the window
    n_spikes = length(wdw_spikes); %% number of spikes
    spike_freqz = n_spikes/(window/fs); %% frequency of the spikes
    mean_amp = mean(data_spikes.amplitude(wdw_spikes)); %% mean amplitude of the spikes
    mean_dur = mean(data_spikes.duration(wdw_spikes)); %% mean duration of the spikes
    energy = spike_freqz*mean_amp; %% energy of the spikes
    data_window.n_spikes(n_steps, 1) = n_spikes;
    data_window.spikes_frequency(n_steps, 1) = spike_freqz;
    data_window.mean_amplitude(n_steps, 1) = mean_amp;
    data_window.mean_duration(n_steps, 1) = mean_dur;
    data_window.energy(n_steps, 1) = energy;
    data_window.step_loc(n_steps, 1) = start_idx+ceil(window/2);
    data_window.step_time(n_steps, 1) = (start_idx+ceil(window/2))/fs;
end

data_window.mean_amplitude(isnan(data_window.mean_amplitude)) = mean(data_window.mean_amplitude(~isnan(data_window.mean_amplitude))); % get rid of one or two "NaN" values that disturb the things
data_window.spikes_frequency(isnan(data_window.spikes_frequency)) = mean(data_window.spikes_frequency(~isnan(data_window.spikes_frequency))); % get rid of one or two "NaN" values that disturb the things
data_window.mean_duration(isnan(data_window.mean_duration)) = mean(data_window.mean_duration(~isnan(data_window.mean_duration))); % get rid of one or two "NaN" values that disturb the things
data_window.energy(isnan(data_window.energy)) = mean(data_window.energy(~isnan(data_window.energy))); % get rid of one or two "NaN" values that disturb the things
