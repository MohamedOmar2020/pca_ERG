import sys
import openslide
import numpy as np
import pandas as pd
import math
from glob import glob
import matplotlib.pyplot as plt
import scipy.io as sio
import cv2
import json
import anndata as ad
from multiprocessing import Pool, cpu_count
from tqdm import tqdm

hovernet_output_path = '/data/projects/deep_learning/PCa/outs/hovernet_wsi/json/'


def process_json(json_path):
    """
    Load the JSON file, extract nuclear types, and return a dictionary with counts of each type.
    """
    # Extract patient id from the json filename
    patient_id = os.path.basename(json_path).split('.')[0]

    # Load JSON data
    with open(json_path, 'r') as f:
        data = json.load(f)

    nuc_info = data.get('nuc', {})

    # Get nuclear types and convert them to their respective names
    nucleus_types = {
        0: "no label",
        1: "neoplastic",
        2: "inflammatory",
        3: "stromal",
        4: "necrotic",
        5: "benign epithelial"
    }

    type_list = [nucleus_types[inst['type']] for inst in nuc_info.values()]

    # Count the occurrences of each type
    type_counts = dict(pd.Series(type_list).value_counts())
    type_counts['patient_id'] = patient_id

    return type_counts
def worker(json_path):
    return process_json(json_path)

hovernet_output_folder = '/data/projects/deep_learning/PCa/outs/hovernet_wsi/json'

# Get list of JSON files
json_paths = glob(os.path.join(hovernet_output_folder, '*.json'))

# Create a pool of workers
pool = Pool(processes=cpu_count())

# Process the JSON files in parallel using a progress bar
results = list(tqdm(pool.imap(worker, json_paths), total=len(json_paths)))

# Close the pool and wait for the work to finish
pool.close()
pool.join()

# Create a DataFrame from the results
df = pd.DataFrame(results)

# Set patient_id as the index
df.set_index('patient_id', inplace=True)

print(df.head())