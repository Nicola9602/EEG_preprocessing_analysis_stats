MATLAB pipeline for preprocessing BrainVision EEG recordings from an experiment combining Stroop and misinformation-rating tasks. Automated processing is combined with supervised quality control to produce cleaned continuous recordings, event-aligned epochs, and participant-level trial-count summaries.

A readme file is present in the folder 01_Functrions explaining how to use each of them.

# Processing workflow

Run the numbered scripts sequentially. Participant-specific `Part_info` logs store quality-control decisions and parameters for reuse across stages.

| Script | Processing steps |
| - | - |
| `00_Setup.m` | Defines paths, toolbox locations, electrode files, preprocessing parameters, and task-specific event codes. Supports pilot and experimental datasets. |
| `01_Bad_channels.m` | Displays continuous EEG and assists with noisy-channel identification. Records the final channel selection and interactively selected amplitude thresholds and rejection windows used to prepare ICA input. This stage requires supervision for each participant. |
| `02_Preprocessing_ICA.m` | Removes bad channels, applies average referencing and a 1 Hz high-pass filter, and excludes high-amplitude segments from ICA estimation. Computes extended Infomax ICA and classifies components with ICLabel. Exports component diagnostics for visual inspection, transfers the decomposition to the continuous dataset, and subtracts flagged components. The current configuration flags eye-related components with ICLabel probability ≥ 0.90. |
| `03_Preprocessing_final.m` | Converts ICA-corrected EEG to FieldTrip format. Applies 0.1–40 Hz filtering, 50 Hz DFT line-noise removal, demeaning, detrending, and average referencing. Detects candidate muscle artifacts for supervised review, replaces rejected intervals with `NaN` to preserve timing, reconstructs excluded channels using spline interpolation, and standardizes channel order. |
| `04_Segmentation.m` | Extracts stimulus-aligned Stroop epochs and feedback-aligned misinformation epochs using event markers and custom trial functions. Adds temporal padding for subsequent time-frequency analysis, saves trial metadata, and updates an Excel summary of trial counts and event-parsing diagnostics. |
| `05_TrialsTable.m` | Summarizes misinformation trials by participant across four conditions: sharing or not sharing false or true information. Exports `trial_counts_summary.xlsx` to support participant selection and assessment of condition balance. |

# Setup and execution

1.Software Requirements

The EEG preprocessing pipeline was developed using MATLAB, EEGLAB 2024.2, and FieldTrip 20230118.

The EEGLAB environment includes the following plugins: bva-io 1.73, ICLabel 1.6, trimOutlier 2.0, and Viewprops 1.5.4.

For reproducibility, the specified software and plugin versions are recommended when configuring the processing environment.

2. Make the project-specific helper functions, electrode coordinates, and channel-layout files available on the configured paths.

3. Configure local paths and dataset settings in the setup function. BrainVision inputs consist of matching `.eeg`, `.vhdr`, and `.vmrk` files organized by participant.

4. Run bad-channel identification for each participant and record the supervised decisions.

5. Run ICA estimation and inspect the component diagnostics. Set `ic_calc = true` to compute new decompositions; `false` loads existing decompositions. The `plot_ic` block also flags and removes components, so it performs more than plotting.

6. Complete final preprocessing, visually reviewing candidate artifact intervals before saving.

7. Segment the cleaned recordings and generate the condition-count summary.

**Summary export:** `05_TrialsTable.m` overwrites its output workbook. Select all intended participants when generating the complete summary.

# Quality control notes

`Notes_PreProcessing.xlsx` illustrates a manual QC record covering problematic channels, rejection thresholds, excluded ICA components, recording-specific issues, and final processing notes. It complements the machine-readable logs by documenting the reasoning behind decisions. Publish an empty template or fictional entries rather than participant-specific records.

# Data and dependencies

Raw recordings, participant logs, intermediate datasets, and installed FieldTrip and EEGLAB distributions are not included. Running the workflow requires access to the expected data and project-specific helper files. The preprocessing workflow prepares inputs for subsequent analyses; these scripts do not themselves implement the downstream statistical or time-frequency analyses.


