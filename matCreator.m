% matCreator.m
% Build the demo gait dataset inside a MATLAB struct and save to .mat.

%% ---------- parameters & dummy data ----------
matname = "gait_demo.mat";
if exist(matname,"file"); delete(matname); end

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

%% ---------- assemble struct ----------
gaitData = struct();
gaitData.schema_version   = "0.1.0";
gaitData.created_by       = "Reece (Biomech demo)";
gaitData.coordinate_frame = "lab: +X fwd, +Y left, +Z up";

gaitData.subject = struct( ...
    "id","S001", ...
    "sex","F", ...
    "mass_kg",70.0, ...
    "height_m",1.70);

trial001 = struct();
trial001.sampling_hz = single(100.0);
trial001.treadmill   = false;
trial001.notes       = 'Synthetic demo data.';

trial001.time = struct( ...
    "values", single(t), ...
    "units","percent");

trial001.joint_angles = struct( ...
    "values", single(jointAngles), ...
    "units","deg", ...
    "plane","sagittal", ...
    "joint_names", jointNames);

trial001.grf = struct( ...
    "values", single(grf), ...
    "units","N", ...
    "axes","[Fx,Fy,Fz] in lab frame");

trial001.events = struct( ...
    "indices", events, ...
    "labels", ["heel_strike","toe_off","heel_strike_end","toe_off_end"]);

gaitData.trials = struct("trial001", trial001);

save(matname,"gaitData");

%% ---------- view contents ----------
disp("=== MATLAB struct contents ===");
disp(gaitData);

%% Recall Data
clearvars
matname = "gait_demo.mat";
loaded   = load(matname);
gaitData = loaded.gaitData;

trial = gaitData.trials.trial001;
A     = double(trial.joint_angles.values);              % [N x J]
names = trial.joint_angles.joint_names;
unit  = trial.joint_angles.units;

fprintf("Loaded %d samples, %d joints (%s)\n", size(A,1), size(A,2), unit);
disp("Joints: " + strjoin(cellstr(names),", "));

JointAngles = array2table(A, 'VariableNames', cellstr(names));
clear matname loaded A names unit;

%% Plot joint angles
t = linspace(0,100,height(JointAngles));
plot(t,table2array(JointAngles(:,1)));
hold on;
plot(t,table2array(JointAngles(:,2)));
plot(t,table2array(JointAngles(:,3)));
legend(cellstr(trial.joint_angles.joint_names),"Location","best");
xlabel("Gait cycle (%)");
ylabel("Angle (deg)");
title("Synthetic Sagittal Joint Angles");
grid on;
