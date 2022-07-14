#! /bin/bash -l
#SBATCH --partition=scu-gpu
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=35
#SBATCH --job-name=trERGnatHist
#SBATCH --time=2-00:00:00
#SBATCH --mem=100G
#SBATCH --gres=gpu:2

source ~/.bashrc

conda activate /home/mao4005/.conda/envs/clam

CUDA_VISIBLE_DEVICES=0,1 python clam/main.py --early_stopping --drop_out --lr 1e-4 --k 10 --label_frac 0.7 --exp_code pca_ERG_512_NatHist_MBbig_B8CE_size512_mag10x --weighted_sample --bag_loss ce --inst_loss svm --task pca_ERG_NatHist --bag_weight 0.7 --model_type clam_mb --model_size big --B 8 --log_data --data_root_dir data/features_clam_NatHist_size512_mag10x --results_dir objs/clam/training_results/NatHist --max_epochs 150 --split_dir pca_ERG_NatHist_70
