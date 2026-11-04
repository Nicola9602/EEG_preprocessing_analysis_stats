function [meanCh, upperCI, lowerCI] = compute_CI(data, chan)
% COMPUTE_CI Compute mean and 95% confidence interval for a channel
%
% Inputs:
%   data - subjects x channels x time matrix
%   chan - index of the channel to extract
%
% Outputs:
%   meanCh  - 1 x time, mean ERP at channel
%   upperCh - 1 x time, upper CI
%   lowerCh - 1 x time, lower CI


% Number of subjects
nSub = size(data, 1);

% Extract the channel of interest
chanData = squeeze(data(:, chan, :));   % subj x timepoints

% Compute mean across subjects
meanCh = mean(chanData, 1);             % 1 x time

% Compute standard error of the mean (SEM)
SEM = std(chanData, 0, 1) / sqrt(nSub);

% Compute 95% confidence interval
tcrit = tinv(0.975, nSub - 1);         % two-tailed t-value
upperCI = meanCh + tcrit * SEM;
lowerCI = meanCh - tcrit * SEM;

end