#! /bin/bash -l
#SBATCH --partition=scu-gpu
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=30
#SBATCH --job-name=featExtNatHist
#SBATCH --time=2-00:00:00
#SBATCH --mem=350G
#SBATCH --gres=gpu:2

source ~/.bashrc

conda activate /home/mao4005/.conda/envs/clam

CUDA_VISIBLE_DEVICES=0,1 python clam/extract_features_fp.py --data_h5_dir data/tiles_clam_512_NatHist --data_slide_dir data/NatHistory --csv_path data/tiles_clam_512_NatHist/process_list_autogen_featExt.csv --feat_dir data/features_clam_512_NatHist_patchSize1 --batch_size 512 --slide_ext .ndpi --target_patch_size 1

