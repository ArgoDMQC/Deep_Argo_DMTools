# Deep_Argo_Tools
This repository contains tools to process deep-Argo floats in delayed-mode

- **DM_CPCor**
  
This matlab code gives a refined estimate of CPcor_new for a float by comparing a Deep-Argo profile to a reference profile (e.g. deployment CTD casts). Algorithm is based on Brian King's m is based on Brian King's one. The refined CPcor value can be used in delayed mode to correct a pressure-dependant salinity bias for the Deep Argo floats. See Quality Control Manual, section 3.8 for more details.

- **Deep_CTD_selection**
  
This code can be swapped into OWC to select only reference CTD deeper than a set pressure level.
