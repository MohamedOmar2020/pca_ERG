
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
metadata = pd.read_csv('/athena/marchionnilab/scratch/lab_data/Mohamed/pca_outcome/data/tcga_meta_data_all.csv')

metadata['label'] = metadata['PTENstatus']
metadata['label'].value_counts()

# rename
metadata['label'].replace('PTEN POSITIVE', 'pos', inplace=True)
metadata['label'].replace('PTEN NEGATIVE', 'neg', inplace=True)

#metadata.dropna(subset = ['label'], inplace = True)
#metadata = metadata[metadata.label != 'n']

## Extract the important clinical label: ERG
pten = pd.DataFrame({'label':metadata['label'], 'case_id':metadata['patient_id']})

# replace the '.' with '-'
pten['case_id'] =  [i.replace('.', '-') for i in pten['case_id']]

#################################
## Get the IDs for the WSIs and patients
slide_dir = '/athena/marchionnilab/scratch/lab_data/Mohamed/pca_outcome/data/tiles_clam_2048_TCGA_lvl0/patches'
slides = listdir(slide_dir)

# make a dataframe: slide_id: slide ID! // case_id: patient ID
MetaData_clam = pd.DataFrame({'slide_id': slides})

MetaData_clam['case_id'] =  [i.replace(i, '-'.join(i.split("-")[0:3])) for i in MetaData_clam['slide_id']]

print(MetaData_clam['case_id'].value_counts())
print(MetaData_clam['slide_id'].value_counts())

# Remove the .h5 extension from the slide_id
MetaData_clam['slide_id'] = MetaData_clam['slide_id'].str.replace('.h5','')
#MetaData_clam['case_id'] = MetaData_clam['case_id'].str.replace('.h5','')


## Add labels
MetaData_clam = pd.merge(MetaData_clam, pten, left_on='case_id', right_on='case_id')
MetaData_clam = MetaData_clam.dropna()

# subset to the ones with feature extraction
#filt = listdir('/athena/marchionnilab/scratch/lab_data/Mohamed/pca_outcome/data/features_clam_256_NatHist/h5_files')
#filt = pd.DataFrame({'slide_id': filt})
#filt['slide_id'] = filt['slide_id'].str.replace('.h5','')

#MetaData_clam = MetaData_clam.loc[MetaData_clam['slide_id'].isin(filt['slide_id']),:]

MetaData_clam = MetaData_clam.drop_duplicates()
# print the slides/patients
print(MetaData_clam['label'].value_counts())
print(MetaData_clam['case_id'].value_counts())
print(MetaData_clam['slide_id'].value_counts())
print(MetaData_clam.shape)



# Save to disk
MetaData_clam.to_csv('dataset_csv/pca_pten_TCGA.csv')




