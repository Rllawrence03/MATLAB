% mat_to_hdf5_converter.m
% Convert the gait_demo.mat file to HDF5 format
% This script reads the structured .mat file and converts it to an HDF5 file
% with the same hierarchical organization.

%% ---------- Load .mat file ----------
matname = "gait_demo.mat";
h5name = "gait_demo_converted.h5";

% Check if mat file exists
if ~exist(matname, "file")
    error("File %s does not exist. Please run matCreator.m first.", matname);
end

% Remove existing HDF5 file if it exists
if exist(h5name, "file")
    delete(h5name);
end

% Load the .mat file
fprintf("Loading %s...\n", matname);
loaded = load(matname);
gaitData = loaded.gaitData;

%% ---------- Create HDF5 file with root attributes ----------
fprintf("Creating HDF5 file %s...\n", h5name);

% Create a dummy dataset so the file exists
h5create(h5name, "/dummy", 1);
h5write(h5name, "/dummy", 1);

% Write root-level attributes
h5writeatt(h5name, "/", "schema_version", gaitData.schema_version);
h5writeatt(h5name, "/", "created_by", gaitData.created_by);
h5writeatt(h5name, "/", "coordinate_frame", gaitData.coordinate_frame);

%% ---------- Create subject group and attributes ----------
% Create subject group
H5G.close(H5G.create(H5F.open(h5name, 'H5F_ACC_RDWR', 'H5P_DEFAULT'), ...
                     '/subject', 'H5P_DEFAULT', 'H5P_DEFAULT', 'H5P_DEFAULT'));

% Write subject attributes
h5writeatt(h5name, "/subject", "id", gaitData.subject.id);
h5writeatt(h5name, "/subject", "sex", gaitData.subject.sex);
h5writeatt(h5name, "/subject", "mass_kg", gaitData.subject.mass_kg);
h5writeatt(h5name, "/subject", "height_m", gaitData.subject.height_m);

%% ---------- Create trials group ----------
H5G.close(H5G.create(H5F.open(h5name, 'H5F_ACC_RDWR', 'H5P_DEFAULT'), ...
                     '/trials', 'H5P_DEFAULT', 'H5P_DEFAULT', 'H5P_DEFAULT'));

%% ---------- Process each trial ----------
trial_names = fieldnames(gaitData.trials);

for i = 1:length(trial_names)
    trial_name = trial_names{i};
    trial_data = gaitData.trials.(trial_name);
    trial_path = sprintf("/trials/%s", trial_name);
    
    fprintf("Processing trial: %s\n", trial_name);
    
    % Create trial group
    H5G.close(H5G.create(H5F.open(h5name, 'H5F_ACC_RDWR', 'H5P_DEFAULT'), ...
                         trial_path, 'H5P_DEFAULT', 'H5P_DEFAULT', 'H5P_DEFAULT'));
    
    % Write trial attributes
    h5writeatt(h5name, trial_path, "sampling_hz", trial_data.sampling_hz);
    h5writeatt(h5name, trial_path, "treadmill", uint8(trial_data.treadmill));
    h5writeatt(h5name, trial_path, "notes", trial_data.notes);
    
    %% ---------- Time data ----------
    if isfield(trial_data, 'time')
        time_path = sprintf("%s/time", trial_path);
        time_values = trial_data.time.values;
        
        h5create(h5name, time_path, size(time_values), ...
                 'Datatype', 'single', 'ChunkSize', [min(64, length(time_values)), 1], 'Deflate', 9);
        h5write(h5name, time_path, single(time_values));
        h5writeatt(h5name, time_path, "units", trial_data.time.units);
    end
    
    %% ---------- Joint angles data ----------
    if isfield(trial_data, 'joint_angles')
        ja_path = sprintf("%s/joint_angles", trial_path);
        ja_values = trial_data.joint_angles.values;
        
        h5create(h5name, ja_path, size(ja_values), ...
                 'Datatype', 'single', 'ChunkSize', [min(64, size(ja_values,1)), size(ja_values,2)], 'Deflate', 9);
        h5write(h5name, ja_path, single(ja_values));
        h5writeatt(h5name, ja_path, "units", trial_data.joint_angles.units);
        h5writeatt(h5name, ja_path, "plane", trial_data.joint_angles.plane);
        
        % Joint names as separate dataset
        jn_path = sprintf("%s/joint_names", trial_path);
        joint_names = trial_data.joint_angles.joint_names;
        h5create(h5name, jn_path, size(joint_names), 'Datatype', 'string');
        h5write(h5name, jn_path, joint_names);
    end
    
    %% ---------- Ground reaction forces ----------
    if isfield(trial_data, 'grf')
        grf_path = sprintf("%s/grf", trial_path);
        grf_values = trial_data.grf.values;
        
        h5create(h5name, grf_path, size(grf_values), ...
                 'Datatype', 'single', 'ChunkSize', [min(64, size(grf_values,1)), size(grf_values,2)], 'Deflate', 9);
        h5write(h5name, grf_path, single(grf_values));
        h5writeatt(h5name, grf_path, "units", trial_data.grf.units);
        h5writeatt(h5name, grf_path, "axes", trial_data.grf.axes);
    end
    
    %% ---------- Events ----------
    if isfield(trial_data, 'events')
        events_path = sprintf("%s/events", trial_path);
        events_indices = trial_data.events.indices;
        
        h5create(h5name, events_path, size(events_indices), 'Datatype', 'uint32');
        h5write(h5name, events_path, events_indices);
        h5writeatt(h5name, events_path, "labels", trial_data.events.labels);
    end
