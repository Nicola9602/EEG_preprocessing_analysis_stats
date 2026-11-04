# EEG preprocessing, time-frequency analysis, and statistical modelling

MATLAB and R pipeline for preprocessing BrainVision EEG recordings and analysing data from an experiment combining Stroop and misinformation-rating tasks. Automated processing is combined with supervised quality control to produce cleaned continuous recordings, event-aligned epochs, group-level time-frequency plots, trial-level theta-power measures, and behavioural/EEG statistical models.

The preprocessing scripts should be run before the downstream analyses. A separate README in `01_Functions` documents the project-specific helper functions.

## Processing workflow

Run the numbered preprocessing scripts sequentially. Participant-specific `Part_info` logs store quality-control decisions and parameters for reuse across stages.

| **Script** | **Processing steps** |
| --- | --- |
| `00_Setup.m` | Defines paths, toolbox locations, electrode files, preprocessing parameters, and task-specific event codes. Supports pilot and experimental datasets. |
| `01_Bad_channels.m` | Displays continuous EEG and assists with noisy-channel identification. Records the final channel selection and interactively selected amplitude thresholds and rejection windows used to prepare ICA input. This stage requires supervision for each participant. |
| `02_Preprocessing_ICA.m` | Removes bad channels, applies average referencing and a 1 Hz high-pass filter, and excludes high-amplitude segments from ICA estimation. Computes extended Infomax ICA and classifies components with ICLabel. Exports component diagnostics for visual inspection, transfers the decomposition to the continuous dataset, and subtracts flagged components. The current configuration flags eye-related components with ICLabel probability >= 0.90. |
| `03_Preprocessing_final.m` | Converts ICA-corrected EEG to FieldTrip format. Applies 0.1–40 Hz filtering, 50 Hz DFT line-noise removal, demeaning, detrending, and average referencing. Detects candidate muscle artifacts for supervised review, replaces rejected intervals with `NaN` to preserve timing, reconstructs excluded channels using spline interpolation, and standardizes channel order. |
| `04_Segmentation.m` | Extracts stimulus-aligned Stroop epochs and feedback-aligned misinformation epochs using event markers and custom trial functions. Adds temporal padding for subsequent time-frequency analysis, saves trial metadata, and updates an Excel summary of trial counts and event-parsing diagnostics. |
| `05_TrialsTable.m` | Summarizes misinformation trials by participant across sharing/not-sharing and true/false conditions. Exports `trial_counts_summary.xlsx` for participant selection and condition-balance checks. |

## EEG analysis workflow (MATLAB)

These scripts use segmented EEG data generated during preprocessing. The grand-average analysis and the trial-level analysis serve different purposes and need not be executed sequentially relative to each other.

| **Script** | **Analysis and outputs** |
| --- | --- |
| `NI_00_Setup_analysis.m` | Defines paths, condition/event codes, EEG frequency settings, baselines, and the electrode layout used by the downstream MATLAB analyses. Supports Stroop and misinformation configurations. |
| `NI_01_Stroop_theta.m` | Processes segmented Stroop epochs, excludes selected trials with missing data, computes Morlet time-frequency power for correct congruent/incongruent trials, applies dB baseline correction, and produces group-level comparison plots. The uploaded version is configured for pilot data and references `MI_00_Setup_analysis`; check that setup name before running. |
| `NI_02_Misinformation_GrandAvg_threshold_All_Subjects.m` | Selects participants using minimum trial-count thresholds, keeps valid *sharing* trials, separates shared True and Fake trials, computes Morlet time-frequency power, applies dB baseline correction, and saves group grand averages for each condition. |
| `NI_03_Plot_Conditions.m` | Produces custom time-frequency contour plots for shared True, shared Fake, and Fake-minus-True power averaged over Fz, FCz, and Cz. |
| `NI_03_Plot_FieldTrip.m` | Produces FieldTrip electrode multiplots, ROI singleplots, and scalp topographies for the True, Fake, and difference data. |
| `NI_03_Plot_Theta.m` | Produces Fake-minus-True time-frequency plots with scalp-map insets for specified theta time windows, including a combined three-panel figure. |
| `NI_04_Misinformation_3_Chan_SingleTrials_theta_all_subj.m` | Extracts trial-level theta power separately for Fz, FCz, and Cz (no averaging across channels or trials). Supports multiple time windows and Morlet widths, with general or focused `NaN` rejection. Saves trial-level CSV files and exclusion summaries. |

### Analysis details

- **Grand averages (`NI_02`):** currently configured with threshold `1` and Morlet width `4` (other thresholds/widths can be selected in the script). It analyses shared True versus shared Fake feedback trials, uses the frequency grid defined in `Params.Misinformation.Freq`, and saves FieldTrip `.mat` grand averages after baseline correction. The saved structures are group averages, not trial-level observations.
- **Plots (`NI_03`):** visualise previously saved grand averages; they do not recalculate EEG power or perform significance testing. The channel-averaged maps and the all-electrode scalp topographies answer different descriptive questions.
- **Single trials (`NI_04`):** currently uses Morlet width `4`, focused `NaN` rejection, and theta windows `[0, 0.75]`, `[0, 0.5]`, `[0.5, 0.75]`, and `[0.4, 0.75]` seconds. Theta is selected over `[4, 8]` Hz; the actual frequency grid used for estimation is defined in `NI_00_Setup_analysis.m`. Each exported row corresponds to a trial from one participant and contains trial metadata and individual electrode power estimates.
- **Baselines and settings:** the analysis setup currently defines a misinformation baseline of `[-0.8, -0.4]` seconds and a 5–8 Hz frequency-of-interest grid. Consult the active code and saved output metadata rather than relying on older header comments or output filenames for exact parameters.

