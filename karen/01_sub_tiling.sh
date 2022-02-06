#! /bin/bash -l
#SBATCH --partition=scu-gpu
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=25
#SBATCH --job-name=tiling
#SBATCH --time=2-00:00:00
#SBATCH --mem=350G


source ~/.bashrc

conda activate /home/mao4005/.conda/envs/pathml
#python code/ImageProcessing.py

python3 karen/Tiling.py --df_path 'objs/karen/MetaData_tiling.csv' --target_path 'data/tiles_karen' --workers 24 --tissuepct_value 0.5  




