#Purpose: Analysis the parcel and neighborhood scale impacts of the 2025 LA Urban Fres 
#Created by: Carl A. Norlen
#Created date: 2/10/2025
#Updated date: 8/1/2025

#Packages for analysis
my_packages <- c('tidyverse', 'ggpubr', 'sf', 'patchwork', 'tigris', 'tidycensus', 'units', 'osmdata', 'rethnicity', 'viridis', 'terra', 'corrplot', 'reshape2')

#Load the packages
lapply(my_packages, require, character.only = TRUE)
options(tigris_use_cache = TRUE)

#Data directory
dir <- 'C://Users//CarlNorlen//mystuff//data//urban-fires//'

#Load the FRAP data
frap <- st_read(paste0(dir, 'fire23-1.shp'))

#Extract CRS values
c <- st_crs(frap)

#Select NIFC perimeters for Palisades and Eaton Fires
wgis <- st_read(paste0(dir, 'WFIGS_Interagency//2025//Perimeters.shp'))
# plot(wgis)
la.fires <- wgis %>% filter(poly_Incid %in% c('Eaton', 'PALISADES'))
la.fires <- st_transform(la.fires, c)

#Add a 100-meter buffer to the fire
la.fires.buffer <- la.fires %>% st_buffer(dist = 100)

#Load the block summary data
block.summary <- read.csv('C://Users//CarlNorlen//mystuff//data//urban-fires//census_blocks_dins_destroyed_burned_area_20250424.csv')
# block.summary |> filter(UR20 == 'U' & !is.na(structure.count) & !is.na(structure_value_median)) |> pull('BLOCKCE20')

#Sociodemographic cencus block data
socio.demo.block <- read.csv(paste0(dir, 'census_blocks_sample_sociodemographic_20250502.csv'))

#Calculate the corrected values for US Census data
socio.demo.block <- socio.demo.block |> mutate(Tpct.FA_Hispanic_C = FA_Hispanic / fire.affected_pop, Tpct.FA_whitep_C = FA_white / fire.affected_pop, Tpct.FA_AAp_C = FA_AA / fire.affected_pop, Tpct.FA_AIANp_C = FA_AIAN / fire.affected_pop, 
                                               Tpct.FA_Ap_C = FA_A / fire.affected_pop, ww_bbg_pct_associate_C = FA_BEstimate..Total...Associate.s.degree / fire.affected_pop, ww_bbg_pct_bachelor_C = FA_BEstimate..Total...Bachelor.s.degree / fire.affected_pop, 
                                               ww_bbg_pct_graduate.Prof_C = FA_Bgraduate.or.Professional.degree / fire.affected_pop, ww_bbg_pct_belowpoverty_C = FA_BEstimate..Total.pop...Income.in.the.past.12.months.below.poverty.level. / fire.affected_pop, 
                                               ww_bbg_pct_noneng_C = FA_BEstimate..Total...Speak.other.languages. / fire.affected_pop, ww_pct_bbg_noschooling_C = FA_BEstimate..Total...No.schooling.completed..no.formal.education / fire.affected_pop, 
                                               ww_bbg_pct_highsch_C = FA_BHighschool.OR.equivalent / fire.affected_pop, Tpct.FA_renter_occ_C = FA_renter_occ / fire.affected_pop, Tpct.FA_65.and.over_yrs._C = FA_65.and.over_yrs. / fire.affected_pop, 
                                               ww_bbg_pct_speak.eng_C = FA_BlockEstimate..Total...Speak.only.English / fire.affected_pop)

#Load the block data
la.blocks.2020 <- tigris::blocks(
  state = "CA",
  county = "Los Angeles",
  year = 2020, )

# plot(la.blocks.2020)
#Update the CRS of the census blocks
la.blocks.2020 <- st_transform(la.blocks.2020, c)

# #Filter by the census blocks
la.fire.blocks <- la.blocks.2020 %>% st_filter(la.fires.buffer, .predicates = st_intersects)

#Add the summary values to the tracts for export
#Add selection of columns for block.summary
block.dins.sf <- st_read(paste0(dir, 'la_fires_census_blocks_dins_destroyed_burned_area.gpkg'))

#Update the CRES of teh 
block.dins.sf <- st_transform(block.dins.sf, c)

#Combine the census blocks into two polygons
la.fire.blocks.union <- block.dins.sf %>% 
  #Filter for Urban Census Blocks
  filter(!is.na(structure.count) & UR20 == 'U') %>%
  #Group by the 2025 Fire
  group_by(which.fire) %>% 
  #Combine the census blocks
  st_union()

