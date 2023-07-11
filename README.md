# Deep_CTD_selection
This code can be swapped into OWC to select only reference CTD deeper than a set pressure level. 

To use this code, swap 'update_salinity_mapping.m' in your current OWC code with 'update_salinity_mapping_ow_deep.m'.  The other Matlab files and the bsn.mat file support this main function.

To set the minimum depth at which you want to start selecting below, change the 'mindepth' value when 'find_besthist_deep.m' is called.  
For example, here is the function call for find_besthist_deep within 'update_salinity_mapping_ow_deep.m'.  The current value of the minimum pressure to search under is the last input variable and is set at 3000:

[ index ] = find_besthist_deep( la_grid_lat, la_grid_long, la_grid_dates, la_grid_Z,la_grid_maxpres, LAT, LONG2, DATES, Z,...
        latitude_large, latitude_small, longitude_large, longitude_small, phi_large, phi_small,...
        map_age,map_age_large, map_use_pv, ln_max_casts, 3000 );
        
If you want to change it to shallower or deeper, adjust the '3000' to the desired pressure level.
