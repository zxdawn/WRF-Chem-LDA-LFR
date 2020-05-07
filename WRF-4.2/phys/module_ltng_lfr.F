! WRF:MODEL_LAYER:PHYSICS
!
! Assimilate lightning flash data (minutes time resolution)
!   directly without parameterization.
!
! Contact: Xin Zhang <xinzhang1215@gmail.com>
!
!**********************************************************************
! Revision History:
!   26 Feb 2020 Xin Zhang: Basic version
!**********************************************************************

 MODULE module_ltng_lfr
 CONTAINS

 SUBROUTINE readlfr ( &
                          ! Scheme specific prognostics
                            lfr,                                  &
                          ! Order dependent args for domain, mem, and tile dims
                            ids, ide, jds, jde, kds, kde,         &
                            ims, ime, jms, jme, kms, kme,         &
                            ips, ipe, jps, jpe, kps, kpe,         &
                          ! Mandatory output for all quantitative schemes
                            total_flashrate                       & 
                )
!-----------------------------------------------------------------
! Framework
 USE module_state_description

! Model layer
 USE module_model_constants
 USE module_wrf_error
 IMPLICIT NONE
!-----------------------------------------------------------------
! Scheme specific prognostics
 REAL,    DIMENSION( ims:ime,          jms:jme ), INTENT(IN   ) :: lfr !(flash/s)

! Order dependent args for domain, mem, and tile (patch) dims
 INTEGER, INTENT(IN   )    ::       ids,ide, jds,jde, kds,kde
 INTEGER, INTENT(IN   )    ::       ims,ime, jms,jme, kms,kme
 INTEGER, INTENT(IN   )    ::       ips,ipe, jps,jpe, kps,kpe

! Mandatory outputs for all quantitative schemes
 REAL,    DIMENSION( ims:ime,          jms:jme ), INTENT(  OUT) :: total_flashrate

! Local variables
 CHARACTER (LEN=250) :: message

!-----------------------------------------------------------------
! Because we just read lightning rates from file,
! we don't need to assign lfr to dBz >= *.
! IF ( maxval(cellcount(kps:kpe)) .eq. 0 ) RETURN
! Assign value directly
 total_flashrate( ips:ipe, jps:jpe ) = lfr
 END SUBROUTINE readlfr
 END MODULE module_ltng_lfr
