% Mireia Torralba MRG Group 2024
% Use this script to obtain ICA decomposition of data and detect
% artifactual components (mostly visual)

clear

%Initialize paths and parameters that you will use
code='experiment';

%IC calculation: true for calculating, false to load previously calculated
%IC decompositions
ic_calc=false;
%Plot components
plot_ic=true;
%Visualize labelled components: true for inspecting the artifactual
%compontents (this will be true until you learn to recognize artifactual
%patterns)

[Path,Params,Triggers]=MI_00_Setup(code);

%Initialize eeglab (you can comment these lines if you already called
%eeglab at least once in your matlab session)
try
    eeglab;
    close;
catch
    addpath(Path.eeglab);
    eeglab;
    close;
end

%% =========================
%  Use a mode switch to not overwrite the existing stuff and go all on a
%  troubleshooting folder
%  =========================
RunMode = 'normal';   % 'normal' or 'troubleshooting'


switch lower(RunMode)

    case 'troubleshooting'
        Dirs.log    = Path.log_troubleshooting;
        Dirs.interim = Path.interim_troubleshooting;
        Dirs.figure = Path.figure_troubleshooting;

    case 'normal'
        Dirs.log    = Path.log;
        Dirs.interim = Path.interim;
        Dirs.figure = Path.figure;

    otherwise
        error('Unknown RunMode "%s". Use "normal" or "troubleshooting".', RunMode);
end

% Make sure directories exist
dirFields = fieldnames(Dirs);
for k = 1:numel(dirFields)
    d = Dirs.(dirFields{k});
    if ~exist(d,'dir')
        mkdir(d);
    end
end

%% Select the subjects to preprocess

subject=select_subject(Path.raw_eeg,'multiple');

%The ICA decomposition takes time, run this in a loop and save the
%decomposition for each subject

if ic_calc
    for sj=1:length(subject)

        fullpath=fullfile(Path.raw_eeg,subject{sj});
        filename=[Params.experiment_name subject{sj}];

        load(fullfile(Dirs.log,[Params.log_name subject{sj} '.mat']),'Part_info');


        %Load the data and remove bad channels
        EEG=[];
        EEG = pop_loadbv(fullpath,[filename Params.header], [ ],[ ]);
        EEG=pop_select(EEG,'rmchannel',Part_info.Bad_channel_final)

        %This is to be able to obtain topographical information
        EEG=pop_chanedit(EEG, 'lookup',Params.elecfile);

        %Now prepare data for ICA decomposition, we create a new dataset

        %Once bad channels are removed from data, perform average reference
        EEG= pop_reref( EEG, [] ,'keepref','on');

        %First of all apply a high pass filter that will elliminate trends in the
        %data and will improve the quality of the estimation

        EEG0 = pop_eegfiltnew(EEG,'locutoff',Params.ICA_filt_freq,'filtorder',Params.ICA_filt_order);

        %Authomatic rejection of highly noisy segments. Do not discard channels,
        %discard only timepoints that are above/below the indicated threshold (in microvolts)
        EEG0 = trimOutlier(EEG0, nan, nan, Part_info.Threshold_ICA, Part_info.Window_threshold_ICA);
       

        %Do ICA on the data (after having rejected defective channels and always
        %before interpolating them again) for the subject with two recordings,
        %we will add that change later or manually
        EEG0 = pop_runica(EEG0, 'icatype', 'runica', 'extended',1,'interrupt','on');


        %This is the authomatic labelling, we will discard visual artifacts, and
        %muscle artifacts
        EEG0 = pop_iclabel(EEG0, 'default');

        save(fullfile(Dirs.interim,[Params.experiment_name subject{sj} '_interim_preproc_1.mat']),'EEG','EEG0');
        save(fullfile(Dirs.log,[Params.log_name Part_info.ID '.mat']),'Part_info','Params');


    end

end

%Once IC has been calculated and the components flagged we will discard
%artifactual components, this will be done automatically but, before, it is
%important that you learn to recognize the patterns of activations that are
%considered artifacts


% Added this line because if above is set to false it does not pick
% up the ID, which gets loaded in the previous loop. I didn't insert it in
% the loop below to avoid confusion. In other words



if plot_ic
    for sj=1:length(subject)

        load(fullfile(Dirs.interim,[Params.experiment_name subject{sj} '_interim_preproc_1.mat']),'EEG','EEG0');
        load(fullfile(Dirs.log,[Params.log_name subject{sj} '.mat']),'Part_info');


        %Visualize artifactual components (click on the numbers above each of
        %the components to visualize extended properties)
        pop_viewprops(EEG0,0,1:32);
        h=gcf;
        saveas(h, fullfile(Dirs.figure, ['IC_plots_1_' subject{sj} '.jpg']), 'jpg');
        pop_viewprops(EEG0,0,33:size(EEG0.icawinv,2));
        h=gcf;
        saveas(h,fullfile(Dirs.figure,['IC_plots_2_' subject{sj} '.jpg']),'jpg');

        %Label artifactual components (according to the thresholds we set before)
        EEG0 = pop_icflag(EEG0, [Params.ICA.Brain;Params.ICA.Muscle;Params.ICA.Eye...
            ;Params.ICA.Heart;Params.ICA.Line_Noise;Params.ICA.Channel_Noise;Params.ICA.Other]);
        Part_info.Bad_ic_components=find(EEG0.reject.gcompreject);

        %Store extended properties of components labelled as artifacts
        for c=1:length(Part_info.Bad_ic_components)
            pop_prop_extended(EEG0, 0, Part_info.Bad_ic_components(c));
            h=gcf;
            saveas(h,fullfile(Dirs.figure,['IC_plots_comp_' num2str(c) '_' subject{sj} '.jpg']),'jpg');
            close
        end



        %Now include the ICA decomposition into the EEG file
        EEG.icaweights=EEG0.icaweights;
        EEG.icasphere=EEG0.icasphere;
        EEG.icachansind=EEG0.icachansind;
        EEG.icawinv=EEG0.icawinv;
        EEG.icaact=(EEG.icaweights*EEG.icasphere)*EEG.data(EEG.icachansind,:);

        %Reject artifactual components
        EEG = pop_subcomp( EEG, Part_info.Bad_ic_components, 0);

        save(fullfile(Dirs.interim,[Params.experiment_name subject{sj} '_interim_preproc_2.mat']),'EEG');



        %Update participant information
        save(fullfile(Dirs.log,[Params.log_name Part_info.ID '.mat']),'Part_info','Params');


    end
end