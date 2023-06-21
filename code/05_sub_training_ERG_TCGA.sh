#! /bin/bash -l
#SBATCH --partition=scu-gpu
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=35
#SBATCH --job-name=trERGtcga
#SBATCH --time=2-00:00:00
#SBATCH --mem=150G
#SBATCH --gres=gpu:2

source ~/.bashrc

conda activate /home/mao4005/.conda/envs/clam

CUDA_VISIBLE_DEVICES=0,1 python clam/main_mod.py --early_stopping --drop_out --lr 1e-4 --k 10 --label_frac 1.0 --exp_code pca_ERG_512_TCGA_MBbig_B16CE_size512_mag10x_2 --weighted_sample --bag_loss ce --inst_loss ce --task pca_ERG_TCGA --bag_weight 0.7 --model_type clam_mb --model_size big --B 16 --log_data --data_root_dir data/features_clam_TCGA_size512_mag10x --results_dir objs/clam/training_results/TCGA/new --max_epochs 200 --split_dir pca_ERG_TCGA_100
