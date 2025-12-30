#Purpose: Export data combine with the census block and block group data.
#Created by: Carl A. Norlen
#Created date: 3/10/2025
#Updated date: 4/11/2025

#install packages
# install.packages(c('terra'))

#Packages for analysis
my_packages <- c('tidyverse', 'ggpubr', 'sf', 'patchwork', 'tigris', 'tidycensus', 'units', 'osmdata', 'rethnicity', 'terra')

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
# plot(la.fires.buffer)
# plot(la.fires)

#TEsting census variables
dhc.2020 <- load_variables(2020, "dhc", cache = TRUE)

dp.2020 <- load_variables(2020, "dp", cache = TRUE)

#LA Building footprint
building.footprint <- st_read( paste0(dir,'la.fires.building.footprint.gpkg'))

#Add the structure data filter for the fires
nsi.fires <- st_read(paste0(dir,'nsi_2022_06_filter.gpkg'), layer = 'nsi_2022_06_filter')

#Add the LA Fires Building Overlaps
la.fires.building.overlap <- sf::st_read(paste0(dir, 'building_footprint_overlaps.geojson'))
la.fires.building.overlap <- la.fires.building.overlap |> select(-c('dstnc_c')) |> rename(footprint.acre = ftprnt_c, footprint.sqft = ftprnt_s)

#Transform the spatial reference system.
la.fires.building.overlap <- la.fires.building.overlap |> st_transform(c)

la.fires.building.overlap <- la.fires.building.overlap |> mutate(zone_one_overlap_correct = zone_one_overlap - zone_zero_overlap, zone_two_overlap_correct = zone_two_overlap - zone_one_overlap - zone_zero_overlap)

#CAlifornia Census Blocks
la.blocks.2020 <- tigris::blocks(
  state = "CA",
  county = "Los Angeles",
  year = 2020)

la.blocks.2020 <- st_transform(la.blocks.2020, c)

#Filter by the census blocks
la.fire.blocks <- la.blocks.2020 %>% st_filter(la.fires.buffer, .predicates = st_intersects)
# la.fire.tracts %>% plot()
#Label the tracts by which fire they intersect
la.fire.blocks <- la.fire.blocks %>% mutate(which.fire = case_when(lengths(st_intersects(la.fire.blocks, la.fires.buffer %>% filter(poly_Incid == 'Eaton'))) > 0 ~ 'Eaton', 
                                                                   lengths(st_intersects(la.fire.blocks, la.fires.buffer %>% filter(poly_Incid == 'PALISADES'))) > 0 ~ 'Palisades'))

#Combine the census blocks into two polygons
la.fire.blocks.union <- la.fire.blocks |> 
  # Filter for Urban Census Blocks
  # filter(NAME != '9304') %>%
  #Group by the 2025 Fire
  group_by(which.fire) |> 
  #Combine the census blocks
  st_union()

#California counties
ca.counties <- counties(state = "CA", cb = FALSE, resolution = "500k", year = 2020)
# head(la)

#LA county
la.county <-  ca.counties %>% filter(NAME == "Los Angeles")
la.county <- st_transform(la.county, crs = c)

#LA County FRAP perimeters
frap.la <- frap %>% st_filter(la.fires, .predicates = st_intersects)
frap.la <- frap.la %>% mutate(year = as.numeric(frap.la$YEAR_))

#Adding a label with the fires
frap.la <- frap.la %>% mutate(which.fire = case_when(lengths(st_intersects(frap.la, la.fires %>% filter(poly_Incid == 'Eaton'))) > 0 ~ 'Eaton', lengths(st_intersects(frap.la, la.fires %>% filter(poly_Incid == 'PALISADES'))) > 0 ~ 'Palisades'))

#Create FRAP Burned area
#FRAP (1910 to 2023) intersection with census tracts, combined FRAP into one polygon
frap.la.block.intersect <- frap.la %>% st_union() %>% st_as_sf() %>% st_intersection(la.fire.blocks)

#Add the area of the clipped fires
frap.la.block.intersect <- frap.la.block.intersect %>% mutate(fire.area.1910to2023 = set_units(st_area(frap.la.block.intersect), 'hectare')) 

