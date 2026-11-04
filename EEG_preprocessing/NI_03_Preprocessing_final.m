% Mireia Torralba MRG Group 2024
% Use this script to finish the preprocessing of the data, once artifactual
% ICA components have been discarded

clear

%Initialize paths and parameters that you will use
code='experiment';


[Path,Params,Triggers]=MI_00_Setup(code);

%This is for the reconstruction of defective channels
load(Params.layout)
%Initialize fieldtrip (you can comment these lines if you already called
%fieldtrip at least once in your matlab session)
try
    ft_defaults;
    
catch
    addpath(Path.fieldtrip_analysis_pc);
    ft_defaults;
end

%Select the subject to preprocess

subject=select_subject(Path.raw_eeg,'single');


 load(fullfile(Path.log,[Params.log_name subject{1} '.mat']),'Part_info');
 load(fullfile(Path.interim,[Params.experiment_name subject{1} '_interim_preproc_2.mat']),'EEG');
   
 %Convert EEGlab structure into something that fieldtrip can understand
     subID = Part_info.ID;   

    % Header
    [~, hdr_name, hdr_ext] = fileparts(Part_info.header_file);
    Part_info.header_file = fullfile(Path.raw_eeg, subID, [hdr_name hdr_ext]);

    hdr=ft_read_header(Part_info.header_file);
  
    data=[];
    data.trial{1}=EEG.data;
    data.time{1}=EEG.times/1000; %Because EEGlab gives times in ms, Fieldtrip in seconds
    data.fsample=EEG.srate;
    data.sampleinfo=[1 EEG.pnts];
    for lb=1:length(EEG.chanlocs)
        data.label{lb,1}=EEG.chanlocs(lb).labels;
    end


cfg=[];
cfg.demean='yes';
cfg.lpfilter      = 'yes';
cfg.hpfilter      = 'yes';
cfg.dftfilter     = 'yes';
%Put in params file
cfg.lpfreq        = 40;
cfg.hpfreq        = 0.1;
cfg.dftfreq       = 50;
cfg.lpfiltord     = 4;
cfg.hpfiltord     = 4;
cfg.lpfilttype    = 'but';
cfg.hpfilttype    = 'but';
cfg.lpfiltdir     = 'twopass';
cfg.hpfiltdir     = 'twopass';
cfg.detrend       = 'yes';
cfg.reref         ='yes';
cfg.refchannel    ='all';
preproc=ft_preprocessing(cfg,data);


%Authomatic detection of artifacts, supervised rejection
%We will ask the code to indicate artifactual segments, but we will verify
%visually marked artifacts

%Detect muscle artifacts
cutoff_m=4;
data_channel=setdiff(data.label,Params.External);
[cfgm, artifact.artifact_muscle] = interactive_muscle(preproc,data_channel,cutoff_m);   
Part_info.Muscle_cutoff=cutoff_m;

%Select only data channels
cfg=[];
cfg.channel=data_channel;
preproc=ft_selectdata(cfg,preproc);

%Visualize the artifacts and validate choice
cfg=[];
cfg.artfctdef.muscle=cfgm.artfctdef.zvalue;
cfg.viewmode='vertical';
cfg.ylim=[-20 20]; %Vertical scale (microvolts)
cfg.allowoverlap='yes';
cfg.blocksize=20; %In seconds, set this value to something comfortable for revising
artf=ft_databrowser(cfg,preproc);

%Store the information of artefactual segments
Part_info.artefact=artf.artfctdef;

%Discard artefactual segments

if isfield(artf, 'trl')
    artf = rmfield(artf, 'trl');
end

artf.artfctdef.reject='nan';
data=ft_rejectartifact(artf,preproc);

%Interpolate missing channels
if ~isempty(Part_info.Bad_channel_final{1})
cfg=[];
    cfg.missingchannel=Part_info.Bad_channel_final;
    cfg.badchannel={' '};
    cfg.neigbours=neighbours;
    cfg.method='spline';
    cfg.elec=elec;
   data=ft_channelrepair(cfg,data);
end

%This is to keep the size of the files small
data=rmfield(data,'cfg');

%Now make sure that all the electrodes are in the same order
%First of all, select layout electrodes that are in our data
layout_chans=ismember(layout.label,data.label);
new_layout=[];

new_layout.pos=layout.pos(layout_chans,:);
new_layout.width=layout.width(layout_chans,:);
new_layout.outline=layout.outline;
new_layout.mask=layout.mask;

nchan=0;
for chan=1:length(layout.label)
    if layout_chans(chan)
        nchan=nchan+1;
        new_layout.label{nchan,1}=layout.label{chan};
    end
end



layout=new_layout;

try
   assert(isequal(data.label,layout.label));
catch
    tmp=data;
    tmp.label=layout.label;
    for chan=1:length(data.label)
        idx=find(strcmp(layout.label{chan},data.label));
        for trl=1:length(tmp.trial)
             tmp.trial{1,trl}(chan,:)=data.trial{1,trl}(idx,:);
        end
    end

data=tmp;
end
%Update info file with artifactual segments (we will discard them later)
save(fullfile(Path.log,[Params.log_name Part_info.ID '.mat']),'Part_info','Params');


%Store preprocessed data
 save(fullfile(Path.preprocessed,[Params.experiment_name subject{1} '_preprocessed.mat']),'data');
 

