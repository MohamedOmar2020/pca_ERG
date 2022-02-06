#! /bin/bash -l
#SBATCH --partition=scu-cpu
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=15
#SBATCH --job-name=tiling_pca
#SBATCH --time=24:00:00
#SBATCH --mem=64G
##SBATCH --gres=gpu:2

source ~/.bashrc

conda activate /home/mao4005/.conda/envs/clam
#python code/ImageProcessing.py

python clam/create_patches_fp.py --source data/TCGA/prad --save_dir data/tiles_clam_128 --patch_size 128 --seg --patch --stitch --preset pca.csv 


