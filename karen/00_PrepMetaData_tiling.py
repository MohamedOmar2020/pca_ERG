import re
import numpy as np
import pandas as pd
from pathlib import Path
from os import listdir,path,getcwd,walk
import glob
from itertools import chain

import torchvision.models
from sklearn.model_selection import train_test_split

################################################
## Metadata for tiling
slidedir = r'data/TCGA/prad'
slides = listdir(slidedir)

paths = glob.glob(path.join(slidedir, "*svs"))

MetaData = pd.DataFrame({'SVS_Path': paths}, slides)
MetaData['PatientID'] = MetaData.index


# Add the patient ID
MetaData['PatientID'] =  [i.replace(i, '-'.join(i.split("-")[0:3])) for i in MetaData['slides']]
MetaData.index = np.linspace(0, MetaData.shape[0]-1, num= MetaData.shape[0]).astype('int')

print(MetaData.shape)
# Save
MetaData.to_csv('objs/karen/MetaData_tiling.csv')


