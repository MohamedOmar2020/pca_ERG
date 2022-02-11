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

# Read the TCGA metadata
metadata = pd.read_table('data/ClinicalData.tsv')

metadata['label'] = metadata['Biochemical Recurrence Indicator']
metadata['label'].value_counts()

# rename
metadata['label'].replace('NO', '0', inplace=True)
metadata['label'].replace('YES', '1', inplace=True)

metadata.dropna(subset = ['label'], inplace = True)

metadata['label'] = metadata['label'].astype(int)

## Extract the important clinical labels eg. Gleason grade
BCR = pd.DataFrame({'label':metadata['label'], 'PatientID':metadata['Patient ID']})

# replace the '.' with '-'
#ER'PatientID'] =  [i.replace('.', '-') for i in ERG['PatientID']]

print(BCR.shape)
################################################
## Get the paths for the tiled WSIs
tile_dir = r'/athena/marchionnilab/scratch/lab_data/Mohamed/pca_outcome/data/tiles_karen/20x/'
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

MetaData_training = pd.merge(MetaData_training, BCR, left_on = 'PatientID', right_on='PatientID')

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
print(MetaData_training.shape)

# Save to disk
MetaData_training.to_csv('objs/karen/MetaData_training_BCR_20x.csv')

