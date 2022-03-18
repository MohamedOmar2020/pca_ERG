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
## Metadata for training

# Read the natural history cohort metadata
metadata = pd.read_csv('/athena/marchionnilab/scratch/lab_data/Mohamed/pca_outcome/data/NatHistPheno.csv')

metadata['label'] = metadata['PTEN_LOSS']
metadata['label'].value_counts()

# rename
metadata['label'].replace('PTEN_NEGATIVE', '0', inplace=True)
metadata['label'].replace('PTEN_POSITIVE', '1', inplace=True)

metadata.dropna(subset = ['label'], inplace = True)

metadata['label'] = metadata['label'].astype(int)


## Extract the important clinical labels eg. Gleason grade
pten = pd.DataFrame({'label':metadata['label'], 'PatientID':metadata['slide_id']})

print(pten['PatientID'])

################################################
## Get the paths for the tiled WSIs
tile_dir = r'/athena/marchionnilab/scratch/lab_data/Mohamed/pca_outcome/data/tiles_karen_NatHist/5x/'
tiles = listdir(tile_dir)

# path for each slide folder
paths = []
for i in range(len(tiles)):
    paths.append((path.join(tile_dir, tiles[i])))

# make a dataframe
MetaData_training = pd.DataFrame({'Path': paths}, tiles)
MetaData_training['PatientID'] = MetaData_training.index
MetaData_training['PatientID'] =  [i.replace(i, '-'.join(i.split("-")[0:3])) for i in MetaData_training['PatientID']]
MetaData_training.index = np.linspace(0, MetaData_training.shape[0]-1, num= MetaData_training.shape[0]).astype('int')

MetaData_training = pd.merge(MetaData_training, pten, left_on = 'PatientID', right_on='PatientID')

# Train-validation-test
#y = MetaData_training['label']
#Train, test = train_test_split(MetaData_training, train_size = 0.75, test_size=0.25, random_state=42, stratify=y)
#y2 = test['label']
#validation, test = train_test_split(test, test_size=0.50, random_state=42, stratify=y2)
MetaData_training['Train_Test'] = 'Test'



print(MetaData_training['Train_Test'].value_counts())
print(pd.crosstab(MetaData_training['Train_Test'], MetaData_training['label']))
print(MetaData_training.shape)

# Save to disk
MetaData_training.to_csv('objs/karen/MetaData_training_pten_NatHist_5x_test.csv')

