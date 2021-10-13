

import os

slide_dir = "/athena/marchionnilab/scratch/lab_data/Mohamed/blca_dl/data/slides/"
for fileName in os.listdir(slide_dir):
    os.rename(slide_dir + fileName, slide_dir + "blca_" + fileName)

