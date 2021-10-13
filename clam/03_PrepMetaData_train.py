
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

# Read labels from Karen
KarenLabels = pd.read_csv('data/TCGA_Risk_Prediction_tspada.csv')
KarenLabels['Gleason'] = KarenLabels['Gleason.pattern.primary'] + KarenLabels['Gleason.pattern.secondary']

## Categorize Gleason score into low and high
for i in KarenLabels.index:
    if KarenLabels.loc[i, 'Gleason'] >= 8:
        KarenLabels.loc[i, 'Gleason_HighLow'] = 'high'
    else:
        KarenLabels.loc[i, 'Gleason_HighLow'] = 'low'

Gleason = pd.DataFrame({'Gleason':KarenLabels['Gleason_HighLow'], 'case_id':KarenLabels['Patient.ID']})


#################################
## Get the IDs for the WSIs and patients
slide_dir = '/athena/marchionnilab/scratch/lab_data/Mohamed/pca_outcome/data/tiles_clam/patches'
slides = listdir(slide_dir)

# make a dataframe: slide_id: slide ID! // case_id: patient ID
MetaData_clam = pd.DataFrame({'slide_id': slides})
MetaData_clam['case_id'] =  [i.replace(i, '-'.join(i.split("-")[0:3])) for i in MetaData_clam['slide_id']]

# Remove the .h5 extension from the slide_id
MetaData_clam['slide_id'] = MetaData_clam['slide_id'].str.replace('.h5','')

## Add labels
MetaData_clam = pd.merge(MetaData_clam, Gleason, left_on='case_id', right_on='case_id')

print(MetaData_clam)

# Save to disk

MetaData_clam.to_csv('dataset_csv/pca_gleason.csv')
