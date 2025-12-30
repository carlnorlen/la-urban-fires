#Purpose: Compare CALFIRE perimeters to census data 
#Created by: Carl A. Norlen
#Created date: 2/10/2025
#Updated date: 7/2/2025

#install packages

# install.packages(c('tigris'))

#Packages for analysis
my_packages <- c('tidyverse', 'ggpubr', 'sf', 'patchwork', 'tigris', 'tidycensus', 'units', 'osmdata', 'rethnicity', 'viridis', 'terra', 'corrplot', 'reshape2')

# install.packages('reshape2')
# library(tidycensus)
#Load the packages
lapply(my_packages, require, character.only = TRUE)
options(tigris_use_cache = TRUE)
# census_api_key('a37785ade28119ad5a1ba3ffc67f3a9812db4d23', install = TRUE)

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
p1a <- ggplot() + 
       geom_line(data = fire.combine.intersect  %>% 
                filter(as.numeric(year) >= 1910) %>% group_by(year, which.fire) %>% 
                summarize(area = sum(area), block.area = first(block.area)), 
                mapping = aes(x = as.numeric(year), y = as.numeric(area / block.area) * 100, color = which.fire, linetype = which.fire),
                linewidth = 2) +
      scale_color_brewer(palette = 'Dark2', type = 'seq', name = 'Fire Name') +
      scale_linetype(name = 'Fire Name') +
  # scale_color_brewer(palette =1, name = 'Recent Fire') +
      theme_bw() + 
      theme(legend.position = "inside", legend.position.inside = c(0.1, 0.8), 
            axis.text.x = element_text(size = 12), axis.title.x = element_text(size = 14),
            axis.text.y = element_text(size = 12), axis.title.y = element_text(size = 14)) +
      xlab('Fire Year') + 
      ylab('Urban Area Burned (%)')
p1a

#Do a Percent affected figure for historic fires
#Save the figure
ggsave('Fig1_fire_area_by_year.png',
  plot = p1a,
  path = 'C://Users//CarlNorlen//mystuff//la-urban-fires//figures',
  scale = 1,
  width = 16,
  height = 10,
  units = c("cm"),
  dpi = 300
)

#Combine panels for Figure 2
#Palisades Fires 
p2a <- ggplot() +
      ggtitle('Palisades') +
      geom_sf(data = combined.block.sf %>% filter(which.fire == 'Palisades' & !is.na(structure_value_median) & !is.na(structure.count) & UR20 == 'U'), color = 'black', mapping = aes(fill = destroy_pct)) +
      geom_sf(data = rbind(frap.la.intersect |> filter(year >= 1910 & which.fire == 'Palisades') |> st_union() |> st_as_sf() |> mutate(when.fire = '1910-2024'), 
                           wgis.la.intersect |> filter(poly_Incid == 'PALISADES') |> mutate(when.fire = '2025') |> select(when.fire) |> rename(x = geometry)), 
              mapping = aes(color = when.fire), fill = 'gray', linewidth = 1, alpha = 0) +
      scale_color_brewer(name = 'Fire Impact Years', type = 'qual', palette = 6) +
      scale_fill_viridis_c(option = 'magma', name = 'Homes Destroyed (%)') +
      scale_linetype(name = 'Fire Years') +
      theme_bw() +
  theme(legend.position = "inside", legend.direction="horizontal", legend.position.inside = c(0.35, 0.75), 
        legend.background = element_blank(), legend.title = element_text(size = 10), legend.text = element_text(size = 8),
        axis.text.x = element_text(size = 12),
        axis.text.y = element_text(size = 12)) +
  guides(fill = guide_colorbar(title.position = "top", order = 2),
         color = guide_legend(order = 1))
p2a

#Eaton Fire
p2b <- ggplot() +
    ggtitle('Eaton') +
    geom_sf(data = combined.block.sf %>% filter(which.fire == 'Eaton' & !is.na(structure.count) & !is.na(structure_value_median) & UR20 == 'U'), color = 'black', mapping = aes(fill = destroy_pct)) +
    geom_sf(data = rbind(frap.la.intersect |> filter(year >= 1910 & which.fire == 'Eaton') |> st_union() |> st_as_sf() |> mutate(when.fire = '1910-2024'), 
                       wgis.la.intersect |> filter(poly_Incid == 'Eaton') |> mutate(when.fire = '2025') |> select(when.fire) |> rename(x = geometry)), 
          mapping = aes(color = when.fire), fill = 'gray', linewidth = 1 , alpha = 0) +
  scale_color_brewer(name = 'Fire Years', type = 'qual', palette = 6) +
  scale_fill_viridis_c(option = 'magma', name = 'Destroyed (%)') +
    theme_bw() +
  theme(legend.position = "none", legend.direction="horizontal", legend.position.inside = c(0.8, 0.8),
        axis.text.x = element_text(size = 12),
        axis.text.y = element_text(size = 12)) +
  guides(fill = guide_colorbar(title.position = "top"))
p2b

f2 <- ggarrange(p2a, p2b, nrow = 2, ncol = 1, common.legend = FALSE, labels = c('a', 'b'))
f2

#Save the figure
ggsave('Fig2_fire_history.png',
       plot = f2,
       path = 'C://Users//CarlNorlen//mystuff//la-urban-fires//figures',
       scale = 1,
       width = 16,
       height = 18,
       units = c("cm"),
       dpi = 300
)

#Create Figure 3
#Pre-fire Structure basal area
p3a <- ggplot(data = combined.block.sf |> as.data.frame() |>  filter(as.numeric(fire.area.2025.pct) > 0 & !is.na(structure.count) & !is.na(structure_value_median) & UR20 == 'U'), mapping = aes(color = which.fire, x = structure.basal.area, y = destroy_pct)) +
  geom_point(size = 1, alpha = 0.5) +
  # ggtitle('Neighborhood-Scale') +
  stat_cor(mapping = aes(label = paste(after_stat(rr.label), after_stat(p.label), sep = "~`,`~"), 
                         color = which.fire), label.x.npc = 0.05, label.y.npc = 0.99, p.accuracy = 0.01, size = 5) +
  geom_smooth(method = 'lm', mapping = aes(linetype = which.fire, color = which.fire), linewidth = 1.5) +
  scale_color_brewer(palette = 'Dark2', type = 'seq', name = 'Fire Name') +
  scale_linetype(name = 'Fire Name') +
  ylim(0, 119) +
  ylab('Homes Destroyed (%)') + xlab(expression('Structure Basal Area (m'^2*' ha'^-1*')')) +
  theme_bw() +
  theme(legend.position = 'none', 
        plot.title = element_text(size = 18, face = "bold"),
        axis.text.x = element_text(size = 12), axis.title.x = element_text(size = 14), 
        axis.text.y = element_text(size = 12), axis.title.y = element_text(size = 14))
p3a

#Pre-fire urban tree cover
p3b <- ggplot(data = combined.block.sf |> as.data.frame() |>  filter(as.numeric(fire.area.2025.pct) > 0 & !is.na(structure.count) & !is.na(structure_value_median) & UR20 == 'U'), mapping = aes(color = which.fire, x = tree.cover.2022, y = destroy_pct)) +
  geom_point(size = 1, alpha = 0.5) +
  stat_cor(mapping = aes(label = paste(after_stat(rr.label), after_stat(p.label), sep = "~`,`~"), 
                         color = which.fire), label.x.npc = 0.05, label.y.npc = 0.99, p.accuracy = 0.01, size = 5) +
  geom_smooth(method = 'lm', mapping = aes(linetype = which.fire, color = which.fire), linewidth = 1.5) +
  scale_color_brewer(palette = 'Dark2', type = 'seq', name = 'Fire Name') +
  scale_linetype(name = 'Fire Name') +
  ylim(0, 119) +
  ylab('Homes Destroyed (%)') + xlab('Urban Tree Cover (%)') +
  theme_bw() +
  theme(legend.position = 'none', 
        axis.text.x = element_text(size = 12), axis.title.x = element_text(size = 14), 
        axis.text.y = element_text(size = 12), axis.title.y = element_text(size = 14))
p3b

#Mean strucutre overlaps in Zone zero
p3c <- ggplot(data = combined.block.sf |> as.data.frame() |>  filter(as.numeric(fire.area.2025.pct) > 0 & !is.na(structure.count) & !is.na(structure_value_median) & UR20 == 'U'), 
               mapping = aes(color = which.fire, x = zone_zero_overlap_mean, y = destroy_pct)) +
  geom_point(size = 1, alpha = 0.5) +
  stat_cor(mapping = aes(label = paste(after_stat(rr.label), after_stat(p.label), sep = "~`,`~"), 
                         color = which.fire), label.x.npc = 0.05, label.y.npc = 0.99, p.accuracy = 0.01, size = 5) +
  geom_smooth(method = 'lm', mapping = aes(linetype = which.fire, color = which.fire), linewidth = 1.5) +
  scale_color_brewer(palette = 'Dark2', type = 'seq', name = 'Fire Name') +
  scale_linetype(name = 'Fire Name') +
  ylim(0, 119) + 
  # xlim(0, 5) +
  ylab('Homes Destroyed (%)') + xlab('Number structures in DSB 0') +
  theme_bw() +
  # scale_y_continuous(labels = c('0', '25', '50', '75', '100', '')) +
  theme(legend.position = 'none', 
        axis.text.x = element_text(size = 12), axis.title.x = element_text(size = 14), 
        axis.text.y = element_text(size = 12), axis.title.y = element_text(size = 14))
p3c

#Socioeconomic characteristics
p3d <- ggplot(data = combined.block.sf |> as.data.frame() |>  filter(as.numeric(fire.area.2025.pct) > 0 & !is.na(structure.count) & !is.na(structure_value_median) & !is.na(ww_bbg_pct_bachelor_C) & UR20 == 'U'), 
               mapping = aes(color = which.fire, x = ww_bbg_pct_speak.eng_C * 100, y = destroy_pct)) +
  geom_point(size = 1, alpha = 0.5) +
  stat_cor(mapping = aes(label = paste(after_stat(rr.label), after_stat(p.label), sep = "~`,`~"), 
                         color = which.fire), label.x.npc = 0.05, label.y.npc = 0.99, p.accuracy = 0.01, size = 5) +
  geom_smooth(method = 'lm', mapping = aes(linetype = which.fire, color = which.fire), linewidth = 1.5) +
  scale_color_brewer(palette = 'Dark2', type = 'seq', name = 'Fire Name') +
  scale_linetype(name = 'Fire Name') +
  ylim(0, 119) + 
  # xlim(0, 5) +
  ylab('Homes Destroyed (%)') + xlab("English Speakers (%)") +
  theme_bw() +
  # scale_y_continuous(labels = c('0', '25', '50', '75', '100', '')) +
  theme(legend.position = 'none', 
        axis.text.x = element_text(size = 12), axis.title.x = element_text(size = 14), 
        axis.text.y = element_text(size = 12), axis.title.y = element_text(size = 14))
p3d

p3e <- ggplot(data = combined.block.sf |> as.data.frame() |>  filter(as.numeric(fire.area.2025.pct) > 0 & !is.na(structure.count) & !is.na(structure_value_median) & !is.na(PercapitaInc) & UR20 == 'U'), 
               mapping = aes(color = which.fire, x = ww_bbg_pct_bachelor_C * 100, y = destroy_pct)) +
  geom_point(size = 1, alpha = 0.5) +
  stat_cor(mapping = aes(label = paste(after_stat(rr.label), after_stat(p.label), sep = "~`,`~"), 
                         color = which.fire), label.x.npc = 0.05, label.y.npc = 0.99, p.accuracy = 0.01, size = 5) +
  geom_smooth(method = 'lm', mapping = aes(linetype = which.fire, color = which.fire), linewidth = 1.5) +
  scale_color_brewer(palette = 'Dark2', type = 'seq', name = 'Fire Name') +
  scale_linetype(name = 'Fire Name') +
  ylim(0, 140) + 
  # xlim(0, 5) +
  ylab('Homes Destroyed (%)') + xlab("Bachelor's Degree (%)") +
  theme_bw() +
  # scale_y_continuous(labels = c('0', '25', '50', '75', '100', '')) +
  theme(legend.position = 'inside', legend.position.inside = c(0.85, 0.85), legend.background = element_blank(), 
        axis.text.x = element_text(size = 12), axis.title.x = element_text(size = 14), 
        axis.text.y = element_text(size = 12), axis.title.y = element_text(size = 14))
p3e

p3f <- ggplot(data = combined.block.sf |> as.data.frame() |>  filter(as.numeric(fire.area.2025.pct) > 0 & !is.na(structure.count) & !is.na(structure_value_median) & !is.na(PercapitaInc) & UR20 == 'U'), 
               mapping = aes(color = which.fire, x = Tpct.FA_AAp_C * 100, y = destroy_pct)) +
  geom_point(size = 1, alpha = 0.5) +
  stat_cor(mapping = aes(label = paste(after_stat(rr.label), after_stat(p.label), sep = "~`,`~"), 
                         color = which.fire), label.x.npc = 0.05, label.y.npc = 0.99, p.accuracy = 0.01, size = 5) +
  geom_smooth(method = 'lm', mapping = aes(linetype = which.fire, color = which.fire), linewidth = 1.5) +
  scale_color_brewer(palette = 'Dark2', type = 'seq', name = 'Fire Name') +
  scale_linetype(name = 'Fire Name') +
  ylim(-40, 125) + 
  # xlim(0, 5) +
  ylab('Homes Destroyed (%)') + xlab("African American (%)") +
  theme_bw() +
  # scale_y_continuous(labels = c('0', '25', '50', '75', '100', '')) +
  theme(legend.position = 'none', 
        axis.text.x = element_text(size = 12), axis.title.x = element_text(size = 14), 
        axis.text.y = element_text(size = 12), axis.title.y = element_text(size = 14))
p3f

f3 <- ggarrange(p3a, p3b, p3c, p3d, p3e, p3f, nrow = 2, ncol = 3, align = "hv", common.legend = FALSE, labels = c('a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i'))
f3

#Save the figure
ggsave('Fig3_fire_damage_correlation_grid.png',
       plot = f3,
       path = 'C://Users//CarlNorlen//mystuff//la-urban-fires//figures',
       scale = 1,
       width = 36,
       height = 24,
       units = c("cm"),
       dpi = 300
)

