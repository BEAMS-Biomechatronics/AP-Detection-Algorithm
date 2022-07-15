function [clusters] = cluster_spikes(detected_spikes,  params)

%% clusters.idx is a column matrix containing the ID of the cluster associated to each generically detected spike
%% clusters.centroids is a matrix with each row being the centroid of one cluster. The number of rows = number of clusters

global fs 
rng(params.random_seed);

%% Define the initial centroids (not used in practice yet)
centroids = [];
% first_pos_centroid(1, size(detected_spikes.spec_values, 2)) = 0;
% first_neg_centroid(1, size(detected_spikes.spec_values, 2)) = 0;
% n_pos = 0;
% n_neg = 0;
% parfor i = 1 : size(detected_spikes.spec_values, 1)
%     tmp_spike = detected_spikes.spec_values(i,:);
%     if max(tmp_spike) >= abs(min(tmp_spike))
%         first_pos_centroid = first_pos_centroid + tmp_spike;
%         n_pos = n_pos +1;
%     else
%         first_neg_centroid = first_neg_centroid + tmp_spike;
%         n_neg = n_neg +1;
%     end
% end
% first_pos_centroid = first_pos_centroid / n_pos; %% we added all the spikes values and now we devide by the number of added spikes to get the mean of them
% first_neg_centroid = first_neg_centroid / n_neg;


%% Cluster the spikes with the k-means method
done_sorting = false;
n_clusters = 2;
while ~done_sorting
    disp('Trying ' + string(n_clusters) + ' clusters')
    [cluster_idx, centroids] = kmeans(detected_spikes.spec_values, n_clusters, 'distance','correlation', 'start','plus', 'emptyaction','drop');
    
    clear mean_discorr tmp_spks discorr
    for n_centroid = 1 :  size(centroids, 1)
        tmp_spikes = detected_spikes.spec_values(cluster_idx == n_centroid, :);
        parfor n_spikes = 1 : size(tmp_spikes,1)
            r = corrcoef(centroids(n_centroid,:), tmp_spikes(n_spikes, :)); %% "r" is a 2 x 2 matrix [corr(a, a) corr(a,b); corr(b, a) corr(b, b))
            discorr(n_spikes) = 1 - r(1, 2); %% so r(1, 2) is the correlation between the two, and 1 - r(1, 2) is the discorr (kind of an inverse function)
        end
        mean_discorr(n_centroid) = mean(discorr); %% Mean of de discorrelation between the centroid and its affiliated spikes, should be minimized
    end
    disp('Mean discorrelation : ' + string(max(mean_discorr)));
    if max(mean_discorr) <= params.cluster_discorr_thresh %% Otherwise means that one of the centroids has a too high discorrelation, so not a good cluster choice and maybe a need of more clusters, so start over with 1 more centroid
        done_sorting = true;
    end
    n_clusters = n_clusters+1;
end

%% Removing non-representative clusters
n_centroid = 1;
while n_centroid <=  size(centroids, 1)
    spikes_from_this = find(cluster_idx == n_centroid);
    if length(spikes_from_this)/length(cluster_idx) < params.cluster_min_population_thresh
        centroids(n_centroid,:) = [];
        cluster_idx(spikes_from_this) = [];
    else
        n_centroid = n_centroid +1;
    end
end        
   
%% Plot the templates
% time = [1:size(centroids, 2)]/fs*1000;
% figure; hold on;
% for n_centroid = 1 :  size(centroids, 1)
%     plot(time, centroids(n_centroid, :));
% end
% title ('Centroids')
% xlabel('Time (ms)')

%%%% To do: compare the results with the initial centroids chosen by the code above, or by the kmeans++ method using the 'start' argument.

%%%% If issue with empty cluster, check lines 77-83 in original code for conditions to avoid it, seems unnecessary upfront

clusters.idx = cluster_idx;
clusters.centroids = centroids;