# INPUT:
#       ENTLN DATA
#       WPS GEO DATA
#
# OUTPUT:
#       LDA WRFINPUT FILES EVERY DELTA MINS
#
# UPDATE:
#       Xin Zhang
#           10/19/2019 : basic
#           02/12/2020 : support constant iccg_ratio

import os, glob, copy
import numpy as np
import pandas as pd
import xarray as xr
from datetime import datetime
from satpy.scene import Scene
from satpy.utils import debug_on
from pyresample import create_area_def
from pyresample.geometry import AreaDefinition, SwathDefinition

#debug_on()
os.environ['PPP_CONFIG_DIR'] = '/yin_raid/xin/satpy_config/'

# --------------- set paras --------------- #
# -----date---- #
yyyy = 2019
mm = 7
dd = 25
minhour = 0
maxhour = 12
delta = 5  # unit: mintues

# ----entln---- #
ic_de = 0.50  # the detection efficiency of IC flash
cg_de = 0.95  # the detection efficiency of CG flash
only_cg = True  # Only input the CG data
iccg_ratio = 3  # assume IC:CG is constant, such as 3

# ----dir---- #
wps_path = '/yin_raid/xin/tmp_lfr/v4.1.4/WPS/'
entln_path = '/xin/data/ENGTLN/'
output_dir = './lda/'
domain = 'd01'

# --------------- end paras --------------- #

