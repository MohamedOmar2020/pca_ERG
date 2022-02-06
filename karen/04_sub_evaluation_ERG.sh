#! /bin/bash -l
#SBATCH --partition=scu-gpu
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=30
#SBATCH --job-name=evERG
#SBATCH --time=1-00:00:00
#SBATCH --mem=250G
#SBATCH --gres=gpu:2

source ~/.bashrc

conda activate /home/mao4005/.conda/envs/pathml
#python code/ImageProcessing.py

python3 karen/Evaluation.py --df_path 'objs/karen/MetaData_training_ERG.csv' --y_col='label' --Model_Folder 'objs/karen/model_ERG/2021-11-07 21:02:29/' --key_word 'Test' --no_age --two_forward_off --action 'summary'
