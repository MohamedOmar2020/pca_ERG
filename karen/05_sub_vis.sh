#! /bin/bash -l
#SBATCH --partition=scu-gpu
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=15
#SBATCH --job-name=visERG
#SBATCH --time=2-00:00:00
#SBATCH --mem=64G
#SBATCH --gres=gpu:2

source ~/.bashrc
conda activate /home/mao4005/.conda/envs/pathml

python3 karen/Visualize.py --magnification '2.5x' --svs_path 'data/TCGA/prad/' --model_folder_path 'objs/karen/model/' --by acc --step_pct 0.5 --target_path 'objs/karen/heatmaps' --heatmaps --down_size 2
