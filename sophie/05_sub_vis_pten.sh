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

python3 karen/Visualize.py --magnification '20x' --svs_path 'data/TCGA/prad/TCGA-HC-7232-01A-01-BS1.41fa2ea1-012c-4d60-bab6-8e21817c5b42.svs' --model_folder_path 'objs/karen/model_pten/pten_10x_att_A32_patch200' --by acc --step_pct 0.5 --target_path 'objs/karen/heatmaps/TCGA_HC_7232/20x' --heatmaps --down_size 1 --file_name 'Prediction_Map_20x' --heatmap_name 'heatmap_20x.png'
