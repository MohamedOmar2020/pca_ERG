#! /bin/bash -l
#! /bin/bash -l
#SBATCH --partition=scu-cpu
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=20
#SBATCH --job-name=spl_pca_pten
#SBATCH --time=02:00:00
#SBATCH --mem=64G
##SBATCH --gres=gpu:2


source ~/.bashrc
conda activate /home/mao4005/.conda/envs/clam

python clam/create_splits_seq.py --task pca_pten --seed 1 --label_frac 1.00 --k 10 --val_frac 0.1 --test_frac 0.1