## Statistical analysis (R)

| **Script** | **Analysis steps** |
| --- | --- |
| `Lmer_TF_Theta_3Chan.r` | Imports behavioural ratings and trial-level EEG theta-power CSV files; structures pre/post responses; derives true/fake conditions and political-orientation groups; matches pre/post responses by participant and item; fits mixed-effects models; evaluates contrasts with `emmeans`; and compares results across several theta time windows with Holm-adjusted p-values and plots. |

The R analysis includes three main components:

1. **Behavioural ratings:** models the original 1–7 sharing ratings across pre/post assessment, information truth, and political-orientation groups, with participant and item random effects.
2. **Behavioural–EEG matching:** calculates an item-level change score (`post - pre`), joins behavioural and theta-power data using participant and item identifiers, and applies a minimum number of Fake/True trials per participant.
3. **EEG and behavioural models:** averages Fz/FCz/Cz theta estimates for selected models, tests feedback and political-group effects on theta power, and examines whether theta power predicts item-level rating changes. Models are repeated across time windows, with selected contrasts and multiple-testing adjustments.

**Status:** the uploaded R script is a research working script rather than a verified, one-command reproducible pipeline. In particular, its `emmeans(..., var"mean_power")` expression needs correction, and a later `emtrends()` call requests feedback-specific slopes from a model without a feedback predictor. These sections should be reviewed before publishing numerical results from an automated run. The script also creates an ordered-response dataset but fits the main `lmer()` model to the numeric-response dataset; this should be documented as a continuous-rating analysis if intentional.

## Setup and execution

1. **Software:** EEG preprocessing was developed with MATLAB, EEGLAB 2024.2, and FieldTrip 20230118. EEGLAB plugins include bva-io 1.73, ICLabel 1.6, trimOutlier 2.0, and Viewprops 1.5.4. The R analysis uses packages including `dplyr`, `tidyr`, `readr`, `ggplot2`, `lme4`, `lmerTest`, `emmeans`, and `purrr`. Pin exact R/package versions with `renv` if a reproducible environment is required.
2. Make the project helper functions, electrode coordinates, FieldTrip layout files, and required toolboxes available locally. Configure computer-specific paths before executing the MATLAB scripts. BrainVision inputs comprise matching `.eeg`, `.vhdr`, and `.vmrk` files organised by participant.
3. Run supervised bad-channel selection, ICA estimation/inspection, final preprocessing, and segmentation in the order listed above. `05_TrialsTable.m` overwrites its summary workbook; select all intended participants for a complete summary.
4. Set the task and analysis mode in `NI_00_Setup_analysis.m`, then run the appropriate `NI_01`, `NI_02`, or `NI_04` analysis. `NI_02` uses `trial_counts_summary.xlsx`; `NI_04` exports one row per retained trial and channel-specific theta values.
5. To create `NI_03` plots, first generate or obtain the corresponding `NI_02` grand averages and configure the requested input filenames/threshold. The uploaded plotting scripts invoke `NI_03_Setup_Plots.m`, which must be available separately (or the loading code must be incorporated into their setup).
6. For statistics, place the authorised behavioural CSV and the matching trial-number EEG CSVs in the locally configured data locations, adjust the file paths in `Lmer_TF_Theta_3Chan.r`, and run the R analyses. The EEG–behavioural join requires compatible participant and item identifiers; the basic `NI_04` CSV shown here does not itself document an `ItemNum` field, so use an export containing that metadata for the join.

## Quality control notes

`Notes_PreProcessing.xlsx` illustrates manual QC records for problematic channels, rejection thresholds, excluded ICA components, recording-specific issues, and final processing decisions. The record complements machine-readable logs by documenting the reasoning behind decisions. Share only a blank template or fictitious examples, not participant-specific records.

In downstream analysis, participant inclusion may vary with the minimum trial threshold, trial selection, missing-data rejection, and availability of matched pre/post behavioural ratings. Record the selected thresholds, final participant counts, and exact time-frequency settings when reporting results.

## Data availability, privacy, and reproducibility

Raw BrainVision recordings, participant-level EEG files, behavioural response tables, participant lists/logs, trial-count workbooks, and generated trial-level results are **not included in the public repository**. Some data include sensitive participant characteristics. Access to research data is subject to the study's applicable ethics approval, consent, and institutional data-sharing rules.

The repository shares analysis code and describes the expected inputs, but **code availability does not imply public availability of the underlying data**. Reproduction of the actual estimates requires authorised access to the original dataset. Synthetic example data and a data dictionary can be added to permit testing without disclosing participant information.

Local absolute paths should be kept outside version-controlled scripts wherever possible. A private local paths file or environment configuration can be used alongside a public example template. Configure `.gitignore` to exclude restricted datasets, private configuration files, participant logs, and generated outputs; note that files previously committed are not made private by adding them to `.gitignore`.

## Current limitations

- Some filename labels and older script comments differ from the active parameters; the executed code and configuration take precedence.
- The uploaded `NI_00_Setup_analysis.m` includes additional plotting-setup statements after the function's main parameter-definition section. These should be separated into the plotting setup file before treating the repository as a clean, runnable pipeline.
- The scripts have not been end-to-end verified here using the restricted datasets and installed toolboxes. Outputs should be checked against the original study results after any refactoring.
