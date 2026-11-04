% Original custom time-frequency plots with scalp-map insets.
% Creates two separate figures and one combined three-panel figure.
run(fullfile(fileparts(mfilename('fullpath')), 'NI_03_Setup_Plots.m'));

% Settings

roi_channels = {'Fz', 'FCz', 'Cz'};

% Frequency interval used for rectangle and topography
freq_roi = [5 8];

% Two time windows:
% 1. Full analysis window
% 2. Late interval
time_rois = [
    0.00 0.75
    0.50 0.75
];

% Time displayed on the x-axis for each figure
time_limits_all = [
   -0.75 1.20
   -0.75 1.20
];

% Frequency displayed on the y-axis
freq_limits = [4 10];

% Identical colour limits for TF plots and topographies
colour_limits = [-0.7 0.7];

% Average Fz, FCz and Cz for the TF background

cfg = [];
cfg.channel = roi_channels;
cfg.avgoverchan = 'yes';

roiTF = ft_selectdata(cfg, diffTF);

% After channel averaging:
% frequency x time
pow = squeeze(roiTF.powspctrm);

% Generate one figure for each time window

for iWindow = 1:size(time_rois, 1)

    % Current time interval
    current_time_roi = time_rois(iWindow, :);

    % Current x-axis limits
    current_time_limits = time_limits_all(iWindow, :);

    % --------------------------------------------------------
    % Create figure
    % --------------------------------------------------------

    h = figure( ...
        'Color', 'w', ...
        'Position', [100 100 1050 620]);

    % --------------------------------------------------------
    % Main time-frequency axes
    % --------------------------------------------------------

    axMain = axes( ...
        'Parent', h, ...
        'Units', 'normalized', ...
        'Position', [0.09 0.13 0.70 0.80] ...
    );

    % --------------------------------------------------------
    % Plot the time-frequency difference
    % --------------------------------------------------------

    contourf( ...
        axMain, ...
        roiTF.time, ...
        roiTF.freq, ...
        pow, ...
        100, ...
        'LineStyle', 'none' ...
    );

    hold(axMain, 'on');

    xlim(axMain, current_time_limits);
    ylim(axMain, freq_limits);
    clim(axMain, colour_limits);

    xlabel(axMain, 'Time from feedback onset (s)');
    ylabel(axMain, 'Frequency (Hz)');

    set( ...
        axMain, ...
        'FontName', 'Arial', ...
        'FontSize', 13, ...
        'LineWidth', 1 ...
    );

    box(axMain, 'off');

    % --------------------------------------------------------
    % Dashed line at feedback onset
    % --------------------------------------------------------

    xline( ...
        axMain, ...
        0, ...
        'k--', ...
        'LineWidth', 1.5 ...
    );

    % --------------------------------------------------------
    % Rectangle showing the current TF window
    % --------------------------------------------------------

    rectangle( ...
        axMain, ...
        'Position', [ ...
            current_time_roi(1), ...
            freq_roi(1), ...
            diff(current_time_roi), ...
            diff(freq_roi) ...
        ], ...
        'EdgeColor', 'k', ...
        'LineStyle', '--', ...
        'LineWidth', 1.5 ...
    );

    % --------------------------------------------------------
    % Topographical inset
    % [left bottom width height]
    % This places a smaller topoplot in the top-right corner.
    % --------------------------------------------------------

    axTopoPosition = [0.61 0.64 0.17 0.24];

    axTopo = axes( ...
        'Parent', h, ...
        'Units', 'normalized', ...
        'Position', axTopoPosition ...
    );

    axes(axTopo);

    % --------------------------------------------------------
    % Topographical plot settings
    % --------------------------------------------------------

    cfg = [];

    cfg.layout = layout;

    % Same time-frequency interval as the rectangle
    cfg.xlim = current_time_roi;
    cfg.ylim = freq_roi;

    % Same scale as the main TF plot
    cfg.zlim = colour_limits;

    cfg.colorbar = 'no';
    cfg.comment = 'no';

    % Filled topography with contour lines
    cfg.style = 'both';
    cfg.contournum = 3;

    % Electrode markers
    cfg.marker = 'on';
    cfg.markersymbol = '.';
    cfg.markercolor = [0.40 0.40 0.40];
    cfg.markersize = 6;

    ft_topoplotTFR(cfg, diffTF);

    % --------------------------------------------------------
    % Restore position in case FieldTrip modifies the axes
    % --------------------------------------------------------

    set( ...
        axTopo, ...
        'Units', 'normalized', ...
        'Position', axTopoPosition ...
    );

    % --------------------------------------------------------
    % Topoplot title
    % --------------------------------------------------------

    title( ...
        axTopo, ...
        sprintf( ...
            '%.2f-%.2f s, %d-%d Hz', ...
            current_time_roi(1), ...
            current_time_roi(2), ...
            freq_roi(1), ...
            freq_roi(2) ...
        ), ...
        'FontName', 'Arial', ...
        'FontSize', 9 ...
    );

    % --------------------------------------------------------
    % Shared colormap
    % --------------------------------------------------------

    colormap(h, parula);

    % --------------------------------------------------------
    % Colourbar
    % --------------------------------------------------------

    cb = colorbar(axMain);

    cb.Position = [0.84 0.22 0.025 0.58];

    cb.Label.String = sprintf( ...
        'Fake - True\npower (dB)' ...
    );

    cb.Label.FontName = 'Arial';
    cb.Label.FontSize = 12;

    % --------------------------------------------------------
    % Optional saving
    % --------------------------------------------------------

    % exportgraphics( ...
    %     h, ...
    %     sprintf( ...
    %         'TF_topography_%d_%d_ms.png', ...
    %         round(current_time_roi(1) * 1000), ...
    %         round(current_time_roi(2) * 1000) ...
    %     ), ...
    %     'Resolution', 300 ...
    % );

    saveas(h, fullfile(Path.Plots_Bolo, sprintf('Theta_inset_%d_%dms_threshold%d.jpg', ...
        round(current_time_roi(1)*1000), round(current_time_roi(2)*1000), thresholdm)));
