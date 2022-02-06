#! /bin/bash -l
#SBATCH --partition=scu-gpu
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=31
#SBATCH --job-name=trKrPten10x
#SBATCH --time=2-00:00:00
#SBATCH --mem=650G
#SBATCH --gres=gpu:2

source ~/.bashrc

conda activate /home/mao4005/.conda/envs/pathml
#python code/ImageProcessing.py

python3 karen/Train.py --result_dir 'objs/karen/model_pten' --df_path 'objs/karen/MetaData_training_pten_10x.csv' --workers 30 --CNN densenet --no_age --y_col 'label' --patch_n 250 --spatial_sample_off --n_epoch 150 --lr 0.00001 --optimizer Adam --use_scheduler --balance 0.5 --balance_training --freeze_batchnorm --pooling attention --A 16 --notes model0 --gpu 2 --model_name 'pten_10x_att_A16_patch250'
