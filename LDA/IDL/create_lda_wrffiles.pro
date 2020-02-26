;+
;NAME:  CREATE_LDA_WRFFILES.PRO
;
;INPUT:         
;		ENTLN DATA
;		WRFINPUT 
;
;OUTPUT:        10MIN LDA WRFINPUT FILES
;
;UPDATE:
;               LYY     04/20/2016

; Begin of Main Program
;############################################################################
;USER MODIFIED
wrfinput_file = '/public/home/zhangxin/bigdata/WRF/results/1km_Lin_60eta/wrfout_d01_2019-07-24_18:00:00'
entln_dir = '/xin/data/ENTLN/'
output_dir = './'
yyyy = '2019'
mm = '07'
dd = '25'
minhour = 3 ;15     ; which hours of the day emissions should be created
maxhour = 0 ;21
lonboxmin = 117 ;-90
lonboxmax = 121 ;-83
latboxmin = 30 ;32
latboxmax = 35 ;39
invmin = 10
domain = 'd01'

;end of user modified
;##############################################################################
;================1. create netcdf wrf file===============
; get infomation from wrfinput file

id = ncdf_open(wrfinput_file)

ncdf_attget,id,'DX',dx,/GLOBAL
ncdf_attget,id,'WEST-EAST_GRID_DIMENSION',wrf_ii,/GLOBAL
ncdf_attget,id,'SOUTH-NORTH_GRID_DIMENSION',wrf_jj,/GLOBAL
ncdf_attget,id,'BOTTOM-TOP_GRID_DIMENSION',eta_dim,/GLOBAL
;;; GGP
ncdf_attget,id,'CEN_LAT',cen_lat,/GLOBAL
ncdf_attget,id,'CEN_LON',cen_lon,/GLOBAL
ncdf_attget,id,'STAND_LON',stand_lon,/GLOBAL
ncdf_attget,id,'TRUELAT1',truelat1,/GLOBAL
ncdf_attget,id,'TRUELAT2',truelat2,/GLOBAL
ncdf_attget,id,'MAP_PROJ',map_proj,/GLOBAL
ncdf_attget,id,'MOAD_CEN_LAT',moad_cen_lat,/GLOBAL
ncdf_varget,id,'XLONG',dloncen0
ncdf_varget,id,'XLAT',dlatcen0
ncdf_close,id

ilmm = wrf_ii - 1
ijmm = wrf_jj - 1

dloncen0 = dloncen0(*,*,0) & dlatcen0 = dlatcen0(*,*,0)

;--------------------------add one out circle-------------
dlat=(max(dlatcen0)-min(dlatcen0))/(ijmm-1.0)
dlon=(max(dloncen0)-min(dloncen0))/(ilmm-1.0)
dlatcen=fltarr(ilmm+2,ijmm+2)
dloncen=fltarr(ilmm+2,ijmm+2)
for i=1,ilmm do begin
  for j=1,ijmm do begin
    dlatcen(i,j)=dlatcen0(i-1,j-1)
    dloncen(i,j)=dloncen0(i-1,j-1)
  endfor
endfor
for j=1,ijmm do begin
  dlatcen(0,j)=dlatcen0(0,j-1)-dlat
  dlatcen(ilmm+1,j)=dlatcen0(ilmm-1,j-1)+dlat
  dloncen(0,j)=dloncen0(0,j-1)
  dloncen(ilmm+1,j)=dloncen0(ilmm-1,j-1)
endfor
for i=1,ilmm do begin
  dloncen(i,0)=dloncen0(i-1,0)-dlon
  dloncen(i,ijmm+1)=dloncen0(i-1,ijmm-1)+dlon
  dlatcen(i,0)=dlatcen0(i-1,0)
  dlatcen(i,ijmm+1)=dlatcen0(i-1,ijmm-1)
