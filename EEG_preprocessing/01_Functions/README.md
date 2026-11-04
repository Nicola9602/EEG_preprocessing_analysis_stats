# EEG Analysis Functions

MATLAB helpers for supervised EEG quality control, event-based epoch definition, participant selection, and statistical summaries. These functions support the main preprocessing and analysis scripts; they are not a standalone pipeline.

## Quick navigation

- [Channel quality control](#channel-quality-control)
- [Artifact detection](#artifact-detection)
- [Trial definition](#trial-definition)
- [Participant selection and file utilities](#participant-selection-and-file-utilities)
- [Statistical and time-frequency utilities](#statistical-and-time-frequency-utilities)
- [Figure asset](#figure-asset)
- [Dependencies and implementation notes](#dependencies-and-implementation-notes)

## Channel quality control

### `authomatic_detection_bad_channels`

```matlab
[bad_chan, Part_info] = authomatic_detection_bad_channels(EEG, Params, Part_info, method);
```

Identifies candidate noisy channels after applying a 49–51 Hz band-stop filter to a working copy of an EEGLAB dataset. Accepts three modes:

| Mode | Detection method |
| --- | --- |
| `'clean'` | Flatline, interchannel correlation, and line-noise criteria through `pop_clean_rawdata`. |
| `'trim'` | Interactive channel standard-deviation thresholds through `pop_trimOutlier_mtc_channels`. |
| `'clean_trim'` | Union of channels identified by both methods. |

Returns candidate channel labels and, when trimming is used, stores selected SD bounds in `Part_info.Channel_SD_bounds`. Displays diagnostic comparisons and pauses for review. Returns `{''}` when no channels are identified. The existing spelling `authomatic` is part of the function name.

### `pop_trimOutlier_mtc_channels`

```matlab
[EEG, com] = pop_trimOutlier_mtc_channels(EEG);
```

Interactive adaptation of the trimOutlier interface focused on channel rejection. Computes channel SD within 100 recording bins, displays SD summaries and topographies when coordinates are available, and lets the user refine upper and lower SD thresholds. Calls `trimOutlier` to remove channels while disabling time-point rejection for continuous input. Returns the modified EEGLAB dataset and a history command; selected bounds are stored in `EEG.etc.trimOutlier.channel_SD_bounds`.

### `Mark_bad_channel`

```matlab
Bad_chan = Mark_bad_channel(Params, layout, bad_chan);
```

Opens an electrode-layout GUI with candidate bad channels preselected in red. Users toggle channels and confirm the final selection. Requires `layout.pos`, `layout.label`, and GUI geometry fields in `Params`. Returns selected channel labels, or `{''}` when none are selected. Uses the two callbacks below and shared global GUI state.

### `pushbutton1_Callback`

Channel-button callback for `Mark_bad_channel`. Toggles `hObject.UserData` and switches the button between green (retained) and red (excluded). It changes selection state without modifying EEG data.

### `okpush_Callback`

Confirmation callback for `Mark_bad_channel`. Copies the buttons' selection states into the global `State` vector and closes **all open figures**, allowing the parent function to return the selected labels.

### `extract_bad_chan_label`

```matlab
bad_channel_label = extract_bad_chan_label(bad_channels);
```

Splits a comma-separated string in the first input cell into a cell array of channel labels. For example, `{'Fp1,F7,C3'}` becomes `{'Fp1','F7','C3'}`. It does not trim whitespace. The current implementation does not assign an output for an empty input.

## Artifact detection

### `pop_trimOutlier_mtc_time`

```matlab
[EEG, com] = pop_trimOutlier_mtc_time(EEG);
```

Interactive amplitude-based rejection for **continuous** EEGLAB data. Displays the across-channel signal envelope, previews rejection using an absolute threshold in µV and a spread window in ms, and calls `trimOutlier` with channel rejection disabled. Stores the selected values in `EEG.etc.trimOutlier.threshold` and `EEG.etc.trimOutlier.reject_window_ms`. The filename and declared function name currently differ; see implementation notes.

### `interactive_eog`

```matlab
[cfg, artifact_eog] = interactive_eog(data, cutoff);
```

Configures interactive FieldTrip z-value detection on channels selected by `'EOG'`. Uses a 2–15 Hz fourth-order Butterworth filter, Hilbert envelope, and 0.1 s artifact padding. The default z-value cutoff is `4`. Returns the detector configuration and artifact sample intervals; it does not itself remove data.

### `interactive_muscle`

```matlab
[cfg, artifact_muscle] = interactive_muscle(data, channel, cutoff);
```

Configures interactive FieldTrip z-value detection on the requested channels using a 110–140 Hz ninth-order Butterworth filter, Hilbert envelope, 0.2 s smoothing, and 0.1 s artifact padding. The default cutoff is `4`. Returns configuration and candidate artifact intervals for subsequent review and rejection. Detection input must retain the target frequency band and have a suitable sampling rate; this band is absent from data already low-pass filtered at 40 Hz.

## Trial definition

These custom trial functions read BrainVision events and headers through FieldTrip and return a `trl` matrix. Set `cfg.trialfun` to the chosen function name when calling `ft_definetrial`.

**Shared inputs:** `cfg.marker`, `cfg.header`, `cfg.Add_time` (seconds), and ordered marker lists such as `Fixation`, `Stim_onset`, and `Response`. Rating functions also require `Feedback`. Marker-list order determines the numerical condition and response codes.

The first three `trl` columns are begin sample, end sample, and temporal offset in samples. Remaining columns describe each trial and become `trialinfo` when epochs are created.

### `ft_trialfun_stroop`

Extracts consecutive fixation → stimulus → response sequences, with time zero at **stimulus onset**. Epochs run from fixation minus padding to response plus padding. Encodes condition and response as `10 × marker-list index`, followed by reaction time and the fixation-to-stimulus interval in seconds. The third configured response category is treated as a timeout and receives `NaN` reaction time.

### `ft_trialfun_misinf_stim`

Stimulus-aligned misinformation variant requiring consecutive fixation → stimulus → response → feedback events. Epochs span fixation minus padding to feedback plus padding. Intended metadata include condition, response, feedback, reaction time, and fixation-to-stimulus interval. This variant contains feedback-decoding and no-response assumptions that need correction before use; see implementation notes.

### `ft_trialfun_rating`

Feedback-aligned misinformation parser. Filters events to relevant markers, searches for complete trial sequences, and handles additional response markers by selecting the last response before feedback in longer sequences. Counts buffer-overflow markers and appends that participant-level count to every accepted trial. The marker `S199` produces `NaN` reaction time, while its response category remains numerically encoded.

Optional `BlockEnd` and `TaskEnd` markers are recognized. Although the code calculates a possible endpoint at the next boundary, accepted trials currently end at **feedback plus `Add_time`**.

### `ft_trialfun_rating_itemnum`

Feedback-aligned variant that adds reconstructed block and within-block trial numbers. Counts **every stimulus onset before validating trial completeness**, so skipping an incomplete trial does not renumber subsequent onsets. Requires `BlockStart` and `subject_id` in addition to the shared rating configuration.

By default, raises an error unless each configured block has exactly 40 onsets. Set `Require40Onsets = false` to warn and continue instead. Optional fields include `NoResponse`, `BlockEnd`, `TaskEnd`, and `Debug`. Without `NoResponse`, the last configured response category is treated as no response. Behavioral item identifiers are attached by a separate downstream alignment script, not by this function.

### `ft_trialfun_rating_itemnum_fixed`

Alternative for recordings with missing block-start markers or incomplete onset counts. Infers block membership from event order and preceding block ends where possible, warns about nonstandard onset counts, and retains valid trial sequences. Accepts the same configuration as the item-number variant except `Require40Onsets`.

Its within-block number is a **raw EEG onset ordinal**, not a recovered behavioral trial number. A separate behavioral alignment step must resolve missing markers before attaching item identifiers. Neither item-number function performs that alignment itself.

### Rating output schema

| `trl` column | Meaning |
| --- | --- |
| 1–3 | Begin sample, end sample, feedback-aligned offset. |
| 4 | Condition: `100 × Stim_onset` list index. In the supplied setup: false-left, false-right, true-right, true-left. |
| 5 | Response: `100 × Response` list index, including a numeric no-response category when configured. |
| 6 | Feedback-list index. In the supplied setup: `1` false, `2` true. |
| 7 | Reaction time in seconds; `NaN` for recognized no-response markers. |
| 8 | Fixation-to-stimulus interval in seconds. |
| 9 | Basic rating parser: buffer-overflow count. Item-number variants: reconstructed block number. |
| 10 | Item-number variants only: within-block onset ordinal, with the interpretation described above. |
| 11 | Item-number variants only: buffer-overflow count. |

Extract and remove the overflow-count column before epoch creation when it should be retained as participant-level QC rather than trial metadata. Missing responses must be explicitly excluded when computing behavioral condition counts.

## Participant selection and file utilities

### `select_subject`

```matlab
Names = select_subject(raw_path, sel_mode);
```

Lists participant subfolders and opens a selection dialog. `sel_mode` is `'single'` or `'multiple'`. Returns a cell array of selected folder names, excluding `.` and `..`.

### `select_subject_multiple`

```matlab
Names = select_subject_multiple(raw_path, desiredIDs);
```

Selects participant folders programmatically using requested numeric IDs, string arrays, or cell arrays. Returns matching folder names in directory-list order and warns about missing IDs. The string-array branch currently contains a typo; see implementation notes.

### `filter_participants_by_trials`

```matlab
[idsEither, idsBoth, summary_table] = filter_participants_by_trials(T, threshold);
```

Uses `T.Subject_ID`, `T.Share_Fake`, and `T.Share_True` to identify participants meeting a trial threshold in at least one or both **sharing** conditions. Adds `Both_conditions_<threshold>`: `1` for both, `0` for one, and `NaN` for neither. Returns both ID lists and the annotated table. Calls `MI_00_Setup('experiment')` and **overwrites** `participants_filtered_by_trials.csv` in `Path.ERP`.

The uploaded file is named `filter_participants_by_trials_nuanced(1).m`; the declared function name is the one shown above.

### `trigger_label_BV`

```matlab
labels = trigger_label_BV([8 40 199]);
% {'S  8', 'S 40', 'S199'}
```

Converts numeric trigger codes into a row cell array of BrainVision stimulus labels, preserving the spacing used for single-, double-, and triple-digit codes.

### `scan_vhdr`

```matlab
Electrode = scan_vhdr(filename, Num_chans_per_set);
```

Reads electrode definitions from a BrainVision header organized as **two consecutive channel sets**. Returns a table containing electrode `Name`, `Set`, and within-set `Chan_num`. Skips exactly 22 header lines and subtracts the first-set size from second-set channel indices. This is a format-specific reader, not a general `.vhdr` parser.

## Statistical and time-frequency utilities

### `compute_CI`

```matlab
[meanCh, upperCI, lowerCI] = compute_CI(data, chan);
```

Computes the across-participant mean and pointwise 95% Student's t confidence intervals for one channel. Expects `data` arranged as **participants × channels × time** and a scalar channel index. Uses `SEM = SD / sqrt(n)` and `tinv(0.975, n-1)`. Requires at least two participants for meaningful intervals; missing values are not explicitly omitted. Intervals are pointwise, with no multiple-comparison correction.

### `check_cycles`

```matlab
check_cycles([4 8 12], 0.5);
```

Prints a diagnostic table of frequencies, time-window durations, cycle counts (`frequency × duration`), and whether those counts are integers. Accepts a scalar duration or one duration per frequency; errors on incompatible lengths. It prints results without returning a value and does not change analysis parameters. Integer-cycle checks use exact floating-point equality.

## Figure asset

`Multiplot.fig` is a saved MATLAB figure, **not a function or dependency of the supplied helpers**. Its stored figure title identifies a FieldTrip `ft_multiplotER` comparison of `grandaverage_no_share` and `grandaverage_share`. Keep it as an optional example output, preferably in the repository's figures folder.

## Dependencies and implementation notes

### Runtime dependencies

| Dependency | Used by |
| --- | --- |
| MATLAB desktop graphics | Selection dialogs and interactive QC tools. |
| EEGLAB and trimOutlier | Channel filtering, channel rejection, and amplitude-based trimming. |
| clean_rawdata plugin | `authomatic_detection_bad_channels`: `pop_clean_rawdata` in clean modes and `vis_artifacts` diagnostics. |
| FieldTrip | Event/header reading, custom trial definitions, and interactive artifact detection. |
| Statistics and Machine Learning Toolbox | `compute_CI` through `tinv`. |
| Project setup and electrode/layout files | Path-dependent participant exports and electrode-layout QC. |

Install external toolboxes separately and add the project functions folder to the MATLAB path. Retain existing author credits and license notices in source files adapted from external tools.

### Filename alignment

MATLAB primary function names should match their `.m` filenames. Remove upload-copy suffixes when placing these files in the repository:

| Uploaded filename | Repository filename matching its declaration |
| --- | --- |
| `compute_CI(1).m` | `compute_CI.m` |
| `filter_participants_by_trials_nuanced(1).m` | `filter_participants_by_trials.m` |
| `ft_trialfun_rating(6).m` | `ft_trialfun_rating.m` |
| `ft_trialfun_rating_itemnum(2).m` | `ft_trialfun_rating_itemnum.m` |
| `ft_trialfun_rating_itemnum_fixed(1).m` | `ft_trialfun_rating_itemnum_fixed.m` |
| `select_subject_multiple(1).m` | `select_subject_multiple.m` |

`pop_trimOutlier_mtc_time.m` declares `pop_trimOutlier_mtc`. Align the declaration with the existing filename and pipeline calls before use.

### Current code caveats

- **Participant ID conversion:** `select_subject_multiple` calls `ceelstr` in its string-array branch; this should be `cellstr`.
- **Stimulus-aligned misinformation parser:** `ft_trialfun_misinf_stim` looks up feedback against the response list instead of the feedback list. It also treats response-list index `3` as no response, which does not match the supplied seven-level rating setup.
- **Epoched trimOutlier branches:** the channel helper calls `trimOutlier_mtc`, which was not supplied. The time helper's epoched-data branch also references uninitialized variables. Use the documented continuous-data workflow until these branches are repaired.
- **GUI side effects:** the channel-selection callbacks use globals, and confirmation closes all figures. Avoid concurrent channel-selection sessions.

Descriptions reflect the supplied source files. Functions were inspected but not executed against EEG recordings or a MATLAB installation.
