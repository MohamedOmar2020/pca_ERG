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

CUDA_VISIBLE_DEVICES=0 python clam/eval.py --drop_out --k 10 --models_exp_code pca_pten_256_s1 --save_exp_code pca_pten_256_NatHist_s1 --task pca_pten_NatHist --model_type clam_sb --results_dir objs/clam/training_results --data_root_dir data/features_clam_256_NatHist --model_size small --split 'all' --k 10
