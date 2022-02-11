#! /bin/bash -l
#SBATCH --partition=panda-gpu
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=16
#SBATCH --job-name=training
#SBATCH --time=2-00:00:00
#SBATCH --mem=64G
#SBATCH --gres=gpu:2

source ~/.bashrc

conda activate /home/mao4005/.conda/envs/pathml
#python code/ImageProcessing.py

python3 code/Train.py --result_dir 'data/model/' --df_path 'objs/MetaData_training.csv' --workers 16 --CNN densenet --no_age --y_col 'label' --patch_n 200 --spatial_sample_off --n_epoch 100 --lr 0.00001 --optimizer Adam --use_scheduler --balance 0.5 --balance_training --freeze_batchnorm --pooling mean --notes model0 --gpu 2



