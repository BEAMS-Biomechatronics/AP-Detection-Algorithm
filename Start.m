% for hour = 1:24
%     start_hour = 11;
%     this_hour = start_hour+hour-1; %% hour of this recording as a function of the first one of this batch
%     tstart = datetime('now','Format','HH:mm:ss.SSS');
%     
%     global fs
%     
%     fs = 40000;
%     
%     % folder_save = 'D:\Utilisateurs\Romain\Docu\Thesis\Matlab\Data\Results\';  %Location for the save of the results %%% laptop
%     % folder_data = 'D:\Utilisateurs\Romain\Docu\Thesis\Matlab\Data\data paper hugo\';
%     folder_data = 'C:\Users\Administrateur\Documents\Thesis\Matlab\Data\Veng\chronic circadian\rat3\'; %location of the folder containing the data to process %%% home pc
% % folder_data = 'C:\Users\Administrateur\Documents\Thesis\Matlab\Data\Veng\Elenananinanere\';
%     folder_save = 'C:\Users\Administrateur\Documents\Thesis\Matlab\Data\Veng\Saves Circadian\'; 
% % folder_save = 'C:\Users\Administrateur\Documents\Thesis\Matlab\Data\Veng\matlab saves\';
% %     fil   ename = 'test_elena_ref' + string(1);  %Name of the data to process
%     % filename = ['Acute_test_cuff_homemade_electrode']; %% home PC
%     filename = '2021-07-12_15-57_' + string(hour);
%     
%     savefilename = 'save_' + filename  + '_5min_1ms';
%     signal_in = 'veng_save';%     signal_in = 'veng_save'; %% name of the signal to process %% note that the signal in should be in µV and in a column vector
%     animal = 'rat3';
%     
%     data_to_use.name = [signal_in]; %% name of the signal to process
%     data_to_use.savefilename = savefilename;
%     data_to_use.file = [folder_data + filename];
%     data_to_use.save_folder = folder_save;
%     data_to_use.start = [0]; %% set start timestamp (in s) of the detection, leave empty for start at the beginning 
%     data_to_use.end = [300]; %% set end timestamp (in s) of the detection, leave empty for include all data til the end 
%     data_to_use.animal = animal;
%     data_to_use.day_hour = this_hour; %% hour of this recording
%     
%     main(data_to_use) %% start detection
%     
%     disp([folder_data filename ' - detection done'])
%     
%     tend = datetime('now','Format','HH:mm:ss.SSS');
%     ttot = tend- tstart;
%     
%     disp('TOTAL TIME:');
%     ttot
%     
%     clear all
% 
% end 

for hour = 1
    start_hour = 11;
    this_hour = start_hour+hour-1; %% hour of this recording as a function of the first one of this batch
    tstart = datetime('now','Format','HH:mm:ss.SSS');
    
    global fs
    
    fs = 40000;
    
    % folder_save = 'D:\Utilisateurs\Romain\Docu\Thesis\Matlab\Data\Results\';  %Location for the save of the results %%% laptop
    % folder_data = 'D:\Utilisateurs\Romain\Docu\Thesis\Matlab\Data\data paper hugo\';
    folder_data = "C:\Users\Administrateur\Documents\Thesis\Matlab\Data\Veng\Elenananinanere\"; %location of the folder containing the data to process %%% home pc
% folder_data = 'C:\Users\Administrateur\Documents\Thesis\Matlab\Data\Veng\Elenananinanere\';
    folder_save = "C:\Users\Administrateur\Documents\Thesis\Matlab\Data\Veng\Biocas acute\"; 
% folder_save = 'C:\Users\Administrateur\Documents\Thesis\Matlab\Data\Veng\matlab saves\';
%     fil   ename = 'test_elena_ref' + string(1);  %Name of the data to process
    filename = "acti_test_elena"; %% home PC
%     filename = 'rat3-2021-07-12_15-57_' + string(hour);
    
    savefilename = "save_" + filename + "_07ms_80-85";
    signal_in = 'veng';%     signal_in = 'veng_save'; %% name of the signal to process %% note that the signal in should be in µV and in a column vector
    animal = "rat_elena";
    
    data_to_use.name = [signal_in]; %% name of the signal to process
    data_to_use.savefilename = savefilename;
    data_to_use.file = [folder_data + filename];
    data_to_use.save_folder = folder_save;
    data_to_use.start = [0]; %% set start timestamp (in s) of the detection, leave empty for start at the beginning 
    data_to_use.end = [300]; %% set end timestamp (in s) of the detection, leave empty for include all data til the end 
    data_to_use.animal = animal;
    data_to_use.day_hour = this_hour; %% hour of this recording
    
    main(data_to_use) %% start detection
    
    disp([folder_data filename ' - detection done'])
    
    tend = datetime('now','Format','HH:mm:ss.SSS');
    ttot = tend- tstart;
    
    disp('TOTAL TIME:');
    ttot
    
    clear all

end 