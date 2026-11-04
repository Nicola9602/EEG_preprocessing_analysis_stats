function trl = ft_trialfun_rating_itemnum_fixed(cfg)
% FT_TRIALFUN_RATING_ITEMNUM_FIXED
% Feedback-locked trial definition for the misinformation rating task.
%
% This version is robust to:
%   - a missing block-start marker (especially S81 at recording start);
%   - fewer than 40 onset markers because recording started late or markers
%     were lost during buffer overflows;
%   - malformed trials that have no response or feedback.
%
% IMPORTANT
% ---------
% Column 10 is only the raw EEG onset ordinal within the reconstructed block.
% It is NOT assumed to equal the behavioural TrialNum when markers are
% missing. MI_NI_04_Segmentation_itemnum_fixed aligns the accepted EEG trial
% sequence to the behavioural sequence and replaces column 10 with the true
% behavioural TrialNum before ItemNum is attached.
%
% Required cfg fields
%   marker, header, Add_time, Fixation, Stim_onset, Response, Feedback,
%   BlockStart, subject_id
%
% Optional cfg fields
%   NoResponse, BlockEnd, TaskEnd, Debug
%
% Output trl columns
%   1  begin sample
%   2  end sample
%   3  offset, with feedback onset at time zero
%   4  condition code: 100 FalseLeft, 200 FalseRight,
%                      300 TrueRight, 400 TrueLeft
%   5  response code: 100 ... 700; normally 800 = no response
%   6  feedback code: 1 false, 2 true
%   7  reaction time in seconds; NaN for no response
%   8  fixation-to-stimulus interval in seconds
%   9  reconstructed BlockNum
%   10 raw onset ordinal within block (diagnostic only)
%   11 buffer-overflow count, repeated for each accepted trial

%% Validate configuration
required_fields = { ...
    'marker', 'header', 'Add_time', 'Fixation', 'Stim_onset', ...
    'Response', 'Feedback', 'BlockStart', 'subject_id'};

for k = 1:numel(required_fields)
    if ~isfield(cfg, required_fields{k}) || isempty(cfg.(required_fields{k}))
        error('ft_trialfun_rating_itemnum_fixed:MissingCfgField', ...
            'Missing or empty required cfg field: %s', required_fields{k});
    end
end

if isfield(cfg, 'Debug')
    debug_mode = logical(cfg.Debug);
else
    debug_mode = false;
end

%% Read events and header
events = ft_read_event(cfg.marker);
hdr = ft_read_header(cfg.header);
samples_to_add = round(cfg.Add_time * hdr.Fs);
subject_id = char(string(cfg.subject_id));

% Normalise marker lists to row cell arrays of character vectors.
blockstart = cellstr(string(cfg.BlockStart(:)))';
fixation = cellstr(string(cfg.Fixation(:)))';
onset = cellstr(string(cfg.Stim_onset(:)))';
response = cellstr(string(cfg.Response(:)))';
feedback = cellstr(string(cfg.Feedback(:)))';

if isfield(cfg, 'NoResponse') && ~isempty(cfg.NoResponse)
    noresponse = cellstr(string(cfg.NoResponse(:)))';
else
    noresponse = {};
end

if isfield(cfg, 'BlockEnd') && ~isempty(cfg.BlockEnd)
    blockend = cellstr(string(cfg.BlockEnd(:)))';
else
    blockend = {};
end

if isfield(cfg, 'TaskEnd') && ~isempty(cfg.TaskEnd)
    taskend = cellstr(string(cfg.TaskEnd(:)))';
else
    taskend = {};
end

% Trial searches cannot cross another fixation or a block/task boundary.
trial_stoppers = [fixation, blockstart, blockend, taskend];

%% Count buffer-overflow markers before filtering events
buffer_overflow_count = 0;
for k = 1:numel(events)
    value = events(k).value;
    if (ischar(value) || isstring(value)) && ...
            contains(string(value), 'Buffer Overflow', 'IgnoreCase', true)
        buffer_overflow_count = buffer_overflow_count + 1;
    end
end

