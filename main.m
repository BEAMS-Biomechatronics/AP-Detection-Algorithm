function [ ] = main(data_to_use)

global fs

define_params;  %% creates a list of the paramters used for the filtering, spike detection, etc. in a variable called "params"

disp('Initializing detection')

[gen_filt_data, spec_filt_data, raw_data, rms_gen, rms_spec start_end_idx] = get_data(data_to_use, params);  %% BP filtering of the original signal generic and specific values. The start&end indexes are to save and remember after processing

generic_templates = generate_generic_template(gen_filt_data, params); %% generates generic templates based on the RMS of the generic BP signal (so generic BP template) (1 column for each template)

n_tot_spikes = 0;
all_spikes_centers = [];
for i = 1 : size(generic_templates, 2) %% loop for each template (1 line structure = 1 template)
    disp('Starting generic detection with template ' + string(i))
    gen_detected_spikes(i) = spike_detection (generic_templates(i),params, gen_filt_data, spec_filt_data, rms_gen, all_spikes_centers); %% detected_spikes.gen_values are the values in the signal of the spikes detected, detected_spikes.times contains the times corresponding to those values. Each row is one spike
    disp('Generic detection done - ' + string(size(gen_detected_spikes(i).times,1)) + ' spikes found')
    disp('Starting clustering')
    clusters(i) = cluster_spikes (gen_detected_spikes(i), params); %% contains the centroids of the clusters and the cluster each spike is associated to (each row a centroid, and column matrix for the cluster ID's)
    disp('Clustering done  -  Starting specific detection')
    spec_detected_spikes(i) = cluster_spike_detection (clusters(i), spec_filt_data, params, gen_filt_data, rms_spec, all_spikes_centers, generic_templates(i)); %% the detected spikes have now also the '.cluster_idx' attribute, being the cluster ID from which they have been detected (and gen_filt_data is just for a final plot without the generic filtering)
    disp('Specific detection with template ' + string(i) + ' done - ' + string(size(spec_detected_spikes(i).times,1)) + ' spikes found')
    all_spikes_centers = sort([all_spikes_centers; spec_detected_spikes(i).center]);
end

disp('Starting data extraction...')
[data_spikes, data_window] = extract_data(spec_detected_spikes, generic_templates, params, gen_filt_data, rms_spec);

time = [1:length(gen_filt_data)]/fs; 

data_signal.gen_signal = gen_filt_data;
data_signal.rms_gen = rms_gen;
% data_signal.spec_signal = spec_filt_data;
% data_signal.rms_spec = rms_spec;
data_signal.time = time;

n_tot_spikes = size(data_spikes.values_averaged, 1);
disp('Total detected spikes : ' + string(n_tot_spikes)); 

%% Generic plot 
figure; plot(time, gen_filt_data, 'b'); hold on;
numb_spikes = size(data_spikes.values_averaged, 1);
if numb_spikes > 3000
    numb_spikes = 3000;
end
for i_spike = 1 : numb_spikes
    if data_spikes.template(i_spike) == 1
        plot(data_spikes.times(i_spike,:), data_spikes.values(i_spike,:), 'g');
    elseif data_spikes.template(i_spike) == 2
        plot(data_spikes.times(i_spike,:), data_spikes.values(i_spike,:), 'r');
    elseif data_spikes.template(i_spike) == 3
        plot(data_spikes.times(i_spike,:), data_spikes.values(i_spike,:), 'm');
    elseif data_spikes.template(i_spike) == 4
        plot(data_spikes.times(i_spike,:), data_spikes.values(i_spike,:), 'k');
    else
        plot(data_spikes.times(i_spike,:), data_spikes.values(i_spike,:), 'color', [0.8500 0.3250 0.0980]);
    end
end
% plot(data_window.step_time, data_window.spikes_frequency-mean(data_window.spikes_frequency), 'color', [0.8500 0.3250 0.0980]); %% orange
% plot(data_window.step_time, data_window.mean_amplitude, 'color', [0.4940 0.1840 0.5560]); %% purple
% plot(time, rms_gen, 'color', '#03fc0f' )
% plot(time, raw_data, 'r');
title('Second detection with specific templates - B: gen filt data - R: spikes template monophasic - G: spikes template biphasic - Total spikes detected : ' + string(n_tot_spikes));
xlabel('Time (s)');
ylabel('Amplitude (µV)');

save_data(data_to_use, data_spikes, data_window, data_signal, clusters, params);

disp('Saved --- Well played BG !')



%%%%% IF YOU WANT THE UNFILTERED PLOT %%%%%

%% Unfiltered plot 
% time = [1:length(raw_data)]/fs;
% figure; plot(time, raw_data, 'b'); hold on;
% for i = 1 : size(generic_templates, 2)
%     if i == 1
%         numb_spikes = size(spec_detected_spikes(i).gen_values, 1);
%         if numb_spikes >5000
%             numb_spikes = 5000;
%         end
%         for i_spike = 1 : numb_spikes
%             plot(spec_detected_spikes(i).times(i_spike,:), raw_data(round(spec_detected_spikes(i).times(i_spike,:)*fs)), 'g');
%         end
%     elseif i == 2
%         numb_spikes = size(spec_detected_spikes(i).gen_values, 1);
%         if numb_spikes >5000
%             numb_spikes = 5000;
%         end
%         for i_spike = 1 : numb_spikes
%             plot(spec_detected_spikes(i).times(i_spike,:), raw_data(round(spec_detected_spikes(i).times(i_spike,:)*fs)), 'r');
%         end
%     else
%         numb_spikes = size(spec_detected_spikes(i).gen_values, 1);
%         if numb_spikes >5000
%             numb_spikes = 5000;
%         end
%         for i_spike = 1 : numb_spikes
%             plot(spec_detected_spikes(i).times(i_spike,:), raw_data(round(spec_detected_spikes(i).times(i_spike,:)*fs)), 'm');
%         end
%     end
% end
% title('Second detection with specific templates - B: raw data - R: spikes template 1 - G: spikes template 1 - Total spikes detected : ' + string(n_tot_spikes));
% xlabel('Time (s)');
% ylabel('Amplitude (µV)');