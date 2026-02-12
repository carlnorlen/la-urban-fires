# Datasets, R, STATA and Google Earth Engine scripts used in "Socio-Ecological Impacts of the 2025 Los Angeles Urban Fires on Communities, Neighborhoods, and Homes"
---

These data sets and scripts allow for the creation of all figures and supplementary figures and tables in the following manuscript. When using these data and script please cite the following manuscript.
Norlen, C.A.; Sharma, S.; Escobedo, F.J. (in review) "Socio-Ecological Impacts of the 2025 Los Angeles Urban Fires on Communities, Neighborhoods, and Homes" Nature Communications

## Data Access
The code and data sets required to create figures, and tables are available as a figshare repository (https://doi.org/10.6084/m9.figshare.29936876). The code is also available as a github 
repository (https://github.com/carlnorlen/la-urban-fires). Google Earth Engine code is also available through the Code Editor (https://code.earthengine.google.com/?accept_repo=users/cnorlen-usgs/la-urban-fire). 

## Description of the data and file structure
All data in STATA .dta format used for modeling and table creation.
  *  stata_all_revised_data.dta

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
  
Socio-economic US Census Block data used for figure creation. This file includes the same data fields as above along with the following primarily socio-demographic data fields: Categorical fire indicator (fire),
total census block population (Total.Popn), Fire affected proportion (FAP), Fire affected population (fire.affected_pop), Total number of males (X..Total...Male.), Number of fire affected males (Fireaffected_male),                                                                                             
% of males that are fire affected (pct.FA_male), Total male % (Tpct.FA_male), Total number females (X..Total...Female.), Number of fire-affected females (Fire.affected.female), % of females who are fire affected (pct.Fireaffected_female),                                                                                       
Total female % (Tpct.FA_female), Total population under 5 years (X..Total...Pop...Under.5.years), Fire affected population under 5 years (FA_under_5yrs.), % of fire affected 5 year olds (pct.FA_under_5yrs.), % of 5 year olds (Tpct.FA_under_5yrs),                                                                                            
Total population between 5 to 19 years old (X..Total...Popn...5.to.19.years), Fire affected population between 5 to 19 years old (FA_5.19_yrs), % of fire affected 5 to 19 year olds (pct.FA_5.19_yrs), Total percentage of 5 to 19 year olds (Tpct.FA_5.19_yrs),                                                                                           
 [74] "X..Total...Popn...below.20years"                                                                               
 [75] "FA_below_20_yrs"                                                                                               
 [76] "pct.FA_below_20_yrs"                                                                                           
 [77] "Tpct.FA_below_20_yrs"                                                                                          
 [78] "X..Total...Popn...20.to.64.years"                                                                              
 [79] "FA_20.64_yrs."                                                                                                 
 [80] "Tpct.FA_20.64_yrs"                                                                                             
 [81] "X..Total...Popn...65.years.and.over"                                                                           
 [82] "FA_65.and.over_yrs."                                                                                           
 [83] "Tpct.FA_65.and.over_yrs."                                                                                      
 [84] "X..Total...Hispanic.or.Latino"                                                                                 
 [85] "FA_Hispanic"                                                                                                   
 [86] "Tpct.FA_Hispanic"                                                                                              
 [87] "X..Total...Not.Hispanic.or.Latino."                                                                            
 [88] "FA_not_Hispanic"                                                                                               
 [89] "Tpct.FA_not_Hispanic"                                                                                          
 [90] "X..Total...Population.of.one.race"                                                                             
 [91] "X..Total...Population.of.one.race...White.alone"                                                               
 [92] "FA_white"                                                                                                      
 [93] "Tpct.FA_white1"                                                                                                
 [94] "Tpct.FA_whitep"                                                                                                
 [95] "X..Total...Population.of.one.race...Black.or.African.American.alone"                                           
 [96] "FA_AA"                                                                                                         
 [97] "Tpct.FA_AA1"                                                                                                   
 [98] "Tpct.FA_AAp"                                                                                                   
 [99] "X..Total...Population.of.one.race...American.Indian.and.Alaska.Native.alone"                                   
[100] "FA_AIAN"                                                                                                       
[101] "Tpct.FA_AIAN1"                                                                                                 
[102] "Tpct.FA_AIANp"                                                                                                 
[103] "X..Total...Population.of.one.race...Asian.alone"                                                               
[104] "FA_A"                                                                                                          
[105] "Tpct.FA_A1"                                                                                                    
[106] "Tpct.FA_Ap"                                                                                                    
[107] "X..Total...Population.of.one.race...Native.Hawaiian.and.Other.Pacific.Islander.alone"                          
[108] "FA_NHOPI"                                                                                                      
[109] "Tpct.NHOPI1"                                                                                                   
[110] "Tpct.NHOPIp"                                                                                                   
[111] "white1"                                                                                                        
[112] "whitep"                                                                                                        
[113] "nonwhite1"                                                                                                     
[114] "nonwhitep"                                                                                                     
[116] "X..Total...Population.of.one.race...Some.Other.Race.alone"                                                     
[117] "FA_otherrace"                                                                                                  
[118] "Tpct.OR"                                                                                                       
[119] "X..Total...Population.of.two.or.more.races."                                                                   
[120] "FA_2.or.more_R"                                                                                                
[121] "Tpct.2.or.more_R"                                                                                              
[122] "X..Total...Population.of.two.or.more.races...Population.of.two.races."                                         
[123] "FA_Two_R"                                                                                                      
[124] "Tpct.2_R"                                                                                                      
[125] "X..Total.Housing_units"                                                                                        
[126] "FA_Housingunits"                                                                                               
[127] "X..Total...Occupied"                                                                                           
[128] "FA_occupied"                                                                                                   
[129] "Tpct.FA_occ"                                                                                                   
[130] "X..Total...Vacant"                                                                                             
[131] "FA_vaccant"                                                                                                    
[132] "Tpct.FA_vaccant"                                                                                               
[133] "X..Total.0ccupied_housing_units"                                                                               
[134] "X..Total...Owner.occupied."                                                                                    
[135] "FA_owner_occ"                                                                                                  
[136] "Tpct.FA_owner_occ"                                                                                             
[137] "X..Total...Renter.occupied."                                                                                   
[138] "FA_renter_occ"                                                                                                 
[139] "Tpct.FA_renter_occ"                                                                                            
[143] "Bpopulation"                                                                                                   
[144] "BGPopulation"                                                                                                  
[145] "popweights"                                                                                                    
[146] "BGEstimate..Total.Pop..5.year.or.above."                                                                       
[147] "BEstimate..Total.Pop..5.year.or.above."                                                                        
[148] "BGEstimate..Total...Speak.only.English"                                                                        
[149] "BlockEstimate..Total...Speak.only.English"                                                                     
[150] "FA_BlockEstimate..Total...Speak.only.English"                                                                  
[151] "ratio_FA_BlockEstimate..Total...Speak.only.English"                                                            
[152] "Tpct_FA_Eng_speakers"                                                                                          
[153] "BGEstimate..Total...Speak.other.languages."                                                                    
[154] "BEstimate..Total...Speak.other.languages."                                                                     
[155] "FA_BEstimate..Total...Speak.other.languages."                                                                  
[156] "ratio_FA_BEstimate..Total...Speak.other.languages."                                                            
[157] "Tpct_FA_Non.Eng_speakers"                                                                                      
[158] "BGEstimate..Per.capita.income.in.the.past.12.months..in.2023.inflation.adjusted.dollars."                      
[159] "BGEstimate..Total.pop...Income.in.the.past.12.months.below.poverty.level."                                     
[160] "BEstimate..Total.pop...Income.in.the.past.12.months.below.poverty.level."                                      
[161] "FA_BEstimate..Total.pop...Income.in.the.past.12.months.below.poverty.level."                                   
[162] "ratio_FA_BEstimate..Total.pop...Income.in.the.past.12.months.below.poverty.level."                             
[163] "Tpct_FA_poverty"                                                                                               
[164] "BGEstimate..Total..Pop.over.25"                                                                                
[165] "BEstimate..Total..Pop.over.25"                                                                                 
[166] "BGEstimate..Total...No.schooling.completed..no.formal.education"                                               
[167] "BEstimate..Total...No.schooling.completed..no.formal.education"                                                
[168] "FA_BEstimate..Total...No.schooling.completed..no.formal.education"                                             
[169] "ratio_FA_B.no.formal.education"                                                                                
[170] "Tpct_FA_B.no.formal.education"                                                                                 
[171] "BGHighschool.OR.equivalent"                                                                                    
[172] "BHighschool.OR.equivalent"                                                                                     
[173] "FA_BHighschool.OR.equivalent"                                                                                  
[174] "ratio_FA_BHighschool"                                                                                          
[175] "Tpct_FA_BHighschool"                                                                                           
[176] "BGEstimate..Total...Associate.s.degree"                                                                        
[177] "BEstimate..Total...Associate.s.degree"                                                                         
[178] "FA_BEstimate..Total...Associate.s.degree"                                                                      
[179] "ratio_FA_BAssociate.s.degree"                                                                                  
[180] "Tpct_FA_BAssociate.s.degree"                                                                                   
[181] "BGEstimate..Total...Bachelor.s.degree"                                                                         
[182] "BEstimate..Total...Bachelor.s.degree"                                                                          
[183] "FA_BEstimate..Total...Bachelor.s.degree"                                                                       
[184] "ratio_FA_BBachelor.s.degree"                                                                                   
[185] "Tpct_FA_BBachelor.s.degree"                                                                                    
[186] "BGgraduate.or.Professional.degree"                                                                             
[187] "Bgraduate.or.Professional.degree"                                                                              
[188] "FA_Bgraduate.or.Professional.degree"                                                                           
[189] "ratio_FA_Bgraduate.or.Professional.degree"                                                                     
[190] "Tpct_FA_Bgraduate.or.Professional.degree"                                                                      
[193] "ww_pct_bbg_noschooling"                                                                                        
[194] "ww_bbg_pct_highsch"                                                                                            
[195] "ww_bbg_pct_associate"                                                                                          
[196] "ww_pct.bbg.belowbachelors"                                                                                     
[197] "ww_bbg_pct_bachelor"                                                                                           
[198] "ww_bbg_pct_graduate.Prof"                                                                                      
[199] "ww_pct.bbg_atand.above.bachelors"                                                                              
[200] "ww_bbg_pct_belowpoverty"                                                                                       
[201] "Estimate..Per.capita.income.in.the.past.12.months..in.2023.inflation.adjusted.dollars..Block.Percapitaincome"  
[202] "ww_bbg_pct_noneng"                                                                                             
[203] "ww_bbg_pct_speak.eng"                                                                                          
[204] "Pop_weight"                                                                                                    
[205] "Estimate..Median.household.income.in.the.past.12.months..in.2023.inflation.adjusted.dollars."                  
[206] "PercapitaInc"                                                                                                  
[208] "Income_b"                                                                                                      
[209] "Estimate..Per.capita.income.in.the.past.12.months..in.2023.inflation.adjusted.dollars..Block.Percapitaincome.1"
[211] "Estimate..Total.Pop..5.year.or.above.blockgroup"                                                               
[212] "Estimate..Total.Pop..5.year.or.above.block..Pop.weighted"                                                      
[213] "Estimate..Total...Speak.only.English.Block.Group"                                                              
[214] "Estimate..Total...Speak.only.English.Block.Pop.weighted"                                                       
[215] "w_bbg_ratio_speak.eng"                                                                                         
[216] "ww_bbg_ratio_speak.eng"                                                                                        
[217] "ww_bbg_pct_speak.eng.1"                                                                                        
[218] "Estimate..Total...Speak.other.languages.Block.Group"                                                           
[219] "Estimate..Total...Speak.other.languages.Block.Population.weighted"                                             
[220] "w_bbg_ratio_noneng"                                                                                            
[221] "ww_bbg_ratio_noneng"                                                                                           
[222] "ww_bbg_pct_noneng.1"                                                                                           
[223] "Estimate..Median.household.income.in.the.past.12.months..in.2023.inflation.adjusted.dollars..1"                
[224] "Estimate..Per.capita.income.in.the.past.12.months..in.2023.inflation.adjusted.dollars."                        
[225] "Estimate..Per.capita.income.in.the.past.12.months..in.2023.inflation.adjusted.dollars..Block.Percapitaincome.2"
[226] "Estimate..Total.pop...Income.in.the.past.12.months.below.poverty.level.Block.group"                            
[227] "Estimate..Total.pop...Income.in.the.past.12.months.below.poverty.level.Pop.weighted.Block"                     
[228] "w_bbg_ratio_belowpoverty"                                                                                      
[229] "ww_bbg_ratio_belowpoverty"                                                                                     
[230] "ww_bbg_pct_belowpoverty.1"                                                                                     
[231] "Estimate..Total..Pop.over.25.Block.group"                                                                      
[232] "Estimate..Total..Pop.over.25.Block.Pop.weighted"                                                               
[233] "Estimate..Total...No.schooling.completed..no.formal.education.Block.Group"                                     
[234] "Estimate..Total...No.schooling.completed..no.formal.education.Block.Pop.weighted"                              
[235] "w_ratio_bbg_noschooling"                                                                                       
[236] "ww_ratio_bbg_noschooling"                                                                                      
[237] "ww_pct_bbg_noschooling.1"                                                                                      
[238] "Estimate..Total...Regular.high.school.diploma.Block.group"                                                     
[239] "Estimate..Total...Regular.high.school.diploma.Block"                                                           
[240] "w_bbg_ratio__highsch"                                                                                          
[241] "ww_bbg_ratio_highsch"                                                                                          
[242] "ww_bbg_pct_highsch.1"                                                                                          
[243] "Estimate..Total...Associate.s.degree.Block.Group"                                                              
[244] "Estimate..Total...Associate.s.degree.Block"                                                                    
[245] "w_bbg_ratio_associate"                                                                                         
[246] "ww_bbg_ratio_associate"                                                                                        
[247] "ww_bbg_pct_associate.1"                                                                                        
[248] "Estimate..Total...Bachelor.s.degree.Block.Group"                                                               
[249] "Estimate..Total...Bachelor.s.degree.popweighted.Block"                                                         
[250] "w_bbg_ratio_bachelor"                                                                                          
[251] "ww_bbg_ratio_bachelor"                                                                                         
[252] "ww_bbg_pct_bachelor.1"                                                                                         
[253] "Graduate.or.Professional.degree.Block.Level"                                                                   
[254] "Graduate.or.Professional.degree.Block.Pop.weighted"                                                            
[255] "w_ratio_bbg_graduate.Prof"                                                                                     
[256] "ww_bbg_ratio_graduate.Prof"                                                                                    
[257] "ww_bbg_pct_graduate.Prof.1"                                                                                    
                 
  *  census_blocks_sample_sociodemographic_20250502.csv

Parcel scale data on fire impacts and urban morphology characteristics as a geopackage (.gpkg)
  *  combined_la_fires_parcel_all_structures_data.gpkg

Parcel scale data on fire impacts and urban morphology characteristics as a CSV (.CSV)
  *  combined_la_fires_parcel_all_structures_data_20250414_v2.csv

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