#!/usr/bin/env python3
"""
mat_to_hdf5_converter.py
Convert the gait_demo.mat file to HDF5 format using Python

This script reads the structured .mat file and converts it to an HDF5 file
with the same hierarchical organization.
"""

import numpy as np
import h5py
from scipy.io import loadmat
import os
import sys

def convert_mat_to_hdf5(mat_filename="gait_demo.mat", h5_filename="gait_demo_converted.h5"):
    """
    Convert a MATLAB .mat file to HDF5 format.
    
    Parameters:
    -----------
    mat_filename : str
        Path to the input .mat file
    h5_filename : str
        Path to the output HDF5 file
    """
    
    # Check if mat file exists
    if not os.path.exists(mat_filename):
        raise FileNotFoundError(f"File {mat_filename} does not exist. Please run matCreator.m first.")
    
    # Remove existing HDF5 file if it exists
    if os.path.exists(h5_filename):
        os.remove(h5_filename)
        print(f"Removed existing {h5_filename}")
    
    print(f"Loading {mat_filename}...")
    
    # Load the .mat file with proper MATLAB string handling
    def extract_string(obj):
        """Extract string from MATLAB string object."""
        if hasattr(obj, 'item'):
            return str(obj.item())
        elif isinstance(obj, np.ndarray):
            if obj.dtype.kind == 'U' or obj.dtype.kind == 'S':
                return str(obj.item())
            elif obj.size == 1:
                return str(obj.item())
        return str(obj)
    
    mat_data = loadmat(mat_filename, struct_as_record=False, squeeze_me=True)
    gait_data = mat_data['gaitData']
    
    print(f"Creating HDF5 file {h5_filename}...")
    
    # Create HDF5 file
    with h5py.File(h5_filename, 'w') as h5f:
        
        # Write root-level attributes
        h5f.attrs['schema_version'] = extract_string(gait_data.schema_version)
        h5f.attrs['created_by'] = extract_string(gait_data.created_by)
        h5f.attrs['coordinate_frame'] = extract_string(gait_data.coordinate_frame)
        
        # Create subject group
        subject_grp = h5f.create_group('subject')
        subject_grp.attrs['id'] = extract_string(gait_data.subject.id)
        subject_grp.attrs['sex'] = extract_string(gait_data.subject.sex)
        subject_grp.attrs['mass_kg'] = float(gait_data.subject.mass_kg)
        subject_grp.attrs['height_m'] = float(gait_data.subject.height_m)
        
        # Create trials group
        trials_grp = h5f.create_group('trials')
        
        # Process trial001 (can be extended for multiple trials)
        trial_data = gait_data.trials.trial001
        trial_grp = trials_grp.create_group('trial001')
        
        print("Processing trial: trial001")
        
        # Write trial attributes
        trial_grp.attrs['sampling_hz'] = float(trial_data.sampling_hz)
        trial_grp.attrs['treadmill'] = bool(trial_data.treadmill)
        trial_grp.attrs['notes'] = extract_string(trial_data.notes)
        
        # Time data
        if hasattr(trial_data, 'time'):
            time_values = np.array(trial_data.time.values, dtype=np.float32)
            time_dset = trial_grp.create_dataset('time', 
                                                data=time_values,
                                                dtype=np.float32,
                                                chunks=True,
                                                compression='gzip',
                                                compression_opts=9)
            time_dset.attrs['units'] = extract_string(trial_data.time.units)
        
        # Joint angles data
        if hasattr(trial_data, 'joint_angles'):
            ja_values = np.array(trial_data.joint_angles.values, dtype=np.float32)
            ja_dset = trial_grp.create_dataset('joint_angles',
                                              data=ja_values,
                                              dtype=np.float32,
                                              chunks=True,
                                              compression='gzip',
                                              compression_opts=9)
            ja_dset.attrs['units'] = extract_string(trial_data.joint_angles.units)
            ja_dset.attrs['plane'] = extract_string(trial_data.joint_angles.plane)
            
            # Joint names as separate dataset
            joint_names = [extract_string(name) for name in trial_data.joint_angles.joint_names]
            jn_dset = trial_grp.create_dataset('joint_names',
                                              data=joint_names,
                                              dtype=h5py.string_dtype(encoding='utf-8'))
        
        # Ground reaction forces
        if hasattr(trial_data, 'grf'):
            grf_values = np.array(trial_data.grf.values, dtype=np.float32)
            grf_dset = trial_grp.create_dataset('grf',
                                               data=grf_values,
                                               dtype=np.float32,
                                               chunks=True,
                                               compression='gzip',
                                               compression_opts=9)
            grf_dset.attrs['units'] = extract_string(trial_data.grf.units)
            grf_dset.attrs['axes'] = extract_string(trial_data.grf.axes)
        
        # Events
        if hasattr(trial_data, 'events'):
            events_indices = np.array(trial_data.events.indices, dtype=np.uint32)
            events_dset = trial_grp.create_dataset('events',
                                                  data=events_indices,
                                                  dtype=np.uint32)
            event_labels = [extract_string(label) for label in trial_data.events.labels]
            events_dset.attrs['labels'] = event_labels
    
    print(f"\nConversion complete!")
    print(f"Original .mat file: {mat_filename}")
    print(f"Converted HDF5 file: {h5_filename}")
    
    return h5_filename

