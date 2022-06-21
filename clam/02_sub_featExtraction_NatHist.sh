#! /bin/bash -l
#SBATCH --partition=scu-gpu
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=20
#SBATCH --job-name=featExtNatHist
#SBATCH --time=2-00:00:00
#SBATCH --mem=350G
#SBATCH --gres=gpu:2

source ~/.bashrc

conda activate /home/mao4005/.conda/envs/clam

# For the nat history cohort: 'openslide.level[0].downsample': '1' and 'openslide.level[1].downsample': '2'. 
# feature extraction with custom_downsample 2 means that feature extraction will be performed on level 1 (20x). 
# feature extraction with custom_downsample 4 means that feature extraction will be performed on level 3 (10x) 

# tiles from the nat history cohort were extracted from level 0 (40x) and have a size of 2048*2048 pixels. Here we do the feature extraction with custom downsample of 4 so the training will be done on patches of 512*512 pixels extracted from 10x magnification

CUDA_VISIBLE_DEVICES=0,1 python clam/extract_features_fp.py --data_h5_dir data/tiles_clam_2048_NatHist_lvl0 --data_slide_dir data/NatHistory --csv_path data/tiles_clam_2048_NatHist_lvl0/process_list_autogen_featExt.csv --feat_dir data/features_clam_NatHist_size512_mag10x --batch_size 512 --slide_ext .ndpi --custom_downsample 4

