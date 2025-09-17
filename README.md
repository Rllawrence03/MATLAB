# Gait Data Demo

This repository contains MATLAB scripts that build a small, fully synthetic gait cycle dataset and show how to store it in both HDF5 and MAT formats. Each script regenerates its demo file from scratch, annotates the data with metadata, and plots the resulting joint angle trajectories so you can validate the workflow end to end.

## Repository contents
- `hdf5_testing.m`: Creates `gait_demo.h5`, writes a hierarchical layout with attributes, reloads the data, and plots the three sagittal joint angles.
- `matCreator.m`: Builds the same dataset as a nested MATLAB struct and saves it to `gait_demo.mat`, then performs a round-trip load and visualization.
- `gait_demo.h5` and `gait_demo.mat`: Example outputs; delete and regenerate them by running the scripts.
- `hdf5Creator.py`: Placeholder for a future Python port (currently empty).

## Requirements
- MATLAB R2020b or newer for `h5create`, string arrays, and table utilities.
- Optional: an HDF5 viewer such as HDFView if you prefer a GUI inspection.

## Getting started
1. Launch MATLAB and set the working folder to this repository.
2. Run `hdf5_testing`. The script will:
   - Rebuild `gait_demo.h5` with compressed datasets and descriptive attributes.
   - Display the file layout via `h5disp`.
   - Reload the joint angles into a table and show a quick plot for visual verification.
3. Run `matCreator` to generate the equivalent MATLAB struct in `gait_demo.mat` and repeat the same round-trip load and plot.

Both scripts can be re-run at any time; they delete the previous demo file before writing a fresh copy.

## Data layout cheat sheet
### HDF5 hierarchy
| Path | Type | Notes |
| --- | --- | --- |
| `/` | group | Attributes: `schema_version`, `created_by`, `coordinate_frame`. |
| `/subject` | group | Subject metadata attributes (`id`, `sex`, `mass_kg`, `height_m`). |
| `/trials/trial001` | group | Trial-level attributes (`sampling_hz`, `treadmill`, `notes`). |
| `/trials/trial001/time` | dataset (single) | Percent gait cycle vector. Units stored in attribute `units`. |
| `/trials/trial001/joint_angles` | dataset (single) | `N x 3` matrix of hip, knee, ankle sagittal angles. Attributes: `units`, `plane`. |
| `/trials/trial001/joint_names` | dataset (string) | Variable-length strings naming the joint columns. |
| `/trials/trial001/grf` | dataset (single) | Ground reaction forces `[Fx, Fy, Fz]` with `units` and `axes` attributes. |
| `/trials/trial001/events` | dataset (uint32) | Indices into the time vector; labels stored in attribute `labels`. |

### MATLAB struct (`gait_demo.mat`)
Top-level fields mirror the HDF5 attributes and groups. Notable fields:
- `schema_version`, `created_by`, `coordinate_frame`: Global metadata strings.
- `subject`: Struct with `id`, `sex`, `mass_kg`, `height_m`.
- `trials.trial001`: Nested struct containing `sampling_hz`, `treadmill`, `notes`, `time`, `joint_angles`, `grf`, and `events`. Measurement sub-structs wrap `values`, metadata strings, and labels.

## Customizing the demo
- Replace the synthetic sine-wave definitions in either script to experiment with different signals or sampling rates.
- Extend the HDF5 layout with additional groups (e.g. motion-capture markers or EMG) to mock up richer datasets.
- Port the MATLAB logic into `hdf5Creator.py` if you want a Python/Numpy implementation; the placeholder file is ready for that work.

## License
No explicit license is provided. Feel free to adapt the scripts for internal experimentation, and add a license file if you plan to distribute the dataset.