#Figure 4
#Create combined figure for correlations urban morphology with structures destroyed (%)
#Create a Neighborhood-Scale Eaton correlation matrix
eaton.cor <- combined.block.sf |> as.data.frame() |>  filter(as.numeric(fire.area.2025.pct) > 0 & !is.na(structure.count) & !is.na(structure_value_median) & UR20 == 'U' & which.fire == 'Eaton' & !is.na(PercapitaInc)) |>
             select(c('destroy_pct', 'Tpct.FA_65.and.over_yrs._C', 'Tpct.FA_Hispanic_C', 'Tpct.FA_whitep_C', 'Tpct.FA_AAp_C', 'Tpct.FA_Ap_C',
                      'Tpct.FA_renter_occ_C', 'ww_pct_bbg_noschooling_C', 'ww_bbg_pct_highsch_C', 'ww_bbg_pct_associate_C', 'ww_bbg_pct_bachelor_C', 'ww_bbg_pct_graduate.Prof_C',
                      'ww_bbg_pct_belowpoverty_C', 'PercapitaInc', 'zone_two_overlap_mean', 'zone_one_overlap_mean', 'zone_zero_overlap_mean', 'structure.basal.area', 'structure_value_median', 
                      'after_2008_pct', 'year.built.median',  'fire.area.1910to2023.pct', 'tree.cover.2022')) |> cor() 

#Melt the Eaton correlation matrix
eaton.melt <- eaton.cor |> melt()



#Do the Neighborhood-Scale Palisades correlation
palisades.cor <- combined.block.sf |> as.data.frame() |>  filter(as.numeric(fire.area.2025.pct) > 0 & !is.na(structure.count) & !is.na(structure_value_median) & UR20 == 'U' & which.fire == 'Palisades' & !is.na(PercapitaInc)) |>
  select(c('destroy_pct', 'Tpct.FA_65.and.over_yrs._C', 'Tpct.FA_Hispanic_C', 'Tpct.FA_whitep_C', 'Tpct.FA_AAp_C', 'Tpct.FA_Ap_C',
           'Tpct.FA_renter_occ_C', 'ww_pct_bbg_noschooling_C', 'ww_bbg_pct_highsch_C', 'ww_bbg_pct_associate_C', 'ww_bbg_pct_bachelor_C', 'ww_bbg_pct_graduate.Prof_C',
           'ww_bbg_pct_belowpoverty_C', 'PercapitaInc', 'zone_two_overlap_mean', 'zone_one_overlap_mean', 'zone_zero_overlap_mean', 'structure.basal.area', 'structure_value_median', 
           'after_2008_pct', 'year.built.median',  'fire.area.1910to2023.pct', 'tree.cover.2022')) |> cor() 

#Melt the Palisades correlation matrix
palisades.melt <- palisades.cor |> melt()

#Parcel-Scale Analysis
#Create an Eaton Parcel-Scale Data frame, correlation matrix and melted correlation matrix
eaton.parcel.df <- all.join |> filter(DAMAGE_1 != 'Inaccessible' & 
                                      STRUCTURECATEGORY %in% c('Single Residence', 'Multiple Residence' , 'Mixed Commercial/Residential') &
                                      !is.na(YearBuilt1) & !is.na(structure.basal.area) & !is.na(over.65.pct) & YearBuilt1 > 1500 & Fire_Name == 'Eaton') |>
                                      as.data.frame() |>
                                      select(c('damage.binary', 'over.65.pct', 'pop.total', 
                                               'zone_two_overlap_correct', 'zone_one_overlap_correct', 'zone_zero_overlap', 'structure.basal.area',  
                                               'val_struct', 'YearBuilt1', 'fire.exposed.1910to2023', 'tree.cover.2022')) 

#Convert some of the data fields to numeric from character
eaton.parcel.df$YearBuilt1 <- as.numeric(eaton.parcel.df$YearBuilt1)
eaton.parcel.df$fire.exposed.1910to2023 <- as.numeric(eaton.parcel.df$fire.exposed.1910to2023)

#Create the correlation matrix
eaton.parcel.cor <- eaton.parcel.df |> cor()

#Create the parcel level correlation
eaton.parcel.melt <- eaton.parcel.cor |> melt()

parcel.labs <- c('Home destroyed (Y/N)',  'Occupants 65+ years (%)', 'Total occupants', 'Number structures in DSB 2',
                 'Number of structures in DSB 1', 'Number of structures in DSB 0', 'Structure basal area', 'Home replacement value ($)',
                 'Year home built', 'Pre-2025 fire impacted (Y/N)', 'Pre-fire tree cover (%)')

#Create a palisades data frame, correlation matrix and melted correlation matrix
palisades.parcel.df <- all.join |> filter(DAMAGE_1 != 'Inaccessible' & 
                                        STRUCTURECATEGORY %in% c('Single Residence', 'Multiple Residence' , 'Mixed Commercial/Residential') &
                                        !is.na(YearBuilt1) & !is.na(structure.basal.area) & !is.na(over.65.pct) & YearBuilt1 > 1500 & Fire_Name == 'Palisades') |>
  as.data.frame() |>
  select(c('damage.binary', 'over.65.pct', 'pop.total', 
           'zone_two_overlap_correct', 'zone_one_overlap_correct', 'zone_zero_overlap', 'structure.basal.area',  
           'val_struct', 'YearBuilt1', 'fire.exposed.1910to2023', 'tree.cover.2022')) 

#Convert Year Built and fire exposed to numeric varaibles
palisades.parcel.df$YearBuilt1 <- as.numeric(palisades.parcel.df$YearBuilt1)
palisades.parcel.df$fire.exposed.1910to2023 <- as.numeric(palisades.parcel.df$fire.exposed.1910to2023)

#Create the parcel level correlation matrix
palisades.parcel.cor <- palisades.parcel.df |> cor()

#Create the parcel level correlation
palisades.parcel.melt <- palisades.parcel.cor |> melt()

#Combined neighborhood-level Eaton and Palisades damage correlations
combined.cor <- rbind(eaton.cor[1,], palisades.cor[1,]) 

row.names(combined.cor) <- c('Eaton', 'Palisades')

combined.cor[,-1]

combined.melt <- combined.cor[,-1] |> melt()

labs.2 <- c('Pre-fire tree cover (%)', 'Pre-2025 fire impacted (%)', 'Median year home built', 'Homes built after 2008 (%)',  
            'Median home replacement value ($)', 'Structure basal area',
            'Number of structures in DSB 0', 'Number of structures in DSB 1',  'Number of structures in DSB 2', 
            'Per capita income ($)', 'Below poverty (%)', 'Professional/Graduate degree (%)',
            "Bachelor's degree (%)", "Associated's degree (%)", "High school (%)", "No schooling (%)", "Renter (%)", "Asian (%)",
            "African American (%)", "White (%)", "Hispanic (%)", "65 years and over (%)")

combined.labs <- c('65+ years old (%)', 'Number structures in DSB 2',
                 'Number structures in DSB 1', 'Number structures in DSB 0', 'Structure basal area', 'Home replacement value ($)',
                 'Year home built', 'Pre-2025 fire impacted', 'Pre-fire tree cover (%)')

#Figure 4 Parcel and Neighborhood Scale Correlation plots
#Panel showing the melted neighborhood level correlations
fig4a <- ggplot(data = combined.melt |> filter(Var2 %in% c('Tpct.FA_65.and.over_yrs._C', 'zone_two_overlap_mean', 'zone_one_overlap_mean', 'zone_zero_overlap_mean', 
                                                          'structure.basal.area', 'structure_value_median', 
                                                          'year.built.median',  'fire.area.1910to2023.pct', 'tree.cover.2022')), aes(x = Var1, y = Var2, fill = value)) +
  geom_tile() +
  scale_fill_gradient2(midpoint = 0, mid ="grey70", 
                       limits = c(-0.5, +0.5)) +
  labs(title = "Neighborhood", 
       x = "", y = "", fill = "Correlation") +
  theme_bw() +
  theme(plot.title = element_text(hjust = 0.5, colour = "black", face = "bold"), 
        axis.title.x = element_text(face="bold", colour="darkgreen", size = 12),
        axis.title.y = element_text(face="bold", colour="darkgreen", size = 12),
        axis.text.x = element_text(size = 14, face = "bold"),
        axis.text.y = element_text(size = 12, face = "bold"),
        legend.title = element_text(face="bold", colour="black", size = 10)) +
  geom_text(aes(x = Var1, y = Var2, label = round(value, 2)), color = "black", 
            fontface = "bold", size = 5) +
  scale_x_discrete(labels = c('Eaton', 'Palisades')) + scale_y_discrete(labels = combined.labs)
fig4a

#Combined parcel-level Eaton and Palisades damage correlations
combined.parcel.cor <- rbind(eaton.parcel.cor[1,], palisades.parcel.cor[1,]) 

#Add row names
row.names(combined.parcel.cor) <- c('Eaton', 'Palisades')

#Remove one row from selection and melt
combined.parcel.melt <- combined.parcel.cor[,-1] |> melt()

#Remove one of the labels
parcel.labs.2 <- parcel.labs[-1]

#Create a figure with the melted Parcel data
fig4b <- ggplot(data = combined.parcel.melt |> filter(Var2 != 'pop.total'), aes(x = Var1, y = Var2, fill = value)) +
  geom_tile() +
  scale_fill_gradient2(midpoint = 0, mid ="grey70", 
                       limits = c(-0.5, +0.5)) +
  labs(title = "Parcel", 
       x = "", y = "", fill = "Correlation") +
  theme_bw() +
  theme(plot.title = element_text(hjust = 0.5, colour = "black", face = "bold"), 
        axis.title.x = element_text(face="bold", colour="darkgreen", size = 12),
        axis.title.y = element_text(face="bold", colour="darkgreen", size = 12),
        axis.text.x = element_text(size = 14, face = "bold"),
        axis.text.y = element_blank(), 
        legend.title = element_text(face="bold", colour="brown", size = 10)) +
  geom_text(aes(x = Var1, y = Var2, label = round(value, 2)), color = "black", 
            fontface = "bold", size = 5) +
  scale_x_discrete(labels = c('Eaton', 'Palisades')) #+ scale_y_discrete(labels = parcel.labs.2)
fig4b

#combine the plots together
fig4 <- ggarrange(fig4a, fig4b, nrow = 1, ncol = 2, common.legend = TRUE, legend = 'right',  widths = c(1.0, 0.50))
fig4

ggsave('Fig4_combined_neighborhood_correlation_plot.png',
       plot = fig4,
       path = 'C://Users//CarlNorlen//mystuff//la-urban-fires//figures',
       scale = 1,
       width = 20,
       height = 16,
       units = c("cm"),
       dpi = 300
)


#Supplementary Figures

#Figure S1
#Create a figure showing the breakdown of structure types
fs1a <- all.join %>%
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
fs1a

fs1b <- all.join %>%
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
fs1b

fs1 <- ggarrange(fs1a, fs1b, ncol = 1, nrow = 2, common.legend = TRUE, legend = 'right', align = 'v', heights = c(0.6, 1), labels = c('a', 'b'))
fs1 

#Save the figure
ggsave('FigS1_damage_by_structure_category.png',
       plot = fs1,
       path = 'C://Users//CarlNorlen//mystuff//la-urban-fires//figures',
       scale = 1,
       width = 14,
       height = 16,
       units = c("cm"),
       dpi = 300
)

#Figure S2
#Counts by Race
fs2 <- all.join %>%
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
fs2

#Save the figure
ggsave('FigS2_count_by_race.png',
       plot = fs2,
       path = 'C://Users//CarlNorlen//mystuff//la-urban-fires//figures',
       scale = 1,
       width = 14,
       height = 10,
       units = c("cm"),
       dpi = 300
)

#Figure S3
#Create combined figure for correlations urban morphology with structures destroyed (%)
#Year Structure Built
ps3a <- ggplot(data = all.join |> filter(DAMAGE_1 != "Inaccessible" & STRUCTURECATEGORY %in% c('Single Residence', 'Multiple Residence' , 'Mixed Commercial/Residential') &
                                           !is.na(YearBuilt1) & YearBuilt1 > 1500), #
               mapping = aes(x = as.numeric(YearBuilt1), y = damage.binary)) +
  geom_bin2d() +
  scale_fill_gradient2(limits = c(0,2300), breaks = c(500, 1000, 1500, 2000), midpoint = 1150, low = "cornflowerblue", mid = "yellow", high = "red",
                       na.value = 'transparent', name = "Count") +
  stat_cor(mapping = aes(label = paste(after_stat(rr.label), after_stat(p.label), sep = "~`,`~"), 
                         color = Fire_Name), label.x.npc = 0.05, label.y.npc = 0.95, p.accuracy = 0.01) +
  geom_smooth(method = "glm", method.args = list(family = "binomial"), mapping = aes(linetype = Fire_Name, color = Fire_Name)) +
  scale_color_brewer(palette = 'Dark2', type = 'seq', name = 'Fire Name') +
  scale_linetype(name = 'Fire Name') +
  ylab('Probability Structure Destroyed (%)') + xlab('Year Structure Built') +
  theme_bw() +
  guides(fill = "none") +
  theme(legend.position = 'inside', legend.position.inside = c(0.2, 0.2))
ps3a


#Zone Zero Overlaps
ps3b <- ggplot(data = all.join |> filter(DAMAGE_1 != 'Inaccessible' & STRUCTURECATEGORY %in% c('Single Residence', 'Multiple Residence' , 'Mixed Commercial/Residential') &
                                           !is.na(YearBuilt1) & YearBuilt1 > 1500), 
               mapping = aes(x = as.numeric(zone_zero_overlap), y = damage.binary)) +
  geom_bin2d() +
  scale_fill_gradient2(limits = c(0,2300), breaks = c(500, 1000, 1500, 2000), midpoint = 1150, low = "cornflowerblue", mid = "yellow", high = "red",
                       na.value = 'transparent', name = "Count") +
  stat_cor(mapping = aes(label = paste(after_stat(rr.label), after_stat(p.label), sep = "~`,`~"),
                         color = Fire_Name), label.x.npc = 0.05, label.y.npc = 0.95, p.accuracy = 0.01) +
  geom_smooth(method = "glm", method.args = list(family = "binomial"), mapping = aes(linetype = Fire_Name, color = Fire_Name)) +
  scale_color_brewer(palette = 'Dark2', type = 'seq', name = 'Fire Name') +
  scale_linetype(name = 'Fire Name') +
  ylab('Probability Structure Destroyed (%)') + xlab('Number Zone Zero Overlaps') +
  theme_bw() +
  guides(color = "none", linetype = "none") +
  theme(legend.position = 'inside', legend.position.inside = c(0.3, 0.29), legend.direction = 'vertical')
ps3b

