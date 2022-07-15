function [save_state] = save_data (saving_info, data_spike, data_window, data_signal, data_clusters, params_used) 
save_state = 'not saved';

% save_name = "save_hugo_full";
save_loc = [saving_info.save_folder + saving_info.savefilename];
animal = saving_info.animal;
day_hour = saving_info.day_hour;
save (save_loc, 'data_spike', 'data_window', 'data_signal', 'data_clusters', 'params_used', 'animal', 'day_hour');

save_state = 'well saved' + ' ' + saving_info.savefilename;
end