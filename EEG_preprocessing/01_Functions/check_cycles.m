function check_cycles(foi, t_ftimwin)
% CHECK_CYCLES  Verify that each frequency has an integer number of cycles
%               within the time window specified.
%
%   check_cycles(foi, t_ftimwin)
%
%   Inputs:
%       foi         - vector of frequencies of interest (e.g., 1:30)
%       t_ftimwin   - scalar or vector of time window lengths (seconds)
%
%   This function prints:
%       - frequency
%       - number of cycles in the window
%       - whether the cycles count is an integer (1 = good, 0 = bad)
%
%   Example:
%       check_cycles(2:20, 4 ./ (2:20));
%
%   Author: ChatGPT

    % Ensure inputs are column vectors
    foi = foi(:);

    % If t_ftimwin is a scalar, expand to match foi
    if isscalar(t_ftimwin)
        t_ftimwin = repmat(t_ftimwin, size(foi));
    else
        t_ftimwin = t_ftimwin(:);
    end

    % Sanity check: sizes must match now
    if length(foi) ~= length(t_ftimwin)
        error('foi and t_ftimwin must have the same length or t_ftimwin must be a scalar.');
    end

    % Compute cycles
    cycles = foi .* t_ftimwin;

    % Check integer cycles
    good_freqs = cycles == round(cycles);

    % Display results
    disp(table(foi, t_ftimwin, cycles, good_freqs));
end
