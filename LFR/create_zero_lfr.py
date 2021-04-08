'''
INPUT:
       LFR OUTPUT

OUTPUT:
       LFR OUTPUT with zero lightning flash

UPDATE:
       Xin Zhang     10/19/2019
'''

import xarray as xr
import numpy as np
import pandas as pd

# set the date range of output files
st = '20200901 00:00'
et = '20200901 11:50'
dt = 10  # unit: min

# get basic file
datadir = './lfr/20200901/'
# base = 'wrflfr_d01_2020-09-01_00:00:00'
base = 'wrflfr_d01_2020-08-31_23:00:00'
ds = xr.open_dataset(datadir+base)

# load data and create zero DataArray
da = ds['LFR']
ds['LFR'] = da.copy(data=np.full_like(da, 0.))

# generate output filenames based on the date range
dr = pd.date_range(st, et, freq=str(dt)+'T')
filenames = [d.strftime(f'{base[:10]}_%Y-%m-%d_%H:%M:%S') for d in dr]


# create files (zero values) based on filenames
for tindex, f in enumerate(filenames):
    # generate 'Times' variable
    Times = xr.DataArray(np.array([dr[tindex].strftime('%Y-%m-%d_%H:%M:%S')], dtype=np.dtype(('S', 19))), dims=['Time'])
    ds['Times'] = Times

    ncfile = datadir + f
    print('Saving to {}'.format(ncfile))
    ds.to_netcdf(ncfile, format='NETCDF4',
                 encoding={
                          'Times': {
                             'zlib': True,
                             'complevel': 5,
                             'char_dim_name': 'DateStrLen'
                          },
                          'LFR': {'zlib': True, 'complevel': 5}
                          },
                 unlimited_dims={'Time': True})
