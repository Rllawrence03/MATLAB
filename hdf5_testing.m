% The purpose of this file is to try creating and hdf5 file and see its
% viability for datasets

%% ---------- parameters & dummy data ----------
fname = "gait_demo.h5";
if exist(fname,"file"); delete(fname); end

N = 201;                % samples over one gait cycle (0..100%)
J = 3;                  % hip, knee, ankle (sagittal)
t = linspace(0,100,N)'; % percent gait cycle

% simple synthetic sagittal angles (deg)
hip   = 30 - 10*cos(2*pi*t/100);
knee  = 60*max(0,sin(2*pi*t/100)).^1.5;
ankle = 10*sin(2*pi*t/100) - 5;

jointAngles = [hip, knee, ankle];    % [N x J]
jointNames  = ["hip_flexion","knee_flexion","ankle_dorsiflexion"];

% synthetic vertical GRF with double-peaked stance (N)
BW = 700;  % body weight in newtons
grfV = BW*(0.05 + 0.95*(sin(pi*t/100)).^2);   % toy curve
grf   = [zeros(N,1), zeros(N,1), grfV];       % [Fx,Fy,Fz]

% fake events: foot-strike at 0% and 62%, toe-off at ~62% and 100%
events = uint32([1, round(0.62*N), round(0.62*N), N]); % indices

%% ---------- create groups ----------
h5create(fname,"/dummy",1);           % tiny placeholder so file exists
h5write(fname,"/dummy",1);
fileattrib = struct("schema_version","0.1.0", ...
                    "created_by","Reece (Biomech demo)", ...
                    "coordinate_frame","lab: +X fwd, +Y left, +Z up");
h5writeatt(fname,"/","schema_version",fileattrib.schema_version);
h5writeatt(fname,"/","created_by",fileattrib.created_by);
h5writeatt(fname,"/","coordinate_frame",fileattrib.coordinate_frame);

% subject group (no datasets yet; just attrs)
H5G.close(H5G.create(H5F.open(fname,'H5F_ACC_RDWR','H5P_DEFAULT'), ...
                     '/subject','H5P_DEFAULT','H5P_DEFAULT','H5P_DEFAULT'));
h5writeatt(fname,"/subject","id","S001");
h5writeatt(fname,"/subject","sex","F");
h5writeatt(fname,"/subject","mass_kg",70.0);
h5writeatt(fname,"/subject","height_m",1.70);

% trials group
H5G.close(H5G.create(H5F.open(fname,'H5F_ACC_RDWR','H5P_DEFAULT'), ...
                     '/trials','H5P_DEFAULT','H5P_DEFAULT','H5P_DEFAULT'));

% trial001
H5G.close(H5G.create(H5F.open(fname,'H5F_ACC_RDWR','H5P_DEFAULT'), ...
                     '/trials/trial001','H5P_DEFAULT','H5P_DEFAULT','H5P_DEFAULT'));
h5writeatt(fname,"/trials/trial001","sampling_hz",100.0);
h5writeatt(fname,"/trials/trial001","treadmill",uint8(0));  % 0=false, 1=true
h5writeatt(fname,"/trials/trial001","notes",'Synthetic demo data.'); % use char

%% ---------- datasets (with compression & chunking) ----------
% time
h5create(fname,"/trials/trial001/time", size(t), ...
         'Datatype','single','ChunkSize',[64,1],'Deflate',9);
h5write(fname,"/trials/trial001/time", single(t));
h5writeatt(fname,"/trials/trial001/time","units","percent");

% joint angles
h5create(fname,"/trials/trial001/joint_angles", size(jointAngles), ...
         'Datatype','single','ChunkSize',[64, J],'Deflate',9);
h5write(fname,"/trials/trial001/joint_angles", single(jointAngles));
h5writeatt(fname,"/trials/trial001/joint_angles","units","deg");
h5writeatt(fname,"/trials/trial001/joint_angles","plane","sagittal");

% joint names (store as variable-length strings)
h5create(fname,"/trials/trial001/joint_names", size(jointNames), 'Datatype','string');
h5write(fname,"/trials/trial001/joint_names", jointNames);

% ground reaction forces
h5create(fname,"/trials/trial001/grf", size(grf), ...
         'Datatype','single','ChunkSize',[64, 3],'Deflate',9);
h5write(fname,"/trials/trial001/grf", single(grf));
h5writeatt(fname,"/trials/trial001/grf","units","N");
h5writeatt(fname,"/trials/trial001/grf","axes","[Fx,Fy,Fz] in lab frame");

% events (indices into time vector)
h5create(fname,"/trials/trial001/events", size(events), 'Datatype','uint32');
h5write(fname,"/trials/trial001/events", events);
h5writeatt(fname,"/trials/trial001/events","labels", ...
    ["heel_strike","toe_off","heel_strike_end","toe_off_end"]);

%% ---------- view contents ----------
disp("=== HDF5 structure ===");
h5disp(fname);

%% Recall Data
clearvars
fname = "gait_demo.h5";
A = h5read(fname,"/trials/trial001/joint_angles");  % [N x J]
names = h5read(fname,"/trials/trial001/joint_names");
unit  = h5readatt(fname,"/trials/trial001/joint_angles","units");
fprintf("Loaded %d samples, %d joints (%s)\n", size(A,1), size(A,2), unit);
disp("Joints: " + strjoin(cellstr(names),", "));
JointAngles = array2table(A, 'VariableNames',names);
clearvars fname names A;

%% 
t = linspace(0,100,numel(JointAngles(:,1)));
plot(t,table2array(JointAngles(:,1)))
hold on;
plot(t,table2array(JointAngles(:,2)))
plot(t,table2array(JointAngles(:,3)))