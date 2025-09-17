# Gait Demo Dataset

This repository contains  scripts that synthesize a toy lower-limb gait dataset and save it as both `.mat` and `.h5` files. The project is mainly a sandbox to compare MATLAB struct storage with an HDF5 layout that is friendlier for cross-language access.

## Repository Contents
- `hdf5_testing.m` - builds `gait_demo.h5`, adds attributes and datasets, then reloads and plots the joint angles.
- `matCreator.m` - mirrors the same data model using MATLAB structs and writes `gait_demo.mat`.
- `gait_demo.h5` - latest HDF5 artifact (overwritten each time the script runs).
- `gait_demo.mat` - latest MATLAB struct save.
- `hdf5Creator.py` - placeholder for a Python implementation of the HDF5 writer.

## Notes
- Synthetic joint angles approximate a sagittal gait cycle; adjust `J` or the dummy curves as needed.
- If you extend the dataset, mirror the updates in both scripts to keep `.mat` and `.h5` outputs aligned.
