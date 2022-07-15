function [generic_templates] = generate_generic_template(data, detection_params)

global fs

%% definition of the main characteristics of the template(s)
pre_window(1) = detection_params.generic_template_duration *5; %% we will remove the excess afterwards, allows to derivate well
end_window(1) = fs * pre_window(1);
center(1) = round(fs * pre_window(1) /2);
i = 1;
for width = detection_params.generic_template_width
    beg_spike(i) = center(1) - round(fs * width/2);
    end_spike(i) = center(1) + round(fs * width/2);
    i = i+1;
end

%% Amplitude criteria %% Useless if we work with a normalized correlation
spike_ampl = rms(data)*detection_params.generic_template_ampl_factor;

%% Templates creation
n_temp = 0;

%%%%% Template option 1: (bi-phasic)
% n_temp = n_temp+1;
% template.values(round(end_window(1) + detection_params.generic_template_width),n_temp) = 0;
% template.values(beg_spike(1) : center(1),n_temp) = linspace(0, spike_ampl,center(1) - beg_spike(1)+1);
% template.values(center(1):center(1) + round(detection_params.generic_template_width*fs), n_temp) = linspace(spike_ampl, -spike_ampl, detection_params.generic_template_width*fs+1);
% template.values(center(1) + round(detection_params.generic_template_width*fs) : center(1) + round(3/2*round(detection_params.generic_template_width*fs)), n_temp) = linspace(-spike_ampl, 0, round(detection_params.generic_template_width*fs/2)+1);
% template.values(:,n_temp) = circshift(template(:,n_temp), -(detection_params.generic_template_width*fs/2)); %% shift back the template centered

%%%%% Template option 2: (mono-phasic)
for i = 1:length(detection_params.generic_template_width)
    n_temp = n_temp+1;
    template.type(n_temp, 1) = 1; %% 1 for monophasic, 2 for biphasic etc
    template.values(1:end_window,n_temp) = 0; 
    template.values(beg_spike(i) : center(1),n_temp) = linspace(0, spike_ampl,center(1) - beg_spike(i)+1);   %% We create a triangular template of from beg_spike to end_spike and of amplitude spike_ampl (shouldn't it be "-1" instead of "+1" ? (details)
    template.values(center(1) : end_spike(i),n_temp) = linspace(spike_ampl, 0, end_spike(i) - center(1)+1);  %% centerd on the "center" element of v. The elements before and after the triangle = 0
    template.width(n_temp, 1) = detection_params.generic_template_width(i);
end



%% Filtering through generic parameters of the template and trimming of the excess
for i = 1 : size(template.values, 2)
    tmp_generic_template = gen_filter(template.values(:,i), detection_params);
    generic_templates(i).values(:,1) = tmp_generic_template(round(size(tmp_generic_template,1)/2-detection_params.generic_template_duration*fs /2)+1 : round(size(tmp_generic_template,1)/2+detection_params.generic_template_duration*fs/2));
    generic_templates(i).type = template.type(n_temp, 1);
    generic_templates(i).width = template.width(n_temp, 1);
end

% Plot the templates
% for i  = 1 : size(generic_templates.values, 2)
%     time = [1: size(generic_templates.values,1)]/fs*1000; %% in ms
%     figure; plot(time, generic_templates.values(:,i));
%     title('Template ' + string(i));
%     xlabel('Time (ms)'); ylabel('Normalized relative amplitude');
% end