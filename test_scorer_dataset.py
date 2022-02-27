import yaml

from scorer_dataset import ScorerDataset
from smart_config import SmartConfig
import matplotlib.pyplot as plt


def main():
    cfg = SmartConfig('training')
    try:
        cfg.load('cfg/config.yml')
    except yaml.YAMLError as e:
        print('\033[91mCould not load configuration file. Error: \033[0m' + str(e))
        return
    dataset = ScorerDataset(cfg.sources, cfg.flag_unknowns, cfg.resize_strategy)

    img, label = dataset[0]
    plt.imshow(img.numpy().transpose((1, 2, 0)))
    plt.title(f'{label[0]}')
    plt.pause(0.001)


if __name__ == '__main__':
    main()