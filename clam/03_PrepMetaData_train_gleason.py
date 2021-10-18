
import re
import numpy as np
import pandas as pd
from pathlib import Path
from os import listdir,path,getcwd,walk
import glob
from itertools import chain
import torchvision.models
from sklearn.model_selection import train_test_split

######################################################
######################################################
## Metadata for CLAM training

# Read clinical data
clinicalData = pd.read_csv('data/tcga_clinical_data.csv')
clinicalData['Gleason'] = clinicalData['gleason_score']

## Categorize Gleason score into low and high
for i in clinicalData.index:
    if clinicalData.loc[i, 'Gleason'] >= 8:
        clinicalData.loc[i, 'Gleason_HighLow'] = 'high'
    else:
        clinicalData.loc[i, 'Gleason_HighLow'] = 'low'

clinicalData['Gleason_HighLow'].value_counts()

## Extract the important clinical labels eg. Gleason grade
Gleason = pd.DataFrame({'Gleason':clinicalData['Gleason_HighLow'], 'case_id':clinicalData['id']})

Gleason['case_id'] = Gleason['case_id'].str.replace('.', '-')

#################################
## Get the IDs for the WSIs and patients
slide_dir = '/athena/marchionnilab/scratch/lab_data/Mohamed/pca_outcome/data/tiles_clam_256/patches'
slides = listdir(slide_dir)

# make a dataframe: slide_id: slide ID! // case_id: patient ID
MetaData_clam = pd.DataFrame({'slide_id': slides})
MetaData_clam['case_id'] =  [i.replace(i, '-'.join(i.split("-")[0:3])) for i in MetaData_clam['slide_id']]

print(len(MetaData_clam['case_id']))

# Remove the .h5 extension from the slide_id
MetaData_clam['slide_id'] = MetaData_clam['slide_id'].str.replace('.h5','')

## Add labels
MetaData_clam = pd.merge(MetaData_clam, Gleason, left_on='case_id', right_on='case_id')

print(MetaData_clam.shape)
print(MetaData_clam['Gleason'].value_counts())
# Save to disk

MetaData_clam.to_csv('dataset_csv/pca_gleason.csv')

