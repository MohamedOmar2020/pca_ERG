
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

# Read the TCGA metadata
metadata = pd.read_csv('data/tcga_meta_data_all.csv')

metadata['pten_status'] = metadata['PTENstatusCNV']
metadata['pten_status'].value_counts()

# rename
metadata['pten_status'].replace('PTEN POSITIVE', 'pos', inplace=True)
metadata['pten_status'].replace('PTEN NEGATIVE', 'neg', inplace=True)


## Extract the important clinical labels eg. Gleason grade
pten = pd.DataFrame({'pten_status':metadata['pten_status'], 'case_id':metadata['patient_id']})

# replace the '.' with '-'
pten['case_id'] =  [i.replace('.', '-') for i in pten['case_id']]

#################################
## Get the IDs for the WSIs and patients
slide_dir = '/athena/marchionnilab/scratch/lab_data/Mohamed/pca_outcome/data/tiles_clam2/patches'
slides = listdir(slide_dir)

# make a dataframe: slide_id: slide ID! // case_id: patient ID
MetaData_clam = pd.DataFrame({'slide_id': slides})
MetaData_clam['case_id'] =  [i.replace(i, '-'.join(i.split("-")[0:3])) for i in MetaData_clam['slide_id']]

# Remove the .h5 extension from the slide_id
MetaData_clam['slide_id'] = MetaData_clam['slide_id'].str.replace('.h5','')

## Add labels
MetaData_clam = pd.merge(MetaData_clam, pten, left_on='case_id', right_on='case_id')

# print the slides/patients
print(pd.crosstab(MetaData_clam['case_id'], MetaData_clam['slide_id']))

# Save to disk
MetaData_clam.to_csv('dataset_csv/pca_pten.csv')