def display_hdf5_structure(filename):
    """Display the structure of an HDF5 file."""
    print(f"\n=== HDF5 structure of {filename} ===")
    
    def print_structure(name, obj):
        indent = "  " * name.count('/')
        if isinstance(obj, h5py.Group):
            print(f"{indent}{name}/ (Group)")
            # Print attributes
            for attr_name, attr_value in obj.attrs.items():
                print(f"{indent}  @{attr_name}: {attr_value}")
        else:  # Dataset
            print(f"{indent}{name} (Dataset: {obj.shape}, {obj.dtype})")
            # Print attributes
            for attr_name, attr_value in obj.attrs.items():
                print(f"{indent}  @{attr_name}: {attr_value}")
    
    with h5py.File(filename, 'r') as h5f:
        # Print root attributes
        print("/ (Root)")
        for attr_name, attr_value in h5f.attrs.items():
            print(f"  @{attr_name}: {attr_value}")
        
        # Print structure
        h5f.visititems(print_structure)

def verify_conversion(h5_filename):
    """Verify the converted HDF5 file by reading back some data."""
    print(f"\n=== Verification of {h5_filename} ===")
    
    try:
        with h5py.File(h5_filename, 'r') as h5f:
            # Read joint angles
            ja_data = h5f['/trials/trial001/joint_angles'][:]
            joint_names_raw = h5f['/trials/trial001/joint_names'][:]
            # Handle string decoding properly
            if isinstance(joint_names_raw[0], bytes):
                joint_names = [name.decode('utf-8') for name in joint_names_raw]
            else:
                joint_names = [str(name) for name in joint_names_raw]
            ja_units = h5f['/trials/trial001/joint_angles'].attrs['units']
            
            print(f"Successfully read joint angles: {ja_data.shape[0]} samples x {ja_data.shape[1]} joints ({ja_units})")
            print(f"Joint names: {', '.join(joint_names)}")
            
            # Read GRF
            grf_data = h5f['/trials/trial001/grf'][:]
            grf_units = h5f['/trials/trial001/grf'].attrs['units']
            print(f"Successfully read GRF: {grf_data.shape[0]} samples x {grf_data.shape[1]} components ({grf_units})")
            
            # Read events
            events_data = h5f['/trials/trial001/events'][:]
            event_labels = [label.decode() if isinstance(label, bytes) else label 
                           for label in h5f['/trials/trial001/events'].attrs['labels']]
            print(f"Successfully read events: {len(events_data)} events")
            print(f"Event labels: {', '.join(event_labels)}")
            
            print("\nVerification successful! The HDF5 file contains all expected data.")
            
            return ja_data, joint_names, grf_data
            
    except Exception as e:
        print(f"Error during verification: {e}")
        return None, None, None

def plot_data(ja_data, joint_names, grf_data):
    """Create a comparison plot of the converted data."""
    try:
        import matplotlib.pyplot as plt
        
        t_percent = np.linspace(0, 100, ja_data.shape[0])
        
        fig, (ax1, ax2) = plt.subplots(2, 1, figsize=(10, 8))
        
        # Plot joint angles
        for i, name in enumerate(joint_names):
            ax1.plot(t_percent, ja_data[:, i], label=name)
        ax1.set_xlabel('Gait cycle (%)')
        ax1.set_ylabel('Angle (deg)')
        ax1.set_title('Joint Angles from Converted HDF5 File')
        ax1.legend()
        ax1.grid(True)
        
        # Plot vertical GRF
        ax2.plot(t_percent, grf_data[:, 2])  # Vertical component
        ax2.set_xlabel('Gait cycle (%)')
        ax2.set_ylabel('Force (N)')
        ax2.set_title('Vertical Ground Reaction Force')
        ax2.grid(True)
        
        plt.tight_layout()
        plt.suptitle('Data from Converted HDF5 File', y=0.98)
        plt.show()
        
        print("Plot created successfully!")
        
    except ImportError:
        print("Matplotlib not available. Skipping plot generation.")
    except Exception as e:
        print(f"Error creating plot: {e}")

def main():
    """Main function to run the conversion."""
    mat_filename = "gait_demo.mat"
    h5_filename = "gait_demo_converted.h5"
    
    try:
        # Convert the file
        converted_file = convert_mat_to_hdf5(mat_filename, h5_filename)
        
        # Display structure
        display_hdf5_structure(converted_file)
        
        # Verify conversion
        ja_data, joint_names, grf_data = verify_conversion(converted_file)
        
        # Create plot if data was successfully read
        if ja_data is not None:
            plot_data(ja_data, joint_names, grf_data)
        
        print("\nConversion script completed successfully!")
        
    except Exception as e:
        print(f"Error: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()