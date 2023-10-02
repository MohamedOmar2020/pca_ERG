#! /usr/bin/zsh -l


micromamba activate hovernet

python hovernet_wsi/code/hover_net/run_infer.py --nr_types=6 --gpu='0,1,2,3,4,5,6,7' --nr_inference_workers=8 --nr_post_proc_workers=16 --batch_size=75 --model_path=models/hovernet_fast_pannuke_type_tf2pytorch.tar --type_info_path hovernet_wsi/code/hover_net/type_info_pannuke.json --model_mode=fast wsi --tile_shape 2048 --input_dir ../PCa/data/slides --output_dir hovernet_wsi/output/TCGA --cache_path hovernet_wsi/cache --input_mask_dir hovernet_wsi/masks/TCGA --save_thumb --save_mask


