#Purpose: Filter, combined, and write underlying data for the LA Fires
#Created by: Carl A. Norlen
#Created date: 3/6/2025
#Updated date: 2/18/2026

#Packages for analysis
my_packages <- c('tidyverse', 'ggpubr', 'sf', 'patchwork', 'tigris', 'tidycensus', 'units', 'osmdata', 'rethnicity', 'terra')

#Load the packages
lapply(my_packages, require, character.only = TRUE)
options(tigris_use_cache = TRUE)

#Data directory
dir <- 'C://Users//cnorlen//mystuff//data//urban-fires//'

#Load the FRAP data
frap <- st_read(paste0(dir, 'fire23-1.shp'))

#Extract the CRS from FRAP
c <- st_crs(frap)

#Select NIFC perimeters for Palisades and Eaton Fires
wgis <- st_read(paste0(dir, 'WFIGS_Interagency//Perimeters.shp'))

#Select just the LA Fires Data
la.fires <- wgis %>% filter(poly_Incid %in% c('Eaton', 'PALISADES'))

#Transform the LA fires to CA Albers
la.fires <- st_transform(la.fires, c)

#Add a 100-meter buffer to the fire
la.fires.buffer <- la.fires %>% st_buffer(dist = 100)

#Filter and save the Microsoft Building footprint data
building.footprint <- st_read(paste0(dir, 'California.building.footprint.geojson'))

#Transform the building footprint to CA Albers
building.footprint <- st_transform(building.footprint, c)

#Filter the building footprint
building.footprint.filter <- building.footprint %>% st_filter(la.fires.buffer, .predicates= st_intersects())

#Write the filtered file
st_write(building.footprint.filter, paste0(dir,'la.fires.building.footprint.gpkg'), delete_layer = TRUE)

#Filter and save the LA DINS data
#DINS full California data set
dins.ca <- st_read(paste0(dir, 'DINS//POSTFIRE_MASTER_DATA_SHARE.gpkg'))

#The full DINS dataset with parcel data
dins.la.fires <- dins.ca %>% filter(INCIDENTNAME %in% c('Eaton', 'Palisades'))

#Transform the Data
dins.la.fires <- st_transform(dins.la.fires, c)

#Write the filtered DINS data
st_write(dins.la.fires,  paste0(dir,'DINS//dins_postfire_la_fires.gpkg'), delete_layer = TRUE)

#Filter and write the USACE structure data
#Add the USACE Structure Data
usace.structure <- st_read(paste0(dir, 'nsi_2022_06.gpkg'))

#Transform the reference system of the USACE data
usace.structure <- st_transform(usace.structure , c)

#USACE filtered structure data
usace.structure.filter <- usace.structure %>% st_filter(la.fires.buffer, .predicates= st_intersects())

#Save the filter USACE data as a geopackage
st_write(usace.structure.filter,  paste0(dir,'nsi_2022_06_filter.gpkg'), delete_layer = TRUE)

#Filter and Write Core Logic data for the LA Fires
core.logic.1 <- st_read(paste0(dir, 'CoreLogic Data//Point Files//og_06037_points_pro_1.shp'))

core.logic.2 <- st_read(paste0(dir, 'CoreLogic Data//Point Files//og_06037_points_pro_2.shp'))

core.logic.3 <- st_read(paste0(dir, 'CoreLogic Data//Point Files//og_06037_points_pro_3.shp'))

core.logic.combine <- rbind(core.logic.1, core.logic.2, core.logic.3)

#Transform the refernce of the Geopackage
core.logic.combine <- st_transform(core.logic.combine, c)

#Filter the corelogic data to the fire perimeters
core.logic.filter <- core.logic.combine %>% st_filter(la.fires.buffer, .predicates= st_intersects())

#Save the filter Core Logic data as a geopackage
st_write(core.logic.filter,  paste0(dir,'og_06037_points_pro_combine_la_fires.gpkg'), delete_layer = TRUE)