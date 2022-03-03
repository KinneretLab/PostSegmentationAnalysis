from pathlib import Path
from typing import Dict, Tuple

import re

import numpy as np
import scipy.io
import torch
import yaml
import torch.nn
from torch.utils import data

# noinspection PyUnresolvedReferences
import model_loader
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

    dataset = ScorerDataset(cfg.sources, 1, cfg.resize_strategy)
    dl = data.DataLoader(dataset, batch_size=1, shuffle=False)

    model = model_loader.load(cfg.model_path).to(device)
    model.eval()

    loaded_tables: Dict[str, Dict[str, np.ndarray]] = {}
    cells_correct: int = 0
    false_pos: int = 0
    false_neg: int = 0

    with torch.no_grad():
        for i, new_data in enumerate(dl, 0):
            # get the inputs and send them to device
            valid_outputs = torch.squeeze(model(new_data[0].to(device)))
            pred_confidence = torch.sigmoid(valid_outputs).item()

            df, cell_id = get_table(cfg, loaded_tables, dataset, i)
            df['fullCellDataMod']['confidence'][0, cell_id - 1] = pred_confidence

            # statistical analysis
            # noinspection PyUnresolvedReferences
            cells_correct += ((valid_outputs >= 0.0) == new_data[1].to(device)).item()
            false_neg += int((valid_outputs < 0.0) and new_data[1].to(device))
            false_pos += int((valid_outputs >= 0.0) and not new_data[1].to(device))

            print(f"completed image {i + 1} of {len(dataset)}")

    print(f"total accuracy: {cells_correct/len(dataset)}")
    print(f"false positives: {false_pos/len(dataset)}")
    print(f"false negatives: {false_neg/len(dataset)}")

    print("saving files...")
    for file in loaded_tables:
        scipy.io.savemat(file, loaded_tables[file])


def get_table(cfg: SmartConfig, table_db: Dict[str, Dict[str, np.ndarray]], ds: ScorerDataset, index: int) -> \
        Tuple[Dict[str, np.ndarray], int]:
    path = ds.get_path(index)
    for source in cfg.sources:
        if Path(path).is_relative_to(source):
            key = cfg.out_path.replace('{source}', source)
            if key in table_db:
                df = table_db[key]
            else:
                df = scipy.io.loadmat(key)
                if 'confidence' not in df['fullCellDataMod'].dtype.names:
                    merged = np.full(df['fullCellDataMod'].shape, -1,
                                     dtype=df['fullCellDataMod'].dtype.descr + [('confidence', 'O')])
                    for name in df['fullCellDataMod'].dtype.names:
                        merged[name] = df['fullCellDataMod'][name]
                    df['fullCellDataMod'] = merged
                table_db[key] = df
            cell_id = int(re.findall(r'\d+', path)[-1])
            return df, cell_id


if __name__ == '__main__':
    main()
