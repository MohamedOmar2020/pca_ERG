import re
import numpy as np
import pandas as pd
from pathlib import Path
from os import listdir,path,getcwd,walk
import glob
from itertools import chain

import torchvision.models
from sklearn.model_selection import train_test_split

#e####################################################
## Metadata for training

# Read the TCGA metadata
clinical = pd.read_csv('data/tcga_meta_data_all.csv')

clinical['label'] = clinical['ETV1status']
clinical['label'].value_counts()

## str to int
# rename
clinical['label'].replace('ETV1 NEGATIVE', '0', inplace=True)
clinical['label'].replace('ETV1 POSITIVE', '1', inplace=True)

clinical.dropna(subset = ['label'], inplace = True)

clinical['label'] = clinical['label'].astype(int)

## Extract the important clinical labels eg. Gleason grade
ETV1 = pd.DataFrame({'label':clinical['label'], 'PatientID':clinical['patient_id']})


# replace the '.' with '-'
ETV1['PatientID'] =  [i.replace('.', '-') for i in ETV1['PatientID']]

################################################
## Get the paths for the tiled WSIs
tile_dir = r'/athena/marchionnilab/scratch/lab_data/Mohamed/pca_outcome/data/tiles_karen/10x/'
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

#print(MetaData_training['PatientID'])

MetaData_training = pd.merge(MetaData_training, ETV1, left_on = 'PatientID', right_on='PatientID')

#print(MetaData_training['label'].value_counts())

# Train-validation-test
y = MetaData_training['label']
Train, test = train_test_split(MetaData_training, train_size = 0.75, test_size=0.25, random_state=42, stratify=y)
y2 = test['label']
validation, test = train_test_split(test, test_size=0.50, random_state=42, stratify=y2)
Train['Train_Test'] = 'Train'
validation['Train_Test'] = 'Validation'
test['Train_Test'] = 'Test'
all = [Train, validation, test]
MetaData_training = pd.concat(all)
print(MetaData_training['Train_Test'].value_counts())
print(pd.crosstab(MetaData_training['Train_Test'], MetaData_training['label']))

# Save to disk
MetaData_training.to_csv('objs/karen/MetaData_training_ETV1_10x.csv')

