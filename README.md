# DM_CPcor : Obtain a refined estimate of Cpcor_new in delayed mode
This matlab code gives a refined estimate of CPcor_new for a float by comparing a Deep-Argo profile to a reference profile
(e.g. deployment CTD casts). Algorithm is based on Brian King's one. 
The refined CPcor value can be used in delayed mode to correct a pressure-dependant salinity bias for the Deep Argo floats.
See [Quality Control Manual, section 3.8](https://archimer.ifremer.fr/doc/00228/33951/) for more details.



 ## HOW TO USE?
  
  You will need [GSW matlab routines](https://github.com/TEOS-10/GSW-Matlab/tree/master/Toolbox) as well as interp_climatology.m, which is an  [OW routine](https://github.com/ArgoDMQC/matlab_owc/blob/master/matlab_codes/interp_climatology.m)
  

 - Example data are provided in the repository for float 6901601 :
  
  `ex_6901601_float_data.mat` contains the first Argo ascending or descending profile you want to compare with the reference profile:  
  <pre>
         (1xN_LEVELS)             psal_argo, temp_argo, pres_argo, from PSAL, TEMP and PRES variables in the netcdf file, with bad QCS removed (i.e. NaN values)  
         (1xN_LEVELS, optional)   tempad_argo, presad_argo, from TEMP_ADJUSTED and PRES_ADJUSTED variables in the netcdf file, if available (e.g pressure surface offset correction has been applied) 
         (1x1)                    lon_argo, lat_argo  from  LONGITUDE, LATITUDE  variables in the netcdf file
  </pre>

  `ex_6901601_ref_data.mat` contains the reference profile (e.g deployment CTD):  
  <pre>
         (1xN_LEVELS2)  psal_ref, temp_ref, pres_ref,  
         (1x1)          lon_ref, lat_ref  
    </pre>
  - `[CPcor_new, M_new] = COMPUTE_new_cpcor_brian(6901601)`  will give the refined estimate of CPcor value (CPcor_new) and a conductivity cell gain factor (M_new)

The following figure gives the result obtained for the float 6901601. CPcor_SBE is the nominal CPcor value provided by SBE, CPcor_new is the refined estimate and CPcor_new (default) is the new CPcor value that can be used for Deep SBE-41CP data if no other information is available in delayed mode.

![6901601](https://user-images.githubusercontent.com/38859979/111129069-f0a5d600-8575-11eb-8e96-d7be5439607d.png)