#Mean number of structure overlaps in Zones 0 & 1
ps3c <- ggplot(data = all.join |> filter(DAMAGE_1 != 'Inaccessible' & STRUCTURECATEGORY %in% c('Single Residence', 'Multiple Residence' , 'Mixed Commercial/Residential') &
                                           !is.na(YearBuilt1) & YearBuilt1 > 1500), 
               mapping = aes(x = as.numeric(zone_one_overlap), y = damage.binary)) +
  geom_bin2d() +
  scale_fill_gradient2(limits = c(0,2300), breaks = c(500, 1000, 1500, 2000), midpoint = 1150, low = "cornflowerblue", mid = "yellow", high = "red",
                       na.value = 'transparent', name = "Count") +
  stat_cor(mapping = aes(label = paste(after_stat(rr.label), after_stat(p.label), sep = "~`,`~"), 
                         color = Fire_Name), label.x.npc = 0.05, label.y.npc = 0.95, p.accuracy = 0.01) +
  geom_smooth(method = "glm", method.args = list(family = "binomial"), mapping = aes(linetype = Fire_Name, color = Fire_Name)) +
  scale_color_brewer(palette = 'Dark2', type = 'seq', name = 'Fire Name') +
  scale_linetype(name = 'Fire Name') +
  ylab('Probability Structure Destroyed (%)') + xlab('Number Zone One Overlaps') +
  theme_bw() +
  theme(legend.position = 'none')
ps3c

#Mean structure overlaps in Zone Two
ps3d <- ggplot(data = all.join |> filter(DAMAGE_1 != 'Inaccessible' & STRUCTURECATEGORY %in% c('Single Residence', 'Multiple Residence' , 'Mixed Commercial/Residential') &
                                           !is.na(YearBuilt1) & YearBuilt1 > 1500), 
               mapping = aes(x = as.numeric(zone_two_overlap), y = damage.binary)) +
  geom_bin2d() +
  scale_fill_gradient2(limits = c(0,2300), breaks = c(500, 1000, 1500, 2000), midpoint = 1150, low = "cornflowerblue", mid = "yellow", high = "red",
                       na.value = 'transparent', name = "Count") +
  stat_cor(mapping = aes(label = paste(after_stat(rr.label), after_stat(p.label), sep = "~`,`~"), 
                         color = Fire_Name), label.x.npc = 0.05, label.y.npc = 0.95, p.accuracy = 0.01) +
  geom_smooth(method = "glm", method.args = list(family = "binomial"), mapping = aes(linetype = Fire_Name, color = Fire_Name)) +
  scale_color_brewer(palette = 'Dark2', type = 'seq', name = 'Fire Name') +
  scale_linetype(name = 'Fire Name') +
  ylab('Probability Structure Destroyed (%)') + xlab('Number Zone Two Overlaps') +
  theme_bw() +
  theme(legend.position = 'none')
ps3d

#Median structure replacement value
ps3e <- ggplot(data = all.join |> filter(DAMAGE_1 != 'Inaccessible' & STRUCTURECATEGORY %in% c('Single Residence', 'Multiple Residence' , 'Mixed Commercial/Residential') &
                                           !is.na(YearBuilt1) & YearBuilt1 > 1500), 
               mapping = aes(x = as.numeric(val_struct) / 1000, y = damage.binary)) +
  geom_bin2d() +
  scale_fill_gradient2(limits = c(0,2300), breaks = c(500, 1000, 1500, 2000), midpoint = 1150, low = "cornflowerblue", mid = "yellow", high = "red",
                       na.value = 'transparent', name = "Count") +
  stat_cor(mapping = aes(label = paste(after_stat(rr.label), after_stat(p.label), sep = "~`,`~"), 
                         color = Fire_Name), label.x.npc = 0.05, label.y.npc = 0.95, p.accuracy = 0.01) +
  geom_smooth(method = "glm", method.args = list(family = "binomial"), mapping = aes(linetype = Fire_Name, color = Fire_Name)) +
  scale_color_brewer(palette = 'Dark2', type = 'seq', name = 'Fire Name') +
  scale_linetype(name = 'Fire Name') +
  ylab('Probability Structure Destroyed (%)') + xlab('Structure Replacement Value ($1000)') +
  theme_bw() +
  theme(legend.position = 'none')
ps3e

#Total occupants over 65 (%)
ps3f <- ggplot(data = all.join |> filter(DAMAGE_1 != 'Inaccessible' & STRUCTURECATEGORY %in% c('Single Residence', 'Multiple Residence' , 'Mixed Commercial/Residential') &
                                           !is.na(YearBuilt1) & YearBuilt1 > 1500), 
               mapping = aes(x = as.numeric(over.65.pct), y = damage.binary)) +
  geom_bin2d() +
  scale_fill_gradient2(limits = c(0,2300), breaks = c(500, 1000, 1500, 2000), midpoint = 1150, low = "cornflowerblue", mid = "yellow", high = "red",
                       na.value = 'transparent', name = "Count") +
  stat_cor(mapping = aes(label = paste(after_stat(rr.label), after_stat(p.label), sep = "~`,`~"), 
                         color = Fire_Name), label.x.npc = 0.05, label.y.npc = 0.95, p.accuracy = 0.01) +
  geom_smooth(method = "glm", method.args = list(family = "binomial"), mapping = aes(linetype = Fire_Name, color = Fire_Name)) +
  scale_color_brewer(palette = 'Dark2', type = 'seq', name = 'Fire Name') +
  scale_linetype(name = 'Fire Name') +
  ylab('Probability Structure Destroyed (%)') + xlab('Occupants Over 65 (%)') +
  theme_bw() +
  theme(legend.position = 'none')
ps3f

#Pre-fire Structure basal area
ps3g <- ggplot(data = all.join |> filter(DAMAGE_1 != 'Inaccessible' & STRUCTURECATEGORY %in% c('Single Residence', 'Multiple Residence' , 'Mixed Commercial/Residential') &
                                           !is.na(YearBuilt1) & YearBuilt1 > 1500), 
               mapping = aes(x = as.numeric(structure.basal.area), y = damage.binary)) +
  geom_bin2d() +
  scale_fill_gradient2(limits = c(0,2300), breaks = c(500, 1000, 1500, 2000), midpoint = 1150, low = "cornflowerblue", mid = "yellow", high = "red",
                       na.value = 'transparent', name = "Count") +
  stat_cor(mapping = aes(label = paste(after_stat(rr.label), after_stat(p.label), sep = "~`,`~"), 
                         color = Fire_Name), label.x.npc = 0.05, label.y.npc = 0.95, p.accuracy = 0.01, size = 5) +
  geom_smooth(method = "glm", method.args = list(family = "binomial"), mapping = aes(linetype = Fire_Name, color = Fire_Name)) +
  scale_color_brewer(palette = 'Dark2', type = 'seq', name = 'Fire Name') +
  scale_linetype(name = 'Fire Name') +
  ylab('Probability Home Destroyed (%)') + xlab(expression('Structure Basal Area (m'^2*' ha'^-1*')')) +
  theme_bw() +
  theme(legend.position = 'none',
        plot.title = element_text(size = 18, face = "bold"),
        axis.text.x = element_text(size = 12), axis.title.x = element_text(size = 14), 
        axis.text.y = element_text(size = 12), axis.title.y = element_text(size = 14))
ps3g

#Pre-fire urban tree cover
psh <- ggplot(data = all.join |> filter(DAMAGE_1 != 'Inaccessible' & STRUCTURECATEGORY %in% c('Single Residence', 'Multiple Residence' , 'Mixed Commercial/Residential') &
                                           !is.na(YearBuilt1) & YearBuilt1 > 1500), 
               mapping = aes(x = as.numeric(tree.cover.2022), y = damage.binary)) +
  geom_bin2d() +
  scale_fill_gradient2(limits = c(0,2300), breaks = c(500, 1000, 1500, 2000), midpoint = 1150, low = "cornflowerblue", mid = "yellow", high = "red",
                       na.value = 'transparent', name = "Count") +
  stat_cor(mapping = aes(label = paste(after_stat(rr.label), after_stat(p.label), sep = "~`,`~"), 
                         color = Fire_Name), label.x.npc = 0.05, label.y.npc = 0.95, p.accuracy = 0.01, size = 5) +
  geom_smooth(method = "glm", method.args = list(family = "binomial"), mapping = aes(linetype = Fire_Name, color = Fire_Name)) +
  scale_color_brewer(palette = 'Dark2', type = 'seq', name = 'Fire Name') +
  scale_linetype(name = 'Fire Name') +
  ylab('Probability Home Destroyed (%)') + xlab('Urban Tree Cover (%)') +
  theme_bw() +
  guides(color = "none", linetype = "none") +
  theme(legend.position = 'inside', legend.position.inside = c(0.3, 0.29), legend.direction = 'vertical',
        axis.text.x = element_text(size = 12), axis.title.x = element_text(size = 14), 
        axis.text.y = element_text(size = 12), axis.title.y = element_text(size = 14))
psh

#Total occupants
psi <- ggplot(data = all.join |> filter(DAMAGE_1 != 'Inaccessible' & STRUCTURECATEGORY %in% c('Single Residence', 'Multiple Residence' , 'Mixed Commercial/Residential') &
                                           !is.na(YearBuilt1) & YearBuilt1 > 1500), 
               mapping = aes(x = as.numeric(pop.total), y = damage.binary)) +
  geom_bin2d() +
  scale_fill_gradient2(limits = c(0,2300), breaks = c(500, 1000, 1500, 2000), midpoint = 1150, low = "cornflowerblue", mid = "yellow", high = "red",
                       na.value = 'transparent', name = "Count") +
  stat_cor(mapping = aes(label = paste(after_stat(rr.label), after_stat(p.label), sep = "~`,`~"), 
                         color = Fire_Name), label.x.npc = 0.05, label.y.npc = 0.95, p.accuracy = 0.01, size = 5) +
  geom_smooth(method = "glm", method.args = list(family = "binomial"), mapping = aes(linetype = Fire_Name, color = Fire_Name)) +
  scale_color_brewer(palette = 'Dark2', type = 'seq', name = 'Fire Name') +
  scale_linetype(name = 'Fire Name') +
  ylab('Probability Home Destroyed (%)') + xlab('Total Occupants') +
  theme_bw() +
  theme(legend.position = 'none',
        axis.text.x = element_text(size = 12), axis.title.x = element_text(size = 14), 
        axis.text.y = element_text(size = 12), axis.title.y = element_text(size = 14))
psi

fs3 <- ggarrange(ps3a, ps3b, ps3c, ps3d, ps3e, ps3f, ps3g, ps3h, ps3i, nrow = 3, ncol = 3, align = "hv", common.legend = FALSE, labels = c('a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i'))
fs3

#Save the figure
ggsave('FigS3_fire_damage_logistic_correlation_grid.png',
       plot = fs3,
       path = 'C://Users//CarlNorlen//mystuff//la-urban-fires//figures',
       scale = 1,
       width = 36,
       height = 36,
       units = c("cm"),
       dpi = 300
)

#Figure S4: showing the proportion of homes built after 2008
#Palisades
fs4a <- ggplot() +
  geom_sf(data = combined.block.sf %>% filter(which.fire == 'Palisades' & !is.na(structure_value_median) & !is.na(destroy_pct) & UR20 == 'U'), 
          color = 'black', mapping = aes(fill = after_2008_pct)) +
  geom_sf(data = rbind(frap.la.intersect |> filter(year >= 1910 & which.fire == 'Palisades') |> st_union() |> st_as_sf() |> mutate(when.fire = '1910-2023'), 
                       wgis.la.intersect |> filter(poly_Incid == 'PALISADES') |> mutate(when.fire = '2025') |> select(when.fire) |> rename(x = geometry)), 
          mapping = aes(color = when.fire), fill = 'gray', linewidth = 1.5, alpha = 0) +
  scale_color_brewer(name = 'Fire Impact Years', type = 'qual', palette = 6) +
  scale_linetype(name = 'Fire Impact Years') +
  scale_fill_viridis_c(option = 'viridis', name = 'Built After 2008 (%)', limits = c(0, 40)) +
  theme_bw() +
  theme(legend.position = "inside", legend.direction="horizontal", legend.position.inside = c(0.35, 0.75), legend.background = element_blank()) +
  guides(fill = guide_colorbar(title.position = "top", order = 2), color = guide_legend(order = 1))
fs4a

#Eaton
fs4b <- ggplot() +
  geom_sf(data = combined.block.sf %>% filter(which.fire == 'Eaton' & !is.na(structure_value_median) & !is.na(destroy_pct) & UR20 == 'U'), color = 'black', 
          mapping = aes(fill = after_2008_pct)) +
  geom_sf(data = rbind(frap.la.intersect |> filter(year >= 1910 & which.fire == 'Eaton') |> st_union() |> st_as_sf() |> mutate(when.fire = '1910-2023'), 
                       wgis.la.intersect |> filter(poly_Incid == 'Eaton') |> mutate(when.fire = '2025') |> select(when.fire) |> rename(x = geometry)), 
          mapping = aes(color = when.fire), fill = 'gray', linewidth = 1.5 , alpha = 0) +
  scale_color_brewer(name = 'Fire Years', type = 'qual', palette = 6) +
  scale_fill_viridis_c(option = 'viridis', name = 'Built After 2008 (%)', limits = c(0, 40)) +
  theme_bw() +
  theme(legend.position = "none", legend.direction="horizontal", legend.position.inside = c(0.8, 0.8)) +
  guides(fill = guide_colorbar(title.position = "top"))
fs4b

fs4 <- ggarrange(fs4a, fs4b, nrow = 2, ncol = 1, common.legend = FALSE, labels = c('a', 'b'))
fs4

#Save the figure
ggsave('FigS4_map_after_2008_pct.png',
       plot = fs4,
       path = 'C://Users//CarlNorlen//mystuff//la-urban-fires//figures',
       scale = 1,
       width = 16,
       height = 18,
       units = c("cm"),
       dpi = 300
)

#Supplemental Urban Morphology: Figure S5
#Mean number of structure overlaps in Zones 0 & 1
#Pre-fire median year structure built
ps5a <- ggplot(data = combined.block.sf |> as.data.frame() |>  filter(as.numeric(fire.area.2025.pct) > 0 & !is.na(structure.count) & !is.na(structure_value_median) & UR20 == 'U'), mapping = aes(color = which.fire, x = fire.area.1910to2023.pct, y = destroy_pct)) +
  geom_point(size = 1, alpha = 0.5) +
  stat_cor(mapping = aes(label = paste(after_stat(rr.label), after_stat(p.label), sep = "~`,`~"), 
                         color = which.fire), label.x.npc = 0.05, label.y.npc = 0.99, p.accuracy = 0.01) +
  geom_smooth(method = 'lm', mapping = aes(linetype = which.fire, color = which.fire)) +
  scale_color_brewer(palette = 'Dark2', type = 'seq', name = 'Fire Name') +
  scale_linetype(name = 'Fire Name') +
  ylim(0, 119) +
  ylab('Structures Destroyed (%)') + xlab('Pre-2025 Burned Area Proportion (%)') +
  theme_bw() +
  theme(legend.position = 'none')
ps5a

