# MATLAB .mat to HDF5 Conversion Scripts

This repository contains scripts to convert MATLAB `.mat` files to HDF5 format, preserving the hierarchical structure and data organization.

## Available Scripts

### 1. MATLAB Conversion Script
**File: `mat_to_hdf5_converter.m`**

A comprehensive MATLAB script that loads a `.mat` file and converts it to HDF5 format with proper hierarchical organization, compression, and chunking.

#### Features:
- Preserves original data structure and hierarchy
- Includes compression (deflate level 9) for efficient storage
- Proper chunking for optimal read/write performance
- Full metadata preservation (units, labels, attributes)
- Built-in verification and visualization
- Handles multiple trials (extensible)

#### Usage:
```matlab
% Run in MATLAB
mat_to_hdf5_converter
```

#### Requirements:
- MATLAB with HDF5 support
- Existing `gait_demo.mat` file (created by `matCreator.m`)

### 2. Python Conversion Scripts
**Files: `mat_to_hdf5_converter.py` and `simple_mat_to_hdf5_converter.py`**

Two Python approaches for converting `.mat` files to HDF5:

#### Advanced Python Converter (`mat_to_hdf5_converter.py`)
- Attempts to parse original MATLAB structures
- More complex string handling for MATLAB objects
- May have issues with MATLAB string format compatibility

#### Simple Python Converter (`simple_mat_to_hdf5_converter.py`) ⭐ **Recommended**
- Reconstructs data structure manually
- Better compatibility across Python/scipy versions
- Clean, readable HDF5 output
- Includes visualization capabilities

#### Usage:
```bash
# Simple converter (recommended)
python simple_mat_to_hdf5_converter.py

# Advanced converter
python mat_to_hdf5_converter.py
```

#### Requirements:
- Python 3.6+
- Required packages: `numpy`, `h5py`, `scipy`, `matplotlib` (optional, for plots)

#### Installation:
```bash
pip install numpy h5py scipy matplotlib
```

## File Structure

The conversion creates HDF5 files with the following hierarchical structure:

```
/ (root)
├── @schema_version: "0.1.0"
├── @created_by: "Converter info"
├── @coordinate_frame: "lab: +X fwd, +Y left, +Z up"
├── subject/
│   ├── @id: "S001"
│   ├── @sex: "F"
│   ├── @mass_kg: 70.0
│   └── @height_m: 1.70
└── trials/
    └── trial001/
        ├── @sampling_hz: 100.0
        ├── @treadmill: false
        ├── @notes: "Trial description"
        ├── time (dataset: 201×1, float32)
        │   └── @units: "percent"
        ├── joint_angles (dataset: 201×3, float32)
        │   ├── @units: "deg"
        │   └── @plane: "sagittal"
        ├── joint_names (dataset: 3×1, string)
        ├── grf (dataset: 201×3, float32)
        │   ├── @units: "N"
        │   └── @axes: "[Fx,Fy,Fz] in lab frame"
        └── events (dataset: 4×1, uint32)
            └── @labels: ["heel_strike", "toe_off", ...]
```

## Data Description

The example dataset contains synthetic gait analysis data:

- **Time**: Gait cycle from 0-100%
- **Joint Angles**: Hip, knee, ankle flexion angles (degrees)
- **Ground Reaction Forces**: 3D force components (Newtons)
- **Events**: Gait events with timing indices

## Output Files

| Script | Output File | Description |
|--------|-------------|-------------|
| MATLAB converter | `gait_demo_converted.h5` | Full-featured HDF5 with compression |
| Python advanced | `gait_demo_converted.h5` | May have string encoding issues |
| Python simple | `gait_demo_simple.h5` | Clean, reliable output |

## Verification

All scripts include built-in verification that:
1. Reads back the converted data
2. Displays file structure
3. Validates data integrity
4. Creates visualization plots (when possible)

## Performance Features

### MATLAB Version
- **Compression**: Deflate level 9 for optimal file size
- **Chunking**: 64-sample chunks for efficient I/O
- **Data Types**: Optimized (single precision for arrays, appropriate types for metadata)

### Python Versions
- **Compression**: Gzip compression for reduced file size
- **Chunking**: Automatic chunking for large datasets
- **Memory Efficient**: Streaming conversion for large files

## Troubleshooting

### Common Issues

1. **MATLAB String Issues**: The MATLAB converter handles native MATLAB strings properly
2. **Python String Encoding**: The simple Python converter avoids scipy's MATLAB string parsing issues
3. **File Permissions**: Ensure write permissions in the output directory
4. **Memory Usage**: For large files, the Python converters use chunked reading/writing

### Error Messages

- `File does not exist`: Run `matCreator.m` first to create the source `.mat` file
- `Permission denied`: Check file permissions and close any open files
- `Import errors`: Install required Python packages

## Extending the Scripts

### Adding New Data Types
1. Modify the data extraction section
2. Add appropriate HDF5 dataset creation
3. Update verification section

### Multiple Trials
The scripts are designed to handle multiple trials. Modify the trial processing loop to iterate through additional trial data.

### Custom Metadata
Add custom attributes at any level:
```python
# Python
dataset.attrs['custom_attribute'] = 'custom_value'
```
```matlab
% MATLAB
h5writeatt(filename, "/path/to/dataset", "custom_attribute", "custom_value");
```

## Related Files

- `matCreator.m`: Creates the source `.mat` file with synthetic data
- `hdf5_testing.m`: Example of creating HDF5 files directly in MATLAB
- `gait_demo.mat`: Source MATLAB data file
- `gait_demo.h5`: HDF5 version created by `hdf5_testing.m`

## License

These scripts are provided as examples for educational and research purposes.

## Author

Conversion scripts created for biomechanics data analysis workflow.