#California counties
ca.counties <- counties(state = "CA", cb = FALSE, resolution = "500k", year = 2020)

#LA county
la.county <-  ca.counties %>% filter(NAME == "Los Angeles")
la.county <- st_transform(la.county, crs = c)

#LA County FRAP perimeters
frap.la <- frap %>% st_filter(la.fires, .predicates = st_intersects)
frap.la <- frap.la %>% mutate(year = as.numeric(frap.la$YEAR_))

#Adding a label with the fires
frap.la <- frap.la %>% mutate(which.fire = case_when(lengths(st_intersects(frap.la, la.fires %>% filter(poly_Incid == 'Eaton'))) > 0 ~ 'Eaton', lengths(st_intersects(frap.la, la.fires %>% filter(poly_Incid == 'PALISADES'))) > 0 ~ 'Palisades'))
# frap.la %>% head()

# plot(frap.la %>% filter(YEAR_ >= 1910) %>% st_intersection(la.fire.union))

#Total Fire Area
#FRAP intersection with census tracts
frap.la.intersect <- frap.la %>% st_intersection(la.fire.blocks.union)

#Add the area of the clipped fires
frap.la.intersect <- frap.la.intersect %>% mutate(area = set_units(st_area(frap.la.intersect), 'acre'))

#Add the total block area
frap.la.intersect <- frap.la.intersect %>% mutate(block.area = case_when(which.fire == 'Eaton' ~ la.fire.blocks %>% filter(which.fire == 'Eaton' & UR20 == 'U') %>% st_union() %>% st_area() %>% set_units('acre'),
                                                                         which.fire == 'Palisades' ~ la.fire.blocks %>% filter(which.fire == 'Palisades' & UR20 == 'U') %>% st_union() %>% st_area() %>% set_units('acre')))


'%notin%' <- negate('%in%')

fire.years <- data.frame(year = seq(1900, 2024))
eaton.years <- fire.years |> filter(!(year %in% (frap.la.intersect |> as.data.frame() |> filter(which.fire == 'Eaton') |> pull(year) |> unique())))
palisades.years <- fire.years |> filter(!(year %in% (frap.la.intersect |> as.data.frame() |> filter(which.fire == 'Palisades') |> pull(year) |> unique())))

#Fill in FRAP Missing years
frap.missing.years <- data.frame(which.fire = c(rep('Eaton', eaton.years |> count()), rep('Palisades', palisades.years |> count())), 
                                    year = rbind(eaton.years, palisades.years)$year,
                                    area = c(rep(set_units(0, 'acre'), eaton.years |> count()), rep(set_units(0, 'acre'), palisades.years |> count())),
                                    block.area = c(rep(frap.la.intersect |> as.data.frame() |> filter(which.fire == 'Eaton') |> pull(block.area) |> unique(), eaton.years |> count()),
                                                       rep(frap.la.intersect |> as.data.frame() |> filter(which.fire == 'Palisades') |> pull(block.area) |> unique(), palisades.years |> count())))

#Join the missing years to the full data set
frap.la.intersect.gap.fill <- frap.la.intersect |> full_join(frap.missing.years, by = c('which.fire', 'year', 'area','block.area'))

#LA Fires intersection with census blocks
wgis.la.intersect <- st_buffer(la.fires, 0) %>% st_intersection(la.fire.blocks.union)

#Get the areas of the 2025 fires
wgis.la.intersect <- wgis.la.intersect %>% mutate(area = set_units(st_area(wgis.la.intersect), 'acre'))

#Add a year field
wgis.la.intersect <- wgis.la.intersect %>% mutate(year = format(as.Date(poly_Creat, format="%Y-%m-%d"),"%Y"))

#Create the census tract burned area
la.fires.clipped <- st_buffer(la.fires,0) %>% st_intersection(la.fire.blocks)

#Get the 2025 acres burned
la.fire.clipped <- la.fires.clipped %>% mutate(fire.area.2025.acre = set_units(st_area(la.fires.clipped), 'acre'))

