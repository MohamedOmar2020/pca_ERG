#! /bin/bash -l
#SBATCH --partition=scu-cpu
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=25
#SBATCH --job-name=tilNatHist
#SBATCH --time=24:00:00
#SBATCH --mem=200G
##SBATCH --gres=gpu:2

source ~/.bashrc

conda activate /home/mao4005/.conda/envs/clam
#python code/ImageProcessing.py

python clam/create_patches_fp.py --source data/NatHistory --save_dir data/tiles_clam_256_NatHist --patch_size 256 --seg --patch --stitch --preset pca_NatHist.csv 


