#! /bin/bash -l
#SBATCH --partition=scu-gpu
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=35
#SBATCH --job-name=trPTENnatHist
#SBATCH --time=2-00:00:00
#SBATCH --mem=100G
#SBATCH --gres=gpu:2

source ~/.bashrc

conda activate /home/mao4005/.conda/envs/clam

CUDA_VISIBLE_DEVICES=0,1 python clam/main.py --drop_out --early_stopping --lr 5e-5 --k 10 --label_frac 1.0 --exp_code pca_pten_512_NatHist_mbSmall_B32CE_lvl0new --weighted_sample --bag_loss ce --inst_loss ce --task pca_pten_NatHist --bag_weight 0.5 --model_type clam_mb --model_size small --B 32 --log_data --data_root_dir data/features_clam_512_NatHist_lvl0_new --results_dir objs/clam/training_results/NatHist --max_epochs 100 --split_dir pca_pten_NatHist_100
