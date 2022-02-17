#! /bin/bash -l
#SBATCH --partition=scu-cpu
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=25
#SBATCH --job-name=tilNatHist
#SBATCH --time=2-00:00:00
#SBATCH --mem=700G


source ~/.bashrc

conda activate /home/mao4005/.conda/envs/pathml
#python code/ImageProcessing.py

python3 karen/Tiling_Hamamatsu.py --df_path 'objs/karen/MetaData_tiling_NatHist.csv' --target_path 'data/tiles_karen_NatHist' --workers 24 --tissuepct_value 0.5  




