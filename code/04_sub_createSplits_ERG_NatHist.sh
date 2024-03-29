#! /bin/bash -l
#! /bin/bash -l
#SBATCH --partition=scu-cpu
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=15
#SBATCH --job-name=splERGnatHist
#SBATCH --time=02:00:00
#SBATCH --mem=50G
##SBATCH --gres=gpu:2


source ~/.bashrc
conda activate /home/mao4005/.conda/envs/clam

python clam/create_splits_seq.py --task pca_ERG_NatHist --seed 1 --label_frac 1.0 --k 10 --val_frac 0.15 --test_frac 0.15

