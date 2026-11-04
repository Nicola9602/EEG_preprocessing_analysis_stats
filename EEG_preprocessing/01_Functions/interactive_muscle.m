function [cfg, artifact_muscle] = interactive_muscle(data,channel,cutoff)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Just copied the configuration from fieldtrip tutorial
%https://www.fieldtriptoolbox.org/tutorial/automatic_artifact_rejection/
% Inputs:
% data: structure of data in fieldtrip format
% channel: cell array of labels that will be used for inspecting for
% artifacts
% cutoff: number, standard deviations that will be used to mark a segment
% as an artifact
%Output:
% cfg: structure containing artifactual segments
% artifact_muscle: samples containing artefacts
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if nargin<3
    cutoff=4;
end

cfg.artfctdef.zvalue.channel      = channel;
cfg.artfctdef.zvalue.cutoff       = cutoff;
cfg.artfctdef.zvalue.trlpadding   = 0;
cfg.artfctdef.zvalue.fltpadding   = 0;
cfg.artfctdef.zvalue.artpadding   = 0.1;

% algorithmic parameters
cfg.artfctdef.zvalue.bpfilter     = 'yes';
cfg.artfctdef.zvalue.bpfreq       = [110 140];
cfg.artfctdef.zvalue.bpfiltord    = 9;
cfg.artfctdef.zvalue.bpfilttype   = 'but';
cfg.artfctdef.zvalue.hilbert      = 'yes';
cfg.artfctdef.zvalue.boxcar       = 0.2;

% make the process interactive
cfg.artfctdef.zvalue.interactive = 'yes';

[cfg, artifact_muscle] = ft_artifact_zvalue(cfg,data);
end

