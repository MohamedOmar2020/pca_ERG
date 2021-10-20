
import re
import numpy as np
import pandas as pd
from pathlib import Path
from os import listdir,path,getcwd,walk
import glob
from itertools import chain
from sklearn.model_selection import train_test_split

## Metadata for training

# Read original csv file
orig = pd.read_csv('data/tiles_clam_500/process_list_autogen.csv')


# Remove the .svs extension
orig['slide_id'] = orig['slide_id'].str.replace('.svs','')
orig['slide_id'] = orig['slide_id'].astype(str)
print(orig['slide_id'])
print(orig['slide_id'].dtype)

# Save to disk
orig.to_csv('data/tiles_clam_500/process_list_autogen_featExt.csv')