if buffer_overflow_count > 0
    warning('ft_trialfun_rating_itemnum_fixed:BufferOverflow', ...
        'Subject %s has %d Buffer Overflow event(s).', ...
        subject_id, buffer_overflow_count);
end

%% Keep only misinformation markers needed by this trial function
all_markers = [ ...
    blockstart, fixation, onset, response, feedback, blockend, taskend];

event_values = {events.value};
keep_idx = false(size(event_values));

for k = 1:numel(event_values)
    value = event_values{k};
    if ischar(value) || isstring(value)
        keep_idx(k) = any(strcmp(char(string(value)), all_markers));
    end
end

events_filtered = events(keep_idx);

if isempty(events_filtered)
    error('ft_trialfun_rating_itemnum_fixed:NoRelevantMarkers', ...
        'No relevant misinformation markers were found for subject %s.', ...
        subject_id);
end

%% Reconstruct block membership and raw onset ordinals
% A missing S81 is common when recording begins after the block-start marker.
% In that case, the first misinformation onset before the first S88 is safely
% assigned to block 1. The same logic also works if a later block-start marker
% is missing: the next block is inferred after the preceding block end.
n_events = numel(events_filtered);
event_block_num = nan(n_events, 1);
event_raw_ordinal = nan(n_events, 1);

n_blocks = numel(blockstart);
current_block = NaN;
completed_blocks = 0;
raw_ordinal_in_block = 0;
onsets_per_block = zeros(1, n_blocks);
inferred_start_reported = false(1, n_blocks);

for ev = 1:n_events
    current_value = char(string(events_filtered(ev).value));

    block_idx = find(strcmp(current_value, blockstart), 1, 'first');
    if ~isempty(block_idx)
        current_block = block_idx;
        completed_blocks = max(completed_blocks, block_idx - 1);
        raw_ordinal_in_block = 0;

        if debug_mode
            fprintf('Subject %s: explicit block %d start at filtered event %d.\n', ...
                subject_id, current_block, ev);
        end
        continue;
    end

    if any(strcmp(current_value, blockend))
        if ~isnan(current_block)
            completed_blocks = max(completed_blocks, current_block);
        else
            completed_blocks = min(completed_blocks + 1, n_blocks);
        end
        current_block = NaN;
        raw_ordinal_in_block = 0;
        continue;
    end

    if any(strcmp(current_value, taskend))
        current_block = NaN;
        raw_ordinal_in_block = 0;
        continue;
    end

    if ~any(strcmp(current_value, onset))
        continue;
    end

    if isnan(current_block)
        inferred_block = completed_blocks + 1;

        if inferred_block < 1 || inferred_block > n_blocks
            warning('ft_trialfun_rating_itemnum_fixed:UnassignableOnset', ...
                ['Subject %s has an onset outside the expected three ' ...
                 'misinformation blocks. The onset will remain unnumbered.'], ...
                subject_id);
            continue;
        end

        current_block = inferred_block;
        raw_ordinal_in_block = 0;

        if ~inferred_start_reported(current_block)
            warning('ft_trialfun_rating_itemnum_fixed:InferredBlockStart', ...
                ['Subject %s is missing the recognised start marker for ' ...
                 'misinformation block %d. Block membership is inferred ' ...
                 'from marker order and the preceding block end.'], ...
                subject_id, current_block);
            inferred_start_reported(current_block) = true;
        end
    end

    raw_ordinal_in_block = raw_ordinal_in_block + 1;
    event_block_num(ev) = current_block;
    event_raw_ordinal(ev) = raw_ordinal_in_block;
    onsets_per_block(current_block) = onsets_per_block(current_block) + 1;
end

for block_num = 1:n_blocks
    if onsets_per_block(block_num) ~= 40
        warning('ft_trialfun_rating_itemnum_fixed:UnexpectedOnsetCount', ...
            ['Subject %s: EEG block %d contains %d stimulus-onset markers ' ...
             'instead of 40. The participant is NOT discarded; final ' ...
             'TrialNum and ItemNum will be recovered by sequence/time ' ...
             'alignment to the behavioural data.'], ...
            subject_id, block_num, onsets_per_block(block_num));
    end
end

%% Extract valid fixation-to-feedback trials
trl = zeros(0, 10);

