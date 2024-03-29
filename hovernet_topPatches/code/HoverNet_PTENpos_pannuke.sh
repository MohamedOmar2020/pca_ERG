#! /bin/bash -l
#SBATCH --partition=scu-gpu
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=20
#SBATCH --job-name=HovNtPTENpos
#SBATCH --time=2-00:00:00
#SBATCH --mem=128G
#SBATCH --gres=gpu:2

source ~/.bashrc
#conda activate /home/mao4005/.conda/envs/hovernet
conda activate /athena/marchionnilab/scratch/lab_data/Mohamed/pca_outcome/hovernet_env
python hovernet/code/hover_net/run_infer.py --nr_types=6 --model_path=hovernet/models/hovernet_fast_pannuke_type_tf2pytorch.tar --type_info_path hovernet/code/hover_net/type_info_pannuke.json --model_mode=fast tile --input_dir hovernet/input/pten/pos --output_dir hovernet/output/pten/pos/pannuke


