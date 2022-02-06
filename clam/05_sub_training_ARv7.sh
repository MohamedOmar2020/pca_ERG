#! /bin/bash -l
#SBATCH --partition=scu-gpu
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=40
#SBATCH --job-name=trARv7
#SBATCH --time=2-00:00:00
#SBATCH --mem=150G
#SBATCH --gres=gpu:2

source ~/.bashrc

conda activate /home/mao4005/.conda/envs/clam

CUDA_VISIBLE_DEVICES=0,1 python clam/main.py --drop_out --early_stopping --lr 1e-4 --k 10 --label_frac 1.00 --exp_code pca_ARv7_256 --weighted_sample --bag_loss ce --inst_loss svm --task pca_ARv7 --model_type clam_mb --log_data --data_root_dir data/features_clam_256 --results_dir objs/clam/training_results --max_epochs 500 --split_dir pca_ARv7_100 --model_size big
