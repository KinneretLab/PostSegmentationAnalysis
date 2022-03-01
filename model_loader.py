import pretrainedmodels
import torch
from torch import nn


def load(file: str = None):
    model = pretrainedmodels.se_resnext50_32x4d()  # https://github.com/Cadene/pretrained-models.pytorch
    model.last_linear = nn.Linear(model.last_linear.in_features, 1)
    if file is not None:
        model.load_state_dict(torch.load(file))
    return model
