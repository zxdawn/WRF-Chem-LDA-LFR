#  Registry file, EM

#INCLUDES
include registry.dimspec
include Registry.EM_COMMON
include registry.io_boilerplate

include registry.fire
include registry.avgflx
include registry.stoch
include registry.les
include registry.cam
include registry.clm
include registry.ssib
include registry.lake
include registry.diags
include registry.afwa
include registry.sbm
include registry.bdy_perturb

# added to output 5 for ESMF
state   real   landmask            ij    misc          1     -     i0125rh05d=(interp_fcnm_imask)u=(copy_fcnm)   "LANDMASK"      "LAND MASK (1 FOR LAND, 0 FOR WATER)"  ""
state   real   lakemask            ij    misc          1     -     i012rhd=(interp_fcnm_imask)u=(copy_fcnm)      "LAKEMASK"      "LAKE MASK (1 FOR LAKE, 0 FOR NON-LAKE)"  ""

# Masked SST interpolation from the CG
#state    real   SST              ij    misc        1         -     i01245rh05d=(interp_mask_field:lu_index,iswater)f=(p2c_mask:lu_index,tslb,num_soil_layers,iswater)   "SST"              "SEA SURFACE TEMPERATURE" "K"
# Simple SST interpolation from the CG
#state    real   SST              ij    misc        1         -     i01245rh05d=(interp_mask_field:lu_index,iswater)f=(p2c)   "SST"              "SEA SURFACE TEMPERATURE" "K"
state    real   SST              ij     misc        1         -     i01245rh05d=(interp_mask_field:lu_index,iswater)   "SST"              "SEA SURFACE TEMPERATURE" "K"
state    real   SST_INPUT        ij     misc        1         -     rh   "SST_INPUT"              "SEA SURFACE TEMPERATURE FROM WRFLOWINPUT FILE" "K"
#++ LYY LDA++
state    real   LDACHECK         ij     misc        1         -   i8rh   "LDACHECK" "LDACHECK"  ""
rconfig  real   LDAA            namelist,physics     1    0.95    rh      "LDA_A"  "LDA_A"  ""
rconfig  real   LDAB            namelist,physics     1    0.2     rh      "LDA_B"  "LDA_B"  ""
rconfig  real   LDAC            namelist,physics     1    0.01     rh      "LDA_C"  "LDA_C"  ""
rconfig  real   LDAD            namelist,physics     1    0.25     rh      "LDA_D"  "LDA_D"  ""
rconfig  real   LDARHMAX       namelist,physics     1    0        rh      "LDA_RH_MAX" "LDA_RH_MAX" ""
rconfig  real   LDARHTD         namelist,physics     1    0.95     rh      "LDA_RH_THRESHOLD"  "LDA_RH_THRESHOLD"  ""
rconfig  real   LDATMIN         namelist,physics     1    253.15   rh      "LDA_TMIN"  "LDA_TMIN"  "K"
rconfig  real   LDATMAX         namelist,physics     1    273.15   rh      "LDA_TMAX"  "LDA_TMAX"  "K"
rconfig  real   LDARHTD_DAMP         namelist,physics     1    0.95     rh      "LDA_DAMP_RH_THRESHOLD"  "LDA_DAMP_RH_THRESHOLD"  ""
rconfig  integer   LDA_OPT         namelist,physics     1    0     rh      "LDA_OPT"   ""   "" 
rconfig  real   LDA_START_H        namelist,physics     1    0     rh      "LDA_START_H"   "LDA_START_H"   ""
rconfig  real   LDA_START_MIN        namelist,physics     1    0     rh      "LDA_START_MIN"   "LDA_START_MIN"   ""
rconfig  real   LDA_END_H        namelist,physics     1    0     rh      "LDA_END_H"   "LDA_END_H"   ""
rconfig  real   LDA_END_MIN        namelist,physics     1    0     rh      "LDA_END_MIN"   "LDA_END_MIN"   ""
rconfig  real   LDA_FLASH_MIN       namelist,physics     1    0     rh      "LDA_FLASH_MIN"   "LDA_FLASH_MIN"  ""
#-- LYY LDA --

# Registry entries that are exclusive to Registry.EM

# Chem Scalars
rconfig   integer     chem_opt            namelist,physics	max_domains    0       rh       "chem_opt"              ""      ""
state   real    -              ikjftb   chem        1         -     -    -                                       
#
# Tracer Scalars: If you want full resolved and non-resolved dispersion, compile WRF-Chem
#
state   real    -          ikjftb  tracer        1         -     -    -                                       
state   real    tr17_1     ikjftb  tracer        1         -     irhusdf=(bdy_interp:dt)    "tr17_1"         "tr17_1"     "Dimensionless"
state   real    tr17_2     ikjftb  tracer        1         -     irhusdf=(bdy_interp:dt)    "tr17_2"         "tr17_2"     "Dimensionless"
state   real    tr17_3     ikjftb  tracer        1         -     irhusdf=(bdy_interp:dt)    "tr17_3"         "tr17_3"     "Dimensionless"
state   real    tr17_4     ikjftb  tracer        1         -     irhusdf=(bdy_interp:dt)    "tr17_4"         "tr17_4"     "Dimensionless"
state   real    tr17_5     ikjftb  tracer        1         -     irhusdf=(bdy_interp:dt)    "tr17_5"         "tr17_5"     "Dimensionless"
state   real    tr17_6     ikjftb  tracer        1         -     irhusdf=(bdy_interp:dt)    "tr17_6"         "tr17_6"     "Dimensionless"
state   real    tr17_7     ikjftb  tracer        1         -     irhusdf=(bdy_interp:dt)    "tr17_7"         "tr17_7"     "Dimensionless"
state   real    tr17_8     ikjftb  tracer        1         -     irhusdf=(bdy_interp:dt)    "tr17_8"         "tr17_8"     "Dimensionless"

package   tracer_test1  tracer_opt==2       -             tracer:tr17_1,tr17_2,tr17_3,tr17_4,tr17_5,tr17_6,tr17_7,tr17_8


 