#Get the 2025 intersections
#Add the missing fire years here with zeros
wgis.la.intersect %>% select(year, poly_Incid, area) %>% mutate(which.fire = case_when(poly_Incid %in% c('Eaton') ~ 'Eaton', poly_Incid %in% c('PALISADES') ~ 'Palisades'),
                                                                block.area = case_when(which.fire %in% c('Eaton') ~ la.fire.blocks %>% filter(which.fire %in% c('Eaton') & UR20 %in% c('U')) %>% st_union() %>% st_area() %>% set_units('acre'),
                                                                which.fire %in% c('Palisades') ~ la.fire.blocks %>% filter(which.fire %in% c('Palisades') & UR20 %in% c('U')) %>% st_union() %>% st_area() %>% set_units('acre')))

#Combine the two fire perimeters
#I'm getting an error here for some reason
fire.combine.intersect <- rbind(frap.la.intersect.gap.fill |> select(year, which.fire, area, block.area), 
                                wgis.la.intersect |> select(year, poly_Incid, area) |> 
                                mutate(which.fire = case_when(poly_Incid %in% c('Eaton') ~ 'Eaton', 
                                                              poly_Incid %in% c('PALISADES') ~ 'Palisades'),
                                                              block.area = case_when(which.fire %in% c('Eaton') ~ la.fire.blocks |> filter(which.fire %in% c('Eaton') & UR20 %in% c('U')) |> st_union() |> st_area() |> set_units('acre'),
                                                              which.fire %in% c('Palisades') ~ la.fire.blocks |> filter(which.fire %in% c('Palisades') & UR20 %in% c('U')) |> st_union() |> st_area() |> set_units('acre'))) |> select(-c(poly_Incid)))



#Join the Sociodemo block data
#Block census groups
socio.demo.block$TRACTCE20 <- as.character(socio.demo.block$TRACTCE20)
socio.demo.block$BLOCKCE20 <- as.character(socio.demo.block$BLOCKCE20)

#Census blocks
combined.block.sf <- block.dins.sf |> filter(UR20 == 'U'& !is.na(structure.count) & fire.area.2025.pct > 0) |> 
  left_join(socio.demo.block |> 
              select(c('TRACTCE20', 'BLOCKCE20', 'Tpct.FA_male', 'Tpct.FA_female', 'Tpct.FA_under_5yrs', 'fire.affected_pop',
                       'Tpct.FA_5.19_yrs','Tpct.FA_20.64_yrs', 'Tpct.FA_65.and.over_yrs._C', 'Tpct.FA_Hispanic_C', 'Tpct.FA_not_Hispanic', 
                       'Tpct.FA_whitep_C', 'Tpct.FA_AAp_C', 'Tpct.FA_AIANp_C', 'Tpct.FA_Ap_C', 'Tpct.NHOPIp', 'Tpct.FA_occ', 
                       'Tpct.FA_vaccant', 'Tpct.FA_owner_occ', 'Tpct.FA_renter_occ_C','ww_pct_bbg_noschooling_C', 'ww_bbg_pct_highsch_C', 
                       'ww_bbg_pct_associate_C', 'ww_bbg_pct_bachelor_C', 'ww_bbg_pct_graduate.Prof_C', 'ww_bbg_pct_belowpoverty_C', 'ww_bbg_pct_noneng_C', 'ww_bbg_pct_speak.eng_C',
                       'PercapitaInc', 'Bpopulation')), 
            by = c('TRACTCE20', 'BLOCKCE20'))

#Add the parcel level data
#Add the last name ethnicity fields to the large data tables
all.join <- st_read(paste0(dir,'combined_la_fires_parcel_all_structures_data.gpkg'))

#Add a binary dmaage layer
all.join <- all.join |> mutate(damage.binary = case_when(DAMAGE_1 == 'Destroyed (>50%)' ~ 1, DAMAGE_1 == 'Inaccessible' ~ NA, DAMAGE_1 %in% c('Major (26-50%)', 'Minor (10-25%)', 'Affected (1-9%)', 'No Damage') ~ 0))

#Excludes the largest tract be Altadena because it has many previous fires
#Redo this figure with Census Blocks

