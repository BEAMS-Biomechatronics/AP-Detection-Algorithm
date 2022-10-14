tstart = datetime('now','Format','HH:mm:ss.SSS'); % starting time to monitor the duration of the processing

global fs

fs = 80000; % sampling frequnecy

folder_data = "C:\Users\Administrateur\Documents\DataLocation\"; %location of the folder containing the data to process !!!! Dont forget the " \ " at the end !!!!
folder_save = "C:\Users\Administrateur\Documents\SaveLocation\"; % location of the folder in which the processing results will be saved
filename = "Acute_test_cuff_homemade_electrode"; % name of your file !!!! without the ".mat" !!!!
signal_in = 'veng'; % name of the signal to process inside the data file %% note that the signal in should be in µV and in a column vector
animal = "rat001"; % name of your specimen

savefilename = "save_" + filename;

data_to_use.name = [signal_in]; 
data_to_use.savefilename = savefilename;
data_to_use.file = [folder_data + filename];
data_to_use.save_folder = folder_save;
data_to_use.start = [0]; %% set start timestamp (in s) of the detection, leave empty for start at the beginning 
data_to_use.end = [300]; %% set end timestamp (in s) of the detection, leave empty for include all data til the end 
data_to_use.animal = animal;

main(data_to_use) %% start detection

disp([folder_data filename ' - detection done'])

tend = datetime('now','Format','HH:mm:ss.SSS');
ttot = tend- tstart; % total processing time

disp('TOTAL TIME:');
ttot

clear all