
import os
import numpy as np
from tqdm import tqdm
import copy
import matplotlib.pyplot as plt
from matplotlib import cm
import torch
from torch.optim.lr_scheduler import StepLR
import albumentations as A
from pathml.datasets.pannuke import PanNukeDataModule
from pathml.ml.hovernet import HoVerNet, loss_hovernet, post_process_batch_hovernet
from pathml.ml.utils import wrap_transform_multichannel, dice_score
from pathml.utils import plot_segmentation

from torchvision import datasets

##############################
## Model training
n_classes_pannuke = 6

# data augmentation transform
hover_transform = A.Compose(
    [A.VerticalFlip(p=0.5),
     A.HorizontalFlip(p=0.5),
     A.RandomRotate90(p=0.5),
     A.GaussianBlur(p=0.5),
     A.MedianBlur(p=0.5, blur_limit=5)],
    #additional_targets = {f"mask{i}" : "mask" for i in range(n_classes_pannuke)}
)

transform = wrap_transform_multichannel(hover_transform)


#####################################
## load the PanNuke dataset

# Download: https://warwick.ac.uk/fac/cross_fac/tia/data/pannuke

pannuke = PanNukeDataModule(
    data_dir="data/pannuke/",
    download=False,
    nucleus_type_labels=True,
    batch_size=4,
    hovernet_preprocess=True,
    split=1,
    transforms=transform
)

train_dataloader = pannuke.train_dataloader
valid_dataloader = pannuke.valid_dataloader
test_dataloader = pannuke.test_dataloader

#############################
#images, masks, hvs, types = next(iter(train_dataloader))

#n = 4
#fig, ax = plt.subplots(nrows=n, ncols=4, figsize = (8, 8))

#cm_mask = copy.copy(cm.get_cmap("tab10"))
#cm_mask.set_bad(color='white')

########################
# load the model
hovernet = HoVerNet(n_classes=n_classes_pannuke)

# wrap model to use multi-GPU
hovernet = torch.nn.DataParallel(hovernet)

# set up optimizer
opt = torch.optim.Adam(hovernet.parameters(), lr = 1e-4)
# learning rate scheduler to reduce LR by factor of 10 each 25 epochs
scheduler = StepLR(opt, step_size=25, gamma=0.1)


device = torch.device('cpu')
hovernet.to(device);

n_epochs = 50

# print performance metrics every n epochs
print_every_n_epochs = None

# evaluating performance on a random subset of validation mini-batches
# this saves time instead of evaluating on the entire validation set
n_minibatch_valid = 50

epoch_train_losses = {}
epoch_valid_losses = {}
epoch_train_dice = {}
epoch_valid_dice = {}

best_epoch = 0

###############
# data augmentation transform
hover_transform = A.Compose(
    [A.VerticalFlip(p=0.5),
     A.HorizontalFlip(p=0.5),
     A.RandomRotate90(p=0.5),
     A.GaussianBlur(p=0.5),
     A.MedianBlur(p=0.5, blur_limit=5)],
    additional_targets = {f"mask{i}" : "mask" for i in range(6)}
)

transform = wrap_transform_multichannel(hover_transform)

# Data loaders
ERG_patches_dir = 'hovernet/ERG_patches'

ERG_dataset = datasets.ImageFolder(ERG_patches_dir, transform=transform)

ERG_dataloader = torch.utils.data.DataLoader(ERG_dataset, batch_size=32, shuffle=True)

# load the best model
checkpoint = torch.load("hovernet_best_perf.pt", map_location=torch.device('cpu'))
hovernet.load_state_dict(checkpoint)


########
# Next, we loop through the test set and store the model predictions
hovernet.eval()

ims = None
mask_truth = None
mask_pred = None
tissue_types = []

with torch.no_grad():
    for i, data in tqdm(enumerate(ERG_dataloader)):
        # send the data to the GPU
        images = data[0].float().to(device)
        masks = data[1].to(device)
        hv = data[2].float().to(device)
        tissue_type = data[3]

        # pass thru network to get predictions
        outputs = hovernet(images)
        preds_detection, preds_classification = post_process_batch_hovernet(outputs, n_classes=n_classes_pannuke)

        if i == 0:
            ims = data[0].numpy()
            mask_truth = data[1].numpy()
            mask_pred = preds_classification
            tissue_types.extend(tissue_type)
        else:
            ims = np.concatenate([ims, data[0].numpy()], axis=0)
            mask_truth = np.concatenate([mask_truth, data[1].numpy()], axis=0)
            mask_pred = np.concatenate([mask_pred, preds_classification], axis=0)
            tissue_types.extend(tissue_type)

print('done')
# collapse multi-class preds into binary preds
#preds_detection = np.sum(mask_pred, axis=1)

#dice_scores = np.empty(shape = len(tissue_types))

#for i in range(len(tissue_types)):
#    truth_binary = mask_truth[i, -1, :, :] == 0
#    preds_binary = preds_detection[i, ...] != 0
#    dice = dice_score(preds_binary, truth_binary)
#    dice_scores[i] = dice


# save dice_score and tissue_types

#dice_by_tissue = pd.DataFrame({"Tissue Type" : tissue_types, "dice" : dice_scores})
#dice_by_tissue.to_csv('dice_score.csv')

#dice_by_tissue.groupby("Tissue Type").mean().plot.bar()
#plt.title("Dice Score by Tissue Type")
#plt.ylabel("Averagae Dice Score")
#plt.gca().get_legend().remove()
#plt.savefig('diceScore.png')

#print(f"Average Dice score in test set: {np.mean(dice_scores)}")


##################3
## Examples
# change image tensor from (B, C, H, W) to (B, H, W, C)
# matplotlib likes channels in last dimension
#ims = np.moveaxis(ims, 1, 3)


#n = 8
#ix = np.random.choice(np.arange(len(tissue_types)), size = n)
#fig, ax = plt.subplots(nrows = n, ncols = 2, figsize = (8, 2.5*n))

#for i, index in enumerate(ix):
#    ax[i, 0].imshow(ims[index, ...])
#    ax[i, 1].imshow(ims[index, ...])
#    plot_segmentation(ax = ax[i, 0], masks = mask_pred[index, ...])
#    plot_segmentation(ax = ax[i, 1], masks = mask_truth[index, ...])
#    ax[i, 0].set_ylabel(tissue_types[index])

#for a in ax.ravel():
#    a.get_xaxis().set_ticks([])
#    a.get_yaxis().set_ticks([])

#ax[0, 0].set_title("Prediction")
#ax[0, 1].set_title("Truth")
#plt.tight_layout()
#plt.savefig('predictions.png')


