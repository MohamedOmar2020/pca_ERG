#! /bin/bash -l
#SBATCH --partition=panda-gpu
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=24
#SBATCH --job-name=trKrTP53_10x
#SBATCH --time=2-00:00:00
#SBATCH --mem=300G
#SBATCH --gres=gpu:2

source ~/.bashrc

conda activate /home/mao4005/.conda/envs/pathml
#python code/ImageProcessing.py

python3 karen/Train.py --result_dir 'objs/karen/model_TP53' --df_path 'objs/karen/MetaData_training_TP53_10x.csv' --workers 20 --CNN densenet --no_age --y_col 'label' --patch_n 200 --spatial_sample_off --n_epoch 200 --lr 0.00001 --optimizer Adam --use_scheduler --balance 0.6 --balance_training --freeze_batchnorm --pooling attention --notes model0 --gpu 2 --model_name 'TP53_10x'
