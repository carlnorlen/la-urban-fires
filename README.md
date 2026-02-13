# Datasets, R, STATA and Google Earth Engine scripts used in "Socio-Ecological Impacts of the 2025 Los Angeles Urban Fires on Communities, Neighborhoods, and Homes"
---

These data sets and scripts allow for the creation of all figures and supplementary figures and tables in the following manuscript. When using these data and script please cite the following manuscript.
Norlen, C.A.; Sharma, S.; Escobedo, F.J. (in review) "Socio-Ecological Impacts of the 2025 Los Angeles Urban Fires on Communities, Neighborhoods, and Homes" Nature Communications

## Data Access
The code and data sets required to create figures, and tables are available as a figshare repository (https://doi.org/10.6084/m9.figshare.29936876). The code is also available as a github 
repository (https://github.com/carlnorlen/la-urban-fires). Google Earth Engine code is also available through the Code Editor (https://code.earthengine.google.com/?accept_repo=users/cnorlen-usgs/la-urban-fire). 

## Description of the data and file structure
US Census Block scale urban morphology data processed for use in socio-deomgraphic analysis. This file includes the following data fields: census block identifying information such as Block code (BLOCKCE20), 
Census GEOID (GEOID20), Census urban/rural designation (UR20), fire name (which.fire), 2025 fire area (ha; fire.area.2025), 1910-2023 fire area (ha; fire.area.1910to2023), building footprint area (m^2/ha; building.area), 
Number of structures in DSB Zone 0 (zone_zero_overlap_mean), Number of structures in DSB Zone 1 (zone_one_overlap_mean), Number of structures in DSB Zone 2 (zone_two_overlap_mean), median structure replacement value ($; structure_value_median),
census block area (ha; block.area), 2025 proportion of census block burned (%; fire.area.2025.pct), 1910-2023 proportion of census block burned (%; fire.area.1910to2023.pct), Structure footprint area (m^/ha; structure.basal.area),    
Number of structures destroyed (destroy.count), Number of structures with major damage (major.damage.count), Number of structures with minor damage (minor.damage.count), Number of structures affected (affected.count), Number of structures with no damage (no.damage.count),
Number of total structures (structure.count), Median year structure was built (year.built.median), Number of structures built after 2008 (year.built.2008.count), Median structure replacement value ($; property.value.median), Percentage of destroyed structures (destroy_pct),             
Homes with major damage % (major_damage_pct), Homes with minor damage % (minor_damage_pct), Homes affected % (affected_pct), No damage % (no_damage_pct), Built after 2008 % (after_2008_pct), 2022 urban tree cover % (tree.cover.2022)
  *  census_blocks_dins_destroyed_burned_area_20250424.csv

US Census Block scale data on fire impacts and urban morphology characteristics as a geopackage (.gpkg). Contains the same data fields as above.
  *  la_fires_census_blocks_dins_destroyed_burned_area.gpkg
  
Sociodemographic US Census Block and urban morphology data used for figure creation. This file includes the same data fields as above along with the following primarily socio-demographic data fields: Categorical fire indicator (fire),
total census block population (Total.Popn), Fire affected proportion (FAP), Fire affected population (fire.affected_pop), Total number of males (X..Total...Male.), Number of fire affected males (Fireaffected_male),                                                                                             
% of males that are fire affected (pct.FA_male), Total male % (Tpct.FA_male), Total number females (X..Total...Female.), Number of fire-affected females (Fire.affected.female), % of females who are fire affected (pct.Fireaffected_female),                                                                                       
Total female % (Tpct.FA_female), Total population under 5 years (X..Total...Pop...Under.5.years), Fire affected population under 5 years (FA_under_5yrs.), % of fire affected 5 year olds (pct.FA_under_5yrs.), % of 5 year olds (Tpct.FA_under_5yrs),                                                                                            
Total population between 5 to 19 years old (X..Total...Popn...5.to.19.years), Fire affected population between 5 to 19 years old (FA_5.19_yrs), % of fire affected 5 to 19 year olds (pct.FA_5.19_yrs), Total percentage of 5 to 19 year olds (Tpct.FA_5.19_yrs),                                                                                           
Total population below 20 years (X..Total...Popn...below.20years), Fire affected population between 20 years (FA_below_20_yrs), % of fire affected below 20 years (pct.FA_below_20_yrs), % of below 20 year olds (Tpct.FA_below_20_yrs), 
total population 20 to 64 years (X..Total...Popn...20.to.64.years), fire affected 20 to 64 year olds (FA_20.64_yrs.), % 20 to 64 year olds (Tpct.FA_20.64_yr), total population 65 years and over (X..Total...Popn...65.years.and.over), 
fire affected population 65 years and over (FA_65.and.over_yrs.),  % 65 years and over (Tpct.FA_65.and.over_yrs.), total Hispanic or Lation population (X..Total...Hispanic.or.Latino), fire affected Hispanic/Latino population (FA_Hispanic), 
% Hispanic/Latino (Tpct.FA_Hispanic), total White population (X..Total...Population.of.one.race...White.alone), fire affected White population (FA_white), % White (Tpct.FA_whitep), total Black / African American population (X..Total...Population.of.one.race...Black.or.African.American.alone),
fire affected Black / African American population (FA_AA), % Black / African American (Tpct.FA_AAp), total population American Indian / Alaska Native (X..Total...Population.of.one.race...American.Indian.and.Alaska.Native.alone), 
fire affected population American Indian / Alaska Native (FA_AIAN), % American Indian / Alaska Native (Tpct.FA_AIANp), Total population Asian (X..Total...Population.of.one.race...Asian.alone), fire affected population Asian (FA_A), 
% Asian (Tpct.FA_Ap), total population Native Hawaiian / Other Pacific Islander (X..Total...Population.of.one.race...Native.Hawaiian.and.Other.Pacific.Islander.alone), fire affected population Native Hawaiian / Other Pacific Islander (FA_NHOPI),
% Native Hawaiian / Other Pacific Islander (Tpct.NHOPIp), total population other race (X..Total...Population.of.one.race...Some.Other.Race.alone), fire affected population other race (FA_otherrace), % other race (Tpct.OR), total housing units (X..Total.Housing_units), 
fire affected housing units (FA_Housingunits), total occupied housing units (X..Total...Occupied), fire affected occupied housing units (FA_occupied), % occupied housing units (Tpct.FA_occ), total vaccant housing units (X..Total...Vacant),
fire affected vaccant housing units (FA_vaccant), % vaccant housing units (Tpct.FA_vaccant), total occupied housing units (X..Total.0ccupied_housing_units), total owner occupied housing units (X..Total...Owner.occupied.), 
fire affected owner occupied housing units (FA_owner_occ), % owner occupied housing units (Tpct.FA_owner_occ), total renter occupied housing units (X..Total...Renter.occupied.), fire affected renter occupied housing units (FA_renter_occ),
% renter occupied housing units (Tpct.FA_renter_occ), Block population (Bpopulation), fire affected population speaking only English (FA_BlockEstimate..Total...Speak.only.English), % English speakers (Tpct_FA_Eng_speakers), fire affected population of non-English speakers (FA_BEstimate..Total...Speak.other.languages.),
% Non-English Speakers (Tpct_FA_Non.Eng_speakers), fire affected population below poverty level (FA_BEstimate..Total.pop...Income.in.the.past.12.months.below.poverty.level.), % below poverty level (Tpct_FA_poverty), fire affected population with no formal education (FA_BEstimate..Total...No.schooling.completed..no.formal.education),
% no formal education (Tpct_FA_B.no.formal.education), fire affected population with high school or equivalent (FA_BHighschool.OR.equivalent), % high school or equivalent (Tpct_FA_BHighschool), fire affected population with Associate's Degree (FA_BEstimate..Total...Associate.s.degree),
% Associate's Degree (Tpct_FA_BAssociate.s.degree), fire affected population with Bachelor's Degree (FA_BEstimate..Total...Bachelor.s.degree), % Bachelor's Degree (Tpct_FA_BBachelor.s.degree), fire affected population with graduate or professional degree (FA_Bgraduate.or.Professional.degree),
% Graduate of Professional Degree (Tpct_FA_Bgraduate.or.Professional.degree), % No Schooling weighted by block group (ww_pct_bbg_noschooling), % high school weighted by block group (ww_bbg_pct_highsch), % Associate's Degree (weighted by block groupww_bbg_pct_associate),                                                                                          
% Below Bachelor's Degree weighted by block group (ww_pct.bbg.belowbachelors), % Bachelor's Degree weighted by block group (ww_bbg_pct_bachelor), % Graduate or Professional degree weighted by block group (ww_bbg_pct_graduate.Prof),                                                                                       
% Above Bachelor's Degree weighted by block group (ww_pct.bbg_atand.above.bachelors), % Below poverty weighted by block group (ww_bbg_pct_belowpoverty), % non-English speakers weighted by block group (ww_bbg_pct_noneng), % English speakers weighted by block group (ww_bbg_pct_speak.eng),
Per Capita Income (PercapitaInc)
  *  census_blocks_sample_sociodemographic_20250502.csv

Parcel scale data on fire impacts and urban morphology characteristics as a CSV (.CSV). This data file contains the following data fields: LA County Assessor's Identification Number (AIN_1), Address number (SitusHouseNo), Property use (UseType), Description of building use (UseDescription), 
Street Name (SitusStreet), Street number and name (SitusAddress), City (SitusCity)                "SitusZIP"                
 # [11] "SitusFullAddress"
 [21] "DesignType1"              "YearBuilt1"               "EffectiveYear1"           "Units1"                   "Bedrooms1"               
 [26] "Bathrooms1"               "SQFTmain1"                "DesignType2"              "YearBuilt2"               "EffectiveYear2"          
 [31] "Units2"                   "Bedrooms2"                "Bathrooms2"               "SQFTmain2"                "DesignType3"             
 [36] "YearBuilt3"               "EffectiveYear3"           "Units3"                   "Bedrooms3"                "Bathrooms3"              
 [41] "SQFTmain3"                "DesignType4"              "YearBuilt4"               "EffectiveYear4"           "Units4"                  
 [46] "Bedrooms4"                "Bathrooms4"               "SQFTmain4"                "DesignType5"              "YearBuilt5"              
 [51] "EffectiveYear5"           "Units5"                   "Bedrooms5"                "Bathrooms5"               "SQFTmain5"               
 [56] "RecDate"                  "RecDocNo"                 "Roll_Year"                "Roll_LandValue"           "Roll_ImpValue"           
 [61] "Roll_PersPropValue"       "Roll_FixtureValue"        "Roll_HomeOwnersExemp"     "Roll_RealEstateExemp"     "Roll_PersPropExemp"      
 [66] "Roll_FixtureExemp"        "Roll_LandBaseYear"        "Roll_ImpBaseYear"         "LastSaleDate"             "LastSaleAmount"          
 [71] "QualityClass1"            "QualityClass2"            "QualityClass3"            "QualityClass4"            "QualityClass5"           
 [76] "LegalDescLine1"           "LegalDescLine2"           "LegalDescLine3"           "LegalDescLine4"           "LegalDescLine5"          
 [81] "LegalDescLineLast"        "LegalDescription"         "SpatialChangeDate"        "ParcelCreateDate"         "ParcelTypeCode"          
 [86] "Assr_Map"                 "Assr_Index_Map"           "CENTER_LAT"               "CENTER_LON"               "CENTER_X"                
 [91] "CENTER_Y"                 "LAT_LON"                  "Fire_Name"                "DAMAGE_1"                 "STRUCTURECATEGORY"       
 [96] "Total_Units"              "GlobalID"                 "Tot_SqFt"                 "DINS_Count"               "LCITY"                   
[101] "COMMUNITY"                "PARCEL_ID"                "STATE_CODE"               "CNTY_CODE"                "APN2"                    
[106] "ADDR"                     "CITY"                     "STATE"                    "ZIP"                      "PLUS"                    
[111] "STD_ADDR"                 "STD_CITY"                 "STD_STATE"                "STD_ZIP"                  "STD_PLUS"                
[116] "TYPE_CODE"                "LONGITUDE"                "LATITUDE"                 "FIPS_CODE"                "UNFRM_APN"               
[121] "APN_SEQ_NO"               "FRM_APN"                  "ORIG_APN"                 "ACCT_NO"                  "TH_BRO_MAP"              
[126] "MAP_REF1"                 "MAP_REF2"                 "CENSUS_TR"                "BLOCK_NBR"                "LOT_NBR"                 
[131] "RANGE"                    "TOWNSHIP"                 "SECTION"                  "QRT_SECT"                 "LAND_USE"                
[136] "M_HOME_IND"               "ZONING"                   "PROP_IND"                 "SUB_TR_NUM"               "SUB_PLT_BK"              
[141] "SUB_PLT_PG"               "SUB_NAME"                 "OWN_CP_IND"               "OWN1_LAST"                "OWN1_FRST"               
[146] "OWN2_LAST"                "OWN2_FRST"                "MAIL_NBRPX"               "MAIL_NBR"                 "MAIL_NBR2"               
[151] "MAIL_NBRSX"               "MAIL_DIR"                 "MAIL_STR"                 "MAIL_MODE"                "MAIL_QDRT"               
[156] "MAIL_UNIT"                "MAIL_CITY"                "MAIL_STATE"               "MAIL_ZIP"                 "MAIL_CC"                 
[161] "MAIL_OPT"                 "TOT_VAL"                  "LAN_VAL"                  "TOT_VAL_CD"               "LAN_VAL_CD"              
[166] "ASSD_VAL"                 "ASSD_LAN"                 "MKT_VAL"                  "MKT_LAN"                  "APPR_VAL"                
[171] "APPR_LAN"                 "TAX_AMT"                  "TAX_YR"                   "ASSD_YR"                  "TAX_AREA"                
[176] "DOC_NBR"                  "SALE_BK_PG"               "FRONT_FT"                 "DEPTH_FT"                 "LAND_ACRES"              
[181] "LAND_SQ_FT"               "LOT_AREA"                 "YR_BLT"                   "EFF_YR_BLT"               "LEGAL1"                  
[186] "LEGAL2"                   "LEGAL3"                   "fd_id"                    "bid"                      "cbfips"                  
[191] "st_damcat"                "occtype"                  "bldgtype"                 "num_story"                "sqft"                    
[196] "found_type"               "found_ht"                 "med_yr_blt"               "val_struct"               "val_cont"                
[201] "val_vehic"                "ftprntid"                 "ftprntsrc"                "source"                   "students"                
[206] "pop2amu65"                "pop2amo65"                "pop2pmu65"                "pop2pmo65"                "o65disable"              
[211] "u65disable"               "x"                        "y"                        "firmzone"                 "grnd_elv_m"              
[216] "ground_elv"               "id"                       "cptr_d_"                  "footprint.acre"           "footprint.sqft"          
[221] "release"                  "zone_one_overlap"         "zone_two_overlap"         "zone_zero_overlap"        "zone_one_overlap_correct"
[226] "zone_two_overlap_correct" "over.65.pct"              "under.65.pct"             "pop.total"                "building.area"           
[231] "parcel.area"              "structure.basal.area"     "race"                     "tree.cover.2022"          "fire.exposed.1910to2023" 
[236] "race.num"                 "DAMAGE_1.num"
# "APN_1"
 #  [6] "SitusUnit"                         "TaxRateArea"              "TaxRateCity"              "AgencyClassNo"            "AgencyName"              
 # [16] "AgencyType"               "UseCode"                  "UseCode_2" 
 # "SitusFraction"            "SitusDirection"         
  *  combined_la_fires_parcel_all_structures_data_20250414_v2.csv

Parcel scale data on fire impacts and urban morphology characteristics as a geopackage (.gpkg)
  *  combined_la_fires_parcel_all_structures_data.gpkg

All data in STATA .dta format used for modeling and table creation.
  *  stata_all_revised_data.dta

Cropped Landsat 9 image used for creation of Main Text figure 1 in GeoTiff format (.tif)
  *  Landsat_Image_20250114_reproject.tif

## Sharing/Access information
Data was derived from these publicly available sources:
  * CAL FIRE 2023 perimeters:https://www.fire.ca.gov/what-we-do/fire-resource-assessment-program/fire-perimeters
  * WGIS 2025 Fire Perimeters: https://data-nifc.opendata.arcgis.com/pages/faqs
  * USACE National Structure Inventory: https://nsi.sec.usace.army.mil/downloads/
  * Microsoft Building Footprints: https://github.com/microsoft/USBuildingFootprints?tab=readme-ov-file
  * Earth Define 2022 Urban Tree Cover: https://www.fs.usda.gov/detail/r5/communityforests/?cid=fseprd647385
  * 2020 Decennial and 2023 American Community Survey US Census Bureau Data: https://data.census.gov/advanced
  * CAL FIRE Structure Damage (DINS) and LA County Assessor's Data: https://data.lacounty.gov/datasets/lacounty::2025-parcels-with-dins-data/explore
  * Landsat 9 surface reflectance for 1/14/2025 retrieved from Google Earth Engine: https://developers.google.com/earth-engine/datasets/catalog/LANDSAT_LC09_C02_T1_L2#bands

## Code/Software
The code shared with this submission were written in JavaScript for Google Earth Engine (GEE) and R 4.3.2 run using RStudio.
The code requires the tidyverse, ggpubr, sf, patchwork, tigris, tidycensus, units, osmdata, rethnicity, and gstat packages. 

## R Code
Script for general geospatial data processing.
  * 1-data-processing.r
  
Script for exporting urban morphology data to link with the socio-economic analysis.
  * 2-data-export-census.r
  
Script for merging data sets and exporting processed data for final analysis.
  * 3-data-export-structure.r
  
Script doing final analysis and creating all Main Text and Supplementary Figures.
  * 4-manuscript-analysis.r

##STATA Code
STATA code for running models and producing Tables 1, 2, 3, 4, S1, S2, S3, S4
  * june_revision_dofile_submit.do

## GEE JavaScript Code
Script for calculating the number of building footprint overlaps in each parcel and census block.
  * building-footprint-overlap.js

Script calculating the pre-fire urban tree cover in each parcel and census block
  * tree-cover-census-block.js