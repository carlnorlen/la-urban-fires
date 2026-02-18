****Urban Fire Project***
 ** Code for Parcel-scale analysis using STATA**
***creating dummy for structure category, singleresident =1 and all other = 0 (we only had 3162 structures other than single residences)**
  tab struct_cat_nu
  gen singleresidence_dummy = (struct_cat_nu== 6)
  tab singleresidence_dummy_dummy
  
  **creating dummy for race var (1= white, 0= non white)**
  gen white_dummy = ( race_cat ==1)
  tab white_dummy
  
  ***Drop lot_fraction with missing values (there were only two value points)**
   drop if missing( lot_fraction)
   
   summarize lot_fraction if !missing( lot_fraction)
   describe lot_fraction
   gen lot_fraction_num = real( lot_fraction)
   summarize lot_fraction_num
   replace lot_fraction_num = r(mean) if missing( lot_fraction_num)

*** STandardize, create z-values for parcel level data ***
	 
	 egen z_val_struct = std(val_struct)
	 egen z_over65pct = std(over65pct)
	 egen z_poptotal = std (poptotal)
	 egen z_val_struct = std (val_struct)
	 egen z_treecover2022 = std(treecover2022)
	 egen z_YearBuilt1 = std( YearBuilt1)
	 egen z_zone_zero_overlap = std(z_zone_zero_overlap)
	 egen z_zone_one_overlap_correct = std(zone_one_overlap_correct)
	 egen z_zone_two_overlap_correct = std(zone_two_overlap_correct)
	 
	 egen (structurebasalarea) =  std(structurebasalarea)
	 egen (z_fireexposed1910to2023) = std(fireexposed1910to2023)
	 egen (z_single_res) = std(z_single_res)
	 
	 ***Create summary data for each fire***
	 
	 summarize over65pct poptotal white_race val_struct treecover2022 zone_zero_overlap zone_one_overlap_correct zone_two_overlap_correct structurebasalarea fireexposed1910to2023 YearBuilt1 single_res if Fire_Name == "Eaton"
	 
	 	 
	 summarize over65pct poptotal white_race val_struct treecover2022 zone_zero_overlap zone_one_overlap_correct zone_two_overlap_correct structurebasalarea fireexposed1910to2023 YearBuilt1 single_res if Fire_Name == "Palisades"
	  
	 ***Implement Logistic Regression***
	 logit Destroy_Bin z_over65pct z_poptotal z_val_struct z_treecover2022 z_YearBuilt1 z_zone_zero_overlap z_zone_one_overlap_correct z_zone_two_overlap_correct z_structurebasalarea z_fireexposed1910to2023 z_single_res if Fire_Name == "Eaton"
	 
	  estat ic 
	 
	 
	logit Destroy_Bin z_over65pct z_poptotal z_val_struct z_treecover2022 z_YearBuilt1 z_zone_zero_overlap z_zone_one_overlap_correct z_zone_two_overlap_correct z_structurebasalarea z_fireexposed1910to2023 z_single_res if Fire_Name == "Palisades"

	  estat ic 
	 
	 
	 
	 