ps5b <- ggplot(data = combined.block.sf |> as.data.frame() |>  filter(as.numeric(fire.area.2025.pct) > 0 & !is.na(structure.count) & !is.na(structure_value_median) & UR20 == 'U'), mapping = aes(color = which.fire, x = year.built.median, y = destroy_pct)) +
  geom_point(size = 1, alpha = 0.5) +
  stat_cor(mapping = aes(label = paste(after_stat(rr.label), after_stat(p.label), sep = "~`,`~"), 
                         color = which.fire), label.x.npc = 0.05, label.y.npc = 0.99, p.accuracy = 0.01) +
  geom_smooth(method = 'lm', mapping = aes(linetype = which.fire, color = which.fire)) +
  scale_color_brewer(palette = 'Dark2', type = 'seq', name = 'Fire Name') +
  scale_linetype(name = 'Fire Name') +
  ylim(0, 119) +
  ylab('Structures Destroyed (%)') + xlab('Median Year Structure Built') +
  theme_bw() +
  theme(legend.position = 'none')
ps5b

#Median structure replacement value
ps5c <- ggplot(data = combined.block.sf |> as.data.frame() |>  filter(as.numeric(fire.area.2025.pct) > 0 & !is.na(structure.count) & !is.na(structure_value_median) & UR20 == 'U'), 
               mapping = aes(color = which.fire, x = structure_value_median / 1000, y = destroy_pct)) +
  geom_point(size = 1, alpha = 0.5) +
  stat_cor(mapping = aes(label = paste(after_stat(rr.label), after_stat(p.label), sep = "~`,`~"), 
                         color = which.fire), label.x.npc = 0.05, label.y.npc = 0.99, p.accuracy = 0.01) +
  geom_smooth(method = 'lm', mapping = aes(linetype = which.fire, color = which.fire)) +
  scale_color_brewer(palette = 'Dark2', type = 'seq', name = 'Fire Name') +
  scale_linetype(name = 'Fire Name') +
  ylim(-35,125) +
  ylab('Structures Destroyed (%)') + xlab('Median Structure Replacement Value ($1000)') +
  theme_bw() +
  theme(legend.position = 'inside', legend.position.inside = c(0.85, 0.85), legend.background = element_blank())
ps5c

ps5d <- ggplot(data = combined.block.sf |> as.data.frame() |>  filter(as.numeric(fire.area.2025.pct) > 0 & !is.na(structure.count) & !is.na(structure_value_median) & UR20 == 'U'), 
               mapping = aes(color = which.fire, x = after_2008_pct, y = destroy_pct)) +
  geom_point(size = 1, alpha = 0.5) +
  stat_cor(mapping = aes(label = paste(after_stat(rr.label), after_stat(p.label), sep = "~`,`~"), 
                         color = which.fire), label.x.npc = 0.05, label.y.npc = 0.99, p.accuracy = 0.01) +
  geom_smooth(method = 'lm', mapping = aes(linetype = which.fire, color = which.fire)) +
  scale_color_brewer(palette = 'Dark2', type = 'seq', name = 'Fire Name') +
  scale_linetype(name = 'Fire Name') +
  ylim(-70, 125) + 
  ylab('Structures Destroyed (%)') + xlab('Structures Built after 2008 (%)') +
  theme_bw() +
  theme(legend.position = 'none')
ps5d

ps5e <- ggplot(data = combined.block.sf |> as.data.frame() |>  filter(as.numeric(fire.area.2025.pct) > 0 & !is.na(structure.count) & !is.na(structure_value_median) & UR20 == 'U'), mapping = aes(color = which.fire, x = zone_one_overlap_mean, y = destroy_pct)) +
  geom_point(size = 1, alpha = 0.5) +
  stat_cor(mapping = aes(label = paste(after_stat(rr.label), after_stat(p.label), sep = "~`,`~"), 
                         color = which.fire), label.x.npc = 0.05, label.y.npc = 0.99, p.accuracy = 0.01) +
  geom_smooth(method = 'lm', mapping = aes(linetype = which.fire, color = which.fire)) +
  scale_color_brewer(palette = 'Dark2', type = 'seq', name = 'Fire Name') +
  scale_linetype(name = 'Fire Name') +
  ylim(0, 119) + 
  xlim(0, 5) +
  ylab('Structures Destroyed (%)') + xlab('Mean Structures Overlaps in Zone 0 & 1 (0-9.1m)') +
  theme_bw() +
  theme(legend.position = 'none')
ps5e

#Mean number of structure overlaps in Zones 0, 1, & 2
ps5f <- ggplot(data = combined.block.sf |> as.data.frame() |>  filter(as.numeric(fire.area.2025.pct) > 0 & !is.na(structure.count) & !is.na(structure_value_median) & UR20 == 'U'), 
               mapping = aes(color = which.fire, x = zone_two_overlap_mean, y = destroy_pct)) +
  geom_point(size = 1, alpha = 0.5) +
  stat_cor(mapping = aes(label = paste(after_stat(rr.label), after_stat(p.label), sep = "~`,`~"), 
                         color = which.fire), label.x.npc = 0.05, label.y.npc = 0.99, p.accuracy = 0.01) +
  geom_smooth(method = 'lm', mapping = aes(linetype = which.fire, color = which.fire)) +
  scale_color_brewer(palette = 'Dark2', type = 'seq', name = 'Fire Name') +
  scale_linetype(name = 'Fire Name') +
  ylim(-5, 119) + 
  xlim(0, 5) +
  ylab('Structures Destroyed (%)') + xlab('Mean Structures Overlaps in Zone 0, 1 & 2 (0-30.5m)') +
  theme_bw() +
  theme(legend.position = 'none')
ps5f

fs5 <- ggarrange(ps5a, ps5b, ps5c, ps5d, ps5e, ps5f, nrow = 2, ncol = 3, align = "hv", common.legend = FALSE, labels = c('a', 'b', 'c', 'd', 'e', 'f'))
fs5

#Save the figure
ggsave('FigS5_fire_damage_urban_morphology_correlation_grid.png',
       plot = fs5,
       path = 'C://Users//CarlNorlen//mystuff//la-urban-fires//figures',
       scale = 1,
       width = 36,
       height = 24,
       units = c("cm"),
       dpi = 300
)

#Supplemental Urban Morphology: Figure S6
#Mean number of structure overlaps in Zones 0 & 1
#Pre-fire median year structure built
ps6a <- ggplot(data = combined.block.sf |> as.data.frame() |>  filter(as.numeric(fire.area.2025.pct) > 0 & !is.na(structure.count) & !is.na(structure_value_median) & !is.na(PercapitaInc) & UR20 == 'U'), 
               mapping = aes(color = which.fire, x = ww_bbg_pct_belowpoverty_C * 100, y = destroy_pct)) +
  geom_point(size = 1, alpha = 0.5) +
  stat_cor(mapping = aes(label = paste(after_stat(rr.label), after_stat(p.label), sep = "~`,`~"), 
                         color = which.fire), label.x.npc = 0.05, label.y.npc = 0.99, p.accuracy = 0.01) +
  geom_smooth(method = 'lm', mapping = aes(linetype = which.fire, color = which.fire)) +
  scale_color_brewer(palette = 'Dark2', type = 'seq', name = 'Fire Name') +
  scale_linetype(name = 'Fire Name') +
  ylim(0, 119) +
  ylab('Structures Destroyed (%)') + xlab('Below Poverty (%)') +
  theme_bw() +
  theme(legend.position = 'none')
ps6a

# summary(combined.block.sf |> as.data.frame())
ps6b <- ggplot(data = combined.block.sf |> as.data.frame() |>  filter(as.numeric(fire.area.2025.pct) > 0 & !is.na(structure.count) & !is.na(structure_value_median) & !is.na(PercapitaInc) & UR20 == 'U'), 
               mapping = aes(color = which.fire, x = Tpct.FA_whitep_C * 100, y = destroy_pct)) +
  geom_point(size = 1, alpha = 0.5) +
  stat_cor(mapping = aes(label = paste(after_stat(rr.label), after_stat(p.label), sep = "~`,`~"), 
                         color = which.fire), label.x.npc = 0.05, label.y.npc = 0.99, p.accuracy = 0.01) +
  geom_smooth(method = 'lm', mapping = aes(linetype = which.fire, color = which.fire)) +
  scale_color_brewer(palette = 'Dark2', type = 'seq', name = 'Fire Name') +
  scale_linetype(name = 'Fire Name') +
  ylim(0, 119) +
  ylab('Structures Destroyed (%)') + xlab('White (%)') +
  theme_bw() +
  theme(legend.position = 'none')
ps6b

#Median structure replacement value
ps6c <- ggplot(data = combined.block.sf |> as.data.frame() |>  filter(as.numeric(fire.area.2025.pct) > 0 & !is.na(structure.count) & !is.na(structure_value_median) & !is.na(PercapitaInc) & UR20 == 'U'), 
               mapping = aes(color = which.fire, x = Tpct.FA_65.and.over_yrs._C * 100, y = destroy_pct)) +
  geom_point(size = 1, alpha = 0.5) +
  stat_cor(mapping = aes(label = paste(after_stat(rr.label), after_stat(p.label), sep = "~`,`~"), 
                         color = which.fire), label.x.npc = 0.05, label.y.npc = 0.99, p.accuracy = 0.01) +
  geom_smooth(method = 'lm', mapping = aes(linetype = which.fire, color = which.fire)) +
  scale_color_brewer(palette = 'Dark2', type = 'seq', name = 'Fire Name') +
  scale_linetype(name = 'Fire Name') +
  ylim(-35,125) +
  ylab('Structures Destroyed (%)') + xlab('Age 65+ years old (%)') +
  theme_bw() +
  theme(legend.position = 'inside', legend.position.inside = c(0.85, 0.85), legend.background = element_blank())
ps6c

ps6d <- ggplot(data = combined.block.sf |> as.data.frame() |>  filter(as.numeric(fire.area.2025.pct) > 0 & !is.na(structure.count) & !is.na(structure_value_median) & !is.na(PercapitaInc) & UR20 == 'U'), 
               mapping = aes(color = which.fire, x = Tpct.FA_Hispanic_C * 100, y = destroy_pct)) +
  geom_point(size = 1, alpha = 0.5) +
  stat_cor(mapping = aes(label = paste(after_stat(rr.label), after_stat(p.label), sep = "~`,`~"), 
                         color = which.fire), label.x.npc = 0.05, label.y.npc = 0.99, p.accuracy = 0.01) +
  geom_smooth(method = 'lm', mapping = aes(linetype = which.fire, color = which.fire)) +
  scale_color_brewer(palette = 'Dark2', type = 'seq', name = 'Fire Name') +
  scale_linetype(name = 'Fire Name') +
  ylim(0, 150) + 
  # xlim(0, 5) +
  ylab('Structures Destroyed (%)') + xlab('Hispanic (%)') +
  theme_bw() +
  # scale_y_continuous(labels = c('0', 's6', '50', '75', '100', '')) +
  theme(legend.position = 'none')
ps6d

ps6e <- ggplot(data = combined.block.sf |> as.data.frame() |>  filter(as.numeric(fire.area.2025.pct) > 0 & !is.na(structure.count) & !is.na(structure_value_median) & !is.na(PercapitaInc) & UR20 == 'U'), 
               mapping = aes(color = which.fire, x = Tpct.FA_Ap_C * 100, y = destroy_pct)) +
  geom_point(size = 1, alpha = 0.5) +
  stat_cor(mapping = aes(label = paste(after_stat(rr.label), after_stat(p.label), sep = "~`,`~"), 
                         color = which.fire), label.x.npc = 0.05, label.y.npc = 0.99, p.accuracy = 0.01) +
  geom_smooth(method = 'lm', mapping = aes(linetype = which.fire, color = which.fire)) +
  scale_color_brewer(palette = 'Dark2', type = 'seq', name = 'Fire Name') +
  scale_linetype(name = 'Fire Name') +
  ylim(-46.5, 119) + 
  # xlim(0, 5) +
  ylab('Structures Destroyed (%)') + xlab('Asian (%)') +
  theme_bw() +
  # scale_y_continuous(labels = c('0', '25', '50', '75', '100', '')) +
  theme(legend.position = 'none')
ps6e

#Mean number of structure overlaps in Zones 0, 1, & 2
ps6f <- ggplot(data = combined.block.sf |> as.data.frame() |>  filter(as.numeric(fire.area.2025.pct) > 0 & !is.na(structure.count) & !is.na(structure_value_median) & UR20 == 'U'), 
               mapping = aes(color = which.fire, x = (ww_pct_bbg_noschooling_C + ww_bbg_pct_highsch_C + ww_bbg_pct_associate_C) * 100, y = destroy_pct)) +
  geom_point(size = 1, alpha = 0.5) +
  stat_cor(mapping = aes(label = paste(after_stat(rr.label), after_stat(p.label), sep = "~`,`~"), 
                         color = which.fire), label.x.npc = 0.05, label.y.npc = 0.99, p.accuracy = 0.01) +
  geom_smooth(method = 'lm', mapping = aes(linetype = which.fire, color = which.fire)) +
  scale_color_brewer(palette = 'Dark2', type = 'seq', name = 'Fire Name') +
  scale_linetype(name = 'Fire Name') +
  ylim(0, 129) + 
  #xlim(0, 5) +
  ylab('Structures Destroyed (%)') + xlab("Less than Bachelor's Degree (%)") +
  theme_bw() +
  # scale_y_continuous(labels = c('0', '25', '50', '75', '100', '')) +
  theme(legend.position = 'none')
ps6f

fs5 <- ggarrange(ps6a, ps6b, ps6c, ps6d, ps6e, ps6f, nrow = 2, ncol = 3, align = "hv", common.legend = FALSE, labels = c('a', 'b', 'c', 'd', 'e', 'f'))
fs6

#Save the figure
ggsave('FigS6_fire_damage_socioeconomic_correlation_grid.png',
       plot = f25,
       path = 'C://Users//CarlNorlen//mystuff//la-urban-fires//figures',
       scale = 1,
       width = 36,
       height = 24,
       units = c("cm"),
       dpi = 300
)

#Additional Maps and Figure
#These can probably be deleted or moved to a different script
#Palisades Fires 
p13a <- ggplot() +
  geom_sf(data = combined.block.sf %>% filter(which.fire == 'Palisades' & !is.na(structure_value_median) & !is.na(destroy_pct) & UR20 == 'U'), color = 'black', 
          mapping = aes(fill = Tpct.FA_AIANp)) +
  # geom_sf() +
  geom_sf(data = rbind(frap.la.intersect |> filter(year >= 1910 & which.fire == 'Palisades') |> st_union() |> st_as_sf() |> mutate(when.fire = '1910-2023'), 
                       wgis.la.intersect |> filter(poly_Incid == 'PALISADES') |> mutate(when.fire = '2025') |> select(when.fire) |> rename(x = geometry)), 
          mapping = aes(color = when.fire), fill = 'gray', linewidth = 1.5, alpha = 0) +
  # geom_sf(data = wgis.la.intersect |> filter(poly_Incid == 'PALISADES'), color = viridis::viridis_pal(option = "inferno")(12)[12], fill = 'gray', linewidth = 1.5, alpha = 0) +
  scale_color_brewer(name = 'Fire Impact Years', type = 'qual', palette = 6) +
  scale_fill_viridis_c(option = 'viridis', name = 'Native American (%)', limits = c(0, 15)) +
  scale_linetype(name = 'Fire Years') +
  theme_bw() +
  theme(legend.position = "inside", legend.direction="horizontal", legend.position.inside = c(0.35, 0.75), legend.background = element_blank()) +
  guides(fill = guide_colorbar(title.position = "top"))
