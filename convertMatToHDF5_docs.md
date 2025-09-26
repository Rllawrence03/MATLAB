# convertMatToHDF5.m Documentation

## Overview

`convertMatToHDF5.m` is a MATLAB function that converts MATLAB `.mat` files to HDF5 format. This utility enables cross-platform data sharing and provides better performance when working with large datasets. The function recursively handles complex MATLAB data structures including nested structures, cell arrays, numeric arrays, and strings.

## Function Signature

```matlab
convertMatToHDF5(matFilePath, hdf5FilePath)
```

## Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| `matFilePath` | `string` or `char` | Path to the input `.mat` file to be converted |
| `hdf5FilePath` | `string` or `char` | Path where the output `.h5` file will be saved |

## Features

### Supported Data Types
- **Numeric Arrays**: All MATLAB numeric types (double, single, int32, etc.)
- **Logical Arrays**: Converted to uint8 format for HDF5 compatibility
- **Character Arrays & Strings**: Both char and string data types
- **Structures**: Nested structures with hierarchical naming
- **Cell Arrays**: Multi-dimensional cell arrays with indexed naming
- **Mixed Data Types**: Automatically handles complex nested combinations

### Data Handling Features
- **NaN/Inf Handling**: Automatically replaces NaN and infinite values with sentinel values
  - `NaN` → `0`
  - `+Inf` → `999999` 
  - `-Inf` → `-999999`
- **Empty Array Handling**: Processes through empty arrays
- **File Overwriting**: Automatically overwrites existing HDF5 files
- **Error Recovery**: Continues processing even if individual data elements fail

## Usage Examples

### Basic Usage
```matlab
% Convert a simple .mat file
convertMatToHDF5('data.mat', 'data.h5');
```

### With Full Paths
```matlab
% Convert with absolute paths
inputFile = 'C:\Research\Data\experiment_results.mat';
outputFile = 'C:\Research\Data\experiment_results.h5';
convertMatToHDF5(inputFile, outputFile);
```

### Batch Processing Example
```matlab
% Convert multiple files
matFiles = dir('*.mat');
for i = 1:length(matFiles)
    matPath = matFiles(i).name;
    [~, name, ~] = fileparts(matPath);
    hdf5Path = [name '.h5'];
    convertMatToHDF5(matPath, hdf5Path);
    fprintf('Converted: %s -> %s\n', matPath, hdf5Path);
end
```

## HDF5 Naming Convention

The function uses a systematic naming convention to preserve MATLAB data structure hierarchy:

### Structure Fields
- Simple structures: `/originalName__fieldName`
- Structure arrays: `/originalName__1__fieldName` (indexed)

### Cell Arrays
- Cell elements: `/originalName__cell_1_2` (row_col indexing)

### Example Structure Mapping
```matlab
% Original MATLAB structure:
data.experiment.trial1.results = [1, 2, 3];
data.experiment.trial1.notes = 'successful';
data.samples{1,1} = 'sample_A';
data.samples{1,2} = 'sample_B';

% Becomes HDF5 paths:
/experiment__trial1__results
/experiment__trial1__notes  
/samples__cell_1_1
/samples__cell_1_2
```

## HDF5 Directory Structure and Substructure Creation

### How HDF5 Groups Are Created

Unlike traditional file systems, HDF5 files use a hierarchical structure with **groups** (similar to directories) and **datasets** (similar to files). The `convertMatToHDF5` function creates this hierarchy automatically based on your MATLAB data structure.

#### Flat Structure Approach
This function uses a **flat naming convention** rather than creating nested HDF5 groups. This design choice has several advantages:
- **Simplicity**: Easier to navigate and debug
- **Compatibility**: Works with all HDF5 readers across platforms
- **Performance**: Faster access times for deeply nested structures
- **Reliability**: Avoids potential group creation conflicts

### Directory Structure Creation Process

