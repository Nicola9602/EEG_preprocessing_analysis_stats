% Mireia Torralba MRG Group 2024
% Use this script to visualize the data and detect noisy channels, update
% the information in the excel file once you have detected the noisy
% channels of one subject.

clear

%% =========================
%  This allows you to decide whether you are running these codes saving
%  stuff in the troubleshooting folders or in the normal ones
%  =========================

RunMode = 'normal';   % 'normal' or 'troubleshooting'

%Initialize paths and parameters that you will use
code='experiment';
[Path,Params,Triggers]=MI_00_Setup(code);

%Information for repairing missing electrodes
load(Params.layout);

% Switch block
% Decide save folder based on mode
switch lower(RunMode)
    case 'troubleshooting'
        LogDir    = Path.log_troubleshooting;

    otherwise
        LogDir    = Path.log;
        LogSuffix = '';
end

% Make sure the folder exists
if ~exist(LogDir, 'dir')
    mkdir(LogDir);
end


%Initialize eeglab
try
    eeglab;
    close;
catch
    addpath(Path.eeglab);
    eeglab;
    close;
end

try
    ft_defaults;
    
catch
    addpath(Path.fieldtrip);
    ft_defaults;
end

%% Select the subject to preprocess

subject=select_subject(Path.raw_eeg,'single');


Part_info=[];
Part_info.ID=subject{1};


fullpath=fullfile(Path.raw_eeg,subject{1});
filename=[Params.experiment_name subject{1}];
%% 
try
Part_info.eeg_file=fullfile(fullpath,[filename Params.eeg]);
Part_info.marker_file=fullfile(fullpath,[filename Params.events]);
Part_info.header_file=fullfile(fullpath,[filename Params.header]);
Part_info.event=struct2table(ft_read_event(Part_info.marker_file));

catch
    disp('Cannot find file with standard name')
%CODE FOR SOLVING THE NAME PROBLEM
% List and remove directories
D = dir(fullpath); 
D = D(~[D.isdir]);
names = {D.name};

%Select NON-resting files 
isRest = contains(names, 'resting', 'IgnoreCase', true);
eeg_src  = names{endsWith(names, Params.eeg)    & ~isRest};
vmrk_src = names{endsWith(names, Params.events) & ~isRest};
vhdr_src = names{endsWith(names, Params.header) & ~isRest};

% Define standardised filenames (Misinformation_XXX.eeg/vmrk/vhdr)
eeg_tgt  = [filename Params.eeg];
vmrk_tgt = [filename Params.events];
vhdr_tgt = [filename Params.header];

% Rename the files in the folder 
movefile(fullfile(fullpath, eeg_src),  fullfile(fullpath, eeg_tgt));
movefile(fullfile(fullpath, vmrk_src), fullfile(fullpath, vmrk_tgt));
movefile(fullfile(fullpath, vhdr_src), fullfile(fullpath, vhdr_tgt));

% % But also rename the stuff inside the vhdr file, otherwise when doing ICA
% % it trows an error and looks for the most similar file but could get it
% % wrong :/

vhdr_path = fullfile(fullpath, vhdr_tgt);

txt = fileread(vhdr_path);

% Update DataFile= and MarkerFile= lines (BrainVision expects filenames, not full paths)
txt = regexprep(txt, '(?m)^(\s*DataFile\s*=\s*)[^\r\n]*',   ['$1' eeg_tgt]);
txt = regexprep(txt, '(?m)^(\s*MarkerFile\s*=\s*)[^\r\n]*', ['$1' vmrk_tgt]);

% Write back
fid = fopen(vhdr_path, 'w');
fwrite(fid, txt);
fclose(fid);

% Do the same for vmrk 
vmrk_path = fullfile(fullpath, vmrk_tgt);
txt1 = fileread(vmrk_path);

% Update DataFile= and MarkerFile= lines (BrainVision expects filenames, not full paths)
txt1 = regexprep(txt1, '(?m)^(\s*DataFile\s*=\s*)[^\r\n]*',   ['$1' eeg_tgt]);

% Write back
fid1 = fopen(vmrk_path, 'w');
fwrite(fid1, txt1);
fclose(fid1);


% Redo the part above
Part_info.eeg_file    = fullfile(fullpath, eeg_tgt);
Part_info.marker_file = fullfile(fullpath, vmrk_tgt);
Part_info.header_file = fullfile(fullpath, vhdr_tgt);
Part_info.event = struct2table(ft_read_event(Part_info.marker_file));
end
%% First, visualize raw data

cfg=[];
cfg.dataset = Part_info.header_file;

raw=ft_preprocessing(cfg);


cfg=[];
cfg.viewmode='vertical';
cfg.ylim=[-50 50];
cfg.blocksize=20; %Change this value to the one you prefer
ft_databrowser(cfg,raw);

%% Now load continous data


EEG_raw = pop_loadbv(fullpath,[filename Params.header], [ ],[ ]);
EEG=pop_chanedit(EEG_raw,Params.elecfile,'lookup',Params.elecfile);

%I don't know why previous command is not updating electrode location, so
%we wil need to insert channel locations by hand
elocs=(readlocs(Params.elecfile));

elocs=rmfield(elocs,{'sph_theta_besa','sph_phi_besa'});

elocs_tb=struct2table(elocs);
for ch=1:size(EEG.chanlocs,2)
    idx=find(strcmp(EEG.chanlocs(ch).labels,elocs_tb.labels));
    elocs(idx).urchan=[];
    elocs(idx).ref='';
    EEG.chanlocs(ch)=elocs(idx);
end



% This function helps you spot bad electrodes
%Right now it is set to use only comparison of SD between channels (as
%authomatic was too restrictive)
[bad_chan,Part_info] = authomatic_detection_bad_channels(EEG,Params,Part_info,'trim');


Bad_chan=Mark_bad_channel(Params,layout,bad_chan);
%%
Part_info.Bad_channel_final=Bad_chan;
Part_info.Bad_channel_authomatic=bad_chan;


EEG0=pop_select(EEG,'rmchannel',Part_info.Bad_channel_final)


EEG0= pop_reref( EEG0, [] ,'keepref','on');
EEG0 = pop_eegfiltnew(EEG0,'locutoff',Params.ICA_filt_freq,'filtorder',Params.ICA_filt_order);

EEG0=pop_trimOutlier_mtc_time(EEG0);
Part_info.Threshold_ICA=EEG0.etc.trimOutlier.threshold;
Part_info.Window_threshold_ICA=EEG0.etc.trimOutlier.reject_window_ms;


% Automatic save location + optional suffix
save(fullfile(LogDir,[Params.log_name Part_info.ID '.mat']),'Part_info','Params');
