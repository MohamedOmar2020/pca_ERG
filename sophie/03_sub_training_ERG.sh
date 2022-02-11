#! /bin/bash -l
#SBATCH --partition=panda-gpu
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=16
#SBATCH --job-name=trERG5x
#SBATCH --time=2-00:00:00
#SBATCH --mem=350G
#SBATCH --gres=gpu:4

source ~/.bashrc

conda activate /home/mao4005/.conda/envs/pathml
#python code/ImageProcessing.py

python3 karen/Train.py --result_dir 'objs/karen/model_ERG' --df_path 'objs/karen/MetaData_training_ERG_5x.csv' --workers 15 --CNN densenet --no_age --y_col 'label' --patch_n 200 --spatial_sample_off --n_epoch 100 --lr 0.00001 --optimizer Adam --use_scheduler --balance 0.5 --balance_training --freeze_batchnorm --pooling max --notes model0 --gpu '0,1,2,3' --model_name 'ERG_5x_max_patch200'

