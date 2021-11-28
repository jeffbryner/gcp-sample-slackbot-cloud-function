import numpy as np
import pandas as pd


def hello_world(request):
    return f"Hello World, brought to you by numpy version {np.__version__} and pandas version {pd.__version__}"