#Combine panels for Figure 2
#Palisades Fires 
# p2a <- ggplot() +
#       ggtitle('Palisades') +
#       geom_sf(data = combined.block.sf %>% filter(which.fire == 'Palisades' & !is.na(structure_value_median) & !is.na(structure.count) & UR20 == 'U'), color = 'black', mapping = aes(fill = destroy_pct)) +
#       geom_sf(data = rbind(frap.la.intersect |> filter(year >= 1910 & which.fire == 'Palisades') |> st_union() |> st_as_sf() |> mutate(when.fire = '1910-2024'), 
#                            wgis.la.intersect |> filter(poly_Incid == 'PALISADES') |> mutate(when.fire = '2025') |> select(when.fire) |> rename(x = geometry)), 
#               mapping = aes(color = when.fire), fill = 'gray', linewidth = 1, alpha = 0) +
#       scale_color_brewer(name = 'Fire Impact Years', type = 'qual', palette = 6) +
#       scale_fill_viridis_c(option = 'magma', name = 'Homes Destroyed (%)') +
#       scale_linetype(name = 'Fire Years') +
#       theme_bw() +
#   theme(legend.position = "inside", legend.direction="horizontal", legend.position.inside = c(0.35, 0.75), 
#         legend.background = element_blank(), legend.title = element_text(size = 10), legend.text = element_text(size = 8),
#         axis.text.x = element_text(size = 12),
#         axis.text.y = element_text(size = 12)) +
#   guides(fill = guide_colorbar(title.position = "top", order = 2),
#          color = guide_legend(order = 1))
# p2a



#Create a bounding box
bound <- st_bbox(combined.block.sf %>% filter(which.fire == 'Eaton' & !is.na(structure.count) & !is.na(structure_value_median) & UR20 == 'U') |> st_transform(crs = "EPSG:4326"))
bound #|> st_as_sf() |> st_coordinates()

roads <- opq(bbox = bound) |> 
  add_osm_feature(key = 'highway', value = c("primary", "secondary", "tertiary", "residential")) |>
  osmdata_sf ()

ggplot() + geom_sf(data = roads$osm_lines)

# bound |> st_as_sf() |> st_coordinates()
# eaton.roads <- roads$osm_lines %>% st_transform(crs(combined.block.sf)) %>% st_crop(bound)
# crs(roads)
# roads$osm_lines %>% select(name) %>% unique()
roads$osm_lines
# ggplot() + geom_sf(data = hwy.93)

# head(available_features())

#Eaton Fire
p2b <- ggplot() +
    ggtitle('Eaton Fire') +
    geom_sf(data = combined.block.sf %>% filter(which.fire == 'Eaton' & !is.na(structure.count) & !is.na(structure_value_median) & UR20 == 'U'), 
            color = 'gray60', mapping = aes(fill = destroy_pct)) +
    # geom_sf(data = rbind(frap.la.intersect |> filter(year >= 1910 & which.fire == 'Eaton') |> st_union() |> st_as_sf() |> mutate(when.fire = '1910-2024'),
          #              wgis.la.intersect |> filter(poly_Incid == 'Eaton') |> mutate(when.fire = '2025') |> select(when.fire) |> rename(x = geometry)),
          # mapping = aes(color = when.fire), fill = 'gray', linewidth = 1 , alpha = 0) +
    geom_sf(data = roads$osm_lines, color = 'gray40', linewidth = 0.5) +
  scale_color_brewer(name = 'Fire Years', type = 'qual', palette = 6) +
  scale_fill_viridis_c(option = 'magma', name = 'Destroyed (%)') +
    theme_bw() +
  theme(legend.position = "inside", legend.direction="horizontal", legend.position.inside = c(0.8, 0.8),
        axis.text.x = element_text(size = 12),
        axis.text.y = element_text(size = 12)) +
  guides(fill = guide_colorbar(title.position = "top"))
p2b

#Save the figure
ggsave('Fig31_eaton_fire_with_roads.png',
       plot = p2b,
       path = 'C://Users//CarlNorlen//mystuff//la-urban-fires//figures',
       scale = 1,
       width = 18,
       height = 10,
       units = c("cm"),
       dpi = 300
)

#Create Figure 3
#Pre-fire Structure basal area

#Add the parcel level data
#Add the last name ethnicity fields to the large data tables
dins.la <- st_read(paste0(dir,'DINS//dins_postfire_la_fires.gpkg'))

#Work on a project
filtered <- dins.la|> filter(STREETNAME %in% c('Pinecrest', 'Crest', 'Wapello', 'Calaveras', 'Colman', 'El Prieto', 
                                                  'Woodlyn', 'Silver Spruce', 'El Prieto', 'Santa Rosa')) # |
                               # SitusAddress %in% c('2675 NEW YORK DR', '573 SANTA ROSA AVE', '587 SANTA ROSA AVE', 
                               #                     '600 SANTA ROSA AVE', '2542 SANTA ROSA AVE'))

write.csv(filtered |> as.data.frame() |> select(-c('geom')), file = "C://Users//CarlNorlen//mystuff//data//urban-fires//dins_data_altadena_site_visit_08032025.csv")
