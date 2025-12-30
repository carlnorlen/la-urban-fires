#Purpose: Process and combine structure and parcel data for the Palisades and Eaton fires.
#Created by: Carl A. Norlen
#Created date: 3/6/2025
#Updated date: 4/14/2025

my_packages <- c('tidyverse', 'ggpubr', 'sf', 'patchwork', 'tigris', 'tidycensus', 'units', 'osmdata', 'rethnicity', 'gstat')
# library(gstat)
# library(tidycensus)
#Load the packages
lapply(my_packages, require, character.only = TRUE)
options(tigris_use_cache = TRUE)
# census_api_key('a37785ade28119ad5a1ba3ffc67f3a9812db4d23', install = TRUE)

#Data directory
dir <- 'C://Users//CarlNorlen//mystuff//data//urban-fires//'

#Load the FRAP data
frap <- st_read(paste0(dir, 'fire23-1.shp'))
c <- st_crs(frap)

#Select NIFC perimeters for Palisades and Eaton Fires
wgis <- st_read(paste0(dir, 'WFIGS_Interagency//Perimeters.shp'))
# plot(wgis)
la.fires <- wgis %>% filter(poly_Incid %in% c('Eaton', 'PALISADES'))
la.fires <- st_transform(la.fires, c)
# st_crs(la.fires)
#Add a 100-meter buffer to the fire
la.fires.buffer <- la.fires %>% st_buffer(dist = 100)

#Read the full DINS data
# dins.la.fires <- st_read(paste0(dir, 'DINS//dins_postfire_la_fires.gpkg'))
# 
# #Filter the DINS data
# dins.la.residence <- dins.la.fires %>% filter(STRUCTURECATEGORY %in% c('Single Residence', 'Multiple Residence', 'Mixed Commercial/Residential'))

#DINS data combined with LA parcels data
dins.la.residence <- st_read(paste0(dir, '2025_Parcels_with_DINS_data_1400140593036023148.gpkg')) |> 
                     filter(!is.na(STRUCTURECATEGORY))

#Spatially transform the data
dins.la.residence <- st_transform(dins.la.residence, c)

# #DINS original test
# dins.test <- st_read(paste0(dir, 'DINS//dins_postfire_la_fires.gpkg'))
#LA County Parcels
la.parcels <- st_read(paste0(dir, 'LACounty_Parcels_Shapefile//LACounty_Parcels.shp'))
la.parcels <- st_transform(la.parcels, c)

#Add the Core Logic
#This seems to have about 300 duplicate values
core.logic.fires <- st_read(paste0(dir, 'og_06037_points_pro_combine_la_fires.gpkg'))
# ggplot() + geom_sf(data = core.logic.fires)

#Add the structure data filter for the fires
nsi.fires <- st_read(paste0(dir,'nsi_2022_06_filter.gpkg'), layer = 'nsi_2022_06_filter')

#Add Filtered Microsoft structure data
la.fires.building.footprint <- st_read(paste0(dir,'la.fires.building.footprint.gpkg'))

la.fires.building.footprint <- la.fires.building.footprint %>% mutate(footprint.msq = set_units(st_area(la.fires.building.footprint), 'm^2'), footprint.hectare = set_units(st_area(la.fires.building.footprint), 'hectares'))

la.fires.building.overlap <- st_read(paste0(dir, 'building_footprint_overlaps.geojson'))
la.fires.building.overlap <- la.fires.building.overlap |> select(-c('dstnc_c')) |> rename(footprint.acre = ftprnt_c, footprint.sqft = ftprnt_s)

la.fires.building.overlap <- la.fires.building.overlap |> st_transform(c)

la.fires.building.overlap <- la.fires.building.overlap |> mutate(zone_one_overlap_correct = zone_one_overlap , zone_two_overlap_correct = zone_two_overlap - zone_one_overlap - zone_zero_overlap)


#Test core logic filtering

