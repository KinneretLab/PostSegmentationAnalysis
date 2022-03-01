import torch


def load(file: str = None):
    # "sacred code": basically, NVIDIA did not update their model version and saved their neural network using an old
    # class definition of ResNet. as a result, the only way to load this old definition in a robust way
    # is by directly downloading the original model every time from the internet, forcing python to cache the target
    # classes we need to work. This is bad and inefficient, but we are forced to use this because NVIDIA.
    model = torch.hub.load('NVIDIA/DeepLearningExamples:torchhub', 'nvidia_se_resnext101_32x4d')
    if file is not None:
        model = torch.load(file)
    return model
