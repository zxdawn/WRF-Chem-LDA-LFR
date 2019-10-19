;+
; NAME: rd_entln0
;   
; PURPOSE: Read in ENTLN data from a particular day. 
;   
; CALLING SEQUENCE:
;
; NOTES:  ENTLN (Earth Networks Total Lightning Network) 
;         Christopher D. Sloop (CSloop@earthnetworks.com) 
;   
; INPUT PARAMETERS (POSITIONAL):
;   
; INPUT PARAMETERS (KEYWORD) 
;   dd0:  	Base Directory containing input data set
;   yyyymmdd	Desired date (YYYYMMDD)
;   
;   
;   
; OUTPUTS
;   amplitude   Estimate peak amplitude (KAmps)
;
; OUTPUT PARAMETERS (KEYWORD)
;   nobs	long		Number of observations
;   lonts	fltarr(nobs) 	Decimal longitude
;   latts	fltarr(nobs)	Decimal latitude
;   stroke_type strarr(nobs)	Stroke type (0=CG, 1=IC) 
;   height	fltarr(nobs)	Height of flash (meters)
;   adate	strarr(nobs)	Date of flashes (YYYYMMDD)
;   utc		strarr(nobs)	Time of flashes (HHMMSS) 
;   frac	dblarr(nobs)	Fractional day (0 to 1). 
;     
;       
; MODIFICATION HISTORY: First version: 11 Sep 2013 
;-
function rd_entln0,dd0=dd0,yyyymmdd=yyyymmdd,nobs=nobs,$
 lonts=lonts,latts = latts,stroke_type=stroke_type,height=height,$
 adate=adate,utc=utc,frac=frac,hh0=hh0,mm0=mm0,ss0=ss0

if n_elements(dd0) eq 0 then dd0 = '/aosc/eos14/aring/ENTLN/'
if n_elements(yyyymmdd) eq 0 then yyyymmdd = '20090202'

yyyy = strmid(yyyymmdd,0,4) 
dd = dd0 + yyyy + '/' 

dsn = 'LtgFlashPortions' + yyyymmdd + '.csv' 

openr,ilun,dd+dsn,/get_lun
stuff =  ' '
readf,ilun,stuff 
svariable = str_sep(stuff,',') 

i_utc0   = where(svariable eq 'Lightning_Time_String',cc) & i_utc0 = i_utc0(0) & if (cc eq 0) then message,'Time not found'
i_lat    = where(svariable eq 'Latitude',cc)       & i_lat = i_lat(0) & if (cc eq 0) then message,'Latitude not found'
i_lon    = where(svariable eq 'Longitude',cc)      & i_lon = i_lon(0) & if (cc eq 0) then message,'Longitude not found'
i_ht     = where(svariable eq 'Height',cc)         & i_ht = i_ht(0) & if (cc eq 0) then message,'Height not found'
i_stroke = where(svariable eq 'Stroke_Type',cc)    & i_stroke = i_stroke(0) & if (cc eq 0) then message,'Stroke Type not found'
i_amp    = where(svariable eq 'Amplitude',cc)      & i_amp = i_amp(0) & if (cc eq 0) then message,'Amplitude not found'

obsmax = 7000000l 
utc = strarr(obsmax) 
stroke_type = lonarr(obsmax) 
lonts = fltarr(obsmax) & latts = lonts & amplitude = lonts 
height = lonts
frac = dblarr(obsmax) 

nobs = 0l
while (not eof(ilun)) do  begin
   readf,ilun,stuff
   field = str_sep(stuff,',')
   
   utc0 = field(i_utc0)
   hh0 = strmid(utc0,11,2)
   mm0 = strmid(utc0,14,2)
   ss0 = strmid(utc0,17,2) 
   fsec0 = strmid(utc0,20,6)
   utc(nobs) = hh0+mm0+ss0

   latts(nobs) = field(i_lat)
   lonts(nobs) = field(i_lon) 
   height(nobs) = field(i_ht) 
   stroke_type(nobs) = field(i_stroke)
   amplitude(nobs) = float(field(i_amp))*0.001
   frac(nobs)  = (3600d*long(hh0) + 60d*long(mm0) + long(ss0) + long(fsec0)*0.000001)/86400d   
  
   nobs = nobs + 1l 
end 
free_lun,ilun

amplitude = amplitude(0:nobs-1) & lonts = lonts(0:nobs-1)
latts = latts(0:nobs-1) & height = height(0:nobs-1) 
stroke_type = stroke_type(0:nobs-1) 
utc = utc(0:nobs-1) & frac = frac(0:nobs-1) 

adate = replicate(yyyymmdd,nobs)

return,amplitude
end  
