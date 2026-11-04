function trl=ft_trialfun_rating(cfg)
% Chinchella Nicola MRG Group 2025
% Use this script to segment data for the rating task
% specifically using the feedback as onset 
% we'll keep info about the trials so Rating and 
% Type of stimuli

%% Read events and header
events = ft_read_event(cfg.marker);
hdr = ft_read_header(cfg.header);
samples_to_add = round(cfg.Add_time * hdr.Fs);

% Get marker definitions
fixation = cfg.Fixation;
onset = cfg.Stim_onset;
response = cfg.Response;
feedback = cfg.Feedback;

% Optional end markers for last trial of a block/task 
% This is to be more flexible with the baselien correction 

if isfield(cfg, 'BlockEnd')
    blockend = cfg.BlockEnd;
else
    blockend = {};
end

if isfield(cfg, 'TaskEnd')
    taskend = cfg.TaskEnd;
else
    taskend = {};
end

endmarkers = [fixation, blockend, taskend];

%% Filter events to keep only relevant marke

% Check for buffer overwflow 
buffer_overflow_count = 0;
for i = 1:length(events)
    if ischar(events(i).value) && contains(events(i).value, 'Buffer Overflow', 'IgnoreCase', true)
    buffer_overflow_count = buffer_overflow_count + 1;
    end
end

if buffer_overflow_count > 0
     warning('Subject %s has %d Buffer Overflow event(s)', cfg.subject_id, buffer_overflow_count);
end


% Combine all markers of interest
all_markers = [fixation, onset, response, feedback, blockend, taskend];
event_values = {events.value};

% Create logical index keeping only string markers that match our list
% (this removes buffer overflows, empty arrays, and other irrelevant markers)
keep_idx = false(size(event_values));
for i = 1:length(event_values)
    if ischar(event_values{i})
        keep_idx(i) = any(strcmp(event_values{i}, all_markers));
    end
end
events_filtered = events(keep_idx);


%% Extract trials based on fixation-to-feedback sequences
trl = [];

for ev = 1:length(events_filtered)
    % Check if current event is a fixation marker
    is_fixation = any(strcmp(events_filtered(ev).value, fixation));
    % DEBUG: Print every iteration
    fprintf('ev=%d, is_fixation=%d, value=%s\n', ev, is_fixation, events_filtered(ev).value);
    fprintf('-------------------------\n');

    if ~is_fixation
        continue;  % Skip non-fixation events
    end
    
    % Find the next feedback after this fixation
    feedback_idx = [];
    for i = (ev+1):length(events_filtered)
        % Check if we hit another fixation before the feedback in that case
        % restart the loop 
        if any(strcmp(events_filtered(i).value, fixation))
            break;
        end 

        if any(strcmp(events_filtered(i).value, feedback))
            feedback_idx = i;
            fprintf('feedback_idx=%d, value=%s\n', feedback_idx, events_filtered(feedback_idx).value);
            break;
        end
    end
    
    % Skip if no feedback found
    if isempty(feedback_idx)
        continue;
    end

    % Find the next trial-ending event after feedback:
% usually the next fixation, or block/task end for the last trial
next_end_idx = [];

for j = (feedback_idx + 1):length(events_filtered)
    if any(strcmp(events_filtered(j).value, endmarkers))
        next_end_idx = j;
        break;
    end
end

% If no next fixation/block end exists, fallback to feedback + Add_time
if isempty(next_end_idx)
    end_sample = events_filtered(feedback_idx).sample + samples_to_add;
    t_feedback_to_next_event = NaN;
else
    % End immediately before the next fixation/block-end marker
    end_sample = events_filtered(next_end_idx).sample - 1;
    t_feedback_to_next_event = ...
        (events_filtered(next_end_idx).sample - events_filtered(feedback_idx).sample) / hdr.Fs;
