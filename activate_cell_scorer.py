import os
from pathlib import Path
from typing import Dict, Tuple

import re

import pandas
import torch
import yaml
import torch.nn
from torch.utils import data
from pandas import DataFrame

# noinspection PyUnresolvedReferences
from smart_config import SmartConfig
from scorer_dataset import ScorerDataset


def get_device() -> torch.device:
    # automatically choose device: use gpu 0 if it is available, o.w. use the cpu
    device = torch.device("cuda:0" if torch.cuda.is_available() else "cpu")
    print("using device: ", device)
    return device


def main():
    cfg = SmartConfig('activation')
    try:
        cfg.load('cfg/config.yml')
    except yaml.YAMLError as e:
        print('\033[91mCould not load configuration file. Error: \033[0m' + str(e))
        return
    device = get_device()

    dataset = ScorerDataset(cfg.sources, 0, cfg.resize_strategy)
    dl = data.DataLoader(dataset, batch_size=1, shuffle=False)

    # "sacred code": basically, NVIDIA did not update their model version and saved their neural network using an old
    # class definition of ResNet. as a result, the only way to load this old definition in a robust way
    # is by directly downloading the original model every time from the internet, forcing python to cache the target
    # classes we need to work. This is bad and inefficient, but we are forced to use this because NVIDIA.
    torch.hub.load('NVIDIA/DeepLearningExamples:torchhub', 'nvidia_se_resnext101_32x4d')

    model = torch.load(cfg.model_path)
    model.eval()

    if not os.path.exists(cfg.out_path):
        os.makedirs(cfg.out_path)

    loaded_csvs: Dict[str, DataFrame] = {}

    with torch.no_grad():
        for i, new_data in enumerate(dl, 0):
            # get the inputs and send them to device
            valid_outputs = torch.squeeze(model(new_data[0].to(device)))
            pred_confidence = torch.sigmoid(valid_outputs).item()

            df, cell_id = get_csv(cfg, loaded_csvs, dataset, i)
            df['confidence'][cell_id - 1] = pred_confidence

            print(f"completed image {i + 1} of {len(dataset)}")

    print("saving files...")
    for file in loaded_csvs:
        loaded_csvs[file].to_csv(file)


def get_csv(cfg: SmartConfig, csv_db: Dict[str, DataFrame], ds: ScorerDataset, index: int) -> Tuple[DataFrame, int]:
    path = ds.get_path(index)
    for source in cfg.sources:
        if Path(path).is_relative_to(source):
            key = cfg.out_path.replace('{source}', source)
            if key in csv_db:
                df = csv_db[key]
            else:
                df = pandas.read_csv(key)
                csv_db[key] = df
                df['confidence'] = -1
            cell_id = int(re.findall(r'\d+', path)[-1])
            return df, cell_id


if __name__ == '__main__':
    main()