p13a

#Eaton Fire
p13b <- ggplot() +
  geom_sf(data = combined.block.sf %>% filter(which.fire == 'Eaton' & !is.na(structure_value_median) & !is.na(destroy_pct) & UR20 == 'U'), color = 'black', 
          mapping = aes(fill = Tpct.FA_AIANp)) +
  geom_sf(data = rbind(frap.la.intersect |> filter(year >= 1910 & which.fire == 'Eaton') |> st_union() |> st_as_sf() |> mutate(when.fire = '1910-2023'), 
                       wgis.la.intersect |> filter(poly_Incid == 'Eaton') |> mutate(when.fire = '2025') |> select(when.fire) |> rename(x = geometry)), 
          mapping = aes(color = when.fire), fill = 'gray', linewidth = 1.5 , alpha = 0) +
  # geom_sf(data = wgis.la.intersect |> filter(poly_Incid == 'PALISADES'), color = viridis::viridis_pal(option = "inferno")(12)[12], fill = 'gray', linewidth = 1.5, alpha = 0) +
  scale_color_brewer(name = 'Fire Years', type = 'qual', palette = 6) +
  scale_fill_viridis_c(option = 'viridis', name = 'Native American (%)', limits = c(0, 15)) +
  # scale_color_viridis_c(name = 'Fire Year', option = 'inferno', limits = c(1910, 2025)) +
  theme_bw() +
  theme(legend.position = "none", legend.direction="horizontal", legend.position.inside = c(0.8, 0.8)) +
  guides(fill = guide_colorbar(title.position = "top"))
p13b

#
f13 <- ggarrange(p13a, p13b, nrow = 2, ncol = 1, common.legend = FALSE, labels = c('a', 'b'))
f13

#Save the figure
ggsave('Fig13_map_native_american.png',
       plot = f13,
       path = 'C://Users//CarlNorlen//mystuff//la-urban-fires//figures',
       scale = 1,
       width = 16,
       height = 18,
       units = c("cm"),
       dpi = 300
)

#S
p14a <- ggplot() +
  geom_sf(data = combined.block.sf %>% filter(which.fire == 'Palisades' & !is.na(structure_value_median) & !is.na(destroy_pct) & UR20 == 'U'), color = 'black', 
          mapping = aes(fill = as.numeric(Tpct.FA_renter_occ))) +
  # geom_sf() +
  geom_sf(data = rbind(frap.la.intersect |> filter(year >= 1910 & which.fire == 'Palisades') |> st_union() |> st_as_sf() |> mutate(when.fire = '1910-2023'), 
                       wgis.la.intersect |> filter(poly_Incid == 'PALISADES') |> mutate(when.fire = '2025') |> select(when.fire) |> rename(x = geometry)), 
          mapping = aes(color = when.fire), fill = 'gray', linewidth = 1.5, alpha = 0) +
  # geom_sf(data = wgis.la.intersect |> filter(poly_Incid == 'PALISADES'), color = viridis::viridis_pal(option = "inferno")(12)[12], fill = 'gray', linewidth = 1.5, alpha = 0) +
  scale_color_brewer(name = 'Fire Impact Years', type = 'qual', palette = 6) +
  scale_fill_viridis_c(option = 'viridis', name = 'Renter Occupied (%)') +
  scale_linetype(name = 'Fire Years') +
  theme_bw() +
  theme(legend.position = "inside", legend.direction="horizontal", legend.position.inside = c(0.35, 0.75), legend.background = element_blank()) +
  guides(fill = guide_colorbar(title.position = "top"))
p14a

#Eaton Fire
#Combine this with figure 2
p14b <- ggplot() +
  geom_sf(data = combined.block.sf %>% filter(which.fire == 'Eaton' & !is.na(structure_value_median) & !is.na(destroy_pct) & UR20 == 'U'), color = 'black', 
          mapping = aes(fill = as.numeric(Tpct.FA_renter_occ))) +
  geom_sf(data = rbind(frap.la.intersect |> filter(year >= 1910 & which.fire == 'Eaton') |> st_union() |> st_as_sf() |> mutate(when.fire = '1910-2023'), 
                       wgis.la.intersect |> filter(poly_Incid == 'Eaton') |> mutate(when.fire = '2025') |> select(when.fire) |> rename(x = geometry)), 
          mapping = aes(color = when.fire), fill = 'gray', linewidth = 1.5 , alpha = 0) +
  # geom_sf(data = wgis.la.intersect |> filter(poly_Incid == 'PALISADES'), color = viridis::viridis_pal(option = "inferno")(12)[12], fill = 'gray', linewidth = 1.5, alpha = 0) +
  scale_color_brewer(name = 'Fire Years', type = 'qual', palette = 6) +
  scale_fill_viridis_c(option = 'viridis', name = 'Renter Occupied (%)', limits = c(0, 100)) +
  # scale_color_viridis_c(name = 'Fire Year', option = 'inferno', limits = c(1910, 2025)) +
  theme_bw() +
  theme(legend.position = "none", legend.direction="horizontal", legend.position.inside = c(0.8, 0.8)) +
  guides(fill = guide_colorbar(title.position = "top"))
p14b

f14 <- ggarrange(p14a, p14b, nrow = 2, ncol = 1, common.legend = FALSE, labels = c('a', 'b'))
f14

#Save the figure
ggsave('Fig14_map_renter_occupied.png',
       plot = f14,
       path = 'C://Users//CarlNorlen//mystuff//la-urban-fires//figures',
       scale = 1,
       width = 16,
       height = 18,
       units = c("cm"),
       dpi = 300
)

#Check out the distribution of homes
p15a <- ggplot() +
  geom_sf(data = combined.block.sf %>% filter(which.fire == 'Palisades' & !is.na(structure_value_median) & !is.na(destroy_pct) & UR20 == 'U'), color = 'black', 
          mapping = aes(fill = year.built.median)) +
  # geom_sf() +
  geom_sf(data = rbind(frap.la.intersect |> filter(year >= 1910 & which.fire == 'Palisades') |> st_union() |> st_as_sf() |> mutate(when.fire = '1910-2023'), 
                       wgis.la.intersect |> filter(poly_Incid == 'PALISADES') |> mutate(when.fire = '2025') |> select(when.fire) |> rename(x = geometry)), 
          mapping = aes(color = when.fire), fill = 'gray', linewidth = 1.5, alpha = 0) +
  # geom_sf(data = wgis.la.intersect |> filter(poly_Incid == 'PALISADES'), color = viridis::viridis_pal(option = "inferno")(12)[12], fill = 'gray', linewidth = 1.5, alpha = 0) +
  scale_color_brewer(name = 'Fire Impact Years', type = 'qual', palette = 6) +
  scale_fill_viridis_c(option = 'viridis', name = 'Median Year Built') +
  scale_linetype(name = 'Fire Years') +
  theme_bw() +
  theme(legend.position = "inside", legend.direction="horizontal", legend.position.inside = c(0.35, 0.75), legend.background = element_blank()) +
  guides(fill = guide_colorbar(title.position = "top"))
p15a

#Eaton Fire
#Combine this with figure 2
p15b <- ggplot() +
  geom_sf(data = combined.block.sf %>% filter(which.fire == 'Eaton' & !is.na(structure_value_median) & !is.na(destroy_pct) & UR20 == 'U'), color = 'black', 
          mapping = aes(fill = year.built.median)) +
  geom_sf(data = rbind(frap.la.intersect |> filter(year >= 1910 & which.fire == 'Eaton') |> st_union() |> st_as_sf() |> mutate(when.fire = '1910-2023'), 
                       wgis.la.intersect |> filter(poly_Incid == 'Eaton') |> mutate(when.fire = '2025') |> select(when.fire) |> rename(x = geometry)), 
          mapping = aes(color = when.fire), fill = 'gray', linewidth = 1.5 , alpha = 0) +
  # geom_sf(data = wgis.la.intersect |> filter(poly_Incid == 'PALISADES'), color = viridis::viridis_pal(option = "inferno")(12)[12], fill = 'gray', linewidth = 1.5, alpha = 0) +
  scale_color_brewer(name = 'Fire Years', type = 'qual', palette = 6) +
  scale_fill_viridis_c(option = 'viridis', name = 'Median Year Built') +
  # scale_color_viridis_c(name = 'Fire Year', option = 'inferno', limits = c(1910, 2025)) +
  theme_bw() +
  theme(legend.position = "none", legend.direction="horizontal", legend.position.inside = c(0.8, 0.8)) +
  guides(fill = guide_colorbar(title.position = "top"))
p15b

f15 <- ggarrange(p15a, p15b, nrow = 2, ncol = 1, common.legend = FALSE, labels = c('a', 'b'))
f15

#Save the figure
ggsave('Fig15_map_median_year_built.png',
       plot = f15,
       path = 'C://Users//CarlNorlen//mystuff//la-urban-fires//figures',
       scale = 1,
       width = 16,
       height = 18,
       units = c("cm"),
       dpi = 300
)

#Check out the distribution of homes
p16a <- ggplot() +
  geom_sf(data = combined.block.sf %>% filter(which.fire == 'Palisades' & !is.na(structure_value_median) & !is.na(destroy_pct) & UR20 == 'U'), 
          color = 'black', mapping = aes(fill = (Tpct.FA_under_5yrs + Tpct.FA_5.19_yrs))) +
  # geom_sf() +
  geom_sf(data = rbind(frap.la.intersect |> filter(year >= 1910 & which.fire == 'Palisades') |> st_union() |> st_as_sf() |> mutate(when.fire = '1910-2023'), 
                       wgis.la.intersect |> filter(poly_Incid == 'PALISADES') |> mutate(when.fire = '2025') |> select(when.fire) |> rename(x = geometry)), 
          mapping = aes(color = when.fire), fill = 'gray', linewidth = 1.5, alpha = 0) +
  # geom_sf(data = wgis.la.intersect |> filter(poly_Incid == 'PALISADES'), color = viridis::viridis_pal(option = "inferno")(12)[12], fill = 'gray', linewidth = 1.5, alpha = 0) +
  scale_color_brewer(name = 'Fire Impact Years', type = 'qual', palette = 6) +
  scale_fill_viridis_c(option = 'viridis', name = 'Proportion 0-19 Years (%)', limits = c(0, 100)) +
  scale_linetype(name = 'Fire Years') +
  theme_bw() +
  theme(legend.position = "inside", legend.direction="horizontal", legend.position.inside = c(0.35, 0.75), legend.background = element_blank()) +
  guides(fill = guide_colorbar(title.position = "top"))
p16a

#Eaton Fire
#Combine this with figure 2
p16b <- ggplot() +
  geom_sf(data = combined.block.sf %>% filter(which.fire == 'Eaton' & !is.na(structure_value_median) & !is.na(destroy_pct) & UR20 == 'U'), color = 'black', 
          mapping = aes(fill = (Tpct.FA_under_5yrs + Tpct.FA_5.19_yrs))) +
  geom_sf(data = rbind(frap.la.intersect |> filter(year >= 1910 & which.fire == 'Eaton') |> st_union() |> st_as_sf() |> mutate(when.fire = '1910-2023'), 
                       wgis.la.intersect |> filter(poly_Incid == 'Eaton') |> mutate(when.fire = '2025') |> select(when.fire) |> rename(x = geometry)), 
          mapping = aes(color = when.fire), fill = 'gray', linewidth = 1.5 , alpha = 0) +
  # geom_sf(data = wgis.la.intersect |> filter(poly_Incid == 'PALISADES'), color = viridis::viridis_pal(option = "inferno")(12)[12], fill = 'gray', linewidth = 1.5, alpha = 0) +
  scale_color_brewer(name = 'Fire Years', type = 'qual', palette = 6) +
  scale_fill_viridis_c(option = 'viridis', name = 'Proportion 0-19 Years (%)', limits = c(0, 100)) +
  # scale_color_viridis_c(name = 'Fire Year', option = 'inferno', limits = c(1910, 2025)) +
  theme_bw() +
  theme(legend.position = "none", legend.direction="horizontal", legend.position.inside = c(0.8, 0.8)) +
  guides(fill = guide_colorbar(title.position = "top"))
p16b

f16 <- ggarrange(p16a, p16b, nrow = 2, ncol = 1, common.legend = FALSE, labels = c('a', 'b'))
f16

#Save the figure
ggsave('Fig16_map_proportion_0_to_19.png',
       plot = f16,
       path = 'C://Users//CarlNorlen//mystuff//la-urban-fires//figures',
       scale = 1,
       width = 16,
       height = 18,
       units = c("cm"),
       dpi = 300
)

#Structure Replacement Value
p17a <- ggplot() +
  geom_sf(data = combined.block.sf %>% filter(which.fire == 'Palisades' & !is.na(structure_value_median) & !is.na(destroy_pct) & UR20 == 'U'), 
          color = 'black', mapping = aes(fill = structure_value_median / 1000)) +
  # geom_sf() +
  geom_sf(data = rbind(frap.la.intersect |> filter(year >= 1910 & which.fire == 'Palisades') |> st_union() |> st_as_sf() |> mutate(when.fire = '1910-2023'), 
                       wgis.la.intersect |> filter(poly_Incid == 'PALISADES') |> mutate(when.fire = '2025') |> select(when.fire) |> rename(x = geometry)), 
          mapping = aes(color = when.fire), fill = 'gray', linewidth = 1.5, alpha = 0) +
  # geom_sf(data = wgis.la.intersect |> filter(poly_Incid == 'PALISADES'), color = viridis::viridis_pal(option = "inferno")(12)[12], fill = 'gray', linewidth = 1.5, alpha = 0) +
  scale_color_brewer(name = 'Fire Impact Years', type = 'qual', palette = 6) +
  scale_fill_viridis_c(option = 'viridis', name = 'Median Structure Replacement Value ($1000)', limits = c(0, 15000)) +
  scale_linetype(name = 'Fire Years') +
  theme_bw() +
  theme(legend.position = "inside", legend.direction="horizontal", legend.position.inside = c(0.35, 0.75), legend.background = element_blank()) +
  guides(fill = guide_colorbar(title.position = "top"))
p17a

