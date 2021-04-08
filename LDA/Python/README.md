These are rewritten Python scripts by Xin Zhang based on Yunyao's IDL codes.

- create_lda.py

  Create the LDA input file

- create_zero.py

  Generate the LDA file with zero lightning flashes

- damping.py

  Set grid where no lightning happens to constant value (-1)

```
NOTE: The new LDA codes are based on WRFV4.1.4. If you are not using WRFV4.1.4, do not copy the .F files. You can search "LDA" in every .F files, and add the LDA related codes to your WRF.

Part one: WRF CODE

(1) Copy Registry.EM, Registry.EM_COMMON, Registry.EM_CHEM to Registry/
(2) copy solve_em.F to dyn_em/
(3) copy module_microphysics_driver.F, module_lda.F, Makefile to phys/
(4) Then you can configure and compile.
(5) before you run wrf, adding the following lines in your namelist.input 
 &time_control
 io_form_auxinput8                   = 2,
 frames_per_auxinput8                = 1, 1, 1,
 auxinput8_inname                    = 'wrflda_d<domain>_<date>',
 auxinput8_interval_m                = 10, 10, 60,
 auxinput8_begin_h                   = 4,4,
 auxinput8_end_h                     = 5,5,

 &physics:
  lda_opt             = 1,
  lda_start_h         = 4,
  lda_start_min       = 0,
  lda_end_h           = 6,
  lda_end_min         = 0,
  ldaa   	      = 0.93,
  ldab  	      = 0.2,
  ldac   	      = 0.001,
  ldad   	      = 0.25,
  ldarhmax            = 1.03,
  ldatmin   	      = 263.15,
  ldatmax  	      = 290.15,
  ldarhtd             = 0.95,
  ldarhtd_damp        = 0.75,
  lda_flash_min       = 200,
ldap, ldab, ldac, ldad are 4 LDA coefficients. Usually I only change a, b, and c.
lda_start_h, lda_start_min, lda_end_h, lda_end_min are time control parameters of LDA.
ldatmin and ldatmax control the layer where you add water. here I add water in the layer where 263.15K< T< 290.15K
ldarhmax control the uplimit of relative humidity. If qv is greater than ldarhmax*qs, then qv is set to ldarhmax*qs
ldarhtd: If qv/qs is higher than ldarhtd, then LDA will not applied to this grid.
ldarhtd_damp is the uplimit of relative humidity in the damping area. If you don't do damping you can ignore this.
lda_flash_min: only assimilate high flash rate updraft region. This is the lower limit of flashes used in the LDA.

Note: 
(1) In the new LDA version, flashes data are read automatically by WRF. So now you do not need to make any changes in the codes.
(2) Your model timestep should be a divisor of LDA interval (auxinput8_interval_m).

Part Two: Prepare LDA flashes data.
(1) Install necessary Python packages.
(2) Change line 28-45 in create_lda.py.
(3) run create_lda.py, then you will get wrflda_d<domain>_<date>
(4) If you don't have lightning data during some periods, you can run create_zero.py.
(5) If you want to do LDA damping, you can run damping.py
(6) put wrflda_d<domain>_<date> under your test/em_real/

Note: Before running WRF-LDA-LFR, you can use ncview to check the gridded flashes data in wrflda_d<domain>_<date>
```

