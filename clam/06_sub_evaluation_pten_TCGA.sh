#! /bin/bash -l
#SBATCH --partition=scu-gpu
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=16
#SBATCH --job-name=evPtenTCGA
#SBATCH --time=02:00:00
#SBATCH --mem=64G
#SBATCH --gres=gpu:1

source ~/.bashrc

conda activate /home/mao4005/.conda/envs/clam
#python code/ImageProcessing.py

CUDA_VISIBLE_DEVICES=0 python clam/eval.py --drop_out --models_exp_code pca_pten_512_NatHist_mbSmall_B32CE_lvl0new_s1 --save_exp_code PTEN_TCGA2 --task pca_pten_TCGA --model_type clam_mb --results_dir objs/clam/training_results/NatHist --data_root_dir data/features_clam_512_TCGA_lvl0_new2 --model_size small --split 'all'
