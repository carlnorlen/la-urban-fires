#Purpose: Analyze structure damage data for the Palisades and Eaton fires.
#Created by: Carl A. Norlen
#Created date: 3/6/2025
#Updated date: 6/26/2025

#install packages
# install.packages(c('sfdep'))

#Packages for analysis
my_packages <- c('tidyverse', 'ggpubr', 'sf', 'patchwork', 'tigris', 'tidycensus', 'units', 'osmdata', 'rethnicity', 'gstat', 'sfdep')

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
wgis <- st_read(paste0(dir, 'WFIGS_Interagency//2025//Perimeters.shp'))
# plot(wgis)
la.fires <- wgis %>% filter(poly_Incid %in% c('Eaton', 'PALISADES'))
la.fires <- st_transform(la.fires, c)
# st_crs(la.fires)
#Add a 100-meter buffer to the fire
la.fires.buffer <- la.fires %>% st_buffer(dist = 100)

#Add the last name ethnicity fields to the large data tables
all.join <- st_read(paste0(dir,'combined_la_fires_parcel_all_structures_data.gpkg'))

#Add a binary dmaage layer
all.join <- all.join |> mutate(damage.binary = case_when(DAMAGE_1 == 'Destroyed (>50%)' ~ 1, DAMAGE_1 == 'Inaccessible' ~ NA, DAMAGE_1 %in% c('Major (26-50%)', 'Minor (10-25%)', 'Affected (1-9%)', 'No Damage') ~ 0))

#Create a Figure Comparing the damage by race
f1 <- all.join %>%
  filter(DAMAGE_1 != 'Inaccessible' & !is.na(race) & STRUCTURECATEGORY %in% c('Single Residence', 'Multiple Residence')) %>%
  as.data.frame() %>%
  group_by(race, DAMAGE_1, Fire_Name) %>% 
  summarize(count = n()) %>% 
  ggplot(aes(x=race, y = count, fill= factor(DAMAGE_1, levels = c('Destroyed (>50%)',  'Major (26-50%)', 'Minor (10-25%)', 'Affected (1-9%)', 'No Damage')))) + 
  geom_bar(stat="identity", position = "fill") +
  facet_grid(~Fire_Name, scales = "free_x", space = "free_x") +
  scale_fill_brewer(breaks = c('Destroyed (>50%)',  'Major (26-50%)', 'Minor (10-25%)', 'Affected (1-9%)', 'No Damage'), type = 'seq', palette = 7, name = 'Fire Impact', direction = -1) +
  xlab('Race of Property Owner') + ylab('Proportion') +
  theme_bw()
f1

ggsave('Fig4_damage_by_race.png',
       plot = f1,
       path = 'C://Users//CarlNorlen//mystuff//la-urban-fires//figures',
       scale = 1,
       width = 14,
       height = 10,
       units = c("cm"),
       dpi = 300
)

#Damage versus structure basal area
f2 <- all.join %>%
  filter(DAMAGE_1 != 'Inaccessible' & STRUCTURECATEGORY %in% c('Single Residence', 'Multiple Residence')) %>%
  as.data.frame() %>%
  ggplot(aes(x=factor(DAMAGE_1, levels = c('Destroyed (>50%)',  'Major (26-50%)', 'Minor (10-25%)', 'Affected (1-9%)', 'No Damage')), y = structure.basal.area, fill= factor(DAMAGE_1, levels = c('Destroyed (>50%)',  'Major (26-50%)', 'Minor (10-25%)', 'Affected (1-9%)', 'No Damage')))) + 
  geom_boxplot() + #stat="identity", position = "fill") +
  facet_grid(~Fire_Name, scales = "free_x", space = "free_x") +
  scale_fill_brewer(breaks = c('Destroyed (>50%)',  'Major (26-50%)', 'Minor (10-25%)', 'Affected (1-9%)', 'No Damage'), type = 'seq', palette = 7, name = 'Fire Impact', direction = -1) +
  xlab('Fire Impact') + ylab(expression('Structure Basal Area (m'^2*' ha'^-1*')')) +
  theme_bw() +
  theme(axis.text.x = element_text(angle = 90))
f2

ggsave('Fig5_damage_by_structure_basal_area.png',
       plot = f2,
       path = 'C://Users//CarlNorlen//mystuff//la-urban-fires//figures',
       scale = 1,
       width = 14,
       height = 10,
       units = c("cm"),
       dpi = 300
)

