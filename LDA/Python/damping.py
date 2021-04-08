'''
INPUT:
       ENTLN DATA
       WPS GEO DATA

OUTPUT:
       DAMPING LDA WRFINPUT FILES (VALUE = -1)

UPDATE:
       Xin Zhang     10/21/2019
'''

import xarray as xr
import numpy as np
from datetime import datetime, timedelta
from numba import jit

lda_dir = './lda/'
st = datetime(2019, 7, 25, 5, 30)
et = datetime(2019, 7, 25, 6, 0)
delta = 10  # units: min
domain = 'd01'

# If there are flashes within effdx and effdy distance, then no damping
effdx = 10000  # m; If there are flashes within effdx distance, then no damping
effdy = 10000  # m;


def datetime_range(start, end, delta):
    current = start
    while current < end:
        yield current
        current += delta


@jit(nopython=True)
def damp(nj, ni, effgridx, effgridy, ldaflashtemp):
    # damping where's no flash and outside the storm region (outside effdx and effdy)
    i = 0
    while i < ni:
        j = 0
        while j < nj:
            if ldaflash[i, j] > 0:
                imin = max(0, i - effgridx)
                imax = min(ni-1, i + effgridx)
                jmin = max(0, j - effgridy)
                jmax = min(nj-1, j + effgridy)
                ldaflashtemp[jmin:jmax, imin:imax] = 0
                j = j + effgridy
            else:
                j = j + 1
        i = i + 1


files = [lda_dir + dt.strftime('wrflda_{}_%Y-%m-%d_%H:%M:00'.format(domain))
         for dt in datetime_range(st, et, timedelta(minutes=delta))]

for f in files:
    print('Damping {}'.format(f))
    ds = xr.open_dataset(f)
    nj = ds.attrs['SOUTH-NORTH_GRID_DIMENSION']
    ni = ds.attrs['WEST-EAST_GRID_DIMENSION']
    dx = ds.attrs['DX']
    dy = ds.attrs['DY']
    ldaflash = ds.LDACHECK[0, ...].values

    ldaflashtemp = np.zeros((nj, ni)) - 1
    effgridx = int(effdx/dx) + 1
    effgridy = int(effdy/dy) + 1

    damp(nj, ni, effgridx, effgridy, ldaflashtemp)
    ldaflash[ldaflashtemp == -1] = -1

    ds['LDACHECK'].values = ldaflash[np.newaxis, ...].astype('f4')
    print(ds.Times)
    ds.close()
    ds.to_netcdf(f, format='NETCDF4', mode='w')
