#!/usr/bin/env python
# -*- coding: utf-8 -*-
# Copyright (c) 2019 Satpy developers
#
# This file is part of satpy.
#
# satpy is free software: you can redistribute it and/or modify it under the
# terms of the GNU General Public License as published by the Free Software
# Foundation, either version 3 of the License, or (at your option) any later
# version.
#
# satpy is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE.  See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along with
# satpy.  If not, see <http://www.gnu.org/licenses/>.
"""Earth Networks Total Lightning Network Dataset reader

With over 1,700 sensors covering over 100 countries around the world,
ENTLN is the most extensive and technologically-advanced global lightning network.
The data provided is generated by the ENTLN worker.

References:
- [ENTLN] https://www.earthnetworks.com/why-us/networks/lightning

"""

import logging
import pandas as pd
import dask.array as da
import xarray as xr
from datetime import datetime

from satpy import CHUNK_SIZE
from satpy.readers.file_handlers import BaseFileHandler

logger = logging.getLogger(__name__)


class ENTLNFileHandler(BaseFileHandler):
    """ASCII reader for Vaisala GDL360 data."""

    def __init__(self, filename, filename_info, filetype_info):
        super(ENTLNFileHandler, self).__init__(filename, filename_info, filetype_info)

        names = ['type', 'timestamp', 'latitude', 'longitude', 'peakcurrent', \
                 'icheight', 'numbersensors', 'icmultiplicity', 'cgmultiplicity', \
                 'starttime', 'endtime', 'duration', 'ullatitude', 'ullongitude', \
                 'lrlatitude', 'lrlongitude']
        types = ['int', 'str', 'float', 'float', 'float', \
                 'float', 'int', 'int', 'int', \
                 'str', 'str', 'float', 'float', 'float', \
                 'float', 'float']
        dtypes = dict(zip(names, types))

        self.data = pd.read_csv(filename, delimiter=',', dtype=dtypes, parse_dates=['timestamp'], skipinitialspace=True)

    @property
    def start_time(self):
        return self.data['timestamp'].index[0]
        #return self.data['timestamp'][0] #cldn

    @property
    def end_time(self):
        #return self.data['timestamp'].index[-1]
        return self.data['timestamp'].index[-1] #cldn

    def get_dataset(self, dataset_id, dataset_info):
        """Load a dataset."""
        xarr = xr.DataArray(da.from_array(self.data[dataset_id.name],
                                          chunks=CHUNK_SIZE), dims=['y'])#dataset_id.name])

        # Add variables as non-dimensional y-coordinates
        for column in ['type', 'timestamp', 'latitude', 'longitude']:#self.data.columns:
            xarr[column] = ('y', self.data[column])#dataset_id.name, self.data[column])
        xarr.attrs.update(dataset_info)

        return xarr
