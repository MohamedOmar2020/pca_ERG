#! /bin/bash -l
#SBATCH --partition=scu-gpu
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=16
#SBATCH --job-name=evPTENnatHist
#SBATCH --time=02:00:00
#SBATCH --mem=64G
#SBATCH --gres=gpu:1

source ~/.bashrc

conda activate /home/mao4005/.conda/envs/clam
#python code/ImageProcessing.py

CUDA_VISIBLE_DEVICES=0 python clam/eval_mod.py --drop_out --k 10 --models_exp_code pca_pten_512_TCGA_mbBig_B16CE_size512_mag10x_new_s1 --save_exp_code pca_pten_512_TCGA_mbBig_B16CE_size512_mag10x_new_s1_evNathist --task pca_pten_NatHist --model_type clam_mb --results_dir objs/clam/training_results/TCGA/new --data_root_dir data/features_clam_NatHist_size512_mag10x --model_size big --split 'all'
