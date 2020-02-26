ni = 480
nj = 480
dx = 600.0 ;m
flag = 2 ;or 2
effdx = 10000.0 ;m  If there are flashes within effdx distance, then no damping
fname='./wrflda_d02_2012-05-21_20:30:00'
;============Creating damping region mask================
if (flag eq 1) then begin
  ;1. damping whole domain
  ldaflash=fltarr(ni,nj)-1
endif
if (flag eq 2) then begin
  ;2. damping where's no flash & outside the storm region (outside effdx)
  id = ncdf_open(fname)
  ncdf_varget,id,'LDACHECK',ldaflash
  ncdf_close,id
  ldaflashtemp=fltarr(ni,nj)-1
  effgrid = long64(effdx/dx)+1
  i=0
  while (i lt ni) do begin
    j=0
    while (j lt nj) do begin
      if (ldaflash(i,j) gt 0) then begin
        imin = max([0,i-effgrid])
        imax = min([ni-1,i+effgrid])
        jmin = max([0,j-effgrid])
        jmax = min([nj-1,j+effgrid])
        ldaflashtemp(imin:imax,jmin:jmax)=0
        j=j+effgrid
      endif else begin
        j=j+1
      endelse 
    endwhile
    i=i+1
  endwhile
  aa=where(ldaflashtemp eq -1,count1)
  print,count1
  if count1 gt 0 then begin
    ldaflash(aa)=-1
  endif
endif
fileID2 = ncdf_open(fname, /write)
varID=ncdf_varid(fileID2,'LDACHECK')
ncdf_varput,fileID2,varID,ldaflash
ncdf_close, fileID2

end
