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
census block area (ha; block.area), 2025 proportion of census block burned (%; fire.area.2025.pct), 1910-2023 proportion of census block burned (%; fire.area.1910to2023.pct), "structure.basal.area"    
[31] "destroy.count"            "major.damage.count"       "minor.damage.count"       "affected.count"           "no.damage.count"         
[36] "structure.count"          "year.built.median"        "year.built.2008.count"    "property.value.median"    "destroy_pct"             
[41] "major_damage_pct"         "minor_damage_pct"         "affected_pct"             "no_damage_pct"            "after_2008_pct"          
[46] "tree.cover.2022"

  *  census_blocks_dins_destroyed_burned_area_20250424.csv

Parcel scale data on fire impacts and urban morphology characteristics as a geopackage (.gpkg)
  *  combined_la_fires_parcel_all_structures_data.gpkg

Parcel scale data on fire impacts and urban morphology characteristics as a CSV (.CSV)
  *  combined_la_fires_parcel_all_structures_data_20250414_v2.csv

Census Block scale data on fire impacts and urban morphology characteristics as a geopackage (.gpkg)
  *  la_fires_census_blocks_dins_destroyed_burned_area.gpkg
  
Socio-economic Census Block data used for figure creation
  *  census_blocks_sample_sociodemographic_20250502.csv
  
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