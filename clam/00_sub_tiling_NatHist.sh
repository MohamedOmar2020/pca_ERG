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

# Here: tiling on level 0 (40x) with a tile_size of 2048 * 2048 pixels. The plan is to do feature extraction with custom_downsample 4 (10x) which will make the tile_size 512*512 pixels.  
python clam/create_patches_fp.py --source data/NatHistory --save_dir data/tiles_clam_1024_NatHist_lvl0 --patch_size 1024 --step_size 1024 --patch_level 0 --seg --patch --stitch --preset pca_NatHist.csv 


