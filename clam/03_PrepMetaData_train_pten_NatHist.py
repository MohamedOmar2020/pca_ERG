
import glob
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
# Read labels from Karen
metadata = pd.read_csv('/athena/marchionnilab/scratch/lab_data/Mohamed/pca_outcome/data/natHist_IHCdata2.csv')

metadata = metadata.loc[~metadata['PTEN_LOSS'].isin(['a', 'n'])]

metadata['label'] = metadata['PTEN_LOSS']


# rename
metadata['label'].replace('2', 'neg', inplace=True)
metadata['label'].replace(['0', '1'], 'pos', inplace=True)

metadata.dropna(subset = ['label'], inplace = True)
print(metadata['label'].value_counts())

## Extract the important clinical label: ERG
pten = pd.DataFrame({'label':metadata['label'], 'case_id':metadata['slide_id']})

#################################
## Get the IDs for the WSIs and patients
slide_dir = '/athena/marchionnilab/scratch/lab_data/Mohamed/pca_outcome/data/tiles_clam_2048_NatHist_lvl0/patches'
slides = listdir(slide_dir)

# make a dataframe: slide_id: slide ID! // case_id: patient ID
MetaData_clam = pd.DataFrame({'slide_id': slides})

MetaData_clam['case_id'] =  MetaData_clam['slide_id']

# Remove the .h5 extension from the slide_id
MetaData_clam['slide_id'] = MetaData_clam['slide_id'].str.replace('.h5','')
MetaData_clam['case_id'] = MetaData_clam['case_id'].str.replace('.h5','')


## Add labels
MetaData_clam = pd.merge(MetaData_clam, pten, left_on='case_id', right_on='case_id')
MetaData_clam = MetaData_clam.dropna()

# subset to the ones with feature extraction
#filt = listdir('/athena/marchionnilab/scratch/lab_data/Mohamed/pca_outcome/data/features_clam_256_NatHist/h5_files')
#filt = pd.DataFrame({'slide_id': filt})
#filt['slide_id'] = filt['slide_id'].str.replace('.h5','')

#MetaData_clam = MetaData_clam.loc[MetaData_clam['slide_id'].isin(filt['slide_id']),:]

# print the slides/patients
print(MetaData_clam['label'].value_counts())
print(MetaData_clam)


# Save to disk
MetaData_clam.to_csv('dataset_csv/pca_pten_NatHist.csv')