#Merge the building footprints and intersect them with la.fire.blocks
la.building.block.intersect <- building.footprint |> st_union() |> st_as_sf() |> st_intersection(la.fire.blocks)

#Add the area of the clipped building footprints
la.building.block.intersect <- la.building.block.intersect |> mutate(building.area = set_units(st_area(la.building.block.intersect), 'm^2'))

#Create census block burned area
la.fires.block.clipped <- st_buffer(la.fires,0) %>% st_intersection(la.fire.blocks)

#Add acres of the fire area
la.fires.block.clipped <- la.fires.block.clipped %>% mutate(fire.area.2025 = set_units(st_area(la.fires.block.clipped), 'hectare'))

#Intersect teh structure overlaps with the census blocks
la.building.overlap.instersect <- la.fires.building.overlap |> st_intersection(la.fire.blocks)

#Summarize the zone 0, 1, and 2 overlaps
la.building.overlap.summary <- la.building.overlap.instersect |> group_by(BLOCKCE20, TRACTCE20) |> summarize(zone_zero_overlap_mean = mean(zone_zero_overlap), zone_one_overlap_mean = mean(zone_one_overlap), zone_two_overlap_mean = mean(zone_two_overlap))

#Add the NSI structure value
#USACE structure intersect with parcels
nsi.fires.block.intersect <- nsi.fires |> st_intersection(la.fire.blocks)

#Combine data together
nsi.fires.block.summary <- nsi.fires.block.intersect |> group_by(BLOCKCE20, TRACTCE20) |> summarize(structure_value_median = median(val_struct))

#add the pre-2023 fire areas
#Add 2025 fire area, tract area, and 2025 % affected to the layers
block.join <- la.fire.blocks %>% 
  left_join(as.data.frame(la.fires.block.clipped) |> select(c('TRACTCE20', 'BLOCKCE20', 'fire.area.2025')), by = c('TRACTCE20', 'BLOCKCE20')) |> 
  left_join(as.data.frame(frap.la.block.intersect) |> select(c('TRACTCE20', 'BLOCKCE20', 'fire.area.1910to2023')), by = c('TRACTCE20', 'BLOCKCE20')) |>
  left_join(as.data.frame(la.building.block.intersect) |> select(c('TRACTCE20', 'BLOCKCE20', 'building.area')), by = c('TRACTCE20', 'BLOCKCE20')) |>
  left_join(as.data.frame(la.building.overlap.summary) |> select(c('TRACTCE20', 'BLOCKCE20', 'zone_zero_overlap_mean', 'zone_one_overlap_mean', 'zone_two_overlap_mean')), by = c('TRACTCE20', 'BLOCKCE20')) |>
  left_join(as.data.frame(nsi.fires.block.summary) |> select(c('TRACTCE20', 'BLOCKCE20', 'structure_value_median')), by = c('TRACTCE20', 'BLOCKCE20')) |>
  mutate(block.area = set_units(st_area(la.fire.blocks), 'hectare')) 
block.join$fire.area.2025[is.na(block.join$fire.area.2025)] <- 0
block.join$fire.area.1910to2023[is.na(block.join$fire.area.1910to2023)] <- 0
block.join$building.area[is.na(block.join$building.area)] <- set_units(0, 'm^2')
block.join <- block.join |> mutate(fire.area.2025.pct = (fire.area.2025 / block.area) * 100, fire.area.1910to2023.pct = (fire.area.1910to2023 / block.area) * 100,
                                   structure.basal.area = building.area / block.area)

#LA County Parcels combined with DINS data
dins.la <- st_read(paste0(dir, '2025_Parcels_with_DINS_data_1400140593036023148.gpkg'))
# dins.la %>% glimpse()
# dins.la %>% as.data.frame() %>% select(Fire_Name) %>% unique()
dins.la <- st_transform(dins.la, c)
dins.la <- dins.la %>% mutate(DAMAGE_1.num = case_when(DAMAGE_1 == 'No Damage' ~ 1, DAMAGE_1 == 'Affected (1-9%)' ~ 2, DAMAGE_1 == 'Minor (10-25%)' ~ 3, DAMAGE_1 == 'Major (26-50%)' ~ 4, DAMAGE_1 == 'Destroyed (>50%)' ~ 5))
# dins.la <- dins.la %>% mutate(YearBuilt.median = median(YearBuilt1))