f3 <- all.join %>%
  filter(DAMAGE_1 != 'Inaccessible' & STRUCTURECATEGORY %in% c('Single Residence', 'Multiple Residence')) %>%
  as.data.frame() %>%
  ggplot(aes(x=factor(DAMAGE_1, levels = c('Destroyed (>50%)',  'Major (26-50%)', 'Minor (10-25%)', 'Affected (1-9%)', 'No Damage')), y = over.65.pct, fill= factor(DAMAGE_1, levels = c('Destroyed (>50%)',  'Major (26-50%)', 'Minor (10-25%)', 'Affected (1-9%)', 'No Damage')))) + 
  geom_boxplot() + #stat="identity", position = "fill") +
  facet_grid(~Fire_Name, scales = "free_x", space = "free_x") +
  scale_fill_brewer(breaks = c('Destroyed (>50%)',  'Major (26-50%)', 'Minor (10-25%)', 'Affected (1-9%)', 'No Damage'), type = 'seq', palette = 7, name = 'Fire Impact', direction = -1) +
  xlab('Fire Impact') + ylab('Proportion of People over 65 (%))') +
  theme_bw() +
  theme(axis.text.x = element_text(angle = 90))
f3

ggsave('Fig6_damage_by_pct_over_65.png',
       plot = f3,
       path = 'C://Users//CarlNorlen//mystuff//la-urban-fires//figures',
       scale = 1,
       width = 14,
       height = 10,
       units = c("cm"),
       dpi = 300
)

#Structure Value
f4 <- all.join %>%
  filter(DAMAGE_1 != 'Inaccessible' & STRUCTURECATEGORY %in% c('Single Residence', 'Multiple Residence')) %>%
  as.data.frame() %>%
  ggplot(aes(x=factor(DAMAGE_1, levels = c('Destroyed (>50%)',  'Major (26-50%)', 'Minor (10-25%)', 'Affected (1-9%)', 'No Damage')), y = val_struct / 1000, fill= factor(DAMAGE_1, levels = c('Destroyed (>50%)',  'Major (26-50%)', 'Minor (10-25%)', 'Affected (1-9%)', 'No Damage')))) + 
  geom_boxplot() + #stat="identity", position = "fill") +
  facet_grid(~Fire_Name, scales = "free_x", space = "free_x") +
  scale_fill_brewer(breaks = c('Destroyed (>50%)',  'Major (26-50%)', 'Minor (10-25%)', 'Affected (1-9%)', 'No Damage'), type = 'seq', palette = 7, name = 'Fire Impact', direction = -1) +
  xlab('Fire Impact') + ylab('Structure Value ($1000)') +
  theme_bw() +
  theme(axis.text.x = element_text(angle = 90))
f4

ggsave('Fig7_damage_by_assessed_value.png',
       plot = f4,
       path = 'C://Users//CarlNorlen//mystuff//la-urban-fires//figures',
       scale = 1,
       width = 22,
       height = 10,
       units = c("cm"),
       dpi = 300
)
# all.join |> mutate(YearBuilt1 = as.numeric(YearBuilt1)) |> as.data.frame() |> select(YearBuilt1) |> filter(YearBuilt1 !=0 & !is.na(YearBuilt1)) |> summarize(count = n())
f5 <- all.join |>
  filter(DAMAGE_1 != 'Inaccessible' & STRUCTURECATEGORY %in% c('Single Residence', 'Multiple Residence') & !is.na(DAMAGE_1) & YearBuilt1 != 0 & !is.na(YearBuilt1) & YearBuilt1 > 1800) %>%
  as.data.frame() |>
  ggplot(aes(x=factor(DAMAGE_1, levels = c('Destroyed (>50%)',  'Major (26-50%)', 'Minor (10-25%)', 'Affected (1-9%)', 'No Damage')), y = as.numeric(YearBuilt1), fill= factor(DAMAGE_1, levels = c('Destroyed (>50%)',  'Major (26-50%)', 'Minor (10-25%)', 'Affected (1-9%)', 'No Damage')))) + 
  geom_boxplot() + #stat="identity", position = "fill") +
  facet_grid(~Fire_Name, scales = "free_x", space = "free_x") +
  scale_fill_brewer(breaks = c('Destroyed (>50%)',  'Major (26-50%)', 'Minor (10-25%)', 'Affected (1-9%)', 'No Damage'), type = 'seq', palette = 7, name = 'Fire Impact', direction = -1) +
  xlab('Fire Impact') + ylab('Year Built') +
  theme_bw() +
  theme(axis.text.x = element_text(angle = 90))
