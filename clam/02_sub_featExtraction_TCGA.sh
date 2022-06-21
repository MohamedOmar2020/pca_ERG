#! /bin/bash -l
#SBATCH --partition=scu-gpu
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=20
#SBATCH --job-name=featExtTCGA
#SBATCH --time=2-00:00:00
#SBATCH --mem=350G
#SBATCH --gres=gpu:2

source ~/.bashrc

conda activate /home/mao4005/.conda/envs/clam

# For the tcga, the dowsample factors are: 1, 4, 16, 64 and the corresponding magnifications are: 40x, 10x, 2.5x, 0.625x. 
# Here we do the feature extraction using tiles of size (2048*2048 pixels) from level 0 (40x) but we do downsample of factor 4 so now the training will be performed on tiles of size 512*512 pixels from 10x magnification.
 
CUDA_VISIBLE_DEVICES=0,1 python clam/extract_features_fp.py --data_h5_dir data/tiles_clam_2048_TCGA_lvl0 --data_slide_dir data/TCGA_FFPE --csv_path data/tiles_clam_2048_TCGA_lvl0/process_list_autogen_featExt.csv --feat_dir data/features_clam_TCGA_size512_mag10x --batch_size 512 --slide_ext .svs --custom_downsample 4

