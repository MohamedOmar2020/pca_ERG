#! /bin/bash -l
#SBATCH --partition=panda-gpu
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=25
#SBATCH --job-name=trKrPten10x
#SBATCH --time=2-00:00:00
#SBATCH --mem=350G
#SBATCH --gres=gpu:2

source ~/.bashrc

conda activate  /home/sor4002/anaconda3/envs/sophievm
#python code/ImageProcessing.py

python3 karen/Train.py --result_dir 'objs/karen/model_pten' --df_path 'objs/karen/MetaData_training_pten_10x.csv' --workers 23 --CNN densenet --no_age --y_col 'label' --patch_n 300 --spatial_sample_off --n_epoch 100 --lr 0.00001 --optimizer Adam --use_scheduler --balance 0.5 --balance_training --freeze_batchnorm --pooling attention --A 16 --notes model0 --gpu 2 --model_name 'pten_10x_att_sophie'
