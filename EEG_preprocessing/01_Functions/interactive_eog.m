function [cfg, artifact_eog] = interactive_eog(data,cutoff)
%Just copied the configuration from fieldtrip tutorial
%https://www.fieldtriptoolbox.org/tutorial/automatic_artifact_rejection/

if nargin<2
    cutoff=4;
end

 % channel selection, cutoff and padding
 cfg.artfctdef.zvalue.channel     = 'EOG';
 cfg.artfctdef.zvalue.cutoff      = cutoff;
 cfg.artfctdef.zvalue.trlpadding  = 0;
 cfg.artfctdef.zvalue.artpadding  = 0.1;
 cfg.artfctdef.zvalue.fltpadding  = 0;

 % algorithmic parameters
 cfg.artfctdef.zvalue.bpfilter   = 'yes';
 cfg.artfctdef.zvalue.bpfilttype = 'but';
 cfg.artfctdef.zvalue.bpfreq     = [2 15];
 cfg.artfctdef.zvalue.bpfiltord  = 4;
 cfg.artfctdef.zvalue.hilbert    = 'yes';
 cfg.artfctdef.zvalue.fltpadding  = 1;

 % feedback
 cfg.artfctdef.zvalue.interactive = 'yes';

 [cfg, artifact_eog] = ft_artifact_zvalue(cfg,data);

end