#### 1. Root Level Processing
```matlab
% All top-level variables become root datasets
data.variable1 = 123;        % → /variable1
data.variable2 = 'hello';    % → /variable2
```

#### 2. Nested Structure Flattening
```matlab
% Deep nesting gets flattened with delimiter
data.level1.level2.level3.value = 42;
% Becomes: /level1__level2__level3__value
```

#### 3. Structure Array Handling
```matlab
% Structure arrays include index in path
participants(1).name = 'Alice';
participants(2).name = 'Bob';
participants(1).age = 25;
participants(2).age = 30;

% Becomes:
% /participants__1__name
% /participants__2__name  
% /participants__1__age
% /participants__2__age
```

#### 4. Cell Array Directory Mapping
```matlab
% Cell arrays use row-column indexing
results{1,1} = [1, 2, 3];
results{1,2} = 'success';
results{2,1} = [4, 5, 6];
results{2,2} = 'failed';

% Becomes:
% /results__cell_1_1
% /results__cell_1_2
% /results__cell_2_1
% /results__cell_2_2
```

### Complex Nested Example

```matlab
% Complex MATLAB structure:
study.participants(1).demographics.age = 25;
study.participants(1).demographics.gender = 'F';
study.participants(1).trials{1} = struct('rt', 450, 'correct', true);
study.participants(1).trials{2} = struct('rt', 380, 'correct', false);
study.participants(2).demographics.age = 30;
study.participants(2).demographics.gender = 'M';

% Results in HDF5 paths:
/participants__1__demographics__age
/participants__1__demographics__gender
/participants__1__trials__cell_1_1__rt
/participants__1__trials__cell_1_1__correct
/participants__1__trials__cell_2_1__rt
/participants__1__trials__cell_2_1__correct
/participants__2__demographics__age
/participants__2__demographics__gender
```

### Directory Navigation in Different Platforms

#### MATLAB
```matlab
% List all datasets in HDF5 file
info = h5info('study.h5');
for i = 1:length(info.Datasets)
    fprintf('Dataset: %s\n', info.Datasets(i).Name);
end

% Read specific nested data
age_p1 = h5read('study.h5', '/participants__1__demographics__age');
rt_trial1 = h5read('study.h5', '/participants__1__trials__cell_1_1__rt');
```

#### Python (h5py)
```python
import h5py

# Navigate the flattened structure
with h5py.File('study.h5', 'r') as f:
    # List all datasets
    print("Available datasets:")
    for key in f.keys():
        print(f"  /{key}")
    
    # Access nested data
    age_p1 = f['participants__1__demographics__age'][()]
    rt_trial1 = f['participants__1__trials__cell_1_1__rt'][()]
    
    # Filter datasets by pattern
    participant1_data = {k: v[()] for k, v in f.items() 
                        if k.startswith('participants__1__')}
```

#### R (rhdf5)
```r
library(rhdf5)

# List structure
h5ls("study.h5")

# Read nested data
age_p1 <- h5read("study.h5", "participants__1__demographics__age")
rt_trial1 <- h5read("study.h5", "participants__1__trials__cell_1_1__rt")

# Read multiple related datasets
participant1_names <- h5ls("study.h5")$name[
  grepl("^participants__1__", h5ls("study.h5")$name)
]
```

### Reconstructing Original Structure

If you need to reconstruct the original MATLAB structure from the flattened HDF5, you can parse the dataset names:

```matlab
function data = reconstructStructure(hdf5FilePath)
    info = h5info(hdf5FilePath);
    data = struct();
    
    for i = 1:length(info.Datasets)
        path = info.Datasets(i).Name;
        value = h5read(hdf5FilePath, ['/' path]);
        
        % Parse the flattened path
        parts = strsplit(path, '__');
        
        % Reconstruct nested assignment
        eval_str = 'data';
        for j = 1:length(parts)
            if contains(parts{j}, 'cell_')
                % Handle cell array indexing
                indices = regexp(parts{j}, 'cell_(\d+)_(\d+)', 'tokens');
                row = str2double(indices{1}{1});
                col = str2double(indices{1}{2});
                eval_str = sprintf('%s{%d,%d}', eval_str, row, col);
            elseif ~isnan(str2double(parts{j}))
                % Handle structure array indexing
                eval_str = sprintf('%s(%s)', eval_str, parts{j});
            else
                % Handle field names
                eval_str = sprintf('%s.%s', eval_str, parts{j});
            end
        end
        
        % Assign value
        eval(sprintf('%s = value;', eval_str));
    end
end
```

