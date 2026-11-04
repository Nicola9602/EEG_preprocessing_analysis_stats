% Original FieldTrip plots: channel multiplot, ROI singleplots, scalp topographies.
run(fullfile(fileparts(mfilename('fullpath')), 'NI_03_Setup_Plots.m'));

% All-electrode display of Fake minus True.
h1 = figure;
cfg = []; cfg.layout = layout;
ft_multiplotTFR(cfg, diffTF);
title(sprintf('Fake - True | N = %d | threshold = %d', N, thresholdm));
saveas(h1, fullfile(Path.Plots_Bolo, sprintf('FT_Multiplot_threshold%d.jpg', thresholdm)));
close(h1);

% Single-channel/ROI time-frequency maps.
conditions = {misinformation_share_true, misinformation_share_fake, diffTF};
names = {'True', 'Fake', 'Difference'};
for i = 1:3
    h = figure;
    cfg = [];
    cfg.layout = layout;
    cfg.channel = Params.Misinformation.ROI;
    cfg.maskstyle = 'saturation';
    cfg.zlim = [-2 2];
    if i == 3, cfg.zlim = [-1.5 1.5]; end
    cfg.colorbar = 'yes';
    ft_singleplotTFR(cfg, conditions{i});
    title(sprintf('%s | N = %d | threshold = %d', names{i}, N, thresholdm));
    saveas(h, fullfile(Path.Plots_Bolo, sprintf('FT_Single_%s_threshold%d.jpg', names{i}, thresholdm)));
    close(h);
end

% Scalp topographies: original time range and frequency-of-interest.
for i = 1:3
    h = figure;
    cfg = [];
    cfg.layout = layout;
    cfg.xlim = [0.5 0.75];
    cfg.ylim = Params.Misinformation.FOI;
    cfg.zlim = 'maxabs';
    if i == 3, cfg.zlim = [-1 1]; end
    cfg.colorbar = 'yes';
    ft_topoplotTFR(cfg, conditions{i});
    title(sprintf('%s | N = %d | threshold = %d', names{i}, N, thresholdm));
    saveas(h, fullfile(Path.Plots_Bolo, sprintf('FT_Topoplot_%s_threshold%d.jpg', names{i}, thresholdm)));
    close(h);
end
