MODULE module_lda
!      lightning assimilation subroutine following Fierro et al. (2012, MWR)
!      update: Yunyao Li 05/12/2016

CONTAINS
!===================================================================
!
  SUBROUTINE lda(qv, qg, p, t  &
                 ,ldacheck  &
                 ,itt, jtt, ktt  &
                 ,ldaa, ldab, ldac, ldad, ldarhmax    &
                 ,ldarhtd, ldatmin, ldatmax            &
                 ,ldarhtd_damp, lda_flash_min           &
                )
!-------------------------------------------------------------------
  IMPLICIT NONE
!-------------------------------------------------------------------
  INTEGER,      INTENT(IN   )    ::   itt,jtt,ktt
  REAL qv(itt,ktt,jtt) ! in kg/kg
  REAL qg(itt,ktt,jtt) ! in kg/kg
  REAL t(itt,ktt,jtt) ! in deg Kelvin
  REAL p(itt,ktt,jtt) ! in Pa
  REAL ldacheck(itt,jtt)
  INTEGER :: i,j,k
  REAL, INTENT(IN) ::ldaa,ldab,ldac,ldad,lda_flash_min &
             ,ldarhmax,ldarhtd,ldatmin,ldatmax,ldarhtd_damp
  REAL :: qs,es, angle

!------------------------------------
!CALCULATION
!-----------------------------------
      DO j=1,jtt
         DO i=1,itt
         DO k=1,ktt
! Calculate qs
           es = 611.2*exp(17.67*(t(i,k,j)-273.15)/((t(i,k,j)-273.15)+243.5))
           qs = 0.622*es/p(i,k,j)
           if (ldacheck(i,j).gt.lda_flash_min) then
! If Qg >= 3 g/kg no action
             if (qg(i,k,j).lt.0.003) then
! if ambient Qvapor already  >= 95% of env qsat no action
               if (qv(i,k,j).lt.ldarhtd*qs) then
! increase Qv between ldatmin and ldatmax only 
                 if (t(i,k,j).lt.ldatmax.and.t(i,k,j).gt.ldatmin) then
                   angle=((1000*qg(i,k,j))**2.2)
                   qv(i,k,j)=ldaa*qs+ldab*qs*tanh(ldac*ldacheck(i,j))*(1-tanh(ldad*angle))
!                   write(*,*)'qv ok1'
                   if (qv(i,k,j)/qs.gt.ldarhmax) then
                     qv(i,k,j)=ldarhmax*qs
                   endif
                   write(*,*)'qv ok2' 
                 endif
               endif
             endif
           else if (ldacheck(i,j).lt.0) then
             if (qv(i,k,j).gt.ldarhtd_damp*qs) then
               qv(i,k,j)=ldarhtd_damp*qs
               write(*,*)'damp ok'
             endif
           else if (ldacheck(i,j).eq.0) then
             qv(i,k,j)=qv(i,k,j)
           endif
         ENDDO
         ENDDO
      ENDDO
    RETURN
  END SUBROUTINE lda
END MODULE module_lda

