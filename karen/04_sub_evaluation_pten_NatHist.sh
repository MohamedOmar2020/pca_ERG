#! /bin/bash -l
#SBATCH --partition=scu-gpu
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --job-name=evPTEN
#SBATCH --time=1-00:00:00
#SBATCH --mem=350G
#SBATCH --gres=gpu:2

source ~/.bashrc

conda activate /home/mao4005/.conda/envs/pathml
#python code/ImageProcessing.py

python3 karen/Evaluation.py --df_path 'objs/karen/MetaData_training_pten_NatHist_10x.csv' --y_col='label' --Model_Folder 'objs/karen/NatHist/model_pten/pten_10x_mean_patch250' --key_word 'Test' --no_age --two_forward_off --action 'summary'
