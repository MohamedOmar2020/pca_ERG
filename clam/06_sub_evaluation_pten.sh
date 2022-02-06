#! /bin/bash -l
#SBATCH --partition=scu-gpu
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=14
#SBATCH --job-name=evalPTEN
#SBATCH --time=02:00:00
#SBATCH --mem=40G
#SBATCH --gres=gpu:1

source ~/.bashrc

conda activate /home/mao4005/.conda/envs/clam
#python code/ImageProcessing.py

CUDA_VISIBLE_DEVICES=0 python clam/eval.py --drop_out --k 10 --models_exp_code pca_pten_s1 --save_exp_code pca_pten_s1 --task pca_pten --model_type clam_mb --results_dir objs/clam/training_results --data_root_dir data/features_clam

