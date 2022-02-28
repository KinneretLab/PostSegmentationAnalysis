import copy
import math
import os
import pathlib
import time
import warnings

import torch
import yaml
from torch import nn, optim
from torch.utils import data

from scorer_dataset import ScorerDataset
from smart_config import SmartConfig

warnings.filterwarnings('ignore')
# %matplotlib inline


def get_device() -> torch.device:
    # automatically choose device: use gpu 0 if it is available, o.w. use the cpu
    device = torch.device("cuda:0" if torch.cuda.is_available() else "cpu")
    print(f"using device: {device}")
    return device


def train(num_epochs: int, out_path: str, model, device, criterion, optimizer, scheduler, dataloaders, dataset_sizes):
    since = time.time()

    best_model_wts = copy.deepcopy(model.state_dict())
    best_acc = 0.0

    for epoch in range(num_epochs):
        print(f'Epoch {epoch}/{num_epochs - 1}')
        print('-' * 10)

        # Each epoch has a training and validation phase
        for phase in ['train', 'val']:
            if phase == 'train':
                model.train()  # Set model to training mode
            else:
                model.eval()   # Set model to evaluate mode

            running_loss = 0.0
            running_corrects = 0

            # Iterate over data.
            for inputs, labels in dataloaders[phase]:
                inputs = inputs.to(device)
                labels = labels.to(device)

                # zero the parameter gradients
                optimizer.zero_grad()

                # forward
                # track history if only in train
                with torch.set_grad_enabled(phase == 'train'):
                    preds = model(inputs)
                    loss = criterion(preds, labels)

                    # backward + optimize only if in training phase
                    if phase == 'train':
                        loss.backward()
                        optimizer.step()

                # statistics
                running_loss += loss.item() * inputs.size(0)
                running_corrects += torch.sum((preds >= 0.0) == labels).item()
            if phase == 'train':
                scheduler.step()

            epoch_loss = running_loss / dataset_sizes[phase]
            epoch_acc = running_corrects / dataset_sizes[phase]

            print(f'{phase} Loss: {epoch_loss:.4f} Acc: {epoch_acc:.4f}')

            # deep copy the model
            if phase == 'val' and epoch_acc > best_acc:
                best_acc = epoch_acc
                best_model_wts = copy.deepcopy(model.state_dict())
        print()

    time_elapsed = time.time() - since
    print(f'Training complete in {time_elapsed // 60:.0f}m {time_elapsed % 60:.0f}s')
    print(f'Best val Acc: {best_acc:4f}')

    # load best model weights
    model.load_state_dict(best_model_wts)
    # save model
    print('==> Finished Training ...')
    torch.save(model, out_path)


def main():
    cfg = SmartConfig('training')
    try:
        cfg.load('cfg/config.yml')
    except yaml.YAMLError as e:
        print('\033[91mCould not load configuration file. Error: \033[0m' + str(e))
        return
    # make everything do stuff on GPU
    device = get_device()

    # load model from internet
    model = torch.hub.load('NVIDIA/DeepLearningExamples:torchhub', 'nvidia_se_resnext101_32x4d')

    model.fc = nn.Linear(model.fc.in_features, 1)
    model.to(device)

    # Loss and optimizer
    criterion = nn.BCEWithLogitsLoss()
    optimizer = optim.SGD(model.parameters(), lr=cfg.lr_init, momentum=cfg.lr_momentum)
    scheduler = optim.lr_scheduler.StepLR(optimizer, step_size=cfg.lr_decay_step, gamma=cfg.lr_decay_size)

    # generate dataset
    dataset = ScorerDataset(cfg.sources, cfg.flag_unknowns, cfg.resize_strategy)

    data_size = len(dataset)
    valid_size = max(int(math.ceil(data_size * cfg.valid_ratio)), 2)
    train_ds, valid_ds = torch.utils.data.random_split(dataset, (data_size - valid_size, valid_size))

    # the complete data loaders
    train_dl = torch.utils.data.DataLoader(train_ds, batch_size=3, shuffle=True)
    valid_dl = torch.utils.data.DataLoader(valid_ds, batch_size=3, shuffle=True)

    # debug stuff
    xb, yb = next(iter(train_dl))
    print(f'input: {xb.shape} -> output: {yb.shape}')

    # create model directory so we can store it
    out_dir = pathlib.Path(cfg.out_path).parent
    if not out_dir.exists():
        os.makedirs(str(out_dir))

    # training
    train(cfg.epochs, cfg.out_path, model, device, criterion, optimizer, scheduler,
          {'train': train_dl, 'val': valid_dl}, {'train': data_size - valid_size, 'val': valid_size})


if __name__ == '__main__':
    main()