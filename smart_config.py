import glob
import os.path
from datetime import date
from pathlib import Path
from typing import List

import yaml


class SmartConfig:
    def __init__(self, section: str):
        self.sources: List[str] = []
        self.model_path: str = ''
        self.out_path: str = ''
        self.ground_truth_dir: str = ''
        self._section: str = section
        self.epochs: int = 50
        self.valid_ratio: float = 0.05
        self.lr_init: float = 0.0005
        self.lr_momentum: float = 0.9
        self.lr_decay_step: int = 7
        self.lr_decay_size: float = 0.1
        self.flag_unknowns: int = -1
        self.resize_strategy: int = 0

    def load(self, rel_path: str):
        with open(rel_path, 'r') as stream:
            raw = yaml.safe_load(stream)[self._section]

            work_dir: str = raw['work_dir']
            if not work_dir.endswith('/'):
                work_dir += '/'

            output: str = raw['output_format']
            output = 'Inference/{date}_{models}' if output is None else output
            today = date.today()
            output = output.replace('{date}', f'{today.year:04d}_{today.month:02d}_{today.day:02d}')
            if '{models}' in output:
                model_str = '_'.join([self.get_model_name(source_dir) for source_dir in raw['data_sources']])
                output = output.replace('{models}', model_str)
            self.out_path = self.to_absolute(work_dir, output)
            for raw_source in raw['data_sources']:
                if raw_source.endswith('/'):
                    raw_source = raw_source[0:-1]
                self.sources += self.from_glob(self.to_absolute(work_dir, raw_source))

            if self._section == 'activation':
                self.model_path = raw['model']
            if self._section == 'training':
                self.epochs = raw['num_epochs']
                self.lr_init = raw['inital_learning_rate']
                self.ground_truth_dir = self.to_absolute(work_dir, raw['ground_truth_dir'])
                self.valid_ratio = raw['valid_ratio']
                self.lr_momentum = raw['momentum']
                self.lr_decay_step = raw['lr_decay_step']
                self.lr_decay_size = raw['lr_decay_size']
                self.flag_unknowns = raw['flag_unclassified']
                self.resize_strategy = raw['stretch_level']

    @staticmethod
    def get_model_name(source_dir: str) -> str:
        """
        get a shortened model name for each model directory used.
        :param source_dir: the name from which to draw a model name
        :return: the shortened form of the model name. For example, EPySegRaw/EPySegRaw_3/* -> EE3
        """
        ret = ''
        for dirname in source_dir.split('/'):
            for noun in dirname.split('_'):
                ret += noun[0]
        if ret.endswith('*'):
            ret = ret[0:-1]
        return ret.upper().replace('*', 'all')

    def from_glob(self, raw_path: str) -> List[str]:
        result = sorted(glob.glob(raw_path, recursive=True))
        if len(result) == 0:
            print(f'\033[31mNo file was found with the template {raw_path}. Skipping...\033[0m')
            return []
        if 'fakes' not in [filesystem_entity.name for filesystem_entity in Path(result[0]).iterdir()]:
            return self.from_glob(raw_path + '/*')
        return result

    @staticmethod
    def to_absolute(work_dir: str, path: str) -> str:
        """
        converts the path, whatever form it may be in, into an absolute path
        :param work_dir: the working directory from which to mark the relative path
        :param path: the path to convert. May be absolute or relative to work_dir
        :return: an absolute path leading to the target specified by path.
        """
        return path if os.path.isabs(path) else work_dir + path
