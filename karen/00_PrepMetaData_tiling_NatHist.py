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
slidedir = r'data/NatHistory'
slides = listdir(slidedir)

paths = glob.glob(path.join(slidedir, "*ndpi"))

MetaData = pd.DataFrame({'SVS_Path': paths}, slides)
MetaData['slides'] = MetaData.index


# Add the patient ID
MetaData['PatientID'] =  MetaData['slides']
MetaData['PatientID'] = MetaData['PatientID'].str.replace('.ndpi', '')  

# Add the index
MetaData.index = np.linspace(0, MetaData.shape[0]-1, num= MetaData.shape[0]).astype('int')

print(MetaData)

# Save
MetaData.to_csv('objs/karen/MetaData_tiling_NatHist.csv')


