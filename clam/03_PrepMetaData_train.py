
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

# Read labels from David
DavidLabels = pd.read_excel('data/annot.xlsx', header=None, engine='openpyxl')
DavidLabels.columns = ['slide', 'label']

DavidLabels['slide'] = "blca_" + DavidLabels['slide'].astype(str) 

print(DavidLabels['label'].value_counts())

## Extract the important clinical labels eg. Gleason grade
grade = pd.DataFrame({'label':DavidLabels['label'], 'slide_id':DavidLabels['slide']})

#################################
## Get the IDs for the WSIs and patients
slide_dir = '/athena/marchionnilab/scratch/lab_data/Mohamed/blca_dl/data/tiles_clam/patches'
slides = listdir(slide_dir)

# make a dataframe: slide_id: slide ID! // case_id: patient ID
MetaData_clam = pd.DataFrame({'slide_id': slides})
MetaData_clam['case_id'] = MetaData_clam['slide_id']
 
# Remove the .h5 extension from the slide_id
MetaData_clam['slide_id'] = MetaData_clam['slide_id'].str.replace('.h5','')
MetaData_clam['case_id'] = MetaData_clam['case_id'].str.replace('.h5','')

## Add labels
MetaData_clam = pd.merge(MetaData_clam, grade, left_on='slide_id', right_on='slide_id')

print(MetaData_clam)

# Save to disk

MetaData_clam.to_csv('dataset_csv/blca_HGUC_vs_normal.csv')