endfor
dloncen(0,0)=dloncen0(0,0)-dlon
dloncen(0,ijmm+1)=dloncen0(0,ijmm-1)+dlon
dloncen(ilmm+1,0)=dloncen0(ilmm-1,0)-dlon
dloncen(ilmm+1,ijmm+1)=dloncen0(ilmm-1,ijmm-1)+dlon
dlatcen(0,0)=dlatcen0(0,0)-dlat
dlatcen(ilmm+1,0)=dlatcen0(ilmm-1,0)+dlat
dlatcen(0,ijmm+1)=dlatcen0(0,ijmm-1)-dlat
dlatcen(ilmm+1,ijmm+1)=dlatcen0(ilmm-1,ijmm-1)+dlat
;-----------------------------END ADD CIRCLE----------------------
;=============================READ ENTLN DATA=====================
amplitude = rd_entln0(yyyymmdd=yyyy+mm+dd,nobs=nobs,dd0=entln_dir, $
                        lonts=lonts,latts=latts,stroke_type=stroke_type,height=height,$
                        adate=adate,utc=utc,frac=frac,hh0=hh0,mm0=mm0,ss0=ss0)
;timestring 
ntime = (maxhour-minhour+1)*60/invmin
time_hour = timegen(ntime,units='Minutes',start=julday(long(mm),long(dd),long64(yyyy),minhour,00,00),step_size=invmin)
caldat,time_hour,Month, Day, Year, Hour, Minute, Second
shour = strtrim(Hour,2)
ah = where(Hour lt 10,c1)
if (c1 gt 0) then begin
  shour(ah) = '0'+shour(ah)
endif
smin = strtrim(Minute,2)
am = where(Minute lt 10)
smin(am) = '0'+smin(am)
timestring0 = yyyy+'-'+mm+'-'+dd+'_'+shour+':'+smin+':00'
file_out = 'wrflda_'+domain+'_'+timestring0
ncfiles = output_dir + file_out
print,ncfiles
;=============================TIME PERIOD=========================
;---
cgflash = fltarr(ilmm,ijmm,ntime)
icflash = fltarr(ilmm,ijmm,ntime)
flashhr = long(strmid(utc,0,2))
itime = 0
for ih = 0,maxhour-minhour do begin
  print,ih
  iflash = 0
  aa = where(flashhr eq long(shour(ih*6)),counthr)
  lonhr = lonts(aa)
  lathr = latts(aa)
  typehr = stroke_type(aa)
  utchr = utc(aa)
  flashmin = long(strmid(utchr,2,2))
  for im = 0,5 do begin
;print,ih,im
    bb = where((flashmin ge long(smin(im))) and (flashmin lt long(smin(im+1))),countmin)
    lonmm0 = lonhr(bb)
    latmm0 = lathr(bb)
    typemm0 = typehr(bb)
;within storm box1 an box2
 xx = where((lonmm0 ge lonboxmin) and (lonmm0 le lonboxmax) and (latmm0 ge latboxmin) and (latmm0 le latboxmax))
    lonmm = lonmm0(xx)
    latmm = latmm0(xx)
    typemm =typemm0(xx)
;================find nearest grid==========================
;----------------1. locate in smaller region----------------
    for i=1,ilmm do begin
      for j=1,ijmm do begin
        cc = where((lonmm ge dloncen(i-1,j)) and (lonmm lt dloncen(i+1,j)) and (latmm ge dlatcen(i,j-1)) and (latmm lt dlatcen(i,j+1)),nobs1)
        if (nobs1 gt 0) then begin
          lontsb = fltarr(nobs1)
          lontsb = fltarr(nobs1)
          lontsb = lonmm(cc)
          lattsb = latmm(cc)
          typesb = typemm(cc)
        endif
;----------------end 1--------------------------------------             
        for kk=0,nobs1-1 do begin
          dd=fltarr(9)
          inum=0
;----------------9 point distance---------------------------
          for ki=i-1,i+1 do begin
            for kj=j-1,j+1 do begin
              dd(inum)=(lontsb(kk)-dloncen(ki,kj))^2+(lattsb(kk)-dlatcen(ki,kj))^2
              inum=inum+1
            endfor
          endfor
;---------------aggragate-----------------------------------
          if (min(dd) eq dd(4)) then begin
            if (typesb(kk) eq 0) then begin
              cgflash(i-1,j-1,itime)=cgflash(i-1,j-1,itime)+1
              iflash = iflash+1
            endif
            if (typesb(kk) eq 1) then begin
              icflash(i-1,j-1,itime)=icflash(i-1,j-1,itime)+1
              iflash = iflash+1
            endif