f5

ggsave('Fig8_damage_by_year_built.png',
       plot = f5,
       path = 'C://Users//CarlNorlen//mystuff//la-urban-fires//figures',
       scale = 1,
       width = 22,
       height = 10,
       units = c("cm"),
       dpi = 300
)

# f6 <- all.join %>%
#   filter(DAMAGE_1 != 'Inaccessible' & !is.na(FRONT_FT) & STRUCTURECATEGORY %in% c('Single Residence', 'Multiple Residence')) %>%
#   as.data.frame() %>%
#   # group_by(FRONT_FT, DAMAGE_1, Fire_Name) %>% 
#   # summarize(count = n()) %>% 
#   ggplot(mapping = aes(x= factor(DAMAGE_1, levels = c('Destroyed (>50%)',  'Major (26-50%)', 'Minor (10-25%)', 'Affected (1-9%)', 'No Damage')), y = as.numeric(FRONT_FT), fill= factor(DAMAGE_1, levels = c('Destroyed (>50%)',  'Major (26-50%)', 'Minor (10-25%)', 'Affected (1-9%)', 'No Damage')))) + 
#   geom_boxplot() + 
#   facet_grid(~Fire_Name, scales = "free_x", space = "free_x") +
#   scale_fill_brewer(breaks = c('Destroyed (>50%)',  'Major (26-50%)', 'Minor (10-25%)', 'Affected (1-9%)', 'No Damage'), type = 'seq', palette = 7, name = 'Fire Impact', direction = -1) +
#   xlab('Fire Impact') + ylab('Lot Width (ft)') +
#   theme_bw() +
#   theme(axis.text.x = element_text(angle = 90))
# f6
# 
# ggsave('Fig9_damage_by_lot_width.png',
#        plot = f6,
#        path = 'C://Users//CarlNorlen//mystuff//la-urban-fires//figures',
#        scale = 1,
#        width = 14,
#        height = 10,
#        units = c("cm"),
#        dpi = 300
# )

# f7 <- all.join %>%
#   filter(DAMAGE_1 != 'Inaccessible' & STRUCTURECATEGORY %in% c('Single Residence', 'Multiple Residence') & LAND_SQ_FT <= 20000) %>%  
#   as.data.frame() %>%
#   # group_by(FRONT_FT, DAMAGE_1, Fire_Name) %>% 
#   # summarize(count = n()) %>% 
#   ggplot(mapping = aes(x= factor(DAMAGE_1, levels = c('Destroyed (>50%)',  'Major (26-50%)', 'Minor (10-25%)', 'Affected (1-9%)', 'No Damage')), y = as.numeric(LAND_SQ_FT), fill= factor(DAMAGE_1, levels = c('Destroyed (>50%)',  'Major (26-50%)', 'Minor (10-25%)', 'Affected (1-9%)', 'No Damage')))) + 
#   geom_boxplot() + 
#   facet_grid(~Fire_Name, scales = "free_x", space = "free_x") +
#   scale_fill_brewer(breaks = c('Destroyed (>50%)',  'Major (26-50%)', 'Minor (10-25%)', 'Affected (1-9%)', 'No Damage'), type = 'seq', palette = 7, name = 'Fire Impact', direction = -1) +
#   xlab('Fire Impact') + ylab('Lot Area (ft^2)') +
#   theme_bw() +
#   theme(axis.text.x = element_text(angle = 90))
# f7
# 
# ggsave('Fig10_damage_by_lot_area.png',
#        plot = f7,
#        path = 'C://Users//CarlNorlen//mystuff//la-urban-fires//figures',
#        scale = 1,
#        width = 14,
#        height = 10,
#        units = c("cm"),
#        dpi = 300
# )