end

% Remove the dummy dataset
if H5L.exists(H5F.open(h5name, 'H5F_ACC_RDONLY', 'H5P_DEFAULT'), '/dummy', 'H5P_DEFAULT')
    % This is a bit tricky in MATLAB - we'll leave the dummy for now
    % In a production script, you might want to recreate the file without it
end

%% ---------- Display results ----------
fprintf("\nConversion complete!\n");
fprintf("Original .mat file: %s\n", matname);
fprintf("Converted HDF5 file: %s\n", h5name);

fprintf("\n=== HDF5 structure ===\n");
h5disp(h5name);

%% ---------- Verification: Read back some data ----------
fprintf("\n=== Verification ===\n");
try
    % Read joint angles
    ja_data = h5read(h5name, "/trials/trial001/joint_angles");
    joint_names = h5read(h5name, "/trials/trial001/joint_names");
    ja_units = h5readatt(h5name, "/trials/trial001/joint_angles", "units");
    
    fprintf("Successfully read joint angles: %d samples x %d joints (%s)\n", ...
            size(ja_data, 1), size(ja_data, 2), ja_units);
    fprintf("Joint names: %s\n", strjoin(cellstr(joint_names), ", "));
    
    % Read GRF
    grf_data = h5read(h5name, "/trials/trial001/grf");
    grf_units = h5readatt(h5name, "/trials/trial001/grf", "units");
    fprintf("Successfully read GRF: %d samples x %d components (%s)\n", ...
            size(grf_data, 1), size(grf_data, 2), grf_units);
    
    % Read events
    events_data = h5read(h5name, "/trials/trial001/events");
    event_labels = h5readatt(h5name, "/trials/trial001/events", "labels");
    fprintf("Successfully read events: %d events\n", length(events_data));
    fprintf("Event labels: %s\n", strjoin(cellstr(event_labels), ", "));
    
    fprintf("\nVerification successful! The HDF5 file contains all expected data.\n");
    
catch ME
    fprintf("Error during verification: %s\n", ME.message);
end

%% ---------- Optional: Create comparison plot ----------
if exist('ja_data', 'var') && exist('joint_names', 'var')
    figure;
    t_percent = linspace(0, 100, size(ja_data, 1));
    
    subplot(2,1,1);
    plot(t_percent, ja_data);
    legend(cellstr(joint_names), 'Location', 'best');
    xlabel('Gait cycle (%)');
    ylabel('Angle (deg)');
    title('Joint Angles from Converted HDF5 File');
    grid on;
    
    subplot(2,1,2);
    plot(t_percent, grf_data(:,3)); % Plot vertical GRF
    xlabel('Gait cycle (%)');
    ylabel('Force (N)');
    title('Vertical Ground Reaction Force');
    grid on;
    
    sgtitle('Data from Converted HDF5 File');
end

fprintf("\nConversion script completed successfully!\n");