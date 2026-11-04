function [bad_chan,Part_info] = authomatic_detection_bad_channels(EEG,Params,Part_info,method)
% Mireia Torralba Cuello (2024), flag bad channels using authomatic
% procedures

% Now use authomatic procedures for signaling bad channels
%Apply notch filter to the data (for visualization of bad channels)
EEG = pop_eegfiltnew(EEG, 'locutoff',49,'hicutoff',51,'revfilt',1,'plotfreqz',0);

switch method
    case 'clean_trim'
        trim=true;
        clean=true;
    case 'clean'
        trim=false;
        clean=true;
    case 'trim'
        trim=true;
        clean=false;
end

tmp=struct2table(EEG.chanlocs);
chanlocs1=tmp.labels;

%Scan for bad channels
if clean
EEG2 = pop_clean_rawdata(EEG, 'FlatlineCriterion',Params.FlatEEG,'ChannelCriterion',Params.Corr,'LineNoiseCriterion',Params.LineNoise,'Highpass','off','BurstCriterion','off','WindowCriterion','off','BurstRejection','off','Distance','Euclidian','channels_ignore',[]);

disp('Noisy channels according to authomatic detection (correlation, flat channel, line noise)')
vis_artifacts(EEG2,EEG)
tmp=struct2table(EEG2.chanlocs);
chanlocs2=tmp.labels;
bad_channel2=setdiff(chanlocs1,chanlocs2);
input('Press any key to proceed')
else
    bad_channel2=[];
end

if trim
EEG3 =pop_trimOutlier_mtc_channels(EEG); %This is modified from the plugin to address only channel issues


EEG3.etc.clean_channel_mask=EEG3.etc.trimOutlier.cleanChannelMask;
disp('Noisy channels according to high standard deviation')
vis_artifacts(EEG3,EEG)
input('Press any key to proceed')

Part_info.Channel_SD_bounds=EEG3.etc.trimOutlier.channel_SD_bounds;

tmp=struct2table(EEG3.chanlocs);
chanlocs3=tmp.labels;
bad_channel3=setdiff(chanlocs1,chanlocs3);
else
    bad_channel3=[];

end



if all(size(bad_channel2)>0) && all(size(bad_channel3)>0)
   bad_chan=unique(cat(1,bad_channel2,bad_channel3));
elseif all(size(bad_channel2)>0)
    bad_chan=bad_channel2;
elseif all(size(bad_channel3)>0)
    bad_chan=bad_channel3;
else
    bad_chan={''};
end

end