#Join the Parcels and the core logic together
#Filter the core logic data so that there are only distinct APN vales (some parcels have the same APN)
#Re-run this with the left join for Core Logic
dins.core.join <- dins.la.residence |> left_join(core.logic.fires |> as.data.frame() |> distinct(APN, .keep_all = TRUE), by = c('AIN_1' = 'APN'))

#Join the DINS and USACE Structure Data based on distance of 2 meters
dins.core.usace.join <- dins.core.join |> st_join(nsi.fires, left = TRUE, join = st_nearest_feature)

#Add the building foot print information to 
all.join <- dins.core.usace.join |> st_join(la.fires.building.overlap, left = TRUE, join = st_nearest_feature)

#Calculate the structure basal area within the census blocks
la.building.parcel.intersect <- la.fires.building.footprint |> st_union() |> st_as_sf() |> st_intersection(dins.la.residence)

#Add the area of the clipped building footprints
la.building.parcel.summary <- la.building.parcel.intersect |> mutate(building.area = set_units(st_area(la.building.parcel.intersect), 'm^2'))

#Add some additional data columns based on calcuations and joining data
all.join.mutate <- all.join |> 
  #Calculate the population totals
  mutate(over.65.pct = pop2amo65 / (pop2amu65 + pop2amo65),
         under.65.pct = pop2amu65 / (pop2amu65 + pop2amo65),
         pop.total = pop2amu65 + pop2amo65) |>
 #Join the building area layer
 left_join(as.data.frame(la.building.parcel.summary) |> select(c('AIN_1', 'building.area')), by = 'AIN_1') |>
 #All the parcel area in hectares
 mutate(parcel.area = set_units(st_area(all.join), 'hectare')) |>
 #Calculate the structure basal area
 mutate(structure.basal.area = building.area / parcel.area)

#Calculate the full name ethnicity
fullname <- all.join |> filter(!is.na(OWN1_LAST) & !is.na(OWN1_FRST)) %>% mutate(race = (predict_ethnicity(lastnames = as.vector((all.join %>% filter(!is.na(OWN1_LAST) & !is.na(OWN1_FRST)))$OWN1_LAST), firstnames = as.vector((all.join %>% filter(!is.na(OWN1_LAST) & !is.na(OWN1_FRST)))$OWN1_FRST), method = "fullname"))$race)

#Calculate the last name ethnicity
lastname <- all.join |> filter(!is.na(OWN1_LAST) & is.na(OWN1_FRST)) |> mutate(race = (predict_ethnicity(lastnames = as.vector((all.join %>% filter(!is.na(OWN1_LAST) & is.na(OWN1_FRST)))$OWN1_LAST), method = "lastname"))$race)

name.na <- all.join |> filter(is.na(OWN1_LAST) & is.na(OWN1_FRST)) |> mutate(race = NA)

# ethnicity <- all.join |> mutate(race = case_when(!is.na(OWN1_LAST) & !is.na(OWN1_FRST) ~ list((predict_ethnicity(lastnames = as.vector((all.join %>% filter(!is.na(OWN1_LAST) & !is.na(OWN1_FRST)))$OWN1_LAST), firstnames = as.vector((all.join %>% filter(!is.na(OWN1_LAST) & !is.na(OWN1_FRST)))$OWN1_FRST), method = "fullname"))$race),
#                                 !is.na(OWN1_LAST) & is.na(OWN1_FRST) ~ list((predict_ethnicity(lastnames = as.vector((all.join %>% filter(!is.na(OWN1_LAST) & is.na(OWN1_FRST)))$OWN1_LAST), method = "lastname"))$race),
#                                 is.na(OWN1_LAST) & is.na(OWN1_FRST) ~ NA))

# ethnicity.filter <- ethnicity |> select(c('AIN_1', 'OWN1_LAST', 'OWN1_FRST', 'race'))

