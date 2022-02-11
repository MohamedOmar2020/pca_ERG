#! /bin/bash -l
#SBATCH --partition=panda
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=30
#SBATCH --job-name=tiling
#SBATCH --time=2-00:00:00
#SBATCH --mem=128G


source ~/.bashrc

conda activate /home/sor4002/anaconda3/envs/sophievm
#python code/ImageProcessing.py

python3 karen/Tiling.py --df_path 'objs/karen/MetaData_tiling.csv' --target_path 'data/tiles_karen' --workers 30 --tissuepct_value 0.5  