#Distance to Nearest structure
# f8 <- all.join %>%
#   filter(DAMAGE_1 != 'Inaccessible' & STRUCTURECATEGORY %in% c('Single Residence', 'Multiple Residence')) %>%  
#   as.data.frame() %>%
#   # group_by(FRONT_FT, DAMAGE_1, Fire_Name) %>% 
#   # summarize(count = n()) %>% 
#   ggplot(mapping = aes(x= factor(DAMAGE_1, levels = c('Destroyed (>50%)',  'Major (26-50%)', 'Minor (10-25%)', 'Affected (1-9%)', 'No Damage')), y = as.numeric(distance.closest), fill= factor(DAMAGE_1, levels = c('Destroyed (>50%)',  'Major (26-50%)', 'Minor (10-25%)', 'Affected (1-9%)', 'No Damage')))) + 
#   geom_boxplot() + 
#   facet_grid(~Fire_Name, scales = "free_x", space = "free_x") +
#   scale_fill_brewer(breaks = c('Destroyed (>50%)',  'Major (26-50%)', 'Minor (10-25%)', 'Affected (1-9%)', 'No Damage'), type = 'seq', palette = 7, name = 'Fire Impact', direction = -1) +
#   xlab('Fire Impact') + ylab('Distance to Nearest Structure (m)') +
#   theme_bw() +
#   theme(axis.text.x = element_text(angle = 90))
# f8
# 
# ggsave('Fig15_distance_nearest_structure.png',
#        plot = f8,
#        path = 'C://Users//CarlNorlen//mystuff//la-urban-fires//figures',
#        scale = 1,
#        width = 14,
#        height = 10,
#        units = c("cm"),
#        dpi = 300
# )

f9a <- all.join %>%
  filter(DAMAGE_1 != 'Inaccessible' & !is.na(race) & Fire_Name == 'Eaton' & STRUCTURECATEGORY %in% c('Single Residence', 'Multiple Residence' , 'Mixed Commercial/Residential', 'Nonresidential Commercial')) %>%
  ggplot(mapping = aes(fill= factor(DAMAGE_1, levels = c('Destroyed (>50%)',  'Major (26-50%)', 'Minor (10-25%)', 'Affected (1-9%)', 'No Damage')))) + 
  geom_sf(lwd = 0.01) +
  # facet_grid(~Fire_Name) +
  scale_fill_brewer(breaks = c('Destroyed (>50%)',  'Major (26-50%)', 'Minor (10-25%)', 'Affected (1-9%)', 'No Damage'), type = 'seq', palette = 7, name = 'Fire Impact', direction = -1) +
  #xlab('Race of Property Owner') + ylab('Proportion') +
  theme_bw()
f9a

f9b <- all.join %>%
  filter(DAMAGE_1 != 'Inaccessible' & !is.na(race) & Fire_Name == 'Palisades' & STRUCTURECATEGORY %in% c('Single Residence', 'Multiple Residence' , 'Mixed Commercial/Residential', 'Nonresidential Commercial')) %>%
  ggplot(mapping = aes(fill= factor(DAMAGE_1, levels = c('Destroyed (>50%)',  'Major (26-50%)', 'Minor (10-25%)', 'Affected (1-9%)', 'No Damage')))) + 
  geom_sf(lwd = 0.01) +
  # facet_grid(~Fire_Name) +
  scale_fill_brewer(breaks = c('Destroyed (>50%)',  'Major (26-50%)', 'Minor (10-25%)', 'Affected (1-9%)', 'No Damage'), type = 'seq', palette = 7, name = 'Fire Impact', direction = -1) +
  #xlab('Race of Property Owner') + ylab('Proportion') +
  theme_bw()
f9b

f9 <- ggarrange(f9a, f9b, ncol = 1, nrow = 2, common.legend = TRUE)
f9 

ggsave('Fig12_damage_by_build_year.png',
       plot = f9,
       path = 'C://Users//CarlNorlen//mystuff//la-urban-fires//figures',
       scale = 1,
       width = 20,
       height = 24,
       units = c("cm"),
       dpi = 300
)

f10a <- all.join %>%
  filter(DAMAGE_1 != 'Inaccessible' & !is.na(race) & Fire_Name == 'Eaton' & STRUCTURECATEGORY %in% c('Single Residence', 'Multiple Residence' , 'Mixed Commercial/Residential', 'Nonresidential Commercial')) %>%
  ggplot() + 
  geom_sf(mapping = aes(fill = race) , lwd = 0.01) +
  # facet_grid(~Fire_Name) +
  # scale_fill_brewer(breaks = c('Destroyed (>50%)',  'Major (26-50%)', 'Minor (10-25%)', 'Affected (1-9%)', 'No Damage'), type = 'seq', palette = 7, name = 'Fire Impact', direction = -1) +
  #xlab('Race of Property Owner') + ylab('Proportion') +
  theme_bw()