#Eaton Fire
#Combine this with figure 2
p17b <- ggplot() +
  geom_sf(data = combined.block.sf %>% filter(which.fire == 'Eaton' & !is.na(structure_value_median) & !is.na(destroy_pct) & UR20 == 'U'), color = 'black', 
          mapping = aes(fill = structure_value_median / 1000)) +
  geom_sf(data = rbind(frap.la.intersect |> filter(year >= 1910 & which.fire == 'Eaton') |> st_union() |> st_as_sf() |> mutate(when.fire = '1910-2023'), 
                       wgis.la.intersect |> filter(poly_Incid == 'Eaton') |> mutate(when.fire = '2025') |> select(when.fire) |> rename(x = geometry)), 
          mapping = aes(color = when.fire), fill = 'gray', linewidth = 1.5 , alpha = 0) +
  # geom_sf(data = wgis.la.intersect |> filter(poly_Incid == 'PALISADES'), color = viridis::viridis_pal(option = "inferno")(12)[12], fill = 'gray', linewidth = 1.5, alpha = 0) +
  scale_color_brewer(name = 'Fire Years', type = 'qual', palette = 6) +
  scale_fill_viridis_c(option = 'viridis', name = 'Median Structure Replacement Value ($1000)', limits = c(0, 15000)) +
  # scale_color_viridis_c(name = 'Fire Year', option = 'inferno', limits = c(1910, 2025)) +
  theme_bw() +
  theme(legend.position = "none", legend.direction="horizontal", legend.position.inside = c(0.8, 0.8)) +
  guides(fill = guide_colorbar(title.position = "top"))
p17b

f17 <- ggarrange(p17a, p17b, nrow = 2, ncol = 1, common.legend = FALSE, labels = c('a', 'b'))
f17

#Save the figure
ggsave('Fig17_map_structure_replacement_value.png',
       plot = f17,
       path = 'C://Users//CarlNorlen//mystuff//la-urban-fires//figures',
       scale = 1,
       width = 16,
       height = 18,
       units = c("cm"),
       dpi = 300
)

#URban TRee Cover
p18a <- ggplot() +
  geom_sf(data = combined.block.sf %>% filter(which.fire == 'Palisades' & !is.na(structure_value_median) & !is.na(destroy_pct) & UR20 == 'U'), 
          color = 'black', mapping = aes(fill = tree.cover.2022)) +
  # geom_sf() +
  geom_sf(data = rbind(frap.la.intersect |> filter(year >= 1910 & which.fire == 'Palisades') |> st_union() |> st_as_sf() |> mutate(when.fire = '1910-2023'), 
                       wgis.la.intersect |> filter(poly_Incid == 'PALISADES') |> mutate(when.fire = '2025') |> select(when.fire) |> rename(x = geometry)), 
          mapping = aes(color = when.fire), fill = 'gray', linewidth = 1.5, alpha = 0) +
  # geom_sf(data = wgis.la.intersect |> filter(poly_Incid == 'PALISADES'), color = viridis::viridis_pal(option = "inferno")(12)[12], fill = 'gray', linewidth = 1.5, alpha = 0) +
  scale_color_brewer(name = 'Fire Impact Years', type = 'qual', palette = 6) +
  scale_fill_viridis_c(option = 'viridis', name = 'Urban Tree Cover (%)', limits = c(0, 70)) +
  scale_linetype(name = 'Fire Years') +
  theme_bw() +
  theme(legend.position = "inside", legend.direction="horizontal", legend.position.inside = c(0.35, 0.75), legend.background = element_blank()) +
  guides(fill = guide_colorbar(title.position = "top"))
p18a

#Eaton Fire
#Combine this with figure 2
p18b <- ggplot() +
  geom_sf(data = combined.block.sf %>% filter(which.fire == 'Eaton' & !is.na(structure_value_median) & !is.na(destroy_pct) & UR20 == 'U'), color = 'black', 
          mapping = aes(fill = tree.cover.2022)) +
  geom_sf(data = rbind(frap.la.intersect |> filter(year >= 1910 & which.fire == 'Eaton') |> st_union() |> st_as_sf() |> mutate(when.fire = '1910-2023'), 
                       wgis.la.intersect |> filter(poly_Incid == 'Eaton') |> mutate(when.fire = '2025') |> select(when.fire) |> rename(x = geometry)), 
          mapping = aes(color = when.fire), fill = 'gray', linewidth = 1.5 , alpha = 0) +
  # geom_sf(data = wgis.la.intersect |> filter(poly_Incid == 'PALISADES'), color = viridis::viridis_pal(option = "inferno")(12)[12], fill = 'gray', linewidth = 1.5, alpha = 0) +
  scale_color_brewer(name = 'Fire Years', type = 'qual', palette = 6) +
  scale_fill_viridis_c(option = 'viridis', name = 'Urban Tree Cover (%)', limits = c(0, 70)) +
  # scale_color_viridis_c(name = 'Fire Year', option = 'inferno', limits = c(1910, 2025)) +
  theme_bw() +
  theme(legend.position = "none", legend.direction="horizontal", legend.position.inside = c(0.8, 0.8)) +
  guides(fill = guide_colorbar(title.position = "top"))
p18b

f18 <- ggarrange(p18a, p18b, nrow = 2, ncol = 1, common.legend = FALSE, labels = c('a', 'b'))
f18

#Save the figure
ggsave('Fig18_map_urban_tree_cover.png',
       plot = f18,
       path = 'C://Users//CarlNorlen//mystuff//la-urban-fires//figures',
       scale = 1,
       width = 16,
       height = 18,
       units = c("cm"),
       dpi = 300
)

#Percentage Black (%)
p19a <- ggplot() +
  geom_sf(data = combined.block.sf %>% filter(which.fire == 'Palisades' & !is.na(structure_value_median) & !is.na(destroy_pct) & UR20 == 'U'), 
          color = 'black', mapping = aes(fill = Tpct.FA_AAp)) +
  # geom_sf() +
  geom_sf(data = rbind(frap.la.intersect |> filter(year >= 1910 & which.fire == 'Palisades') |> st_union() |> st_as_sf() |> mutate(when.fire = '1910-2023'), 
                       wgis.la.intersect |> filter(poly_Incid == 'PALISADES') |> mutate(when.fire = '2025') |> select(when.fire) |> rename(x = geometry)), 
          mapping = aes(color = when.fire), fill = 'gray', linewidth = 1.5, alpha = 0) +
  # geom_sf(data = wgis.la.intersect |> filter(poly_Incid == 'PALISADES'), color = viridis::viridis_pal(option = "inferno")(12)[12], fill = 'gray', linewidth = 1.5, alpha = 0) +
  scale_color_brewer(name = 'Fire Impact Years', type = 'qual', palette = 6) +
  scale_fill_viridis_c(option = 'viridis', name = 'Black / African American (%)', limit = c(0, 100)) +
  scale_linetype(name = 'Fire Years') +
  theme_bw() +
  theme(legend.position = "inside", legend.direction="horizontal", legend.position.inside = c(0.35, 0.75), legend.background = element_blank()) +
  guides(fill = guide_colorbar(title.position = "top"))
p19a

#Eaton Fire
#Combine this with figure 2
p19b <- ggplot() +
  geom_sf(data = combined.block.sf %>% filter(which.fire == 'Eaton' & !is.na(structure_value_median) & !is.na(destroy_pct) & UR20 == 'U'), color = 'black', 
          mapping = aes(fill = Tpct.FA_AAp)) +
  geom_sf(data = rbind(frap.la.intersect |> filter(year >= 1910 & which.fire == 'Eaton') |> st_union() |> st_as_sf() |> mutate(when.fire = '1910-2023'), 
                       wgis.la.intersect |> filter(poly_Incid == 'Eaton') |> mutate(when.fire = '2025') |> select(when.fire) |> rename(x = geometry)), 
          mapping = aes(color = when.fire), fill = 'gray', linewidth = 1.5 , alpha = 0) +
  # geom_sf(data = wgis.la.intersect |> filter(poly_Incid == 'PALISADES'), color = viridis::viridis_pal(option = "inferno")(12)[12], fill = 'gray', linewidth = 1.5, alpha = 0) +
  scale_color_brewer(name = 'Fire Years', type = 'qual', palette = 6) +
  scale_fill_viridis_c(option = 'viridis', name = 'Black / African American (%)', limit = c(0, 100)) +
  # scale_color_viridis_c(name = 'Fire Year', option = 'inferno', limits = c(1910, 2025)) +
  theme_bw() +
  theme(legend.position = "none", legend.direction="horizontal", legend.position.inside = c(0.8, 0.8)) +
  guides(fill = guide_colorbar(title.position = "top"))
p19b

f19 <- ggarrange(p19a, p19b, nrow = 2, ncol = 1, common.legend = FALSE, labels = c('a', 'b'))
f19

#Save the figure
ggsave('Fig19_map_black_pct.png',
       plot = f19,
       path = 'C://Users//CarlNorlen//mystuff//la-urban-fires//figures',
       scale = 1,
       width = 16,
       height = 18,
       units = c("cm"),
       dpi = 300
)


# glimpse(combined.block.sf)
#Percentage built after 2008
p21a <- ggplot() +
  geom_sf(data = combined.block.sf %>% filter(which.fire == 'Palisades' & !is.na(structure_value_median) & !is.na(destroy_pct) & !is.na(PercapitaInc) & UR20 == 'U'), 
          color = 'black', mapping = aes(fill = ww_bbg_pct_belowpoverty_C * 100)) +
  # geom_sf() +
  geom_sf(data = rbind(frap.la.intersect |> filter(year >= 1910 & which.fire == 'Palisades') |> st_union() |> st_as_sf() |> mutate(when.fire = '1910-2023'), 
                       wgis.la.intersect |> filter(poly_Incid == 'PALISADES') |> mutate(when.fire = '2025') |> select(when.fire) |> rename(x = geometry)), 
          mapping = aes(color = when.fire), fill = 'gray', linewidth = 1.5, alpha = 0) +
  # geom_sf(data = wgis.la.intersect |> filter(poly_Incid == 'PALISADES'), color = viridis::viridis_pal(option = "inferno")(12)[12], fill = 'gray', linewidth = 1.5, alpha = 0) +
  scale_color_brewer(name = 'Fire Impact Years', type = 'qual', palette = 6) +
  scale_fill_viridis_c(option = 'viridis', name = 'Proportion Below Poverty (%)', limits = c(0, 60)) +
  scale_linetype(name = 'Fire Years') +
  theme_bw() +
  theme(legend.position = "inside", legend.direction="horizontal", legend.position.inside = c(0.35, 0.75), legend.background = element_blank()) +
  guides(fill = guide_colorbar(title.position = "top"))
p21a

#Eaton Fire
#Combine this with figure 2
p21b <- ggplot() +
  geom_sf(data = combined.block.sf %>% filter(which.fire == 'Eaton' & !is.na(structure_value_median) & !is.na(destroy_pct) & !is.na(PercapitaInc) & UR20 == 'U'), color = 'black', 
          mapping = aes(fill = ww_bbg_pct_belowpoverty_C * 100)) +
  geom_sf(data = rbind(frap.la.intersect |> filter(year >= 1910 & which.fire == 'Eaton') |> st_union() |> st_as_sf() |> mutate(when.fire = '1910-2023'), 
                       wgis.la.intersect |> filter(poly_Incid == 'Eaton') |> mutate(when.fire = '2025') |> select(when.fire) |> rename(x = geometry)), 
          mapping = aes(color = when.fire), fill = 'gray', linewidth = 1.5 , alpha = 0) +
  # geom_sf(data = wgis.la.intersect |> filter(poly_Incid == 'PALISADES'), color = viridis::viridis_pal(option = "inferno")(12)[12], fill = 'gray', linewidth = 1.5, alpha = 0) +
  scale_color_brewer(name = 'Fire Years', type = 'qual', palette = 6) +
  scale_fill_viridis_c(option = 'viridis', name = 'Proportion Below Poverty (%)', limits = c(0, 60)) +
  # scale_color_viridis_c(name = 'Fire Year', option = 'inferno', limits = c(1910, 2025)) +
  theme_bw() +
  theme(legend.position = "none", legend.direction="horizontal", legend.position.inside = c(0.8, 0.8)) +
  guides(fill = guide_colorbar(title.position = "top"))
p21b

f21 <- ggarrange(p21a, p21b, nrow = 2, ncol = 1, common.legend = FALSE, labels = c('a', 'b'))
f21

#Save the figure
ggsave('Fig21_map_below_poverty_pct.png',
       plot = f21,
       path = 'C://Users//CarlNorlen//mystuff//la-urban-fires//figures',
       scale = 1,
       width = 16,
       height = 18,
       units = c("cm"),
       dpi = 300
)

#Urban Tree Cover Figure
p22 <- ggplot(data = combined.block.sf |> as.data.frame() |> filter(as.numeric(fire.area.2025.pct) > 0 & UR20 == 'U' & !is.na(structure_value_median) & !is.na(destroy_pct)), 
              mapping = aes(color = which.fire, x = tree.cover.2022, y = destroy_pct)) +
  geom_point(size = 1, alpha = 0.5) +
  stat_cor(mapping = aes(label = paste(after_stat(rr.label), after_stat(p.label), sep = "~`,`~"), 
                         color = which.fire), label.x.npc = 0.05, label.y.npc = 0.99, p.accuracy = 0.01) +
  geom_smooth(method = 'lm', mapping = aes(linetype = which.fire, color = which.fire)) +
  scale_color_brewer(palette = 'Dark2', type = 'seq', name = 'Fire Name') +
  scale_linetype(name = 'Fire Name') +
  ylim(0, 119) +
  ylab('Structures Destroyed (%)') + xlab('Urban Tree Cover (%)') +
  theme_bw() +
  # guides(linetype = 'none') +
  theme(legend.position = 'inside', legend.position.inside = c(0.85, 0.9), legend.background = element_blank())
p22

#Save the figure
ggsave('Fig22_figure_urban_tree_cover.png',
       plot = p22,
       path = 'C://Users//CarlNorlen//mystuff//la-urban-fires//figures',
       scale = 1,
       width = 12,
       height = 12,
       units = c("cm"),
       dpi = 300
)

#Structure Basal Area
p23 <- ggplot(data = combined.block.sf |> as.data.frame() |> filter(as.numeric(fire.area.2025.pct) > 0 & UR20 == 'U' & !is.na(structure_value_median) & !is.na(destroy_pct)), 
              mapping = aes(color = which.fire, x = structure.basal.area, y = destroy_pct)) +
  geom_point(size = 1, alpha = 0.5) +
  stat_cor(mapping = aes(label = paste(after_stat(rr.label), after_stat(p.label), sep = "~`,`~"), 
                         color = which.fire), label.x.npc = 0.05, label.y.npc = 0.99, p.accuracy = 0.01) +
  geom_smooth(method = 'lm', mapping = aes(linetype = which.fire, color = which.fire)) +
  scale_color_brewer(palette = 'Dark2', type = 'seq', name = 'Fire Name') +
  scale_linetype(name = 'Fire Name') +
  ylim(0, 119) +
  ylab('Structures Destroyed (%)') + xlab(expression('Structure Basal Area (m'^2*' ha'^-1*')')) +
  theme_bw() +
  theme(legend.position = 'inside', legend.position.inside = c(0.85, 0.9), legend.background = element_blank())
