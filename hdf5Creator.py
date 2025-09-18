import numpy as np
import h5py as h5
from os.path import join
from scipy.io import loadmat
from math import floor, nan

def calcInfoStructureVariableBinSizesNeuroMobLab(directory,listOfTrials,log,commonInfo,delay,emgBinTimeSize,emgBinNumber,subname):
    # Create HDF5 file
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
            print(f"{100 * i // nTrials:3d} | ", end="")
        d = np.load(join(directory,listOfTrials[i])) # load .mat file

        info[iiTrial]["subjectNumber"] = nan
        info[iiTrial]["subjectHeight"] = nan
        info[iiTrial]["subjectMass"] = nan
        info[iiTrial]["subjectAge"] = nan
        info[iiTrial]["subjectSex"] = 'U'
        
        info[iiTrial][perturbationMagnitudeVel] = log.velocity(i)
        info[iiTrial][perturbationMagnitudeAcc] = log.acceleration(i)
        info[iiTrial][perturbationDirection] = log.direction(i)
        info[iiTrial][perturbationOnset] = d['perturbationOnset'][0][0]

        #emg info
        emgNames = d["rawData"]["digital"]["emgBox1id"] + d["rawData"]["digital"]["emgBox2id"]
        emgNames = [name for name in emgNames if "-" in name]
        info[iiTrial]["emgNames"] = emgNames

        info[iiTrial]["emgBinValues"] = ""
        del emgData

        #find max values
        if emgBinValuesMax is None:
            emgBinValuesMax = info[iiTrial]['emgBinValues']
        else:
            emgBinValuesMax = np.maximum(emgBinValuesMax, info[iiTrial]['emgBinValues'])

        infoFields = list(info[iiTrial].keys())
        for field in infoFields:
            if field in commonInfo:
                info[iiTrial][field] = commonInfo[infoFields]

        iiTrial += 1

    emgBinValuesMax = np.max(emgBinValuesMax, axis=1, keepdims=True)
    del iiTrial
    print("done")
    return info