f10a

f10b <- all.join %>%
  filter(DAMAGE_1 != 'Inaccessible' & !is.na(race) & Fire_Name == 'Palisades' & STRUCTURECATEGORY %in% c('Single Residence', 'Multiple Residence' , 'Mixed Commercial/Residential', 'Nonresidential Commercial')) %>%
  ggplot() + 
  geom_sf(mapping = aes(fill = race), lwd = 0.01) +
  # facet_grid(~Fire_Name) +
  # scale_fill_brewer(breaks = c('Destroyed (>50%)',  'Major (26-50%)', 'Minor (10-25%)', 'Affected (1-9%)', 'No Damage'), type = 'seq', palette = 7, name = 'Fire Impact', direction = -1) +
  #xlab('Race of Property Owner') + ylab('Proportion') +
  theme_bw()
f10b

f10 <- ggarrange(f10a, f10b, ncol = 1, nrow = 2, common.legend = TRUE)
f10 

ggsave('Fig13_damage_by_race.png',
       plot = f10,
       path = 'C://Users//CarlNorlen//mystuff//la-urban-fires//figures',
       scale = 1,
       width = 20,
       height = 24,
       units = c("cm"),
       dpi = 300
)

#Counts by Race
f11 <- all.join %>%
  filter(DAMAGE_1 != 'Inaccessible' & !is.na(race) & STRUCTURECATEGORY %in% c('Single Residence', 'Multiple Residence')) %>%
  as.data.frame() %>%
  group_by(race, Fire_Name) %>% 
  summarize(count = n(), pop = sum(pop.total)) %>% 
  ggplot(aes(x=race, y = count)) + 
  geom_bar(stat="identity") +
  facet_grid(~Fire_Name, scales = "free_x", space = "free_x") +
  # scale_fill_brewer(breaks = c('Destroyed (>50%)',  'Major (26-50%)', 'Minor (10-25%)', 'Affected (1-9%)', 'No Damage'), type = 'seq', palette = 7, name = 'Fire Impact', direction = -1) +
  xlab('Race of Property Owner') + ylab('Count') +
  theme_bw()
f11

ggsave('Fig16_count_by_race.png',
       plot = f11,
       path = 'C://Users//CarlNorlen//mystuff//la-urban-fires//figures',
       scale = 1,
       width = 14,
       height = 10,
       units = c("cm"),
       dpi = 300
)

#Population Count
f12 <- all.join %>%
  filter(DAMAGE_1 != 'Inaccessible' & !is.na(pop.total) & STRUCTURECATEGORY %in% c('Single Residence', 'Multiple Residence')) %>% #
  as.data.frame() %>%
  # group_by(FRONT_FT, DAMAGE_1, Fire_Name) %>% 
  # summarize(count = n()) %>% 
  ggplot(mapping = aes(x= factor(DAMAGE_1, levels = c('Destroyed (>50%)',  'Major (26-50%)', 'Minor (10-25%)', 'Affected (1-9%)', 'No Damage')), y = as.numeric(pop.total), fill= factor(DAMAGE_1, levels = c('Destroyed (>50%)',  'Major (26-50%)', 'Minor (10-25%)', 'Affected (1-9%)', 'No Damage')))) + 
  geom_boxplot() + 
  facet_grid(~Fire_Name, scales = "free_x", space = "free_x") +
  scale_fill_brewer(breaks = c('Destroyed (>50%)',  'Major (26-50%)', 'Minor (10-25%)', 'Affected (1-9%)', 'No Damage'), type = 'seq', palette = 7, name = 'Fire Impact', direction = -1) +
  xlab('Fire Impact') + ylab('Total Residents in Structure') +
  theme_bw() +
  theme(axis.text.x = element_text(angle = 90))
f12

ggsave('Fig17_total_population_damage.png',
       plot = f12,
       path = 'C://Users//CarlNorlen//mystuff//la-urban-fires//figures',
       scale = 1,
       width = 14,
       height = 10,
       units = c("cm"),
       dpi = 300
)

