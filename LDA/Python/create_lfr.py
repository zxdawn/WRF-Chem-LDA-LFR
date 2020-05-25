#INPUT:
#       ENTLN DATA
#       WPS GEO DATA
#
#OUTPUT:
#       LDA WRFINPUT FILES EVERY DELTA MINS
#
#UPDATE:
#       Xin Zhang     10/19/2019
#

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
#os.environ['PPP_CONFIG_DIR'] = '/xin/scripts/satpy_config'

# --------------- set paras --------------- #
# -----date---- #
yyyy = 2019
mm = 7
dd = 25
minhour = 0
maxhour = 12
delta = 10  # unit: mintues
# ----entln---- #
ic_de = 0.50
cg_de = 0.95
# ----dir---- #
#wps_path = '/public/home/zhangxin/bigdata/WRF/wrf_3.7.1/WPS/'
wps_path = '/yin_raid/xin/tmp_lfr/v4.1.4/WPS/'
#entln_path = '/xin/data/ENTLN/2019/'
#entln_path = '/xin/data/CLDN/'
entln_path = '/xin/data/ENGTLN/'
output_dir = './lfr/'
domain = 'd01'

wrf_projs = {1: 'lcc',
             2: 'npstere',
             3: 'merc',
             6: 'eqc'
             }

class entln(object):
    def __init__(self, st, et, delta):
        self.get_info()
        self.crop(st, et, delta)

    def get_info(self,):
        # read basic info from geo file generrated by WPS
        self.geo = xr.open_dataset(wps_path + 'geo_em.'+domain+'.nc')
        attrs = self.geo.attrs

        self.map = attrs['MAP_PROJ']
        self.mminlu = attrs['MMINLU']
        self.moad_cen_lat = attrs['MOAD_CEN_LAT']

        self.dx = attrs['DX']
        self.dy = attrs['DY']
        self.stand_lon = attrs['STAND_LON']
        self.lon_0 = attrs['CEN_LON']
        self.lat_0 = attrs['CEN_LAT']
        self.lat_1 = attrs['TRUELAT1']
        self.lat_2 = attrs['TRUELAT2']
        self.eta = attrs['BOTTOM-TOP_GRID_DIMENSION']
        self.i = attrs['WEST-EAST_GRID_DIMENSION'] - 1 
        self.j = attrs['SOUTH-NORTH_GRID_DIMENSION'] - 1 

        # calculate attrs for area definition
        shape = (self.j, self.i)
        radius = (self.i*attrs['DX']/2, self.j*attrs['DY']/2)

        # create area as same as WRF
        area_id = 'wrf_circle'
        proj_dict = {'proj': wrf_projs[self.map],
                     'lat_0': self.lat_0,
                     'lon_0': self.lon_0,
                     'lat_1': self.lat_1,
                     'lat_2': self.lat_2,
                     'a': 6370000,
                     'b': 6370000}
        center = (0, 0)

        self.area_def = AreaDefinition.from_circle(area_id,
                                                   proj_dict,
                                                   center,
                                                   radius,
                                                   shape=shape)

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
                cond_ic = (scn[vname].type == 1) & (cond)
                cond_cg = (scn[vname].type != 1) & (cond)
                self.ic[vname] = self.ic[vname][cond_ic]
                self.cg[vname] = self.cg[vname][cond_cg]
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
                #self.tl = self.ic[vname]/ic_de + self.cg[vname]/cg_de
                self.tl = 4*(self.cg[vname]/cg_de)/(60*delta) # IC/CG = 3, unit: #/s
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
        ncfile = output_dir + 'wrflfr_' + domain +'_' + tstr

        Times = xr.DataArray(np.array([tstr], dtype = np.dtype(('S', 19))), dims = ['Time'])

        # Because xarray's coordinates strat from upper left
        # and WRF's grids strat from lower left
        # We need to flip the y-axis.
        lfr=xr.DataArray(np.fliplr(self.tl.values[np.newaxis, ...].astype('f4')),
                             dims = ['Time', 'south_north', 'west_east'],
                             attrs = {'FieldType': np.int32(104), 'MemoryOrder': 'XY', \
                                      'description': 'lightning flash rate data', 'units':'', 'stagger':''},
                             )

        # create the dataset
        ds = xr.Dataset({'Times':Times, \
                         'LFR':lfr, \
                        },
                         attrs={'TITLE': 'OUTPUT FROM V4.1, Created by Xin Zhang {}'.format(datetime.utcnow()), 
                                'WEST-EAST_GRID_DIMENSION': self.i+1, \
                                'WEST-EAST_PATCH_END_UNSTAG': self.i, \
                                'SOUTH-NORTH_GRID_DIMENSION': self.j+1, \
                                'SOUTH-NORTH_PATCH_END_UNSTAG': self.j, \
                                'BOTTOM-TOP_GRID_DIMENSION': self.eta, \
                                'DX': self.dx, 'DY': self.dy, \
                                'CEN_LAT': self.lat_0, 'CEN_LON': self.lon_0, \
                                'TRUELAT1': self.lat_1, 'TRUELAT2': self.lat_2, \
                                'MOAD_CEN_LAT': self.moad_cen_lat, 'STAND_LON': self.stand_lon, \
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
                               'LFR': {'zlib':True, 'complevel':5}
                              },
                     unlimited_dims={'Time':True})


if __name__ == '__main__':
    #os.environ['PPP_CONFIG_DIR'] = '/xin/scripts/satpy_config/etc/'
    st = datetime(yyyy, mm, dd, minhour)
    et = datetime(yyyy, mm, dd, maxhour)
    entln(st, et, delta)

