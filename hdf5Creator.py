import numpy as np
import h5py as h5
from os.path import join
from scipy.io import loadmat
from math import floor

#%% Create HDF5 file
info = h5.File("info.hdf5","w")

# from matlab code
# function info = calcInfoStructureVariableBinSizesNeuroMobLab(directory,listOfTrials, log,commonInfo,delay,emgBinTimeSize,emgBinNumber,subname)

# Create groups
trialName = info.create_group("trialName")
trialNumber = info.create_group("trialNumber")
subjectName = info.create_group("subjectName")
subjectHeight = info.create_group("subjectHeight")
subjectMass = info.create_group("subjectMass")
subjectAge = info.create_group("subjectAge")
subjectSex = info.create_group("subjectSex")
subjectLegLength = info.create_group("subjectLegLength")                        #Blank
subjectHipWidth = info.create_group("subjectHipWidth")                          #Blank
subjectStanceWidth = info.create_group("subjectStanceWidth")                    #Blank
perturbationMagnitudePos = info.create_group("perturbationMagnitudePos")        #Blank
perturbationMagnitudeVel = info.create_group("perturbationMagnitudeVel")        
perturbationMagnitudeAcc = info.create_group("perturbationMagnitudeAcc")        
perturbationDirection = info.create_group("perturbationDirection")
perturbationOnset = info.create_group("perturbationOnset")
perturbationTrace = info.create_group("perturbationTrace")                      #Blank
emgNames = info.create_group("emgNames")
emgOnsets = info.create_group("emgOnsets")                                      #Blank
emgBinNames = info.create_group("emgBinNames")
emgBinValues = info.create_group("emgBinValues")
emgBinValuesMax = info.create_group("emgBinValuesMax")
comTrace = info.create_group("comTrace")                                        #Blank

fields = [
    "subjectLegLength",
    "subjectHipWidth",
    "subjectStanceWidth",
    "perturbationMagnitudePos",
    "perturbationMagnitudeVel",
    "perturbationMagnitudeAcc",
    "perturbationTrace",
    "emgOnsets",
    "comTrace",
]

for name in fields:
    info.create_dataset(name, shape=(0,), maxshape=(None,), dtype=np.float64)

string_dtype = h5.special_dtype(vlen=str)
for name in ["trialName", "subjectName", "emgNames", "emgBinNames"]:
    info.create_dataset(name, shape=(0,), maxshape=(None,), dtype=string_dtype)

#%% Add data
iiTrial = 1 # index of good trials
nTrials = len(listOfTrials)
for i in range(nTrials):
    if i % floor(nTrials/10) == 0:
        print(f"Processing trial {i} of {nTrials}")
    d = np.load(join(directory,listOfTrials[i])) # load .mat file
    
    
    # create NaN for metadata fields that are blank
    info(iiTrial)
