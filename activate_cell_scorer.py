from pathlib import Path
from typing import Dict, Tuple, List

import re

import pandas
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

    loaded_tables: Dict[str, pandas.DataFrame] = {}
    cells_correct: int = 0
    false_pos: int = 0
    false_neg: int = 0

    with torch.no_grad():
        for i, new_data in enumerate(dl, 0):
            # get the inputs and send them to device
            valid_outputs = torch.squeeze(model(new_data[0].to(device)))
            pred_confidence = torch.sigmoid(valid_outputs).item()

            df, cell_id = get_table(cfg, loaded_tables, dataset, i)
            df.at[cell_id, 'confidence'] = pred_confidence

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
        loaded_tables[file].to_csv(file, index=False)


def get_table(cfg: SmartConfig, table_db: Dict[str, pandas.DataFrame], ds: ScorerDataset, index: int) -> \
        Tuple[pandas.DataFrame, int]:
    path = ds.get_path(index)
    for source in cfg.sources:
        if Path(path).is_relative_to(source):
            key = cfg.out_path.replace('{source}', source)
            if key in table_db:
                df = table_db[key]
            else:
                df = pandas.read_csv(key)
                if 'confidence' not in df:
                    df['confidence'] = -1
                table_db[key] = df
            id_split: List[str] = re.findall(r'[^.\\]+', path)[-2].split("_")
            frame_name = '_'.join(id_split[0:-1])
            # could be generalized into config.yml, but im lazy
            frame_df = pandas.read_csv(re.sub(r'cells\.csv', 'frames.csv', key))
            frame_id = int(frame_df[frame_df['frame_name'] == frame_name]['frame'])
            cell_in_frame = int(id_split[-1])
            cell_id = int((frame_id+cell_in_frame)*(frame_id+cell_in_frame+1)/2+frame_id)
            cell_index = df[df['cell_id'] == cell_id].index[0]
            return df, cell_index


if __name__ == '__main__':
    main()
