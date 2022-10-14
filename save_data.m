function [save_state] = save_data (saving_info, data_spike, data_window, data_signal, data_clusters, params_used) 
save_state = 'not saved';

% save_name = "save_hugo_full";
save_loc = [saving_info.save_folder + saving_info.savefilename + "_" + string(params_used.generic_template_width*10000) + "ms" + string(params_used.generic_norm_xcorr_thresh) + "-" + string(params_used.specific_norm_xcorr_thresh)];
animal = saving_info.animal;
save (save_loc, 'data_spike', 'data_window', 'data_signal', 'data_clusters', 'params_used', 'animal');

save_state = 'well saved' + ' ' + saving_info.savefilename;
end