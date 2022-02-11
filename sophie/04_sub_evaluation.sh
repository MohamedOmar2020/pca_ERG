#! /bin/bash -l
#SBATCH --partition=panda-gpu
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=16
#SBATCH --job-name=evaluation
#SBATCH --time=1-00:00:00
#SBATCH --mem=40G
#SBATCH --gres=gpu:2

source ~/.bashrc

conda activate /home/mao4005/.conda/envs/pathml
#python code/ImageProcessing.py

python3 code/Evaluation.py --df_path 'objs/MetaData_training.csv' --y_col='label' --Model_Folder 'data/model/2021-09-30 22:59:19/' --key_word 'Test' --no_age --two_forward_off --action 'patch'