;            try(iflash,0)=aa(bb(kk))     ;add aggragate info
;            try(iflash,1)=i          ;add aggragate info
;            try(iflash,2)=j          ;add aggragete info
            latmm(cc(kk))=0         ;delete point
            lonmm(cc(kk))=0         ;delete point
          endif
        endfor
      endfor
    endfor
  itime=itime+1
  endfor
endfor
totflash=cgflash/0.95+icflash/0.5
;==============create empty WRF emissions netcdf files
print, ''
print, 'Creating the following files ', ncfiles
; create wrf files.
for i = 0,ntime-1 do begin
  timestring = timestring0(i)
  emisfile = ncfiles(i)
  ncid = ncdf_create(emisfile, /clobber)

; create dimensions
  timeid = ncdf_dimdef(ncid, 'Time',/UNLIMITED)
  datestrlenid = ncdf_dimdef(ncid, 'DateStrLen',19)
  weid   = ncdf_dimdef(ncid, 'west_east',ilmm)
  snid   = ncdf_dimdef(ncid, 'south_north',ijmm)
  btid   = ncdf_dimdef(ncid, 'bottom_top',eta_dim-1)
  bstid   = ncdf_dimdef(ncid, 'bottom_top_stag',eta_dim)
  stagid = ncdf_dimdef(ncid,'lda_zdim_stag',1)
  wseid   = ncdf_dimdef(ncid, 'west_east_stag',ilmm+1)
  ssnid   = ncdf_dimdef(ncid, 'south_north_stag',ijmm+1)

; write global attributes
  ncdf_attput,ncid,/GLOBAL,/char, 'TITLE','Created by Yunyao Li'
  ncdf_attput,ncid,/GLOBAL,/long,'WEST-EAST_GRID_DIMENSION',ilmm+1
  ncdf_attput,ncid,/GLOBAL,/long,'SOUTH-NORTH_GRID_DIMENSION',ijmm+1
  ncdf_attput,ncid,/GLOBAL,/long,'BOTTOM-TOP_GRID_DIMENSION',eta_dim
  ncdf_attput,ncid,/GLOBAL,/float,'DX',dx
  ncdf_attput,ncid,/GLOBAL,/float,'DY',dx
  ncdf_attput,ncid,/GLOBAL,/float,'CEN_LAT',cen_lat
  ncdf_attput,ncid,/GLOBAL,/float,'CEN_LON',cen_lon
  ncdf_attput,ncid,/GLOBAL,/float,'TRUELAT1',truelat1
  ncdf_attput,ncid,/GLOBAL,/float,'TRUELAT2',truelat2
  ncdf_attput,ncid,/GLOBAL,/float,'MOAD_CEN_LAT',moad_cen_lat
  ncdf_attput,ncid,/GLOBAL,/long,'MAP_PROJ',map_proj
  ncdf_attput,ncid,/GLOBAL,/char,'MMINLU','MODIFIED_IGBP_MODIS_NOAH'

; define varaiable fields
  tvarid = ncdf_vardef(ncid,'Times',[datestrlenid, timeid ],/char)
  varid = ncdf_vardef(ncid, 'LDACHECK', [weid,snid, timeid], /FLOAT)
  ncdf_attput,ncid,'LDACHECK', 'FieldType',  /long, 104
  ncdf_attput,ncid,'LDACHECK', 'MemoryOrder',/char,'XY'
  ncdf_attput,ncid,'LDACHECK', 'description',/char,'LDACHECK'
  ncdf_attput,ncid,'LDACHECK', 'units',      /char,''
  ncdf_attput,ncid,'LDACHECK', 'stagger',    /char,''

  ncdf_control,ncid, /endef
; write fields
  ncdf_varput,ncid,'Times',timestring
  ncdf_close,ncid
endfor
for i = 0,ntime-1 do begin
  ncid = ncdf_open(ncfiles(i),/write)
  print,'Writing to ',ncfiles(i)
  ncdf_varput,ncid,'LDACHECK', totflash(*,*,i)
  ncdf_close,ncid
endfor               ; end of hour loop
end