### Best Practices for Structure Organization

1. **Consistent Naming**: Use consistent field names to make flattened paths predictable
2. **Avoid Deep Nesting**: While supported, excessive nesting creates very long dataset names
3. **Logical Grouping**: Structure your MATLAB data logically as the flattening preserves relationships
4. **Index Documentation**: Document what structure array indices represent
5. **Cell Array Organization**: Keep cell arrays organized with consistent data types when possible

## Requirements

### MATLAB Toolboxes
- No additional toolboxes required (uses built-in HDF5 functions)

### MATLAB Version
- MATLAB R2011a or later (when HDF5 support was introduced)
- Tested on MATLAB R2019b and later

### System Requirements
- Sufficient disk space for output file (typically similar to input file size)
- Write permissions to output directory

## Error Handling

### Input Validation
```matlab
if ~exist(matFilePath, 'file')
    error('MAT file does not exist: %s', matFilePath);
end
```

### Degradation
- Individual data elements that fail to convert are skipped
- Function continues processing remaining data
- Uses try-catch blocks to prevent complete failure

## Performance Considerations

### Memory Usage
- Loads entire `.mat` file into memory
- Consider available RAM for large files (>1GB)

### Processing Time
- Linear scaling with data complexity
- Nested structures require more processing time
- Cell arrays with many elements increase conversion time

### File Size
- HDF5 files are typically similar size to original `.mat` files
- May be slightly larger due to metadata overhead
- Compression not currently implemented

## Limitations

1. **Memory Constraints**: Limited by available system memory for large files
2. **Function Handles**: Cannot convert MATLAB function handles
3. **Custom Classes**: Custom MATLAB classes are converted using `mat2str()`
4. **Compression**: No built-in compression (can be added as enhancement)
5. **Metadata**: Original MATLAB metadata is not preserved

## Troubleshooting

### Common Issues

#### "MAT file does not exist"
```matlab
% Check file path
if exist('myfile.mat', 'file')
    disp('File exists');
else
    disp('Check file path and extension');
end
```

#### Permission Denied
```matlab
% Check write permissions
[status, message] = fileattrib('output_directory');
if ~status || ~message.UserWrite
    disp('No write permission to output directory');
end
```

#### Memory Issues
```matlab
% Check available memory
[~, memstats] = memory;
available_GB = memstats.MemAvailableAllArrays / 1024^3;
fprintf('Available memory: %.2f GB\n', available_GB);
```

## Reading HDF5 Files

### In MATLAB
```matlab
% Read HDF5 data back into MATLAB
info = h5info('data.h5');
data = h5read('data.h5', '/dataset_name');
```

### In Python
```python
import h5py
import numpy as np

# Read HDF5 file in Python
with h5py.File('data.h5', 'r') as f:
    dataset = f['dataset_name'][:]
```

### In R
```r
# Read HDF5 file in R
library(rhdf5)
data <- h5read("data.h5", "dataset_name")
```

## Version History

- **v1.0**: Initial implementation with basic data type support
- **Current**: Enhanced error handling and data type coverage

## See Also

- MATLAB `h5create()` - Create HDF5 datasets
- MATLAB `h5write()` - Write data to HDF5 files  
- MATLAB `h5read()` - Read HDF5 data
- MATLAB `load()` - Load .mat files

## License
This function is part of the AcademicUtils repository under MIT License.