#! /bin/bash -l
#SBATCH --partition=panda-gpu
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=20
#SBATCH --job-name=evERG
#SBATCH --time=1-00:00:00
#SBATCH --mem=300G
#SBATCH --gres=gpu:4

source ~/.bashrc

conda activate /home/mao4005/.conda/envs/pathml
#python code/ImageProcessing.py

python3 karen/Evaluation.py --df_path 'objs/karen/MetaData_training_ERG_5x.csv' --y_col='label' --Model_Folder 'objs/karen/model_ERG/ERG_5x_mean_patch200' --key_word 'Test' --no_age --two_forward_off --action 'summary'
