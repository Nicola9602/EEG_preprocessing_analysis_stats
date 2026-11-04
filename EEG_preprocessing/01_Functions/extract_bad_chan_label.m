function bad_channel_label=extract_bad_chan_label(bad_channels)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Mireia Torralba Cuello MRG Group 2024
% Function for converting the input from the excel file to a format that
% eeglab can understand
% Input:
% bad_channels: string that contains all the names of the bad electrodes
% separated by commas
% Output:
% bad_channel_label: cell array that contains the name of the electrodes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
bad_channel_idx=[];
if ~isempty(bad_channels)

    position=strfind(bad_channels{1},',');
    if isempty(position)
        bad_channel_label{1}=bad_channels{1};
    else
        position=cat(2,position,length(bad_channels{1})+1);
        bad_channel_label{1}=bad_channels{1}(1:position(1)-1);
        for c=1:length(position)-1
            bad_channel_label{c+1}=bad_channels{1}(position(c)+1:position(c+1)-1);
        end

    end
end

