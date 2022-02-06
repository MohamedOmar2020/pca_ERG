#! /bin/bash -l
#SBATCH --partition=panda-gpu
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=20
#SBATCH --job-name=visPTEN
#SBATCH --time=2-00:00:00
#SBATCH --mem=100G
#SBATCH --gres=gpu:2

source ~/.bashrc
conda activate /home/mao4005/.conda/envs/pathml

python3 karen/Visualize.py --magnification '10x' --svs_path 'data/TCGA/prad/TCGA-2A-A8VL-01A-02-TS2.AFBBB2D5-39E6-434A-B6E5-779DD8217DCD.svs' --model_folder_path 'objs/karen/model_pten/pten_10x' --by acc --step_pct 0.5 --target_path 'objs/karen/heatmaps' --heatmaps --down_size 1
