****URban Fire Project***
 ** Applying the Analytic weights [aw]: standard for survey based regression**
 [aw = fireaffected_pop]
 
 ** Filter by Urban blocks and by dummy codes**
 if  UR20 == "U" & fire == 1 (Eaton)
 if  UR20 == "U" & fire == 0  (palisades)


*****Block level data, 2025******

egen all_missing = rowmiss(*)
drop if all_missing == _N
egen all_missing = rowmiss(*)
drop if all_missing == `c(k)'
drop all_missing

egen z_zone_zero_overlap_mean = std(zone_zero_overlap_mean)
egen z_zone_one_overlap_mean = std( zone_one_overlap_mean)
egen z_zone_two_overlap_mean = std( zone_two_overlap_mean)
egen z_structure_value_median = std( structure_value_median )
egen z_firearea1910to2023pct = std( firearea1910to2023pct )
egen z_structurebasalarea = std ( structurebasalarea)
egen z_yearbuiltmedian = std ( yearbuiltmedian )
egen z_propertyvaluemedian = std ( propertyvaluemedian )
egen z_post_2008_pct = std ( post_2008_pct )
egen z_treecover2022 = std ( treecover2022 )
egen z_TpctFA_male_C = std( TpctFA_male_C )
egen z_TpctFA_female_C = std( TpctFA_female_C )
egen z_TpctFA_under_5yrs_C = std( TpctFA_under_5yrs_C )
egen z_TpctFA_519_yrs_C = std( TpctFA_519_yrs_C )

egen z_TpctFA_below_20_yrs_C = std( TpctFA_below_20_yrs_C )
egen z_TpctFA_2064_yrs_C = std( TpctFA_2064_yrs_C )
egen z_TpctFA_65andover_yrs_C = std( TpctFA_65andover_yrs_C )
egen z_TpctFA_Hispanic_C = std( TpctFA_Hispanic_C )
egen z_TpctFA_not_Hispanic_C = std( TpctFA_not_Hispanic_C )
egen z_TpctFA_whitep_C = std( TpctFA_whitep_C )
egen z_TpctFA_whitep_C = std( TpctFA_whitep_C )
egen z_TpctFA_AAp_C = std( TpctFA_AAp_C )
 egen z_TpctFA_Aap_C = std( TpctFA_Aap_C )
  egen z_TpctFA_AIANp_C = std( TpctFA_AIANp_C )
   egen z_TpctFA_Ap_C = std( TpctFA_Ap_C )
    egen z_TpctNHOPIp_C = std( TpctNHOPIp_C )
	egen z_nonwhitep_C = std( nonwhitep_C )
	egen z_nonwhitep = std( nonwhitep)
	gen Tpct_Otherrace = TpctOR+ Tpct2ormore_R+ Tpct2_R
	 egen z_Tpct_Otherrace = std ( Tpct_Otherrace)
	  egen z_TpctFA_occ_C = std( TpctFA_occ_C )
	  egen z_TpctFA_vaccant_C = std( TpctFA_vaccant_C )
	  egen z_TpctFA_owner_occ_C = std( TpctFA_owner_occ_C )
	  egen z_TpctFA_renter_occ_C = std( TpctFA_renter_occ_C )
	  egen z_pct_FA_Eng_speakers_C = std ( pct_FA_Eng_speakers_C)
	  egen z_pct_FA_NonEng_speakers_C = std ( pct_FA_NonEng_speakers_C )
	  egen z_pct_FA_poverty_C = std ( pct_FA_poverty_C)

egen z_pct_FA_Bnoformaleducation_C = std ( pct_FA_Bnoformaleducation_C)
egen z_pct_FA_Bhighschool_C = std ( pct_FA_Bhighschool_C)
egen z_pct_FA_BAssociatesdegree_C = std ( pct_FA_BAssociatesdegree_C)
egen z_pct_FA_BBachelorsdegree_C = std ( pct_FA_BBachelorsdegree_C)
egen z_pct_FA_BgraduateorProfessional = std ( pct_FA_BgraduateorProfessional)
egen z_BEstimateTotalpopIncomein = std ( BEstimateTotalpopIncomein)

egen z_BGEstimateTotalpopIncomei = std ( BGEstimateTotalpopIncomei)

gen below_bachlor_degree_C = Tpct_FA_Bnoformaleducation_C + Tpct_FA_BHighschool_C + Tpct_FA_BAssociates degree_C

gen below_bachlor_degree_C = pct_FA_Bnoformaleducation_C+ pct_FA_Bhighschool_C+ pct_FA_BAssociatesdegree_C

egen z_below_bachlor_degree_C = std (below_bachlor_degree_C)
gen above_bachlor_degree = pct_FA_BBachelorsdegree+ pct_FA_BgraduateorProfessional

egen z_above_bachlor_degree = std (above_bachlor_degree)


***OBJECTIVE 2***
use"C:\Users\SadikshyaSharma\Downloads\Fire_project\working_folder\Blockdata\LA_newdata\may2025_urbanfire_project\reanalysis_may1st_dtafile.dta", clear

gen TpctFA_male_C = ( Fireaffected_male/ fireaffected_pop)*100
egen z_TpctFA_male_C = std ( TpctFA_male_C)


gen TpctFA_female_C = ( Fireaffectedfemale/ fireaffected_pop)*100
egen z_TpctFA_female_C = std ( TpctFA_female_C)


gen TpctFA_under_5yrs_C = ( FA_under_5yrs/ fireaffected_pop)*100
egen  z_TpctFA_under_5yrs_C = std (TpctFA_under_5yrs_C)
 egen z_TpctFA_under_5yrs_C = std(TpctFA_under_5yrs_C)

gen TpctFA_519_yrs_CC = ( FA_519_yrs/ fireaffected_pop)*100
egen z_TpctFA_519_yrs_CC = std (TpctFA_519_yrs_CC)

gen TpctFA_below_20_yrs_C = ( FA_below_20_yrs/fireaffected_pop)*100
egen z_TpctFA_below_20_yrs_C = std (TpctFA_below_20_yrs_C)

gen TpctFA_2064_yrs_C = ( FA_2064_yrs/fireaffected_pop)*100
egen z_TpctFA_2064_yrs_C = std(TpctFA_2064_yrs_C)

gen TpctFA_65andover_yrs_C = (FA_65andover_yrs/fireaffected_pop)*100
egen z_TpctFA_65andover_yrs_C = std (TpctFA_65andover_yrs_C)

gen TpctFA_Hispanic_C = ( FA_Hispanic/fireaffected_pop)*100
egen z_TpctFA_Hispanic_C = std (TpctFA_Hispanic_C)

gen TpctFA_not_Hispanic_C = ( FA_not_Hispanic/ fireaffected_pop)*100
egen z_TpctFA_not_Hispanic_C = std (TpctFA_not_Hispanic_C)

gen TpctFA_whitep_CC = ( FA_white/ fireaffected_pop)*100
egen z_TpctFA_whitep_CC = std (TpctFA_whitep_CC)


gen TpctFA_AAp_C = ( FA_AA/fireaffected_pop)*100
egen z_TpctFA_AAp_C = std (TpctFA_AAp_C)

gen TpctFA_AIANp_C = ( FA_AIAN/ fireaffected_pop)
egen z_TpctFA_AIANp_C = std (TpctFA_AIANp_C)

gen TpctFA_Ap_C =  ( FA_A/fireaffected_pop) *100
egen z_TpctFA_Ap_C = std (TpctFA_Ap_C)

gen TpctNHOPIp_C = ( FA_NHOPI/fireaffected_pop)*100
egen z_TpctNHOPIp_C = std (TpctNHOPIp_C )

gen otherthan5race = FA_otherrace+ FA_2ormore_R+ FA_Two_R
gen Tpct_otherthan5race_C = ( otherthan5race/ fireaffected_pop)*100
egen z_Tpct_otherthan5race_C = std (Tpct_otherthan5race_C)

gen Tpct_otherthan5race_CC = (100- TpctFA_whitep_CC- TpctFA_AAp_C- TpctFA_AIANp_C- TpctFA_Ap_C-TpctNHOPIp_C)
egen z_Tpct_otherthan5race_CC = std(Tpct_otherthan5race_CC)

gen TpctFA_occ_C = ( FA_occupied/ FA_Housingunits)*100
egen z_TpctFA_occ_C = std (TpctFA_occ_C)

gen TpctFA_vaccant_C = ( FA_vaccant/FA_Housingunits)*100
egen z_TpctFA_vaccant_C = std (TpctFA_vaccant_C )
replace  TpctFA_owner_occ_C = 0 if missing( TpctFA_owner_occ_C )

gen TpctFA_renter_occ_C = ( FA_renter_occ / FA_occupied)*100
egen z_TpctFA_renter_occ_C = std (TpctFA_renter_occ_C )
replace TpctFA_renter_occ_C = 0 if missing( TpctFA_renter_occ_C )

gen Tpct_FA_Eng_speakers_C = ( FA_BlockEstimateTotalSpeak/ FABEstimateTotalPop5yearor)* 100
egen  z_Tpct_FA_Eng_speakers_C = std ( Tpct_FA_Eng_speakers_C)

gen Tpct_FA_NonEng_speakers_C = ( FA_BEstimateTotalSpeakothe/FABEstimateTotalPop5yearor)*100
egen z_Tpct_FA_NonEng_speakers_C = std (Tpct_FA_NonEng_speakers_C )

gen Tpct_FA_poverty_C = ( FA_BEstimateTotalpopIncome/fireaffected_pop)*100
egen z_Tpct_FA_poverty_C = std (Tpct_FA_poverty_C)

gen FABEstimateTotalPopover25 = ( BEstimateTotalPopover25* EL)
gen Tpct_FA_Bnoformaleducation_C = ( FA_BEstimateTotalNoschooli/FABEstimateTotalPopover25)*100
egen z_Tpct_FA_Bnoformaleducation_C = std (Tpct_FA_Bnoformaleducation_C)

gen Tpct_FA_BHighschool_CC = (FA_BHighschool/FABEstimateTotalPopover25)*100
egen z_Tpct_FA_BHighschool_CC = std (Tpct_FA_BHighschool_CC)


gen Tpct_FA_BAssociatesdegree_C = ( FA_BEstimateTotalAssociate/FABEstimateTotalPopover25)*100
egen z_Tpct_FA_BAssociatesdegree_C = std( Tpct_FA_BAssociatesdegree_C)

gen Tpct_FA_BBachelorsdegree_C = ( FA_BEstimateTotalBachelors/ FABEstimateTotalPopover25)*100
egen z_Tpct_FA_BBachelorsdegree_C = std (Tpct_FA_BBachelorsdegree_C)

gen Tpct_FA_graduate_C = (FA_BgraduateorProfessionaldeg/FABEstimateTotalPopover25)*100
egen z_Tpct_FA_graduate_C = std (Tpct_FA_graduate_C )

gen Tpct_belowbachelors_C = ( Tpct_FA_Bnoformaleducation_C+ Tpct_FA_BHighschool_CC + Tpct_FA_BAssociatesdegree_C)
egen z_Tpct_belowbachelors_C = std (Tpct_belowbachelors_C )

**SUMMARY TABLES **
**EATON FIRE**
summarize POP20 fireaffected_pop blockarea firearea2025pct destroy_pct firearea1910to2023pct zone_zero_overlap_mean zone_one_overlap_mean zone_two_overlap_mean structure_value_median structurebasalarea yearbuiltmedian post_2008_pct treecover2022 TpctFA_male_C TpctFA_female_C TpctFA_under_5yrs_C TpctFA_519_yrs_CC TpctFA_2064_yrs_C TpctFA_65andover_yrs_C TpctFA_Hispanic_C TpctFA_not_Hispanic_C TpctFA_whitep_CC TpctFA_AAp_C TpctFA_AIANp_C TpctFA_Ap_C TpctNHOPIp_C Tpct_otherthan5race_CC TpctFA_occ_C TpctFA_vaccant_C TpctFA_owner_occ_C TpctFA_renter_occ_C Tpct_FA_Eng_speakers_C Tpct_FA_NonEng_speakers_C Tpct_FA_Bnoformaleducation_C Tpct_FA_BHighschool_CC Tpct_FA_BAssociatesdegree_C Tpct_FA_BBachelorsdegree_C Tpct_FA_graduate_C Tpct_FA_poverty_C BGEstimatePercapitaincomein if  UR20 =="U" & fire == 1 [aw = fireaffected_pop]



***PALISADES FIRE**
summarize POP20 fireaffected_pop blockarea firearea2025pct destroy_pct firearea1910to2023pct zone_zero_overlap_mean zone_one_overlap_mean zone_two_overlap_mean structure_value_median structurebasalarea yearbuiltmedian post_2008_pct treecover2022 TpctFA_male_C TpctFA_female_C TpctFA_under_5yrs_C TpctFA_519_yrs_CC TpctFA_2064_yrs_C TpctFA_65andover_yrs_C TpctFA_Hispanic_C TpctFA_not_Hispanic_C TpctFA_whitep_CC TpctFA_AAp_C TpctFA_AIANp_C TpctFA_Ap_C TpctNHOPIp_C Tpct_otherthan5race_CC TpctFA_occ_C TpctFA_vaccant_C TpctFA_owner_occ_C TpctFA_renter_occ_C Tpct_FA_Eng_speakers_C Tpct_FA_NonEng_speakers_C Tpct_FA_Bnoformaleducation_C Tpct_FA_BHighschool_CC Tpct_FA_BAssociatesdegree_C Tpct_FA_BBachelorsdegree_C Tpct_FA_graduate_C Tpct_FA_poverty_C BGEstimatePercapitaincomein if  UR20 =="U" & fire == 0 [aw = fireaffected_pop]


*** REGRESSION RESULTS ***
**EATON FIRE**
regress z_destroy_pct z_structure_value_median z_zone_zero_overlap_mean z_firearea1910to2023pct z_structurebasalarea z_yearbuiltmedian z_treecover2022 z_TpctFA_vaccant_C z_TpctFA_renter_occ_C z_TpctFA_Hispanic_C z_TpctFA_65andover_yrs_C z_TpctFA_AAp_C z_Tpct_FA_Eng_speakers_C z_Tpct_FA_BAssociatesdegree_C z_Tpct_FA_BBachelorsdegree_C z_Tpct_FA_poverty_C z_post_2008_pct z_BGEstimatePercapitaincomein if  UR20 =="U" & fire == 1 [aw = fireaffected_pop ],robust

estat ic
vif


glm z_destroy_pct z_structure_value_median z_zone_zero_overlap_mean z_firearea1910to2023pct z_structurebasalarea z_yearbuiltmedian z_treecover2022 z_TpctFA_vaccant_C z_TpctFA_renter_occ_C z_TpctFA_Hispanic_C z_TpctFA_65andover_yrs_C z_TpctFA_AAp_C z_Tpct_FA_Eng_speakers_C z_Tpct_FA_BAssociatesdegree_C z_Tpct_FA_BBachelorsdegree_C z_Tpct_FA_poverty_C z_post_2008_pct z_BGEstimatePercapitaincomein if  UR20 =="U" & fire == 1 [aw = fireaffected_pop ]

***PALISADES FIRE**


regress z_destroy_pct z_structure_value_median z_zone_one_overlap_mean z_firearea1910to2023pct z_structurebasalarea z_yearbuiltmedian z_treecover2022 z_TpctFA_vaccant_C z_TpctFA_renter_occ_C z_TpctFA_Hispanic_C TpctFA_65andover_yrs_C z_TpctFA_2064_yrs_C z_TpctFA_whitep_CC z_Tpct_FA_Eng_speakers_C z_Tpct_FA_BAssociatesdegree_C z_Tpct_FA_BHighschool_CC z_post_2008_pct z_BGEstimatePercapitaincomein if  UR20 =="U" & fire == 0 [aw = fireaffected_pop ],robust


estat ic
vif


glm z_destroy_pct z_structure_value_median z_zone_one_overlap_mean z_firearea1910to2023pct z_structurebasalarea z_yearbuiltmedian z_treecover2022 z_TpctFA_vaccant_C z_TpctFA_renter_occ_C z_TpctFA_Hispanic_C TpctFA_65andover_yrs_C z_TpctFA_2064_yrs_C z_TpctFA_whitep_CC z_Tpct_FA_Eng_speakers_C z_Tpct_FA_BAssociatesdegree_C z_Tpct_FA_BHighschool_CC z_post_2008_pct z_BGEstimatePercapitaincomein if  UR20 =="U" & fire == 0 [aw = fireaffected_pop ]




******PArcel level data***** MAy 1st****

 summarize YearBuilt1 val_struct zone_zero_overlap zone_one_overlap_correct zone_two_overlap_correct over65pct poptotal structurebasalarea treecover2022 if Fire_Name == "Eaton"
	 
	  summarize YearBuilt1 val_struct zone_zero_overlap zone_one_overlap_correct zone_two_overlap_correct over65pct poptotal structurebasalarea treecover2022 if Fire_Name == "Palisades"
	  
	  logit Destroy_Bin z_YearBuilt1 z_val_struct z_zone_zero_overlap z_zone_one_overlap_correct z_zone_two_overlap_correct z_over65pct z_poptotal z_structurebasalarea z_treecover2022 fireexposed1910to2023 single_res if Fire_Name == "Eaton"

	  estat ic 

logit Destroy_Bin z_YearBuilt1 z_val_struct z_zone_zero_overlap z_zone_one_overlap_correct z_zone_two_overlap_correct z_over65pct z_poptotal z_structurebasalarea z_treecover2022 fireexposed1910to2023 single_res if Fire_Name == "Palisades"

	 estat ic
	 