class entln(object):
    def __init__(self, st, et, delta):
        self.get_info()
        self.crop(st, et, delta)

    def get_info(self,):
        # read basic info from geo file generrated by WPS
        self.geo = xr.open_dataset(wps_path + 'geo_em.'+domain+'.nc')
        attrs = self.geo.attrs
        # read original attrs
        self.lat_1  = attrs['TRUELAT1']
        self.lat_2  = attrs['TRUELAT2']
        self.lat_0  = attrs['MOAD_CEN_LAT']
        self.lon_0  = attrs['STAND_LON']
        self.cenlat = attrs['CEN_LAT']
        self.cenlon = attrs['CEN_LON']
        self.i      = attrs['WEST-EAST_GRID_DIMENSION']
        self.j      = attrs['SOUTH-NORTH_GRID_DIMENSION']
        self.dx     = attrs['DX']
        self.dy     = attrs['DY']
        self.mminlu = attrs['MMINLU']
        self.map    = attrs['MAP_PROJ']
        self.eta    = attrs['BOTTOM-TOP_GRID_DIMENSION']

        # calculate attrs for area definition
        shape = (self.j, self.i)
        center = (0, 0)
        radius = (self.i*self.dx/2, self.j*self.dy/2)

        # create area as same as WRF
        area_id = 'wrf_circle'
        proj_dict = {'proj': 'lcc', 'lat_0': self.lat_0, 'lon_0': self.lon_0, \
                    'lat_1': self.lat_1, 'lat_2': self.lat_2, \
                    'a':6370000, 'b':6370000}
        self.area_def = AreaDefinition.from_circle(area_id, proj_dict, center, radius, shape=shape)

    def crop(self, st, et, delta):
        # Crop data every 'delta' and split into IC and CG
        scn = Scene(glob.glob(entln_path + 'LtgFlashPortions' + st.strftime('%Y%m%d')  + '.csv'), reader='entln')
        vname = 'timestamp' # any name in data is OK, because we just bin the counts
        scn.load([vname])

        # ---- loop through hour and delta interval ----- #
        for h in range(st.hour, et.hour):
            for m in range(0, 60, delta):
                # 1. -----Crop by delta----- #
                timestamp = scn[vname].timestamp.values.astype('datetime64[s]')
                if m+delta < 60:
                    cond = (timestamp >= st.replace(hour=h, minute=m)) & (timestamp < st.replace(hour=h, minute=m+delta))
                else:
                    cond = (timestamp >= st.replace(hour=h, minute=m)) & (timestamp < st.replace(hour=h+1, minute=0))

                # 2. -----Crop by type ----- #
                self.ic = copy.deepcopy(scn)
                self.cg = copy.deepcopy(scn)
                cond_cg = (scn[vname].type != 1) & (cond)
                cond_ic = (scn[vname].type == 1) & (cond)

                self.cg[vname] = self.cg[vname][cond_cg]
                # if we only use CG data, IC is eaual to CG here
                #   and the constant ratio: IC/CG = iccg_ratio is used later
                if only_cg:
                    self.ic[vname] = self.ic[vname][cond_cg]
                else:
                    self.ic[vname] = self.ic[vname][cond_ic]

                # Correct attrs
                area_ic = SwathDefinition(lons=self.ic[vname].coords['longitude'], \
                                          lats=self.ic[vname].coords['latitude']
                                          )
                area_cg = SwathDefinition(lons=self.cg[vname].coords['longitude'], \
                                          lats=self.cg[vname].coords['latitude']
                                          )
                self.correct_attrs(self.ic, area_ic, vname)
                self.correct_attrs(self.cg, area_cg, vname)

                # 3. -----Crop by WRF_grid ----- #
                self.resample_WRF()
                if only_cg:
                    self.tl = (self.ic[vname]*iccg_ratio + self.cg[vname]) / cg_de
                else:
                    self.tl = self.ic[vname]/ic_de + self.cg[vname]/cg_de
                self.save(vname, h, m)
                #break
            #break

    def correct_attrs(self, scn_data, area, vname):
        # Because resample method reads the area and other from attrs,
        # We need to set them with the same condition
        scn_data[vname].attrs['area'] = area
        scn_data[vname].attrs['start_time'] = scn_data['timestamp'].values[0]
        scn_data[vname].attrs['end_time'] = scn_data['timestamp'].values[-1]


    def resample_WRF(self,):
        self.ic = self.ic.resample(self.area_def, resampler='bucket_count')
        self.cg = self.cg.resample(self.area_def, resampler='bucket_count')

    def save(self, vname, h, m):
        t = self.ic[vname].attrs['start_time']
        tstr = pd.to_datetime(str(t)).strftime('%Y-%m-%d_{}:{}:00'.format(str(h).zfill(2), str(m).zfill(2)))
        ncfile = output_dir + 'wrflda_' + domain +'_' + tstr

        Times = xr.DataArray(np.array([tstr], dtype = np.dtype(('S', 19))), dims = ['Time'])

        # Because xarray's coordinates strat from upper left
        # and WRF's grids strat from lower left
        # We need to flip the y-axis.
        LDACHECK=xr.DataArray(np.fliplr(self.tl.values[np.newaxis, ...].astype('f4')),
                             dims = ['Time', 'south_north', 'west_east'],
                             attrs = {'FieldType': np.int32(104), 'MemoryOrder': 'XY', \
                                      'description': 'LDACHECK', 'units':'', 'stagger':''},
                             )

        # create the dataset
        ds = xr.Dataset({'Times':Times, \
                         'LDACHECK':LDACHECK, \
                        },
                         attrs={'TITLE': 'Created by Xin Zhang {}'.format(datetime.utcnow()),
                                'WEST-EAST_GRID_DIMENSION': self.i, \
                                'SOUTH-NORTH_GRID_DIMENSION': self.j, \
                                'BOTTOM-TOP_GRID_DIMENSION': self.eta, \
                                'DX': self.dx, 'DY': self.dy, \
                                'CEN_LAT': self.cenlat, 'CEN_LON': self.cenlon, \
                                'TRUELAT1': self.lat_1, 'TRUELAT2': self.lat_2, \
                                'MOAD_CEN_LAT': self.lat_0, 'STAND_LON': self.lon_0, \
                                'MAP_PROJ': self.map, 'MMINLU': self.mminlu}
                        )

        # save dataset to nc file
        print ('Saving to {}'.format(ncfile))
        os.makedirs(output_dir, exist_ok=True)
        ds.to_netcdf(ncfile, format='NETCDF4',
                     encoding={
                              'Times': {
                                 'zlib':True,
                                 'complevel':5,
                                 'char_dim_name':'DateStrLen'
                              },
                               'LDACHECK': {'zlib':True, 'complevel':5}
                              },
                     unlimited_dims={'Time':True})


if __name__ == '__main__':
    st = datetime(yyyy, mm, dd, minhour)
    et = datetime(yyyy, mm, dd, maxhour)
    entln(st, et, delta)

