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

python clam/create_patches_fp.py --source data/NatHistory --save_dir data/tiles_clam_512_NatHist_lvl0_new --patch_size 512 --step_size 512 --patch_level 0 --seg --patch --stitch --preset pca_NatHist.csv 


