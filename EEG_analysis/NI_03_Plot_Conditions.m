% Original custom MATLAB contour plots: True, Fake, Fake minus True.
run(fullfile(fileparts(mfilename('fullpath')), 'NI_03_Setup_Plots.m'));

channels = {'FCz', 'Fz', 'Cz'};
ch_label = strjoin(channels, ', ');
cfg = [];
cfg.channel = channels;
cfg.avgoverchan = 'yes';
tmp = ft_selectdata(cfg, misinformation_share_true);
tmp2 = ft_selectdata(cfg, misinformation_share_fake);

h = figure('Position', [114 227 1126 751]);

subplot(2,2,1)
contourf(tmp.time, tmp.freq, squeeze(tmp.powspctrm), 20, 'LineStyle', 'none');
caxis([-1 1]); colorbar;
xlabel('Time (s)'); ylabel('Frequency (Hz)'); ylim([2 15]);
set(gca, 'FontName', 'Arial', 'FontSize', 16);
title(sprintf('True | N = %d | threshold = %d', N, thresholdm));

subplot(2,2,2)
contourf(tmp2.time, tmp2.freq, squeeze(tmp2.powspctrm), 20, 'LineStyle', 'none');
caxis([-1 1]); colorbar;
xlabel('Time (s)'); ylabel('Frequency (Hz)'); ylim([2 15]);
set(gca, 'FontName', 'Arial', 'FontSize', 16);
title(sprintf('Fake | N = %d | threshold = %d', N, thresholdm));

subplot(2,1,2)
contourf(tmp.time, tmp.freq, squeeze(tmp2.powspctrm-tmp.powspctrm), 20, 'LineStyle', 'none');
caxis([-0.7 0.7]);
xlabel('Time (s)'); ylabel('Frequency (Hz)'); ylim([2 15]);
c = colorbar; c.Label.String = '\Delta Power (dB)';
set(gca, 'FontName', 'Arial', 'FontSize', 16);
title(sprintf('Fake - True | N = %d | threshold = %d | Morlet = %d | Channels: %s', ...
    N, thresholdm, Morlet, ch_label));

saveas(h, fullfile(Path.Plots_Bolo, ...
    sprintf('Multiplot_threshold%d_Morlet%d_Channels_%s.jpg', thresholdm, Morlet, ch_label)), 'jpg');
close(h);
