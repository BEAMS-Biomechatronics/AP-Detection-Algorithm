%% define parameter
global fs;
params.fs = fs; %% just for the save of the parameters at the end

%% Usual VENG detection setup
%% filtering parameters
params.band_gen = [300 3000]; %% initally [300 3000] % in Hz; BP cutoff freqs for generic detection
params.band_spec = [300 3000]; %% initally [500 4000] % in Hz; BP cutoff freqs for specific spike detection 
params.filter_order = 2; %% filter order default

%% Generic template & generic detection parameters
params.generic_template_duration = 1.8e-3; %% in ms (before the 'e-3'); template duration 
params.generic_template_add_duration = 1.2e-3; %% in ms (before the 'e-3'); template added duration 
params.generic_template_ampl_factor = 5; %% No influence in practice; amplitude of the generic template = RMS of the generic filtered signal * this factor, combine with its width, it gives all the dynamic requirement (since normalized correlation)
params.generic_template_width = 0.7e-3; %% rat3bis 0.7e-3;%%rat3 %%1.2e-3; % [1.1:0.1:1.3]*1e-3; %% 0.6e-3; %% in ms (before the 'e-3'); width range of the spike of the generic template
params.generic_norm_xcorr_thresh = 0.8; %% [0;1]; correlation threshold when correlating with generic template 'normalized', so more on the shape factor

%% Clustering parameters
params.random_seed = 1308; %% random seed to be able to replicate results even when using random initial centroids
params.cluster_min_population_thresh = 0.01; %% the clusters are rejected if contains less than this proportion of the spikes detected
params.cluster_discorr_thresh = 0.14; %% 0.25; %% maximum discorrelation authorized within a cluster, otherwise loop again


%% Specific dection parameters
params.specific_norm_xcorr_thresh = 0.85; %% [0;1]; Cross-correlation threshold for the normalized specific detection
params.time_margin = 1e-3;  %% in ms (before the 'e-3'); if peak of a spike detected closer than this to another spike, considered as the same one and not counted twice

%% Other parameters
params.min_dist_2_spikes = 0.1e-3; %% (1.5) in ms (before the 'e-3'); minimal distance between two spikes, that is added to the width of the spike in practice, so distance btween two borders more or less if width constant
params.spike_duration = 1.5e-3; %% (1.1) in ms (before the 'e-3'); duration of a spike centered on its peak
params.spike_add_duration = 0.7e-3; %% (1.1) in ms (before the 'e-3'); duration of a spike centered on its peak
params.rms_window = 500e-3; %% in s (before the 'e-3'); sliding window size of the rms
params.max_amp_rms_ratio = 5; %% (7) maximum amplitude of the spikes in a ratio comparision with the rms
params.min_amp_rms_ratio = 1; %% (0.75) minimum amplitude of the spikes in a ratio comparision with the rms
% params.max_amplitude = 15; %% (15) in µV; The maximal difference between the extrema of the spike (otherwise, discarded)
% params.min_amplitude = 4.5; %% (4.5) in µV; The minimal difference between the extrema of the spike (otherwise, discarded)

%% Developper-level parameters
params.extract_window = 0.5; %% in sec; duration of the sliding window to extract local data from the detection
params.extract_step = 0.01; %% in sec; temporal step increase when sliding the window to extract local data from the detection



%%%%%%%% Epileptic event Javier

% %% define parameter
% global fs;
% 
% %% filtering parameters
% params.band_gen = [400 6000]; %% initally [300 3000] % in Hz; BP cutoff freqs for generic detection
% params.band_spec = [500 5000]; %% initally [500 4000] % in Hz; BP cutoff freqs for specific spike detection 
% params.filter_order = 2; %% filter order default
% 
% %% Generic template & generic detection parameters
% params.generic_template_duration = 2e-3; %% in ms (before the 'e-3'); template duration 
% params.generic_template_ampl_factor = 5; %% amplitude of the generic template = RMS of the generic filtered signal * this factor, combine with its width, it gives all the dynamic requirement (since normalized correlation)
% params.generic_template_width = 0.4e-3; %% in ms (before the 'e-3'); width of the spike of the generic template
% params.generic_norm_xcorr_thresh = 0.8; %% [0;1]; correlation threshold when correlating with generic template 'normalized', so more on the shape factor
% params.generic_xcorr_thresh = 0.6; %% [0;1]; correlation threshold when correlating with generic template without normalization, so more on the amplitude factor
% 
% %% Clustering parameters
% params.cluster_min_population_thresh = 0.01; %% the clusters are rejected if contains less than this proportion of the spikes detected
% params.cluster_discorr_thresh = 0.1; %% 0.25; %% maximum discorrelation authorized within a cluster, otherwise loop again
% 
% 
% %% Specific dection parameters
% params.specific_norm_xcorr_thresh = 0.85; %% [0;1]; Cross-correlation threshold for the normalized specific detection
% params.time_margin = 0.5e-3;  %% in ms (before the 'e-3'); if peak of a spike detected closer than this to another spike, considered as the same one and not counted twice
% 
% %% Other parameters
% params.min_dist_2_spikes = 1.5e-3; %% in ms (before the 'e-3'); minimal distance between two spikes
% params.spike_duration = 1.3e-3; %% in ms (before the 'e-3'); duration of a spike centered on its peak
% params.max_amplitude = 6.5; %% in µV; The maximal difference between the extrema of the spike (otherwise, discarded)
% params.min_amplitude = 3; %% in µV; The minimal difference between the extrema of the spike (otherwise, discarded)