p23

#Save the figure
ggsave('Fig23_figure_strucutre_basal_area.png',
       plot = p23,
       path = 'C://Users//CarlNorlen//mystuff//la-urban-fires//figures',
       scale = 1,
       width = 12,
       height = 12,
       units = c("cm"),
       dpi = 300
)

#Percentage Non-English Map
p26a <- ggplot() +
  geom_sf(data = combined.block.sf %>% filter(which.fire == 'Palisades' & !is.na(structure_value_median) & !is.na(destroy_pct) & !is.na(PercapitaInc) & UR20 == 'U'), 
          color = 'black', mapping = aes(fill = ww_bbg_pct_noneng_C * 100)) +
  # geom_sf() +
  geom_sf(data = rbind(frap.la.intersect |> filter(year >= 1910 & which.fire == 'Palisades') |> st_union() |> st_as_sf() |> mutate(when.fire = '1910-2023'), 
                       wgis.la.intersect |> filter(poly_Incid == 'PALISADES') |> mutate(when.fire = '2025') |> select(when.fire) |> rename(x = geometry)), 
          mapping = aes(color = when.fire), fill = 'gray', linewidth = 1.5, alpha = 0) +
  # geom_sf(data = wgis.la.intersect |> filter(poly_Incid == 'PALISADES'), color = viridis::viridis_pal(option = "inferno")(12)[12], fill = 'gray', linewidth = 1.5, alpha = 0) +
  scale_color_brewer(name = 'Fire Impact Years', type = 'qual', palette = 6) +
  scale_fill_viridis_c(option = 'viridis', name = 'Proportion Non-English Speakers (%)', limits = c(0, 60)) +
  scale_linetype(name = 'Fire Years') +
  theme_bw() +
  theme(legend.position = "inside", legend.direction="horizontal", legend.position.inside = c(0.35, 0.75), legend.background = element_blank()) +
  guides(fill = guide_colorbar(title.position = "top"))
p26a

#Eaton Fire
#Combine this with figure 2
p26b <- ggplot() +
  geom_sf(data = combined.block.sf %>% filter(which.fire == 'Eaton' & !is.na(structure_value_median) & !is.na(destroy_pct) & !is.na(PercapitaInc) & UR20 == 'U'), color = 'black', 
          mapping = aes(fill = ww_bbg_pct_noneng_C * 100)) +
  geom_sf(data = rbind(frap.la.intersect |> filter(year >= 1910 & which.fire == 'Eaton') |> st_union() |> st_as_sf() |> mutate(when.fire = '1910-2023'), 
                       wgis.la.intersect |> filter(poly_Incid == 'Eaton') |> mutate(when.fire = '2025') |> select(when.fire) |> rename(x = geometry)), 
          mapping = aes(color = when.fire), fill = 'gray', linewidth = 1.5 , alpha = 0) +
  # geom_sf(data = wgis.la.intersect |> filter(poly_Incid == 'PALISADES'), color = viridis::viridis_pal(option = "inferno")(12)[12], fill = 'gray', linewidth = 1.5, alpha = 0) +
  scale_color_brewer(name = 'Fire Years', type = 'qual', palette = 6) +
  scale_fill_viridis_c(option = 'viridis', name = 'Proportion Non-English Speakers (%)', limits = c(0, 60)) +
  # scale_color_viridis_c(name = 'Fire Year', option = 'inferno', limits = c(1910, 2025)) +
  theme_bw() +
  theme(legend.position = "none", legend.direction="horizontal", legend.position.inside = c(0.8, 0.8)) +
  guides(fill = guide_colorbar(title.position = "top"))
p26b

f26 <- ggarrange(p26a, p26b, nrow = 2, ncol = 1, common.legend = FALSE, labels = c('a', 'b'))
f26

#Save the figure
ggsave('Fig26_map_below_poverty_pct.png',
       plot = f21,
       path = 'C://Users//CarlNorlen//mystuff//la-urban-fires//figures',
       scale = 1,
       width = 16,
       height = 18,
       units = c("cm"),
       dpi = 300
)

#2022 Urban Tree Cover
p4a <- ggplot() +
  geom_sf(data = combined.block.sf %>% filter(which.fire == 'Palisades' & !is.na(structure.count) & !is.na(structure_value_median) & UR20 == 'U'), color = 'black', mapping = aes(fill = tree.cover.2022)) +
  # geom_sf() +
  geom_sf(data = rbind(frap.la.intersect |> filter(year >= 1910 & which.fire == 'Palisades') |> st_union() |> st_as_sf() |> mutate(when.fire = '1910-2023'), 
                       wgis.la.intersect |> filter(poly_Incid == 'PALISADES') |> mutate(when.fire = '2025') |> select(when.fire) |> rename(x = geometry)), 
          mapping = aes(color = when.fire), fill = 'gray', linewidth = 1, alpha = 0) +
  # geom_sf(data = wgis.la.intersect |> filter(poly_Incid == 'PALISADES'), color = viridis::viridis_pal(option = "inferno")(12)[12], fill = 'gray', linewidth = 1.5, alpha = 0) +
  scale_color_brewer(name = 'Fire Impact Years', type = 'qual', palette = 6) +
  scale_fill_viridis_c(option = 'viridis', name = 'Tree Cover (%)', limits = c(0, 90)) +
  scale_linetype(name = 'Fire Years') +
  theme_bw() +
  theme(legend.position = "inside", legend.direction="horizontal", legend.position.inside = c(0.35, 0.75), 
        legend.background = element_blank(), legend.title = element_text(size = 10), legend.text = element_text(size = 8)) +
  guides(fill = guide_colorbar(title.position = "top"))
p4a

#Eaton Fire
#Combine this with figure 3
p4b <- ggplot() +
  geom_sf(data = combined.block.sf %>% filter(which.fire == 'Eaton' & !is.na(structure.count) & !is.na(structure_value_median) & UR20 == 'U'), color = 'black', mapping = aes(fill = tree.cover.2022)) +
  geom_sf(data = rbind(frap.la.intersect |> filter(year >= 1910 & which.fire == 'Eaton') |> st_union() |> st_as_sf() |> mutate(when.fire = '1910-2023'), 
                       wgis.la.intersect |> filter(poly_Incid == 'Eaton') |> mutate(when.fire = '2025') |> select(when.fire) |> rename(x = geometry)), 
          mapping = aes(color = when.fire), fill = 'gray', linewidth = 1 , alpha = 0) +
  # geom_sf(data = wgis.la.intersect |> filter(poly_Incid == 'PALISADES'), color = viridis::viridis_pal(option = "inferno")(12)[12], fill = 'gray', linewidth = 1.5, alpha = 0) +
  scale_color_brewer(name = 'Fire Years', type = 'qual', palette = 6) +
  scale_fill_viridis_c(option = 'viridis', name = 'Tree Cover (%)', limits = c(0, 90)) +
  # scale_color_viridis_c(name = 'Fire Year', option = 'inferno', limits = c(1910, 2025)) +
  theme_bw() +
  theme(legend.position = "none", legend.direction="horizontal", legend.position.inside = c(0.8, 0.8)) +
  guides(fill = guide_colorbar(title.position = "top"))
p4b

f4 <- ggarrange(p4a, p4b, nrow = 2, ncol = 1, common.legend = FALSE, labels = c('a', 'b'))
f4

#Save the figure
ggsave('Fig4_urban_tree_cover.png',
       plot = f4,
       path = 'C://Users//CarlNorlen//mystuff//la-urban-fires//figures',
       scale = 1,
       width = 16,
       height = 18,
       units = c("cm"),
       dpi = 300
)

#Median Year Built
p9 <- ggplot(data = combined.block.sf |> as.data.frame() |>  filter(as.numeric(fire.area.2025.pct) > 0 & !is.na(structure.count) & !is.na(structure_value_median) & UR20 == 'U'), mapping = aes(color = which.fire, x = year.built.median, y = destroy_pct)) +
  geom_point() +
  stat_cor(mapping = aes(label = paste(after_stat(rr.label), after_stat(p.label), sep = "~`,`~"), color = which.fire)) +
  geom_smooth(method = 'lm', mapping = aes(linetype = which.fire, color = which.fire)) +
  scale_color_brewer(palette = 'Dark2', type = 'seq', name = 'Fire Name') +
  scale_linetype(name = 'Fire Name') +
  ylab('Structures Destroyed (%)') + xlab('Median Year Structure Built') +
  theme_bw()
p9

#Save the figure
ggsave('Fig9_fire_damage_by_median_year_built.png',
       plot = p9,
       path = 'C://Users//CarlNorlen//mystuff//la-urban-fires//figures',
       scale = 1,
       width = 12,
       height = 10,
       units = c("cm"),
       dpi = 300
)

#Zone 0, 1, and 2 overlap
p10a <- ggplot(data = combined.block.sf |> as.data.frame() |>  filter(as.numeric(fire.area.2025.pct) > 0 & !is.na(structure.count) & !is.na(structure_value_median) & UR20 == 'U'), mapping = aes(color = which.fire, x = zone_zero_overlap_mean, y = destroy_pct)) +
  geom_point() +
  stat_cor(mapping = aes(label = paste(after_stat(rr.label), after_stat(p.label), sep = "~`,`~"), color = which.fire)) +
  geom_smooth(method = 'lm', mapping = aes(linetype = which.fire, color = which.fire)) +
  scale_color_brewer(palette = 'Dark2', type = 'seq', name = 'Fire Name') +
  scale_linetype(name = 'Fire Name') +
  ylab('Structures Destroyed (%)') + xlab('Mean Zone 0 Structures (0-5 ft)') +
  theme_bw()
p10a

p10b <- ggplot(data = combined.block.sf |> as.data.frame() |>  filter(as.numeric(fire.area.2025.pct) > 0 & !is.na(structure.count) & !is.na(structure_value_median) & UR20 == 'U'), mapping = aes(color = which.fire, x = zone_one_overlap_mean, y = destroy_pct)) +
  geom_point() +
  stat_cor(mapping = aes(label = paste(after_stat(rr.label), after_stat(p.label), sep = "~`,`~"), color = which.fire)) +
  geom_smooth(method = 'lm', mapping = aes(linetype = which.fire, color = which.fire)) +
  scale_color_brewer(palette = 'Dark2', type = 'seq', name = 'Fire Name') +
  scale_linetype(name = 'Fire Name') +
  ylim(0, 100) + xlim(0, 5) +
  ylab('Structures Destroyed (%)') + xlab('Number of Structures in Zone 0 & 1 (0-30 ft)') +
  theme_bw()
p10b

p10c <- ggplot(data = combined.block.sf |> as.data.frame() |>  filter(as.numeric(fire.area.2025.pct) > 0 & !is.na(structure.count) & !is.na(structure_value_median) & UR20 == 'U'), mapping = aes(color = which.fire, x = zone_two_overlap_mean, y = destroy_pct)) +
  geom_point() +
  stat_cor(mapping = aes(label = paste(after_stat(rr.label), after_stat(p.label), sep = "~`,`~"), color = which.fire)) +
  geom_smooth(method = 'lm', mapping = aes(linetype = which.fire, color = which.fire)) +
  scale_color_brewer(palette = 'Dark2', type = 'seq', name = 'Fire Name') +
  scale_linetype(name = 'Fire Name') +
  ylab('Structures Destroyed (%)') + xlab('Mean Zone 0, 1 & 2 Structures (0-100 ft)') +
  theme_bw()
p10c

f10 <- ggarrange(p10a, p10b, p10c, nrow = 1, ncol = 3, align = "hv", common.legend = TRUE, labels = c('a', 'b', 'c'), legend = 'right')
f10

#Save the figure
ggsave('Fig10_fire_damage_by_defensible_space_zone_overlap.png',
       plot = f10,
       path = 'C://Users//CarlNorlen//mystuff//la-urban-fires//figures',
       scale = 1,
       width = 30,
       height = 10,
       units = c("cm"),
       dpi = 300
)

# block.summary %>% filter(as.numeric(fire.area.2025.pct) > 0 & UR20 == 'U' & !is.na(structure_value_median) & POP20 != 0 & !is.na(structure.count)) |> summary()
#Add structure value figure
p11 <- ggplot(data = combined.block.sf |> as.data.frame() |>  filter(as.numeric(fire.area.2025.pct) > 0 & !is.na(structure.count) & !is.na(structure_value_median) & UR20 == 'U'), mapping = aes(color = which.fire, x = structure_value_median / 1000, y = destroy_pct)) +
  geom_point() +
  stat_cor(mapping = aes(label = paste(after_stat(rr.label), after_stat(p.label), sep = "~`,`~"), color = which.fire)) +
  geom_smooth(method = 'lm', mapping = aes(linetype = which.fire, color = which.fire)) +
  scale_color_brewer(palette = 'Dark2', type = 'seq', name = 'Fire Name') +
  scale_linetype(name = 'Fire Name') +
  # ylim(0,100) +
  ylab('Proportion of Structures Destroyed (%)') + xlab('Median Structure Replacement Value ($1000)') +
  theme_bw()
p11

#Supplemental Figure Maps
#Structure Basal Area
#Palisades Fires 
p3a <- ggplot() +
  geom_sf(data = combined.block.sf %>% filter(which.fire == 'Palisades' & !is.na(structure.count) & !is.na(structure_value_median) & UR20 == 'U'), color = 'black', mapping = aes(fill = structure.basal.area)) +
  # geom_sf() +
  geom_sf(data = rbind(frap.la.intersect |> filter(year >= 1910 & which.fire == 'Palisades') |> st_union() |> st_as_sf() |> mutate(when.fire = '1910-2023'), 
                       wgis.la.intersect |> filter(poly_Incid == 'PALISADES') |> mutate(when.fire = '2025') |> select(when.fire) |> rename(x = geometry)), 
          mapping = aes(color = when.fire), fill = 'gray', linewidth = 1, alpha = 0) +
  # geom_sf(data = wgis.la.intersect |> filter(poly_Incid == 'PALISADES'), color = viridis::viridis_pal(option = "inferno")(12)[12], fill = 'gray', linewidth = 1.5, alpha = 0) +
  scale_color_brewer(name = 'Fire Impact Years', type = 'qual', palette = 6) +
  scale_fill_viridis_c(option = 'magma', name = expression('Structure Basal Area (m'^2*'ha'^-1*')')) +
  scale_linetype(name = 'Fire Years') +
  theme_bw() +
  theme(legend.position = "inside", legend.direction="horizontal", legend.position.inside = c(0.35, 0.75), 
        legend.background = element_blank(), legend.title = element_text(size = 10), legend.text = element_text(size = 8)) +
  guides(fill = guide_colorbar(title.position = "top"))
p3a

