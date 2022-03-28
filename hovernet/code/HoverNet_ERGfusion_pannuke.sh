#! /bin/bash -l
#SBATCH --partition=scu-gpu
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=20
#SBATCH --job-name=HovNetERGfusion
#SBATCH --time=2-00:00:00
#SBATCH --mem=128G
#SBATCH --gres=gpu:2

source ~/.bashrc
conda activate /home/mao4005/.conda/envs/hovernet

python hovernet/code/hover_net/run_infer.py --nr_types=6 --model_path=hovernet/models/hovernet_fast_pannuke_type_tf2pytorch.tar --type_info_path hovernet/code/hover_net/type_info_pannuke.json --model_mode=fast tile --input_dir hovernet/input/ERG/fusion --output_dir hovernet/output/ERG/fusion/pannuke


