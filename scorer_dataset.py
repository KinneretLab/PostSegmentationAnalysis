from pathlib import Path
from typing import List, Tuple, Dict

import numpy as np
import torch
from tifffile import tifffile
from torch.utils import data
from torchvision import transforms as tf


class ScorerDataset(data.Dataset):
    """
    the dataset type used for the cell scorer.
    Classifies an image to test whether it is a cell or not.
    """

    def __init__(self, gt_dirs: List[str] = None, flag_unknowns=-1, resize_strategy=0):
        super().__init__()

        self.files: Dict[int, List[str]] = self.index_files(gt_dirs, flag_unknowns)
        self.resize_strategy: int = resize_strategy

    def __getitem__(self, img_index: int) -> Tuple[torch.Tensor, torch.Tensor]:
        """
        gets an image, and resizes it in some strategy to 224x224
        :param img_index: the index of the image to get
        :return:
        """

        label = int(img_index >= len(self.files[0]))
        img = tf.ToTensor()(tifffile.imread(self.files[label][img_index - label * len(self.files[0])]))

        if self.resize_strategy == 0:
            img = tf.Pad([(224 - np.size(img, 0)) // 2 + 1, (224 - np.size(img, 1)) // 2 + 1]).forward(img)
        if self.resize_strategy == 1:
            if np.size(img, 0) == np.size(img, 1):
                img = tf.Resize(224).forward(img)
            else:
                img = tf.Resize(223, max_size=224).forward(img)
            img = tf.Pad([(224 - np.size(img, 0)) // 2 + 1, (224 - np.size(img, 1)) // 2 + 1]).forward(img)
        if self.resize_strategy == 2:
            img = tf.Resize([224, 224]).forward(img)
        img = tf.CenterCrop(224).forward(img)

        return img, torch.Tensor([label])

    def __len__(self):
        return len(self.files[0]) + len(self.files[1])

    @staticmethod
    def index_files(gt_dirs, flag_unknowns) -> Dict[int, List[str]]:
        """
        Indexes all the image file names into categories
        :param gt_dirs: the source directories
        :param flag_unknowns: how unclassified cells should be treated
        :return: A dictionary of the classification type and the corresponding list of files fitting that type
        """
        ret = {0: [], 1: []}
        for source in gt_dirs:
            if Path.is_dir(Path(source) / 'fakes'):
                ret[0].extend([str(f.absolute()) for f in (Path(source) / 'fakes').iterdir() if not f.is_dir()])
            if Path.is_dir(Path(source) / 'cells'):
                ret[1].extend([str(f.absolute()) for f in (Path(source) / 'cells').iterdir() if not f.is_dir()])
            if flag_unknowns >= 0 and Path.is_dir(Path(source) / 'unclassified'):
                ret[flag_unknowns].extend([str(f.absolute()) for f in (Path(source) / 'unclassified').iterdir()
                                           if not f.is_dir()])
        return ret