#Zone Zero Damage
f13 <- all.join %>%
  filter(DAMAGE_1 != 'Inaccessible' & STRUCTURECATEGORY %in% c('Single Residence', 'Multiple Residence')) %>%
  as.data.frame() %>%
  group_by(zone_zero_overlap, DAMAGE_1, Fire_Name) %>% 
  summarize(count = n()) %>% 
  ggplot(aes(x=zone_zero_overlap, y = count, fill= factor(DAMAGE_1, levels = c('Destroyed (>50%)',  'Major (26-50%)', 'Minor (10-25%)', 'Affected (1-9%)', 'No Damage')))) + 
  geom_bar(stat="identity", position = "fill") +
  facet_grid(~Fire_Name, scales = "free_x", space = "free_x") +
  scale_fill_brewer(breaks = c('Destroyed (>50%)',  'Major (26-50%)', 'Minor (10-25%)', 'Affected (1-9%)', 'No Damage'), type = 'seq', palette = 7, name = 'Fire Impact', direction = -1) +
  xlab('Number of Structures Overlapping in Zone 0 (0-5 ft)') + ylab('Proportion') +
  theme_bw()
f13

ggsave('Fig17_zone_zero_damage.png',
       plot = f13,
       path = 'C://Users//CarlNorlen//mystuff//la-urban-fires//figures',
       scale = 1,
       width = 14,
       height = 10,
       units = c("cm"),
       dpi = 300
)

#Zone One Damage
f14 <- all.join %>%
  filter(DAMAGE_1 != 'Inaccessible' & STRUCTURECATEGORY %in% c('Single Residence', 'Multiple Residence')) %>%
  as.data.frame() %>%
  group_by(zone_one_overlap_correct, DAMAGE_1, Fire_Name) %>% 
  summarize(count = n()) %>% 
  ggplot(aes(x=zone_one_overlap_correct, y = count, fill= factor(DAMAGE_1, levels = c('Destroyed (>50%)',  'Major (26-50%)', 'Minor (10-25%)', 'Affected (1-9%)', 'No Damage')))) + 
  geom_bar(stat="identity", position = "fill") +
  facet_grid(~Fire_Name, scales = "free_x", space = "free_x") +
  scale_fill_brewer(breaks = c('Destroyed (>50%)',  'Major (26-50%)', 'Minor (10-25%)', 'Affected (1-9%)', 'No Damage'), type = 'seq', palette = 7, name = 'Fire Impact', direction = -1) +
  xlab('Number of Structures Overlapping in Zone 1 (5-30 ft)') + ylab('Proportion') +
  theme_bw()
f14

ggsave('Fig18_zone_one_damage.png',
       plot = f14,
       path = 'C://Users//CarlNorlen//mystuff//la-urban-fires//figures',
       scale = 1,
       width = 14,
       height = 10,
       units = c("cm"),
       dpi = 300
)

#Zone Two Damage
f15 <- all.join %>%
  filter(DAMAGE_1 != 'Inaccessible' & STRUCTURECATEGORY %in% c('Single Residence', 'Multiple Residence')) %>%
  as.data.frame() %>%
  group_by(zone_two_overlap_correct, DAMAGE_1, Fire_Name) %>% 
  summarize(count = n()) %>% 
  ggplot(aes(x=zone_two_overlap_correct, y = count, fill= factor(DAMAGE_1, levels = c('Destroyed (>50%)',  'Major (26-50%)', 'Minor (10-25%)', 'Affected (1-9%)', 'No Damage')))) + 
  geom_bar(stat="identity", position = "fill") +
  facet_grid(~Fire_Name, scales = "free_x", space = "free_x") +
  scale_fill_brewer(breaks = c('Destroyed (>50%)',  'Major (26-50%)', 'Minor (10-25%)', 'Affected (1-9%)', 'No Damage'), type = 'seq', palette = 7, name = 'Fire Impact', direction = -1) +
  xlab('Number of Structures Overlapping in Zone 2 (30-100 ft)') + ylab('Proportion') +
  theme_bw()
f15

ggsave('Fig19_zone_two_damage.png',
       plot = f15,
       path = 'C://Users//CarlNorlen//mystuff//la-urban-fires//figures',
       scale = 1,
       width = 14,
       height = 10,
       units = c("cm"),
       dpi = 300
)

