# Datasets, R, STATA and Google Earth Engine scripts used in "Socio-Ecological Impacts of the 2025 Los Angeles Urban Fires on Communities, Neighborhoods, and Homes"
---

These data sets and scripts allow for the creation of all figures and supplementary figures and tables in the following manuscript. When using these data and script please cite the following manuscript.
Norlen, C.A.; Sharma, S.; Escobedo, F.J. (2026) "Socio-Ecological Impacts of the 2025 Los Angeles Urban Fires on Communities, Neighborhoods, and Homes" Nature Communications

## Data Access
The code and processsed data sets required to create figures, and tables are available as a figshare repository (https://doi.org/10.6084/m9.figshare.29936876). The code is also available in the following GitHub 
repository (https://github.com/carlnorlen/la-urban-fires).  

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
  *  census_blocks_sample_sociodemographic_published_20260211.csv

Parcel scale data on fire impacts and urban morphology characteristics as a CSV (.CSV). This data file contains the following data fields: LA County Assessor's Identification Number (AIN_1), Address number (SitusHouseNo), Property use (UseType), Description of building use (UseDescription), 
Street Name (SitusStreet), Street number and name (SitusAddress), City (SitusCity), Zip Code (SitusZIP), Year structure built (YearBuilt1), Number of units (Units1), Number of bedrooms (Bedrooms1), Number of bathrooms (Bathrooms1), Building square feet (SQFTmain1), Property tax assessment year (Roll_Year),
Property tax land value (Roll_LandValue), Property tax improvement value (Roll_ImpValue), Property legal description (LegalDescription), Name of 2025 fire parcel intersects (Fire_Name), CAL FIRE DINS fire damage class (DAMAGE_1)
CAL FIRE DINS type of structure (STRUCTURECATEGORY), First owner last name (OWN1_LAST), First owner first name (OWN1_FRST), Second owner last name (OWN2_LAST), Second owner first name (OWN2_FRST), USACE structure replacement value (val_struct), Number of structures in Defensible Space Buffer (DSB) Zone 0 (zone_zero_overlap)
Number of structures in DSB Zone 1 (zone_one_overlap_correct), Number of structures in DSB Zone 2 (zone_two_overlap_correct), % of people over 65 (over.65.pct), % of people under 65 (under.65.pct), total population (pop.total), Parcel area (ha; parcel.area), Structure footprint area (m^2; structure.basal.area), Predicted property owner race (race),
2022 % tree cover (tree.cover.2022), Categorical exposure to fire from 1910 to 2023 (fire.exposed.1910to2023), Categorical predicted property owner race (race.num), Categorical CAL FIRE DINS fire damage (DAMAGE_1.num)        
  *  combined_la_fires_parcel_all_structures_data_published_20260212.csv

Parcel scale data on fire impacts and urban morphology characteristics as a geopackage (.gpkg) with the same data fields as the above CSV as well as the parcel geometry (geom).
  *  combined_la_fires_parcel_all_structures_data_published.gpkg

All data in STATA .dta format used for neighborhood and parcel-scale modeling and table creation. Includes the same data fields as the above US Census block and parcel scale data.
  * stata_neighborhood_data_published.dta
  * stata_parcel_data_published.dta

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
The code shared with this submission were written in JavaScript for Google Earth Engine (GEE), R 4.3.2 run using RStudio, and STATA version 19.
The R code requires the tidyverse, ggpubr, sf, patchwork, tigris, tidycensus, units, osmdata, rethnicity, and gstat packages. 

## R Code
Script for general geospatial data processing.
  * 1-data-processing.r
  
Script for exporting urban morphology data to link with the socio-economic analysis.
  * 2-data-export-census.r
  
Script for merging data sets and exporting processed data for final analysis.
  * 3-data-export-structure.r
  
Script doing final analysis and creating all Main Text and Supplementary Figures.
  * 4-manuscript-analysis.r

## STATA Code
STATA code for running neighborhood and parcel-scale models and producing Tables 1, 2, 3, 4, and Supplementary Tables 1, 2, 3, 4
  * 1_neighborhood_analysis_stata_code.do
  * 2_parcel_analysis_stata_code.do

## GEE JavaScript Code
Script for calculating the number of building footprint overlaps in each parcel and census block.
  * 1-building-footprint-overlap.js

Script for calculating the pre-fire urban tree cover in each parcel and census block
  * 2-tree-cover-census-block.js
  
Script for extracting the Landsat 9 surface reflectance background image for the study region
  * 3-landsat-background-image.js