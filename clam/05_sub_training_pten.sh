#! /bin/bash -l
#SBATCH --partition=scu-gpu
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=15
#SBATCH --job-name=train_pten
#SBATCH --time=2-00:00:00
#SBATCH --mem=64G
#SBATCH --gres=gpu:2

source ~/.bashrc

conda activate /home/mao4005/.conda/envs/clam

CUDA_VISIBLE_DEVICES=0,1 python clam/main.py --drop_out --early_stopping --lr 2e-4 --k 10 --label_frac 1.00 --exp_code pca_pten --weighted_sample --bag_loss ce --inst_loss svm --task pca_pten --model_type clam_sb --log_data --data_root_dir data/features_clam --results_dir objs/clam/training_results --max_epochs 100 --split_dir pca_pten_100