#Eaton Fire
#Combine this with figure 3
p3b <- ggplot() +
  geom_sf(data = combined.block.sf %>% filter(which.fire == 'Eaton' & !is.na(structure.count) & !is.na(structure_value_median) & UR20 == 'U'), color = 'black', mapping = aes(fill = structure.basal.area)) +
  geom_sf(data = rbind(frap.la.intersect |> filter(year >= 1910 & which.fire == 'Eaton') |> st_union() |> st_as_sf() |> mutate(when.fire = '1910-2023'), 
                       wgis.la.intersect |> filter(poly_Incid == 'Eaton') |> mutate(when.fire = '2025') |> select(when.fire) |> rename(x = geometry)), 
          mapping = aes(color = when.fire), fill = 'gray', linewidth = 1 , alpha = 0) +
  # geom_sf(data = wgis.la.intersect |> filter(poly_Incid == 'PALISADES'), color = viridis::viridis_pal(option = "inferno")(12)[12], fill = 'gray', linewidth = 1.5, alpha = 0) +
  scale_color_brewer(name = 'Fire Years', type = 'qual', palette = 6) +
  scale_fill_viridis_c(option = 'magma', name = expression('Structure Basal Area (m'^2*'ha'^-1*')')) +
  # scale_color_viridis_c(name = 'Fire Year', option = 'inferno', limits = c(1910, 2025)) +
  theme_bw() +
  theme(legend.position = "none", legend.direction="horizontal", legend.position.inside = c(0.8, 0.8)) +
  guides(fill = guide_colorbar(title.position = "top"))
p3b

f3 <- ggarrange(p3a, p3b, nrow = 2, ncol = 1, common.legend = FALSE, labels = c('a', 'b'))
f3

#Save the figure
ggsave('Fig3_strucuture_basal_area.png',
       plot = f3,
       path = 'C://Users//CarlNorlen//mystuff//la-urban-fires//figures',
       scale = 1,
       width = 16,
       height = 18,
       units = c("cm"),
       dpi = 300
)



#Percentage of Structures Damaged
p5a <- ggplot(data = combined.block.sf %>% filter(!is.na(structure.count) & which.fire == 'Eaton' & as.numeric(fire.area.2025.pct) > 0 & UR20 == 'U')) + 
  geom_sf(mapping = aes(fill = major_damage_pct)) + 
  geom_sf(data = rbind(frap.la.intersect |> filter(year >= 1910 & which.fire == 'Eaton') |> st_union() |> st_as_sf() |> mutate(when.fire = '1910-2023'), 
                       wgis.la.intersect |> filter(poly_Incid == 'Eaton') |> mutate(when.fire = '2025') |> select(when.fire) |> rename(x = geometry)), 
          mapping = aes(color = when.fire, linetype = when.fire), fill = 'gray', linewidth = 1.5 , alpha = 0) +
  scale_fill_viridis_c(option = 'viridis', name = 'Major Damaged (%)') +
  scale_color_brewer(name = 'Fire Years', type = 'qual', palette = 6) +
  theme_bw() + guides(color = 'none', linetype = 'none') +
  theme(legend.position = "inside", legend.direction="horizontal", legend.position.inside = c(0.8, 0.8), axis.text.y = element_blank(), axis.title.y = element_blank())  +
  guides(fill = guide_colorbar(title.position = "top"))
p5a

p5b <- ggplot(data = combined.block.sf %>% filter(!is.na(structure.count) & which.fire  == 'Palisades' & as.numeric(fire.area.2025.pct) > 0 & UR20 == 'U')) + 
  geom_sf(mapping = aes(fill = major_damage_pct)) + 
  geom_sf(data = rbind(frap.la.intersect |> filter(year >= 1910 & which.fire == 'Palisades') |> st_union() |> st_as_sf() |> mutate(when.fire = '1910-2023'), 
                       wgis.la.intersect |> filter(poly_Incid == 'PALISADES') |> mutate(when.fire = '2025') |> select(when.fire) |> rename(x = geometry)), 
          mapping = aes(color = when.fire, linetype = when.fire), fill = 'gray', linewidth = 1.5 , alpha = 0) +
  scale_fill_viridis_c(option = 'viridis', name = 'Major Damage (%)') +
  scale_color_brewer(name = 'Fire Years', type = 'qual', palette = 6) +
  theme_bw() +
  theme(legend.position = "none", legend.direction="horizontal", legend.position.inside = c(0.2, 0.8), axis.text.y = element_blank(), axis.title.y = element_blank())  +
  guides(fill = guide_colorbar(title.position = "top"))
p5b

f5 <- ggarrange(p5a, p5b, nrow = 2, ncol = 1, common.legend = FALSE, labels = c('a', 'b', 'c', 'd'))
f5

#Save the figure
ggsave('Fig5_fire_damage_comparison.png',
       plot = f5,
       path = 'C://Users//CarlNorlen//mystuff//la-urban-fires//figures',
       scale = 1,
       width = 16,
       height = 18,
       units = c("cm"),
       dpi = 300
)

#Analysis of Pre-2025 Fire Area vs Destroy (%)
p6 <- ggplot(data = combined.block.sf |> as.data.frame() |> filter(as.numeric(fire.area.2025.pct) > 0 & !is.na(structure.count) & !is.na(structure_value_median) & UR20 == 'U'), 
             mapping = aes(color = which.fire, x = fire.area.1910to2023.pct, y = destroy_pct)) +
  geom_point() +
  stat_cor(mapping = aes(label = paste(after_stat(rr.label), after_stat(p.label), sep = "~`,`~"), color = which.fire)) +
  geom_smooth(method = 'lm', mapping = aes(linetype = which.fire, color = which.fire)) +
  scale_color_brewer(palette = 'Dark2', type = 'seq', name = 'Fire Name') +
  scale_linetype(name = 'Fire Name') +
  ylim(0, 100) +
  ylab('Structures Destroyed (%)') + xlab('Pre-2025 Burned Area (%)') +
  theme_bw()
p6

#Save the figure
ggsave('Fig6_fire_damage_by_fire_history.png',
       plot = p6,
       path = 'C://Users//CarlNorlen//mystuff//la-urban-fires//figures',
       scale = 1,
       width = 12,
       height = 10,
       units = c("cm"),
       dpi = 300
)

p7 <- ggplot(data = combined.block.sf |> as.data.frame() |>  filter(as.numeric(fire.area.2025.pct) > 0 & !is.na(structure.count) & !is.na(structure_value_median) & UR20 == 'U'), mapping = aes(color = which.fire, x = structure.basal.area, y = destroy_pct)) +
  geom_point() +
  stat_cor(mapping = aes(label = paste(after_stat(rr.label), after_stat(p.label), sep = "~`,`~"), color = which.fire)) +
  geom_smooth(method = 'lm', mapping = aes(linetype = which.fire, color = which.fire)) +
  scale_color_brewer(palette = 'Dark2', type = 'seq', name = 'Fire Name') +
  scale_linetype(name = 'Fire Name') +
  ylab('Structures Destroyed (%)') + xlab(expression('Structure Basal Area (m'^2*' ha'^-1*')')) +
  theme_bw()
p7

#Save the figure
ggsave('Fig7_fire_damage_by_structure_basal_area.png',
       plot = p7,
       path = 'C://Users//CarlNorlen//mystuff//la-urban-fires//figures',
       scale = 1,
       width = 12,
       height = 10,
       units = c("cm"),
       dpi = 300
)

#Urban Tree Cover 2022 impact
p8 <- ggplot(data = combined.block.sf |> as.data.frame() |>  filter(as.numeric(fire.area.2025.pct) > 0 & !is.na(structure.count) & !is.na(structure_value_median) & UR20 == 'U'), mapping = aes(color = which.fire, x = tree.cover.2022, y = destroy_pct)) +
  geom_point() +
  stat_cor(mapping = aes(label = paste(after_stat(rr.label), after_stat(p.label), sep = "~`,`~"), color = which.fire)) +
  geom_smooth(method = 'lm', mapping = aes(linetype = which.fire, color = which.fire)) +
  scale_color_brewer(palette = 'Dark2', type = 'seq', name = 'Fire Name') +
  scale_linetype(name = 'Fire Name') +
  ylab('Structures Destroyed (%)') + xlab('Urban Tree Cover (%)') +
  theme_bw()
p8

#Save the figure
ggsave('Fig8_fire_damage_by_urban_tree_cover.png',
       plot = p8,
       path = 'C://Users//CarlNorlen//mystuff//la-urban-fires//figures',
       scale = 1,
       width = 12,
       height = 10,
       units = c("cm"),
       dpi = 300
)
# block.summary |> summary()

#Save the figure
ggsave('Fig11_fire_damage_by_median_structure_replacement_value.png',
       plot = p11,
       path = 'C://Users//CarlNorlen//mystuff//la-urban-fires//figures',
       scale = 1,
       width = 12,
       height = 10,
       units = c("cm"),
       dpi = 300
)

#Additional Correlation Plot Figures


fig5 <- ggplot(data = palisades.parcel.melt, aes(x = Var1, y = Var2, fill = value)) +
  geom_tile() +
  scale_fill_gradient2(midpoint = 0.5, mid ="grey70", 
                       limits = c(-1, +1)) +
  labs(title = "Correlation Matrix \n Palisades Parcel-Level Data \n", 
       x = "", y = "", fill = "Correlation") +
  theme(plot.title = element_text(hjust = 0.5, colour = "black"), 
        axis.title.x = element_text(face="bold", colour="darkgreen", size = 12),
        axis.title.y = element_text(face="bold", colour="darkgreen", size = 12),
        axis.text.x = element_text(angle = 90, size = 10),
        legend.title = element_text(face="bold", colour="brown", size = 10)) +
  geom_text(aes(x = Var1, y = Var2, label = round(value, 2)), color = "black", 
            fontface = "bold", size = 5) +
  scale_x_discrete(labels = parcel.labs) + scale_y_discrete(labels = parcel.labs)
fig5

ggsave('Fig30_Palisades_parcel_correlation_plot.png',
       plot = fig5,
       path = 'C://Users//CarlNorlen//mystuff//la-urban-fires//figures',
       scale = 1,
       width = 32,
       height = 30,
       units = c("cm"),
       dpi = 300
)

#Eaton Parcel Scale
fig4 <- ggplot(data = eaton.parcel.melt, aes(x = Var1, y = Var2, fill = value)) +
  geom_tile() +
  scale_fill_gradient2(midpoint = 0.5, mid ="grey70", 
                       limits = c(-1, +1)) +
  labs(title = "Correlation Matrix \n Eaton Parcel-Level Data \n", 
       x = "", y = "", fill = "Correlation") +
  theme(plot.title = element_text(hjust = 0.5, colour = "black"), 
        axis.title.x = element_text(face="bold", colour="darkgreen", size = 12),
        axis.title.y = element_text(face="bold", colour="darkgreen", size = 12),
        axis.text.x = element_text(size = 10, angle = 90),
        legend.title = element_text(face="bold", colour="brown", size = 10)) +
  geom_text(aes(x = Var1, y = Var2, label = round(value, 2)), color = "black", 
            fontface = "bold", size = 5) +
  scale_x_discrete(labels = parcel.labs) + scale_y_discrete(labels = parcel.labs)
fig4

ggsave('Fig29_Eaton_parcel_correlation_plot.png',
       plot = fig4,
       path = 'C://Users//CarlNorlen//mystuff//la-urban-fires//figures',
       scale = 1,
       width = 32,
       height = 30,
       units = c("cm"),
       dpi = 300
)

#Neighborhood Scale
#Figure lables
labs <- c('Pre-fire tree cover (%)', 'Pre-2025 fire impacted (%)', 'Median year home built', 'Homes built after 2008 (%)',  
          'Median home replacement value ($)', 'Structure basal area', 'Number of structures in DSB Zone 0', 'Number of structures in DSB Zone 1',
          'Number of structures in DSB Zone 2', 'Per capita income ($)', 'Below poverty (%)', 'Professional/Graduate degree (%)',
          "Bachelor's degree (%)", "Associated's degree (%)", "High school (%)", "No schooling (%)", "Renter (%)", "Asian (%)",
          "African American (%)", "White (%)", "Hispanic (%)", "65 years and over (%)", "Homes destroyed (%)")

#Create the Neighborhood-Scale palisades figure
fig2 <- ggplot(data = palisades.melt, aes(x = Var1, y = Var2, fill = value)) +
  geom_tile() +
  scale_fill_gradient2(midpoint = 0.5, mid ="grey70", 
                       limits = c(-1, +1)) +
  labs(title = "Correlation Matrix \n Palisades Neighborhood-Level Data \n", 
       x = "", y = "", fill = "Correlation \n Measure") +
  theme(plot.title = element_text(hjust = 0.5, colour = "blue"), 
        axis.title.x = element_text(face="bold", colour="darkgreen", size = 12),
        axis.title.y = element_text(face="bold", colour="darkgreen", size = 12),
        axis.text.x = element_text(angle = 90, size = 10),
        legend.title = element_text(face="bold", colour="brown", size = 10)) +
  geom_text(aes(x = Var1, y = Var2, label = round(value, 2)), color = "black", 
            fontface = "bold", size = 5) +
  scale_x_discrete(labels = rev(labs)) + scale_y_discrete(labels = rev(labs))
fig2

ggsave('Fig28_Palisades_neighborhood_correlation_plot.png',
       plot = fig2,
       path = 'C://Users//CarlNorlen//mystuff//la-urban-fires//figures',
       scale = 1,
       width = 32,
       height = 30,
       units = c("cm"),
       dpi = 300
)

#Create the Neighborhood Scale Eaton correlation figure
fig1 <- ggplot(data = eaton.melt, aes(x = Var1, y = Var2, fill = value)) +
  geom_tile() +
  scale_fill_gradient2(midpoint = 0.5, mid ="grey70", 
                       limits = c(-1, +1)) +
  labs(title = "Correlation Matrix \n Eaton Neighborhood-Level Data \n", 
       x = "", y = "", fill = "Correlation \n Measure") +
  theme(plot.title = element_text(hjust = 0.5, colour = "blue"), 
        axis.title.x = element_text(face="bold", colour="darkgreen", size = 12),
        axis.title.y = element_text(face="bold", colour="darkgreen", size = 12),
        axis.text.x = element_text(angle = 90, size = 10),
        legend.title = element_text(face="bold", colour="brown", size = 10)) +
  geom_text(aes(x = Var1, y = Var2, label = round(value, 2)), color = "black", 
            fontface = "bold", size = 5) +
  scale_x_discrete(labels = rev(labs)) + scale_y_discrete(labels = rev(labs))
fig1

ggsave('Fig27_Eaton_neighborhood_correlation_plot.png',
       plot = fig1,
       path = 'C://Users//CarlNorlen//mystuff//la-urban-fires//figures',
       scale = 1,
       width = 32,
       height = 30,
       units = c("cm"),
       dpi = 300
)