end
%% Combined figure:
% (a) 0.00-0.75 s theta window
% (b) 0.35-0.75 s theta window
% (c) 0.50-0.75 s late theta window

% Settings

roi_channels = {'Fz', 'FCz', 'Cz'};

freq_roi = [5 8];

% Time windows represented by each panel
time_rois = [
    0.00 0.75
    0.35 0.75
    0.50 0.75
];

panel_letters = {
    '(a)'
    '(b)'
    '(c)'
};

% Same displayed limits in all panels
time_limits = [-0.75 1.20];
freq_limits = [4 10];

% Same colour limits everywhere
colour_limits = [-0.7 0.7];

% Average Fz, FCz and Cz for the TF background

cfg = [];
cfg.channel = roi_channels;
cfg.avgoverchan = 'yes';

roiTF = ft_selectdata(cfg, diffTF);

% Frequency x time
pow = squeeze(roiTF.powspctrm);

% Create one large figure

h = figure( ...
    'Color', 'w', ...
    'Position', [100 30 1100 1000] ...
);

% Manual positions for the three closely spaced panels
% Format:
% [left bottom width height]

main_positions = [
    0.09 0.665 0.70 0.27
    0.09 0.375 0.70 0.27
    0.09 0.085 0.70 0.27
];

% Smaller topographies in the upper-right of each panel
topo_positions = [
    0.655 0.745 0.105 0.145
    0.655 0.455 0.105 0.145
    0.655 0.165 0.105 0.145
];

letter_positions = [
    0.025 0.900 0.05 0.035
    0.025 0.610 0.05 0.035
    0.025 0.320 0.05 0.035
];

nPanels = size(time_rois, 1);

% Store axes handles
axMain_all = gobjects(nPanels, 1);
axTopo_all = gobjects(nPanels, 1);

% Generate the three panels