for ev = 1:n_events
    current_value = char(string(events_filtered(ev).value));

    if ~any(strcmp(current_value, fixation))
        continue;
    end

    fixation_idx = ev;

    % Find the next feedback without crossing into the next trial or block.
    feedback_idx = [];
    for search_idx = (fixation_idx + 1):n_events
        value_to_check = char(string(events_filtered(search_idx).value));

        if any(strcmp(value_to_check, trial_stoppers))
            break;
        end

        if any(strcmp(value_to_check, feedback))
            feedback_idx = search_idx;
            break;
        end
    end

    if isempty(feedback_idx)
        continue;
    end

    % First onset after fixation and before feedback.
    onset_idx = [];
    for search_idx = (fixation_idx + 1):(feedback_idx - 1)
        value_to_check = char(string(events_filtered(search_idx).value));
        if any(strcmp(value_to_check, onset))
            onset_idx = search_idx;
            break;
        end
    end

    if isempty(onset_idx)
        continue;
    end

    % Last response before feedback, preserving multiple-keypress handling.
    response_idx = [];
    for search_idx = (feedback_idx - 1):-1:(onset_idx + 1)
        value_to_check = char(string(events_filtered(search_idx).value));
        if any(strcmp(value_to_check, response))
            response_idx = search_idx;
            break;
        end
    end

    if isempty(response_idx)
        continue;
    end

    this_block_num = event_block_num(onset_idx);
    this_raw_ordinal = event_raw_ordinal(onset_idx);

    if isnan(this_block_num) || isnan(this_raw_ordinal)
        warning('ft_trialfun_rating_itemnum_fixed:MissingEEGBlock', ...
            ['Subject %s has a valid trial whose onset could not be assigned ' ...
             'to a misinformation block. That single trial is skipped.'], ...
            subject_id);
        continue;
    end

    %% Translate markers into trial information
    onset_value = char(string(events_filtered(onset_idx).value));
    response_value = char(string(events_filtered(response_idx).value));
    feedback_value = char(string(events_filtered(feedback_idx).value));

    code_trial = find(strcmp(onset_value, onset), 1, 'first');
    code_response = find(strcmp(response_value, response), 1, 'first');
    code_feedback = find(strcmp(feedback_value, feedback), 1, 'first');

    if isempty(code_trial) || isempty(code_response) || isempty(code_feedback)
        continue;
    end

    fixation_sample = events_filtered(fixation_idx).sample;
    onset_sample = events_filtered(onset_idx).sample;
    response_sample = events_filtered(response_idx).sample;
    feedback_sample = events_filtered(feedback_idx).sample;

    beg_sample = fixation_sample - samples_to_add;
    end_sample = feedback_sample + samples_to_add;

    % Feedback onset is time zero.
    offset = -samples_to_add - (feedback_sample - fixation_sample);
    t_fixation_onset = (onset_sample - fixation_sample) / hdr.Fs;

    if ~isempty(noresponse)
        is_no_response = any(strcmp(response_value, noresponse));
    else
        is_no_response = (code_response == numel(response));
    end

    if is_no_response
        RT = NaN;
    else
        RT = (response_sample - onset_sample) / hdr.Fs;
    end

    trl(end + 1, :) = [ ...
        beg_sample, ...
        end_sample, ...
        offset, ...
        100 * code_trial, ...
        100 * code_response, ...
        code_feedback, ...
        RT, ...
        t_fixation_onset, ...
        this_block_num, ...
        this_raw_ordinal]; %#ok<AGROW>

    if debug_mode
        fprintf(['Subject %s: accepted block %d raw ordinal %d; ' ...
                 'condition=%d, response=%d, feedback=%d.\n'], ...
            subject_id, this_block_num, this_raw_ordinal, ...
            100 * code_trial, 100 * code_response, code_feedback);
    end
end

if isempty(trl)
    error('ft_trialfun_rating_itemnum_fixed:NoValidTrials', ...
        'No valid misinformation trials were defined for subject %s.', ...
        subject_id);
end

%% Append participant-level buffer-overflow count
trl = [trl, repmat(buffer_overflow_count, size(trl, 1), 1)];

end
