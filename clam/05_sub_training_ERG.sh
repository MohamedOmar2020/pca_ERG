#! /bin/bash -l
#SBATCH --partition=scu-gpu
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=35
#SBATCH --job-name=trERG512
#SBATCH --time=2-00:00:00
#SBATCH --mem=100G
#SBATCH --gres=gpu:2

source ~/.bashrc

conda activate /home/mao4005/.conda/envs/clam

CUDA_VISIBLE_DEVICES=0,1 python clam/main.py --drop_out --early_stopping --lr 1e-4 --k 10 --label_frac 1.00 --exp_code pca_ERG_512 --weighted_sample --bag_loss ce --inst_loss svm --task pca_ERG --model_type clam_sb --log_data --data_root_dir data/features_clam_512 --results_dir objs/clam/training_results --max_epochs 200 --split_dir pca_ERG_100 --model_size big
