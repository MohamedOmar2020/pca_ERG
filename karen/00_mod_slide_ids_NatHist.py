
import os

slide_dir_NatHist = "/athena/marchionnilab/scratch/lab_data/Mohamed/pca_outcome/data/NatHistory/"
for fileName in os.listdir(slide_dir_NatHist):
    os.rename(slide_dir_NatHist + fileName, slide_dir_NatHist + "pca_" + fileName)