#Add the Core Logic 
#Consider switching to the CSV data
core.logic <- st_read(paste0(dir, 'og_06037_points_pro_combine_la_fires.gpkg'))
# glimpse(core.logic)

#Join the DINS data and the Core Logic data by parcel number
dins.core.join <- dins.la %>% left_join(core.logic |> as.data.frame() |> distinct(APN, .keep_all = TRUE), by = c('AIN_1' = 'APN'))

#Create a summary of block level DINS and fire area data
dins.core.block.join <- dins.core.join %>% 
  #Filter by Fire Name
  filter(Fire_Name %in% c('Eaton', 'Palisades')) %>%
  #Join the DINS data to the census tract that it intersects with
  st_join(la.fire.blocks, join = st_intersects)

# dins.core.block.join |> summary()

#Summarize the total structures and median home value for each tract
block.summary <- dins.core.block.join %>% 
  #Convert the data to data frame
  as.data.frame %>% 
  #Filter the data
  filter(!is.na(TOT_VAL) & UseDescription == 'Single' & UseType == 'Residential' & DINS_Count >= 1 & !is.na(YearBuilt1) & !is.na(DAMAGE_1) & DAMAGE_1 != 'Inaccessible') %>% 
  group_by(TRACTCE20, BLOCKCE20) %>%
  #Summarize the data
  #Replace the value with the median of the USACE replacement value?
  summarize(destroy.count = sum(DAMAGE_1.num == 5), major.damage.count = sum(DAMAGE_1.num  == 4), minor.damage.count = sum(DAMAGE_1.num == 3), affected.count = sum(DAMAGE_1.num == 2), 
            no.damage.count = sum(DAMAGE_1.num == 1), structure.count = n(), year.built.median = median(as.numeric(YearBuilt1)), year.built.2008.count = sum(YearBuilt1 > 2008),
            #2023 Assessed taxable value from LA County Assessor's Office
            property.value.median = median(Roll_LandValue + Roll_ImpValue)) %>%
  #Add more data columns
  mutate(destroy_pct = (destroy.count / structure.count) * 100, 
         major_damage_pct = (major.damage.count / structure.count) * 100, 
         minor_damage_pct = (minor.damage.count / structure.count) * 100, 
         affected_pct = (affected.count / structure.count) * 100, 
         no_damage_pct = (no.damage.count / structure.count) * 100,
         after_2008_pct = (year.built.2008.count / structure.count) * 100)

#Add the 2022 Tree Cover summary
tree.cover.summary <- read.csv(paste0(dir, 'tree_cover_block_summary_20250402_v2.csv'))
tree.cover.summary$TRACTCE20 <- as.character(tree.cover.summary$TRACTCE20)
tree.cover.summary$BLOCKCE20 <- as.character(tree.cover.summary$BLOCKCE20)
tree.cover.summary$tree.cover.2022 <- (tree.cover.summary$sum / tree.cover.summary$count) * 100

#Add the summary values to the tracts for export
block.dins.sf <- block.join |> left_join(block.summary, by = c('TRACTCE20', 'BLOCKCE20')) |>
                               left_join(tree.cover.summary |> select('TRACTCE20', 'BLOCKCE20', 'tree.cover.2022'), 
                               by = c('TRACTCE20', 'BLOCKCE20'))

#Export the data as a geopackage
st_write(block.dins.sf, paste0(dir,'la_fires_census_blocks_dins_destroyed_burned_area.gpkg'), delete_layer = TRUE)

#Export the data as a CSV file
write.csv(as.data.frame(block.dins.sf) %>% select(-c('geometry')), file = "C://Users//CarlNorlen//mystuff//data//urban-fires//census_blocks_dins_destroyed_burned_area_20250411.csv")