end
    
    % Calculate distance (number of events from fixation to feedback, inclusive)
    distance = feedback_idx - ev + 1;
    fprintf('feedback_idx=%d, distance=%d\n', feedback_idx, distance);
    
    %% Handle different trial structures based on distance
    if distance == 4
        fprintf('Distance == 4\n');
        % Perfect case: Fixation -> Onset -> Response -> Feedback
        fixation_idx = ev;
        onset_idx = ev + 1;
        response_idx = ev + 2;
        feedback_idx = ev + 3;
        
        % Verify the sequence is correct
        is_fixation = any(strcmp(events_filtered(fixation_idx).value, fixation));
        is_onset = any(strcmp(events_filtered(onset_idx).value, onset));
        is_response = any(strcmp(events_filtered(response_idx).value, response));
        is_feedback = any(strcmp(events_filtered(feedback_idx).value, feedback));

        fprintf('fixation_idx=%d, is_fixation=%d, value=%s\n', ev, is_fixation, events_filtered(fixation_idx).value)
        fprintf('onset_idx=%d, is_onset=%d, value=%s\n', onset_idx, is_onset, events_filtered(onset_idx).value)
        fprintf('response_idx=%d, is_response=%d, value=%s\n', response_idx, is_response, events_filtered(response_idx).value)
        fprintf('feedback_idx=%d, is_feedback=%d, value=%s\n', feedback_idx, is_feedback, events_filtered(feedback_idx).value)
        
        if is_fixation && is_onset && is_response && is_feedback
            % Calculate trial boundaries
            beg_sample = events_filtered(fixation_idx).sample - samples_to_add; % Trial start this is what would be the 0 if offset was not defined
            end_sample = events_filtered(feedback_idx).sample + samples_to_add; % Trial end
            
            % Calculate timing parameters
            t_fixation_onset = (events_filtered(onset_idx).sample - events_filtered(fixation_idx).sample) / hdr.Fs;
            
            % Offset: set time zero to feedback onset
            offset = -samples_to_add - (events_filtered(feedback_idx).sample - events_filtered(fixation_idx).sample);
            
            % Get trial codes
            code_trial = find(strcmp(events_filtered(onset_idx).value, onset));
            code_response = find(strcmp(events_filtered(response_idx).value, response));
            code_feedback = find(strcmp(events_filtered(feedback_idx).value, feedback));
            
            % Calculate reaction time (handle no-response trials)
            if strcmp(events_filtered(response_idx).value, 'S199')
                RT = nan;  % No response trial
            else
                RT = (events_filtered(response_idx).sample - events_filtered(onset_idx).sample) / hdr.Fs;
            end
            
            % Add trial to trl matrix
            trl = cat(1, trl, [beg_sample end_sample offset 100*code_trial 100*code_response ...
                              code_feedback RT t_fixation_onset]);
            %trl = cat(1, trl, [beg_sample end_sample offset 100*code_trial 100*code_response ...
             %         code_feedback RT t_fixation_onset t_feedback_to_next_event]);
            end
        
    elseif distance < 4
        % Too few events between fixation and feedback - discard trial
        continue;
        
    else
        % distance > 4: Multiple events between fixation and feedback
        % Take the LAST response before feedback
        fprintf('Distance > 4\n');
        fixation_idx = ev;
        fprintf('ev=%d, is_fixation=%d, value=%s\n', fixation_idx, is_fixation, events_filtered(ev).value);
        
        % Find onset (first occurrence after fixation)
        onset_idx = [];
        for i = (fixation_idx+1):(feedback_idx-1)
            if any(strcmp(events_filtered(i).value, onset))
                onset_idx = i;
                fprintf('onset_idx=%d, value=%s\n', onset_idx, events_filtered(onset_idx).value);
                fprintf('feedback_idx=%d, value=%s\n', feedback_idx, events_filtered(feedback_idx).value);
                break;
            end
        end
        
        if isempty(onset_idx)
            continue;  % No onset found
        end
        
        % Find LAST response before feedback (closest to feedback)
        response_idx = [];
        for i = (feedback_idx-1):-1:(onset_idx+1)
            if any(strcmp(events_filtered(i).value, response))
                response_idx = i;
                fprintf('response_idx=%d, value=%s\n', response_idx, events_filtered(response_idx).value);
                break;
            end
        end
        
        if isempty(response_idx)
            continue;  % No response found
        end
        
        % Calculate trial boundaries
        beg_sample = events_filtered(fixation_idx).sample - samples_to_add;
        end_sample = events_filtered(feedback_idx).sample + samples_to_add;
        
        % Calculate timing parameters
        t_fixation_onset = (events_filtered(onset_idx).sample - events_filtered(fixation_idx).sample) / hdr.Fs;
        
        % Offset: set time zero to feedback onset
        offset = -samples_to_add - (events_filtered(feedback_idx).sample - events_filtered(fixation_idx).sample);
        
        % Get trial codes
        code_trial = find(strcmp(events_filtered(onset_idx).value, onset));
        code_response = find(strcmp(events_filtered(response_idx).value, response));
        code_feedback = find(strcmp(events_filtered(feedback_idx).value, feedback));
        
        % Calculate reaction time (handle no-response trials)
        if strcmp(events_filtered(response_idx).value, 'S199')
            RT = nan;  % No response trial
        else
            RT = (events_filtered(response_idx).sample - events_filtered(onset_idx).sample) / hdr.Fs;
        end
        
        % Add trial to trl matrix
        trl = cat(1, trl, [beg_sample end_sample offset 100*code_trial 100*code_response ...
                          code_feedback RT t_fixation_onset]);
        %trl = cat(1, trl, [beg_sample end_sample offset 100*code_trial 100*code_response ...
         %         code_feedback RT t_fixation_onset t_feedback_to_next_event]);
    end
end

% Add a column on the trl to count buffer overflow count 
trl(:, end+1) = buffer_overflow_count;

end


%{
for ev=4:length(events) % starts from my starting event whihch is event 3
    is_feedback = any(strcmp(events(ev).value,feedback)); % Feedbcak is my 0
    is_response=any(strcmp(events(ev-1).value,response));
    is_onset=any(strcmp(events(ev-2).value,onset));
    is_fixation=strcmp(events(ev-3).value,fixation);
    

    if is_feedback & is_response & is_onset & is_fixation
       
       beg_sample=events(ev-3).sample-samples_to_add;
       end_sample=events(ev).sample+samples_to_add;
       t_fixation_onset=(events(ev-2).sample-events(ev-3).sample)/hdr.Fs;
       offset=-samples_to_add-(events(ev).sample-events(ev-3).sample); % We set the 0 as the feedback in each segment
       code_trial=find(strcmp(events(ev-2).value,onset));
       code_response=find((strcmp(events(ev-1).value,response)));
       code_feedback=find((strcmp(events(ev).value,feedback)));
       switch code_response
           case 199
               RT=nan;
           otherwise
                RT=(events(ev-1).sample-events(ev-2).sample)/hdr.Fs;
     
       end
       %Trial information
       trl=cat(1,trl,[beg_sample end_sample offset 100*code_trial 100*code_response code_feedback RT t_fixation_onset]);
    end
end


end
%}