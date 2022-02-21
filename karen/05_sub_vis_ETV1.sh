#! /bin/bash -l
#SBATCH --partition=scu-gpu
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=20
#SBATCH --job-name=visETV1
#SBATCH --time=2-00:00:00
#SBATCH --mem=100G
#SBATCH --gres=gpu:2

source ~/.bashrc
conda activate /home/mao4005/.conda/envs/pathml

python3 karen/Visualize.py --magnification '20x' --svs_path 'data/TCGA/prad/TCGA-HC-A9TH-01A-01-TS1.CAC5B6C9-1004-4198-BC84-4CAA1336DAF3.svs' --model_folder_path 'objs/karen/model_ETV1/ETV1_10x_mean' --by acc --step_pct 0.5 --target_path 'objs/karen/heatmaps/TCGA_HC_A9TH/ETV1/20x' --heatmaps --down_size 1 --file_name 'Prediction_Map_20x' --heatmap_name 'heatmap_20x.png'
