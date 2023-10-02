#! /bin/bash -l
#SBATCH --partition=scu-gpu
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=35
#SBATCH --job-name=HovNtTCGA
#SBATCH --time=2-00:00:00
#SBATCH --mem=350G
#SBATCH --gres=gpu:2

module load gcc-8.2.0-gcc-4.8.5-7ox3vie
source ~/.bashrc
conda activate /home/mao4005/.conda/envs/hovernet

python hovernet_wsi/code/hover_net/run_infer.py --nr_types=6 --gpu='0,1' --nr_inference_workers=20 --nr_post_proc_workers=15 --batch_size=64 --model_path=hovernet_wsi/models/hovernet_fast_pannuke_type_tf2pytorch.tar --type_info_path hovernet_wsi/code/hover_net/type_info_pannuke.json --model_mode=fast wsi --tile_shape 2048 --input_dir hovernet_wsi/input/ERG/TCGA --output_dir hovernet_wsi/output/ERG/TCGA --cache_path hovernet_wsi/cache --input_mask_dir hovernet_wsi/masks/TCGA