#Create a figure showing the breakdown of structure types
f16a <- all.join %>%
  filter(DAMAGE_1 != 'Inaccessible' & !is.na(STRUCTURECATEGORY)) %>%
  as.data.frame() %>%
  group_by(STRUCTURECATEGORY, DAMAGE_1, Fire_Name) %>% 
  summarize(count = n()) %>% 
  ggplot(aes(x=STRUCTURECATEGORY, y = count, fill= factor(DAMAGE_1, levels = c('Destroyed (>50%)',  'Major (26-50%)', 'Minor (10-25%)', 'Affected (1-9%)', 'No Damage')))) + 
  geom_bar(stat="identity", position = "fill") +
  facet_grid(~Fire_Name, scales = "free_x", space = "free_x") +
  scale_fill_brewer(breaks = c('Destroyed (>50%)',  'Major (26-50%)', 'Minor (10-25%)', 'Affected (1-9%)', 'No Damage'), type = 'seq', palette = 7, name = 'Fire Impact', direction = -1) +
  xlab('Structure Category') + ylab('Proportion Impacted') +
  theme_bw() +
  theme(axis.text.x = element_blank(), axis.title.x = element_blank())
f16a

f16b <- all.join %>%
  filter(DAMAGE_1 != 'Inaccessible' & !is.na(STRUCTURECATEGORY)) %>%
  as.data.frame() %>%
  group_by(STRUCTURECATEGORY, Fire_Name) %>% 
  summarize(count = n()) %>% 
  ggplot(aes(x=STRUCTURECATEGORY, y = count)) + #, fill= factor(DAMAGE_1, levels = c('Destroyed (>50%)',  'Major (26-50%)', 'Minor (10-25%)', 'Affected (1-9%)', 'No Damage')))) + 
  geom_bar(stat="identity") +
  facet_grid(~Fire_Name, scales = "free_x", space = "free_x") +
  # scale_fill_brewer(breaks = c('Destroyed (>50%)',  'Major (26-50%)', 'Minor (10-25%)', 'Affected (1-9%)', 'No Damage'), type = 'seq', palette = 7, name = 'Fire Impact', direction = -1) +
  xlab('Structure Category') + ylab('Number of Structures') +
  theme_bw() +
  theme(axis.text.x = element_text(angle = 90))
f16b

f16 <- ggarrange(f16a, f16b, ncol = 1, nrow = 2, common.legend = TRUE, legend = 'right', align = 'v', heights = c(0.6, 1), labels = c('a', 'b'))
f16 

ggsave('Fig20_damage_by_structure_category.png',
       plot = f16,
       path = 'C://Users//CarlNorlen//mystuff//la-urban-fires//figures',
       scale = 1,
       width = 14,
       height = 16,
       units = c("cm"),
       dpi = 300
)

#Figure of Pre-Fire Tree Cover Comparison
f17 <- all.join %>%
  filter(DAMAGE_1 != 'Inaccessible' & STRUCTURECATEGORY %in% c('Single Residence', 'Multiple Residence')) %>%
  as.data.frame() %>%
  ggplot(aes(x=factor(DAMAGE_1, levels = c('Destroyed (>50%)',  'Major (26-50%)', 'Minor (10-25%)', 'Affected (1-9%)', 'No Damage')), y = tree.cover.2022, fill= factor(DAMAGE_1, levels = c('Destroyed (>50%)',  'Major (26-50%)', 'Minor (10-25%)', 'Affected (1-9%)', 'No Damage')))) + 
  geom_boxplot() + #stat="identity", position = "fill") +
  facet_grid(~Fire_Name, scales = "free_x", space = "free_x") +
  scale_fill_brewer(breaks = c('Destroyed (>50%)',  'Major (26-50%)', 'Minor (10-25%)', 'Affected (1-9%)', 'No Damage'), type = 'seq', palette = 7, name = 'Fire Impact', direction = -1) +
  xlab('Fire Impact') + ylab('Pre-Fire Urban Tree Cover (%)') +
  theme_bw() +
  theme(axis.text.x = element_text(angle = 90))
f17

ggsave('Fig21_damage_tree_cover.png',
       plot = f17,
       path = 'C://Users//CarlNorlen//mystuff//la-urban-fires//figures',
       scale = 1,
       width = 14,
       height = 10,
       units = c("cm"),
       dpi = 300
)