#Ethnicity combined between the last name and full name approaches 
ethnicity <- rbind(fullname |> select(c('AIN_1', 'OWN1_LAST', 'OWN1_FRST', 'race')), lastname |> select(c('AIN_1', 'OWN1_LAST', 'OWN1_FRST', 'race')), name.na |> select(c('AIN_1', 'OWN1_LAST', 'OWN1_FRST', 'race')))

# ethnicity |> pull(AIN_1) |> as.numeric() |> unique() |> count()

#Add the full name ethnicity fields to the large data table
all.join.ethnicity <- all.join.mutate |> left_join(as.data.frame(ethnicity) |> select(c('AIN_1', 'race')), by = 'AIN_1')

#Add the Tree Cover Parcel data and add it to the layers
tree.cover <- read.csv(paste0(dir, 'tree_cover_parcel_summary_20250402_v2.csv'))
tree.cover$tree.cover.2022 <- (tree.cover$sum / tree.cover$count) * 100
tree.cover$AIN <- as.character(tree.cover$AIN)

#Join the tree cover data to the rest of the data
all.join.ethnicity.tree <- all.join.ethnicity |> inner_join(tree.cover |> select('AIN', 'tree.cover.2022'), by = c('AIN_1' = 'AIN'))

#Convert NAs to 0's for tree cover and structure basal area
all.join.ethnicity.tree$tree.cover.2022[is.na(all.join$tree.cover.2022)] <- 0
all.join.ethnicity.tree$structure.basal.area[is.na(all.join$structure.basal.area)] <- 0

#Add Pre-2025 Fire (Yes or No)
#LA County FRAP perimeters
frap.la <- frap %>% st_filter(la.fires, .predicates = st_intersects)
frap.la <- frap.la %>% mutate(year = as.numeric(frap.la$YEAR_))

#Create FRAP Burned area
#FRAP (1910 to 2023) intersection with census tracts, combined FRAP into one polygon
all.join.export <- all.join.ethnicity.tree |> 
                   mutate(fire.exposed.1910to2023 = case_when(lengths(st_intersects(all.join.ethnicity.tree, frap.la |> st_union() |> st_as_sf())) > 0 ~ '1', 
                                                              lengths(st_intersects(all.join.ethnicity.tree, frap.la |> st_union() |> st_as_sf())) == 0 ~ '0'))

#Calculate a few more variables
all.join.export <- all.join.export |> mutate(race.num = case_when(race == 'black' ~ 1, race == 'hispanic' ~ 2, race == 'white' ~ 3, race == 'asian' ~ 4, is.na(race) ~ NA))

# all.join <- all.join %>% mutate(total.value = Roll_LandValue + Roll_ImpValue)

# all.join <- all.join |> mutate(built.date = case_when(YearBuilt1 > as.numeric(2008) ~ 'Built after 2008', YearBuilt1 <= as.numeric(2008) ~ 'Built 2008 or Before'))

all.join.export <- all.join.export |> mutate(DAMAGE_1.num = case_when(DAMAGE_1 == 'No Damage' ~ 1, DAMAGE_1 == 'Affected (1-9%)' ~ 2, DAMAGE_1 == 'Minor (10-25%)' ~ 3, DAMAGE_1 == 'Major (26-50%)' ~ 4, DAMAGE_1 == 'Destroyed (>50%)' ~ 5, DAMAGE_1 == 'Inaccessible' ~ NA))

# all.join <- all.join |> select(-c('fire.area.1910to2023'))

#Add the last name ethnicity fields to the large data tables
st_write(all.join.export, paste0(dir,'combined_la_fires_parcel_all_structures_data.gpkg'), delete_layer = TRUE)
# colnames(all.join)
#Write the structure data as a CSV file
# test <- all.join.export |> as.data.frame()

write.csv(all.join.export |> as.data.frame() |> select(-c('SHAPE', 'geom')), paste0(dir,'combined_la_fires_parcel_all_structures_data_20250414_v2.csv'), row.names = FALSE)
