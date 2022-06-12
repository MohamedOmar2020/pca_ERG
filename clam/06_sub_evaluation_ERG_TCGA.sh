#! /bin/bash -l
#SBATCH --partition=scu-gpu
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=20
#SBATCH --job-name=evERGtcga
#SBATCH --time=08:00:00
#SBATCH --mem=100G
#SBATCH --gres=gpu:1

source ~/.bashrc

conda activate /home/mao4005/.conda/envs/clam
#python code/ImageProcessing.py

CUDA_VISIBLE_DEVICES=0 python clam/eval.py --drop_out --models_exp_code pca_ERG_512_NatHist_MBsmall_B32SVM_lvl0new_s1 --save_exp_code ERG_TCGA --task pca_ERG_TCGA --model_type clam_mb --results_dir objs/clam/training_results/NatHist --data_root_dir data/features_clam_512_TCGA_lvl0_new --model_size small --split 'all'
