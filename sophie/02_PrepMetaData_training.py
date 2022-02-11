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

# Read labels from David
DavidLabels = pd.read_excel('data/annot.xlsx', header=None)
DavidLabels.columns = ['slide', 'label']

## str to int
for i in DavidLabels.index:
    if DavidLabels.loc[i, 'label'] == 'HGUC':
        DavidLabels.loc[i, 'label'] = 1
    else:
        DavidLabels.loc[i, 'label'] = 0

DavidLabels['label'] = DavidLabels['label'].astype(int)
DavidLabels['label'].value_counts()

## Get the paths for the tiled WSIs
tile_dir = r'/athena/marchionnilab/scratch/lab_data/Mohamed/blca_dl/data/tiles/2_5x/'
tiles = listdir(tile_dir)

# path for each slide folder
paths = []
for i in range(len(tiles)):
    paths.append((path.join(tile_dir, tiles[i])))

# make a dataframe
MetaData_training = pd.DataFrame({'Path': paths}, tiles)
#MetaData_training['Path'] = MetaData_training['Path'].astype('category')
MetaData_training['PatientID'] = MetaData_training.index
MetaData_training.index = np.linspace(0, MetaData_training.shape[0]-1, num= MetaData_training.shape[0]).astype('int')
MetaData_training['PatientID'] .replace('.svs', '', regex=True, inplace=True)
DavidLabels['slide'] = DavidLabels['slide'].astype(str)

MetaData_training = pd.merge(MetaData_training, DavidLabels, left_on='PatientID', right_on='slide')

del MetaData_training['slide']

# Train-validation-test
y = MetaData_training['label']
Train, test = train_test_split(MetaData_training, test_size=0.25, random_state=42, stratify=y)
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
MetaData_training.to_csv('objs/MetaData_training.csv')