for iPanel = 1:nPanels

    current_time_roi = time_rois(iPanel, :);

    % Main TF axes

    axMain = axes( ...
        'Parent', h, ...
        'Units', 'normalized', ...
        'Position', main_positions(iPanel, :) ...
    );

    axMain_all(iPanel) = axMain;

    contourf( ...
        axMain, ...
        roiTF.time, ...
        roiTF.freq, ...
        pow, ...
        100, ...
        'LineStyle', 'none' ...
    );

    hold(axMain, 'on');

    xlim(axMain, time_limits);
    ylim(axMain, freq_limits);
    clim(axMain, colour_limits);

    ylabel(axMain, 'Frequency (Hz)');

    set( ...
        axMain, ...
        'FontName', 'Arial', ...
        'FontSize', 12, ...
        'LineWidth', 1 ...
    );

    box(axMain, 'off');

    % --------------------------------------------------------
    % Only the bottom panel shows the x-axis
    % --------------------------------------------------------

    if iPanel < nPanels

        % Keep the axis line but remove repeated tick labels
        set(axMain, 'XTickLabel', []);

        xlabel(axMain, '');

    else

        xlabel(axMain, 'Time from feedback onset (s)');

    end

    % --------------------------------------------------------
    % Feedback onset
    % --------------------------------------------------------

    xline( ...
        axMain, ...
        0, ...
        'k--', ...
        'LineWidth', 1.5 ...
    );

    % --------------------------------------------------------
    % Time-frequency rectangle
    % --------------------------------------------------------

    rectangle( ...
        axMain, ...
        'Position', [ ...
            current_time_roi(1), ...
            freq_roi(1), ...
            diff(current_time_roi), ...
            diff(freq_roi) ...
        ], ...
        'EdgeColor', 'k', ...
        'LineStyle', '--', ...
        'LineWidth', 1.5 ...
    );

    % Topographical inset

    axTopo = axes( ...
        'Parent', h, ...
        'Units', 'normalized', ...
        'Position', topo_positions(iPanel, :) ...
    );

    axTopo_all(iPanel) = axTopo;

    axes(axTopo);

    cfg = [];
    cfg.layout = layout;

    % Same interval represented by the rectangle
    cfg.xlim = current_time_roi;
    cfg.ylim = freq_roi;

    cfg.zlim = colour_limits;

    cfg.colorbar = 'no';
    cfg.comment = 'no';

    cfg.style = 'both';
    cfg.contournum = 3;

    cfg.marker = 'on';
    cfg.markersymbol = '.';
    cfg.markercolor = [0.40 0.40 0.40];
    cfg.markersize = 5;

    ft_topoplotTFR(cfg, diffTF);

    % FieldTrip can alter the axes position, so restore it
    set( ...
        axTopo, ...
        'Units', 'normalized', ...
        'Position', topo_positions(iPanel, :) ...
    );

    % --------------------------------------------------------
    % Small label identifying the topographical interval
    % --------------------------------------------------------

    title( ...
        axTopo, ...
        sprintf( ...
            '%.2f-%.2f s, %d-%d Hz', ...
            current_time_roi(1), ...
            current_time_roi(2), ...
            freq_roi(1), ...
            freq_roi(2) ...
        ), ...
        'FontName', 'Arial', ...
        'FontSize', 8, ...
        'FontWeight', 'normal' ...
    );

    % Panel letter

    annotation( ...
        h, ...
        'textbox', ...
        letter_positions(iPanel, :), ...
        'String', panel_letters{iPanel}, ...
        'FontName', 'Arial', ...
        'FontSize', 15, ...
        'FontWeight', 'bold', ...
        'LineStyle', 'none', ...
        'HorizontalAlignment', 'left', ...
        'VerticalAlignment', 'middle' ...
    );

end

% Ensure all TF panels share exactly the same x-axis

linkaxes(axMain_all, 'x');

% One shared colormap

colormap(h, parula);

% One shared colourbar

cb = colorbar(axMain_all(end));

% Place it beside all three panels
cb.Position = [0.84 0.18 0.020 0.66];

cb.Label.String = sprintf( ...
    'Fake - True\npower (dB)' ...
);

cb.Label.FontName = 'Arial';
cb.Label.FontSize = 11;

% Creating the colourbar can slightly resize the bottom axes.
% Restore all main and topographical axes positions.
for iPanel = 1:nPanels

    set( ...
        axMain_all(iPanel), ...
        'Units', 'normalized', ...
        'Position', main_positions(iPanel, :) ...
    );

    set( ...
        axTopo_all(iPanel), ...
        'Units', 'normalized', ...
        'Position', topo_positions(iPanel, :) ...
    );

end

% Optional export

% exportgraphics( ...
%     h, ...
%     'Figure_TF_three_topographies_combined.png', ...
%     'Resolution', 300 ...
% );


saveas(h, fullfile(Path.Plots_Bolo, sprintf('Theta_three_panels_threshold%d.jpg', thresholdm)));
