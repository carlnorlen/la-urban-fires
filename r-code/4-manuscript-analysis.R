#Purpose: Analysis the parcel and neighborhood scale impacts of the 2025 LA Urban Fres 
#Created by: Carl A. Norlen
#Created date: 02/10/2025
#Updated date: 02/10/2026

#Packages for analysis
my_packages <- c('tidyverse', 'ggpubr', 'sf', 'patchwork', 'tigris', 'tidycensus', 'units', 'osmdata', 'rethnicity', 'viridis', 'terra', 'reshape2', 'tidyterra', 'RStoolbox', 'RColorBrewer')
# library('RColorBrewer')
# install.packages(c('tigris', 'stringr', 'corrplot'))

#Load the packages
lapply(my_packages, require, character.only = TRUE)
options(tigris_use_cache = TRUE)

#Data directory
dir <- 'C://Users//cnorlen//mystuff//data//la-urban-fires//'


#Load the FRAP data
frap <- st_read(paste0(dir, 'fire23-1.shp'))

#Extract CRS values
c <- st_crs(frap)

#Select NIFC perimeters for Palisades and Eaton Fires
wgis <- st_read(paste0(dir, 'WFIGS_Interagency//2025//Perimeters.shp'))

la.fires <- wgis %>% filter(poly_Incid %in% c('Eaton', 'PALISADES'))
la.fires <- st_transform(la.fires, c)

#Add a 100-meter buffer to the fire
la.fires.buffer <- la.fires %>% st_buffer(dist = 100)

#Load the block summary data
block.summary <- read.csv(paste0(dir,'census_blocks_dins_destroyed_burned_area_20250424.csv'))

block.summary |> colnames()

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

#Update the CRS of the census blocks
la.blocks.2020 <- st_transform(la.blocks.2020, c)

# #Filter by the census blocks
la.fire.blocks <- la.blocks.2020 %>% st_filter(la.fires.buffer, .predicates = st_intersects)

#Add the summary values to the tracts for export
#Add selection of columns for block.summary
block.dins.sf <- st_read(paste0(dir, 'la_fires_census_blocks_dins_destroyed_burned_area.gpkg'))

#Update the CRS of the data
block.dins.sf <- st_transform(block.dins.sf, c)

#Combine the census blocks into two polygons
la.fire.blocks.union <- block.dins.sf %>% 
  #Filter for Urban Census Blocks
  filter(!is.na(structure.count) & UR20 == 'U') %>%
  #Group by the 2025 Fire
  group_by(which.fire) %>% 
  #Combine the census blocks
  st_union()

#California State Perimeter
all.states <- states(cb = FALSE, resolution = "500k", year = 2020)

#Filter for the California Perimeter
ca <- all.states |> filter(STUSPS == "CA")

ca <- ca |> st_transform(c)

#California counties
ca.counties <- counties(state = "CA", cb = FALSE, resolution = "500k", year = 2020)

#LA county
la.county <-  ca.counties %>% filter(NAME == "Los Angeles")
la.county <- st_transform(la.county, crs = c)

#LA County FRAP perimeters
frap.la <- frap %>% st_filter(la.fires, .predicates = st_intersects)
frap.la <- frap.la %>% mutate(year = as.numeric(frap.la$YEAR_))

#Adding a label with the fires
frap.la <- frap.la %>% mutate(which.fire = case_when(lengths(st_intersects(frap.la, la.fires %>% filter(poly_Incid == 'Eaton'))) > 0 ~ 'Eaton', 
                                                     lengths(st_intersects(frap.la, la.fires %>% filter(poly_Incid == 'PALISADES'))) > 0 ~ 'Palisades'))

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

#LA Fires difference with census blocks
wgis.la.difference <- la.fires |> st_buffer(0) |> st_difference(la.fire.blocks.union)

#Get the areas of the 2025 fires
wgis.la.intersect <- wgis.la.intersect %>% mutate(area = set_units(st_area(wgis.la.intersect), 'acre'))

#Add a year field
wgis.la.intersect <- wgis.la.intersect %>% mutate(year = format(as.Date(poly_Creat, format="%Y-%m-%d"),"%Y"))

# plot(la.fires)


#Create the census tract burned area
la.fires.clipped <- st_buffer(la.fires,0) %>% st_intersection(la.fire.blocks)

#Get the 2025 acres burned
la.fire.clipped <- la.fires.clipped %>% mutate(fire.area.2025.acre = set_units(st_area(la.fires.clipped), 'acre'))

#Get the 2025 intersections
wgis.la.intersect %>% select(year, poly_Incid, area) %>% mutate(which.fire = case_when(poly_Incid %in% c('Eaton') ~ 'Eaton', poly_Incid %in% c('PALISADES') ~ 'Palisades'),
                                                                block.area = case_when(which.fire %in% c('Eaton') ~ la.fire.blocks %>% filter(which.fire %in% c('Eaton') & UR20 %in% c('U')) %>% st_union() %>% st_area() %>% set_units('acre'),
                                                                which.fire %in% c('Palisades') ~ la.fire.blocks %>% filter(which.fire %in% c('Palisades') & UR20 %in% c('U')) %>% st_union() %>% st_area() %>% set_units('acre')))

#Combine the two fire perimeters
fire.combine.intersect <- rbind(frap.la.intersect.gap.fill |> select(year, which.fire, area, block.area), 
                                wgis.la.intersect |> select(year, poly_Incid, area) |> 
                                mutate(which.fire = case_when(poly_Incid %in% c('Eaton') ~ 'Eaton', 
                                                              poly_Incid %in% c('PALISADES') ~ 'Palisades'),
                                                              block.area = case_when(which.fire %in% c('Eaton') ~ la.fire.blocks |> filter(which.fire %in% c('Eaton') & UR20 %in% c('U')) |> st_union() |> st_area() |> set_units('acre'),
                                                              which.fire %in% c('Palisades') ~ la.fire.blocks |> filter(which.fire %in% c('Palisades') & UR20 %in% c('U')) |> st_union() |> st_area() |> set_units('acre'))) |> select(-c(poly_Incid)))



#Join the Sociodeomgraphic block data
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

#Add a binary damage layer
all.join <- all.join |> mutate(damage.binary = case_when(DAMAGE_1 == 'Destroyed (>50%)' ~ 1, DAMAGE_1 == 'Inaccessible' ~ NA, DAMAGE_1 %in% c('Major (26-50%)', 'Minor (10-25%)', 'Affected (1-9%)', 'No Damage') ~ 0))

# la.fires.ext <- la.fires |> ext() #|> project(from = st_crs(la.fires), to = c)
la.fires.bbox <- la.fires |> st_bbox() |> st_as_sfc() |> st_as_sf(crs = c) #|> plot()

#Get coordinates for the data
la.fires.coords <- la.fires.bbox |> st_transform('EPSG:4326') |> st_bbox()

#LA Urban Census Blocks
la.urban.blocks <- la.blocks.2020 |> filter(UR20 == 'U') |> st_filter(la.fires.bbox, .predicates = st_intersects)

#Landsat background image
landsat.image <- terra::rast(paste0(dir, 'Landsat_Image_20250114_reproject.tif'))

#California Map Inset
inset <- ggplot() + 
       geom_sf(data = ca, fill = NA, color = 'black') + 
       geom_sf(data = la.fires.bbox, color = 'black', fill = 'black', linewidth = 0.05) + 
       theme_bw() +
       theme(axis.text = element_blank(),
             axis.ticks = element_blank())

#Get R Color Brewer Palettes
brewer.pal(4, "Dark2")

#Save the palette in a new order
palette <- c("#1B9E77", "#7570B3", "#D95F02", "#E7298A")

#Create a map of the overall study area
p1a <- ggplot() +
       geom_spatraster_rgb(data = landsat.image, r=3, g=2, b=1, stretch = "lin", maxcell = 1e6) +
       geom_sf(data = la.urban.blocks |> st_crop(la.fires.bbox), color = 'gray80', fill = NA, linewidth = 0.05, alpha = 0.3) +
       geom_sf(data = wgis.la.difference |> mutate(which.fire = case_when(poly_Incid %in% c('Eaton') ~ 'Eaton Non-Urban', poly_Incid %in% c('PALISADES') ~ 'Palisades Non-Urban')),
               mapping = aes(color = which.fire, fill = which.fire), linewidth = 0.5, alpha = 0.5) +
       geom_sf(data = wgis.la.intersect |> mutate(which.fire = case_when(poly_Incid %in% c('Eaton') ~ 'Eaton Urban', poly_Incid %in% c('PALISADES') ~ 'Palisades Urban')),
          mapping = aes(color = which.fire, fill = which.fire), linewidth = 0.5, alpha = 0.5) +
       scale_color_manual(name = 'Fire Name', values = palette, breaks = c('Eaton Urban',  'Eaton Non-Urban', 'Palisades Urban', 'Palisades Non-Urban')) +
       scale_fill_manual(name = 'Fire Name', values = palette, breaks = c('Eaton Urban', 'Eaton Non-Urban', 'Palisades Urban', 'Palisades Non-Urban')) +
       coord_sf(crs = 4326 , xlim = c((la.fires.coords |> st_bbox())$xmin, (la.fires.coords |> st_bbox())$xmax), 
                             ylim = c((la.fires.coords |> st_bbox())$ymin, (la.fires.coords |> st_bbox())$ymax)) +
       theme_bw() +
       theme(axis.title = element_blank(),
             legend.position = "inside", legend.position.inside = c(0.88, 0.26))

#annotate the figure
p1a.annotate <- p1a + annotate(geom = 'segment', x = -118.22, xend = -118.17, y = 34.19, color = 'black', linewidth = 0.8) +
                      annotate("label", x = -118.29 , y = 34.19, label = "Urban Census Blocks", color = 'black', fill = 'white')

#Create a combined plot with the inset
p1a.inset <- p1a.annotate + inset_element(inset, 0, 0.6, 0.15, 0.98)

#Create bar chart of urban area (census blocks) burned over time
p1b <- ggplot() + 
       geom_bar(stat = 'identity', position = 'dodge', width = 0.9, alpha = 0.5, 
                data = fire.combine.intersect  %>% 
                filter(as.numeric(year) >= 1910) %>% group_by(year, which.fire) %>% 
                summarize(area = sum(area), block.area = first(block.area)), 
                mapping = aes(x = as.numeric(year), y = as.numeric(area / block.area) * 100, color = which.fire, fill = which.fire)) + 
      scale_color_brewer(palette = 'Dark2', type = 'seq', name = 'Fire Name', labels = c('Eaton', 'Palisades')) +
      scale_fill_brewer(palette = 'Dark2', type = 'seq', name = 'Fire Name', labels = c('Eaton', 'Palisades')) +
      scale_linetype_manual(name = 'Fire Name', values = c('solid', 'dashed'), labels = c('Eaton', 'Palisades')) +
      theme_bw() + 
      theme(legend.position = "inside", legend.position.inside = c(0.15, 0.85), 
            axis.text.x = element_text(size = 12), axis.title.x = element_text(size = 14),
            axis.text.y = element_text(size = 12), axis.title.y = element_text(size = 14)) +
      xlab('Fire Year') + 
      ylab('Urban Area Burned (%)')
p1b

#Combine the figures
p1 <- ggarrange(p1a.inset, p1b, nrow = 2, ncol = 1, common.legend = FALSE, labels = c('a', 'b')) 

#Save the figure as PNG
ggsave('Fig1_fire_area_by_year_with_landsat.png',
  plot = p1,
  path = 'C://Users//cnorlen//mystuff//la-urban-fires//figures',
  scale = 1,
  width = 24,
  height = 18,
  units = c("cm"),
  dpi = 300
)

#Save the figure as PDF
ggsave('Fig1_fire_area_by_year_with_landsat.pdf',
       plot = p1,
       path = 'C://Users//cnorlen//mystuff//la-urban-fires//figures',
       scale = 1,
       width = 24,
       height = 18,
       units = c("cm"),
       dpi = 300
)

#Calculate the values for fire time series data
fire.ts <- fire.combine.intersect  %>% 
  filter(as.numeric(year) >= 1910) %>% group_by(year, which.fire) %>% 
  summarize(area = sum(area), block.area = first(block.area)) |>
  mutate(pct = (area / block.area) * 100)

#Combine panels for Figure 2
#Palisades Fires 
#Bounding Box of Palisades
palisades.bbox <- combined.block.sf |> filter(which.fire == 'Palisades' & !is.na(structure_value_median) & !is.na(structure.count) & UR20 == 'U') |> st_bbox()

#Palisades Fire Figure
p2a <- ggplot() +
      ggtitle('Palisades') +
      geom_sf(data = combined.block.sf %>% filter(which.fire == 'Palisades' & !is.na(structure_value_median) & !is.na(structure.count) & UR20 == 'U'), color = 'black', mapping = aes(fill = destroy_pct)) +
      geom_sf(data = 
                           frap.la |> filter(year >= 1910 & which.fire == 'Palisades') |> st_union() |> st_as_sf() |> mutate(when.fire = '1910-2024'), 
              mapping = aes(color = when.fire), fill = 'gray60', linewidth = 1, alpha = 0.3) +
      scale_color_manual(name = 'Fire History', values = 'gray60') +
      scale_fill_viridis_c(option = 'magma', name = 'Homes Destroyed \nin 2025 (%)') +
      scale_linetype(name = 'Fire History') +
      coord_sf(xlim = c(palisades.bbox$xmin, palisades.bbox$xmax),
               ylim = c(palisades.bbox$ymin, palisades.bbox$ymax),
               crs = c) +
      theme_bw() +
  theme(legend.position = "right", legend.direction="horizontal",  
        legend.title = element_text(size = 10), legend.text = element_text(size = 8),
        legend.spacing = unit(1, 'mm'),
        axis.text = element_text(size = 10)) +
  guides(fill = guide_colorbar(title.position = "top", order = 2),
         color = guide_legend(order = 1))
p2a

#Bounding Box for Eaton
eaton.bbox <- combined.block.sf |> filter(which.fire == 'Eaton' & !is.na(structure_value_median) & !is.na(structure.count) & UR20 == 'U') |> st_bbox()

#Eaton Fire Figure
p2b <- ggplot() +
    ggtitle('Eaton') +
    geom_sf(data = combined.block.sf %>% filter(which.fire == 'Eaton' & !is.na(structure.count) & !is.na(structure_value_median) & UR20 == 'U'), color = 'black', mapping = aes(fill = destroy_pct)) +
    geom_sf(data = 
                       frap.la |> filter(year >= 1910 & which.fire == 'Eaton') |> st_union() |> st_as_sf() |> mutate(when.fire = '1910-2024'), 
                       mapping = aes(color = when.fire), fill = 'gray60', linewidth = 1 , alpha = 0.3) +
    scale_color_manual(name = 'Fire History', values = 'gray60') +
    scale_fill_viridis_c(option = 'magma', name = 'Homes Destroyed (%)') +
    coord_sf(xlim = c(eaton.bbox$xmin, eaton.bbox$xmax),
           ylim = c(eaton.bbox$ymin, eaton.bbox$ymax),
           crs = c) +
    theme_bw() +
    theme(legend.position = "none", legend.direction="horizontal", legend.position.inside = c(0.8, 0.8),
        axis.text = element_text(size = 10)) +
    guides(fill = guide_colorbar(title.position = "top"))
p2b

#Combine the panels together
f2 <- ggarrange(p2a, p2b, nrow = 2, ncol = 1, common.legend = FALSE, labels = c('a', 'b'))
f2

#Save the figure as PNG
ggsave('Fig2_fire_history.png',
       plot = f2,
       path = 'C://Users//cnorlen//mystuff//la-urban-fires//figures',
       scale = 1,
       width = 17,
       height = 17,
       units = c("cm"),
       dpi = 300
)

#Save the figure as PDF
ggsave('Fig2_fire_history.pdf',
       plot = f2,
       path = 'C://Users//cnorlen//mystuff//la-urban-fires//figures',
       scale = 1,
       width = 17,
       height = 17,
       units = c("cm"),
       dpi = 300
)

#Create Figure 3
#Pre-fire Structure Footprint area
p3a <- ggplot(data = combined.block.sf |> as.data.frame() |>  filter(as.numeric(fire.area.2025.pct) > 0 & !is.na(structure.count) & !is.na(structure_value_median) & UR20 == 'U'), mapping = aes(color = which.fire, x = structure.basal.area, y = destroy_pct)) +
  geom_point(size = 1, alpha = 0.5) +
  stat_cor(mapping = aes(label = paste(after_stat(rr.label), after_stat(p.label), sep = "~`,`~"), 
                         color = which.fire), label.x.npc = 0.05, label.y.npc = 0.99, size = 5) + #, p.accuracy = 0.01) +
  geom_smooth(method = 'lm', mapping = aes(linetype = which.fire, color = which.fire), linewidth = 1.5) +
  scale_color_brewer(palette = 'Dark2', type = 'seq', name = 'Fire Name') +
  scale_linetype(name = 'Fire Name') +
  ylim(0, 119) +
  ylab('Homes Destroyed (%)') + xlab(expression('Structure Footprint Area (m'^2*' ha'^-1*')')) +
  theme_bw() +
  theme(legend.position = 'none', 
        plot.title = element_text(size = 18, face = "bold"),
        legend.title = element_text(size = 14), legend.text = element_text(size = 12),
        axis.text.x = element_text(size = 12), axis.title.x = element_text(size = 14), 
        axis.text.y = element_text(size = 12), axis.title.y = element_text(size = 14))

#Pre-fire urban tree cover
p3b <- ggplot(data = combined.block.sf |> as.data.frame() |>  filter(as.numeric(fire.area.2025.pct) > 0 & !is.na(structure.count) & !is.na(structure_value_median) & UR20 == 'U'), mapping = aes(color = which.fire, x = tree.cover.2022, y = destroy_pct)) +
  geom_point(size = 1, alpha = 0.5) +
  stat_cor(mapping = aes(label = paste(after_stat(rr.label), after_stat(p.label), sep = "~`,`~"), 
                         color = which.fire), label.x.npc = 0.05, label.y.npc = 0.99, size = 5) + #, p.accuracy = 0.01) +
  geom_smooth(method = 'lm', mapping = aes(linetype = which.fire, color = which.fire), linewidth = 1.5) +
  scale_color_brewer(palette = 'Dark2', type = 'seq', name = 'Fire Name') +
  scale_linetype(name = 'Fire Name') +
  ylim(0, 119) +
  ylab('Homes Destroyed (%)') + xlab('Urban Tree Cover (%)') +
  theme_bw() +
  theme(legend.position = 'none', 
        legend.title = element_text(size = 14), legend.text = element_text(size = 12),
        axis.text.x = element_text(size = 12), axis.title.x = element_text(size = 14), 
        axis.text.y = element_text(size = 12), axis.title.y = element_text(size = 14))
p3b

#Mean strucutre overlaps in Zone zero
p3c <- ggplot(data = combined.block.sf |> as.data.frame() |>  filter(as.numeric(fire.area.2025.pct) > 0 & !is.na(structure.count) & !is.na(structure_value_median) & UR20 == 'U'), 
               mapping = aes(color = which.fire, x = zone_zero_overlap_mean, y = destroy_pct)) +
  geom_point(size = 1, alpha = 0.5) +
  stat_cor(mapping = aes(label = paste(after_stat(rr.label), after_stat(p.label), sep = "~`,`~"), 
                         color = which.fire), label.x.npc = 0.05, label.y.npc = 0.99, size = 5) + #, p.accuracy = 0.01) +
  geom_smooth(method = 'lm', mapping = aes(linetype = which.fire, color = which.fire), linewidth = 1.5) +
  scale_color_brewer(palette = 'Dark2', type = 'seq', name = 'Fire Name') +
  scale_linetype(name = 'Fire Name') +
  ylim(0, 119) + 
  ylab('Homes Destroyed (%)') + xlab('Number structures in DSB Zone 0') +
  theme_bw() +
  theme(legend.position = 'none', 
        legend.title = element_text(size = 14), legend.text = element_text(size = 12),
        axis.text.x = element_text(size = 12), axis.title.x = element_text(size = 14), 
        axis.text.y = element_text(size = 12), axis.title.y = element_text(size = 14))
p3c

#Socioeconomic characteristics
p3d <- ggplot(data = combined.block.sf |> as.data.frame() |>  filter(as.numeric(fire.area.2025.pct) > 0 & !is.na(structure.count) & !is.na(structure_value_median) & !is.na(ww_bbg_pct_bachelor_C) & UR20 == 'U'), 
               mapping = aes(color = which.fire, x = ww_bbg_pct_noneng_C * 100, y = destroy_pct)) +
  geom_point(size = 1, alpha = 0.5) +
  stat_cor(mapping = aes(label = paste(after_stat(rr.label), after_stat(p.label), sep = "~`,`~"), 
                         color = which.fire), label.x.npc = 0.05, label.y.npc = 0.99, size = 5) + #, p.accuracy = 0.01) +
  geom_smooth(method = 'lm', mapping = aes(linetype = which.fire, color = which.fire), linewidth = 1.5) +
  scale_color_brewer(palette = 'Dark2', type = 'seq', name = 'Fire Name') +
  scale_linetype(name = 'Fire Name') +
  ylim(0, 119) + 
  ylab('Homes Destroyed (%)') + xlab("Non-English Speaker (%)") +
  theme_bw() +
  theme(legend.position = 'none', 
        legend.title = element_text(size = 14), legend.text = element_text(size = 12),
        axis.text.x = element_text(size = 12), axis.title.x = element_text(size = 14), 
        axis.text.y = element_text(size = 12), axis.title.y = element_text(size = 14))
p3d

p3e <- ggplot(data = combined.block.sf |> as.data.frame() |>  filter(as.numeric(fire.area.2025.pct) > 0 & !is.na(structure.count) & !is.na(structure_value_median) & !is.na(PercapitaInc) & UR20 == 'U'), 
               mapping = aes(color = which.fire, x = ww_bbg_pct_bachelor_C * 100, y = destroy_pct)) +
  geom_point(size = 1, alpha = 0.5) +
  stat_cor(mapping = aes(label = paste(after_stat(rr.label), after_stat(p.label), sep = "~`,`~"), 
                         color = which.fire), label.x.npc = 0.05, label.y.npc = 0.99, size = 5) + #, p.accuracy = 0.01) +
  geom_smooth(method = 'lm', mapping = aes(linetype = which.fire, color = which.fire), linewidth = 1.5) +
  scale_color_brewer(palette = 'Dark2', type = 'seq', name = 'Fire Name') +
  scale_linetype(name = 'Fire Name') +
  ylim(0, 140) + 
  ylab('Homes Destroyed (%)') + xlab("Bachelor's Degree (%)") +
  theme_bw() +
  theme(legend.position = 'right', legend.background = element_blank(), 
        legend.title = element_text(size = 14), legend.text = element_text(size = 12),
        axis.text.x = element_text(size = 12), axis.title.x = element_text(size = 14), 
        axis.text.y = element_text(size = 12), axis.title.y = element_text(size = 14))
p3e

p3f <- ggplot(data = combined.block.sf |> as.data.frame() |>  filter(as.numeric(fire.area.2025.pct) > 0 & !is.na(structure.count) & !is.na(structure_value_median) & !is.na(PercapitaInc) & UR20 == 'U'), 
               mapping = aes(color = which.fire, x = Tpct.FA_AAp_C * 100, y = destroy_pct)) +
  geom_point(size = 1, alpha = 0.5) +
  stat_cor(mapping = aes(label = paste(after_stat(rr.label), after_stat(p.label), sep = "~`,`~"), 
                         color = which.fire), label.x.npc = 0.05, label.y.npc = 0.99, size = 5) + #, p.accuracy = 0.01) +
  geom_smooth(method = 'lm', mapping = aes(linetype = which.fire, color = which.fire), linewidth = 1.5) +
  scale_color_brewer(palette = 'Dark2', type = 'seq', name = 'Fire Name') +
  scale_linetype(name = 'Fire Name') +
  ylim(-40, 125) + 
  ylab('Homes Destroyed (%)') + xlab("African American (%)") +
  theme_bw() +
  theme(legend.position = 'none', 
        legend.title = element_text(size = 14), legend.text = element_text(size = 12),
        axis.text.x = element_text(size = 12), axis.title.x = element_text(size = 14), 
        axis.text.y = element_text(size = 12), axis.title.y = element_text(size = 14))
p3f

f3 <- ggarrange(p3a, p3b, p3c, p3d, p3e, p3f, nrow = 2, ncol = 3, align = "hv", common.legend = TRUE, legend = 'right', labels = c('a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i'))
f3

#Save the figure as PNG
ggsave('Fig3_fire_damage_correlation_grid.png',
       plot = f3,
       path = 'C://Users//cnorlen//mystuff//la-urban-fires//figures',
       scale = 1,
       width = 40,
       height = 24,
       units = c("cm"),
       dpi = 300
)

#Save the figure as PDF
ggsave('Fig3_fire_damage_correlation_grid.pdf',
       plot = f3,
       path = 'C://Users//cnorlen//mystuff//la-urban-fires//figures',
       scale = 1,
       width = 36,
       height = 24,
       units = c("cm"),
       dpi = 300
)

#Figure 4
#Create combined figure for correlations urban morphology with structures destroyed (%)
eaton.cor <- combined.block.sf |> as.data.frame() |>  filter(as.numeric(fire.area.2025.pct) > 0 & !is.na(structure.count) & !is.na(structure_value_median) & UR20 == 'U' & which.fire == 'Eaton' & !is.na(PercapitaInc)) |>
             select(c('destroy_pct', 'Tpct.FA_65.and.over_yrs._C', 'Tpct.FA_Hispanic_C', 'Tpct.FA_whitep_C', 'Tpct.FA_AAp_C', 'Tpct.FA_Ap_C', 'ww_bbg_pct_noneng_C',
                      'Tpct.FA_renter_occ_C', 'ww_pct_bbg_noschooling_C', 'ww_bbg_pct_highsch_C', 'ww_bbg_pct_associate_C', 'ww_bbg_pct_bachelor_C', 'ww_bbg_pct_graduate.Prof_C',
                      'ww_bbg_pct_belowpoverty_C', 'PercapitaInc', 'zone_two_overlap_mean', 'zone_one_overlap_mean', 'zone_zero_overlap_mean', 'structure.basal.area', 'structure_value_median', 
                      'after_2008_pct', 'year.built.median',  'fire.area.1910to2023.pct', 'tree.cover.2022')) |> cor() 

#Melt the Eaton correlation matrix
eaton.melt <- eaton.cor |> melt()



#Do the Neighborhood-Scale Palisades correlation
palisades.cor <- combined.block.sf |> as.data.frame() |>  filter(as.numeric(fire.area.2025.pct) > 0 & !is.na(structure.count) & !is.na(structure_value_median) & UR20 == 'U' & which.fire == 'Palisades' & !is.na(PercapitaInc)) |>
  select(c('destroy_pct', 'Tpct.FA_65.and.over_yrs._C', 'Tpct.FA_Hispanic_C', 'Tpct.FA_whitep_C', 'Tpct.FA_AAp_C', 'Tpct.FA_Ap_C', 'ww_bbg_pct_noneng_C',
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
                 'Number of structures in DSB 1', 'Number of structures in DSB 0', 'Structure footprint area', 'Home replacement value ($)',
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

#Add row names for each community
row.names(combined.cor) <- c('Eaton', 'Palisades')

#Melt combined correlation matrixes
combined.melt <- combined.cor[,-1] |> melt()

#Create the lables for the plots
labs.2 <- c('Pre-fire tree cover (%)', 'Pre-2025 fire impacted (%)', 'Median year home built', 'Homes built after 2008 (%)',  
            'Median home replacement value ($)', 'Structure footprint area',
            'Number of structures in DSB 0', 'Number of structures in DSB 1',  'Number of structures in DSB 2', 
            'Per capita income ($)', 'Below poverty (%)', 'Professional/Graduate degree (%)',
            "Bachelor's degree (%)", "Associated's degree (%)", "High school (%)", "No schooling (%)", "Renter (%)", "Non-English Speaker (%)",
            "Asian (%)", "African American (%)", "White (%)", "Hispanic (%)", "65 years and over (%)")

#Create the labels for the combined plots
combined.labs <- c('65+ years old (%)', 'Number structures in DSB 2',
                 'Number structures in DSB 1', 'Number structures in DSB 0', 'Structure footprint area', 'Home replacement value ($)',
                 'Year home built', 'Fire exposure 1910-2024 (%)', 'Pre-fire tree cover (%)')

#Figure 4 Parcel and Neighborhood Scale Correlation plots
#Panel showing the melted neighborhood level correlations
fig4a <- ggplot(data = combined.melt |> filter(Var2 %in% c('Tpct.FA_65.and.over_yrs._C', 'zone_two_overlap_mean', 
                                                           'zone_one_overlap_mean', 'zone_zero_overlap_mean', 
                                                          'structure.basal.area', 'structure_value_median', 
                                                          'year.built.median',  'fire.area.1910to2023.pct', 
                                                          'tree.cover.2022')), aes(x = Var1, y = Var2, fill = value)) +
  geom_tile() +
  scale_fill_gradient2(midpoint = 0, mid ="grey70", 
                       limits = c(-0.5, +0.5), na.value = NA) +
  labs(title = "Neighborhood", 
       x = "", y = "", fill = "Correlation") +
  theme_bw() +
  theme(plot.title = element_text(hjust = 0.5, colour = "black", face = "bold"), 
        axis.title.x = element_text(face="bold", colour="darkgreen", size = 12),
        axis.title.y = element_text(face="bold", colour="darkgreen", size = 12),
        axis.text.x = element_text(size = 14, face = "bold"),
        axis.text.y = element_text(size = 12, face = "bold"),
        legend.title = element_text(face="bold", colour="black", size = 10)) +
  geom_text(aes(x = Var1, y = Var2, label = signif(value, 2)), color = "black", 
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
                       limits = c(-0.5, +0.5), na.value = NA) +
  labs(title = "Parcel", 
       x = "", y = "", fill = "Correlation") +
  theme_bw() +
  theme(plot.title = element_text(hjust = 0.5, colour = "black", face = "bold"), 
        axis.title.x = element_text(face="bold", colour="darkgreen", size = 12),
        axis.title.y = element_text(face="bold", colour="darkgreen", size = 12),
        axis.text.x = element_text(size = 14, face = "bold"),
        axis.text.y = element_blank(), 
        legend.title = element_text(face="bold", colour="brown", size = 10)) +
  geom_text(aes(x = Var1, y = Var2, label = signif(value, 2)), color = "black", 
            fontface = "bold", size = 5) +
  scale_x_discrete(labels = c('Eaton', 'Palisades')) #+ scale_y_discrete(labels = parcel.labs.2)
fig4b

#combine the plots together
fig4 <- ggarrange(fig4a, fig4b, nrow = 1, ncol = 2, common.legend = TRUE, legend = 'right',  widths = c(1.0, 0.50))
fig4

#Create Figure as PNG
ggsave('Fig4_combined_neighborhood_correlation_plot.png',
       plot = fig4,
       path = 'C://Users//cnorlen//mystuff//la-urban-fires//figures',
       scale = 1,
       width = 20,
       height = 16,
       units = c("cm"),
       dpi = 300
)

#Create Figure as PDF
ggsave('Fig4_combined_neighborhood_correlation_plot.pdf',
       plot = fig4,
       path = 'C://Users//cnorlen//mystuff//la-urban-fires//figures',
       scale = 1,
       width = 20,
       height = 16,
       units = c("cm"),
       dpi = 300
)

#Create a full list of labels
labs.full <- c('Pre-fire tree cover (%)', 'Fire exposure 1910-2024 (%)', 'Median year home built', 'Homes built after 2008 (%)',  
            'Median home replacement value ($)', 'Structure basal area',
            'Number of structures in DSB 0', 'Number of structures in DSB 1',  'Number of structures in DSB 2', 
            'Per capita income ($)', 'Below poverty (%)', 'Professional/Graduate degree (%)',
            "Bachelor's degree (%)", "Associated's degree (%)", "High school (%)", "No schooling (%)", "Renter (%)", "Non-English Speaker (%)",
            "Asian (%)", "African American (%)", "White (%)", "Hispanic (%)", "Population Total", "65 years and over (%)")

#Missing rows dataframe (populaton total)
pop.total.df <- data.frame(Var1 = c('Eaton', 'Palisades'), Var2 = c('pop.total', 'pop.total'), value = c(NA, NA))

#Add the missing row
combined.melt.fill <- combined.melt |> add_row(pop.total.df, .after = 2)

#Supplementary Figures
#Neighborhood Scale
figS4a <- ggplot(data = combined.melt.fill |> mutate(Var2 = as.factor(Var2)), aes(x = Var1, y = Var2 |> fct_inorder(), fill = value)) +
  geom_tile() +
  scale_fill_gradient2(midpoint = 0, mid ="grey70", 
                       limits = c(-0.5, +0.5), na.value = NA) +
  labs(title = "Neighborhood", 
       x = "", y = "", fill = "Correlation") +
  theme_bw() +
  theme(plot.title = element_text(hjust = 0.5, colour = "black", face = "bold"), 
        axis.title.x = element_text(face="bold", colour="darkgreen", size = 12),
        axis.title.y = element_text(face="bold", colour="darkgreen", size = 12),
        axis.text.x = element_text(size = 14, face = "bold"),
        axis.text.y = element_text(size = 12, face = "bold"),
        legend.title = element_text(face="bold", colour="black", size = 10)) +
  geom_text(aes(x = Var1, y = Var2, label = signif(value, 2)), color = "black", 
            fontface = "bold", size = 5) +
  scale_x_discrete(labels = c('Eaton', 'Palisades')) + scale_y_discrete(labels = labs.full |> rev())
figS4a

#Add missing columns to 
new.rows <- data.frame(Var1 = c('Eaton', 'Palisades', 'Eaton', 'Palisades',
                                'Eaton', 'Palisades', 'Eaton', 'Palisades', 'Eaton', 'Palisades',
                                'Eaton', 'Palisades', 'Eaton', 'Palisades',
                                'Eaton', 'Palisades', 'Eaton', 'Palisades',
                                'Eaton', 'Palisades', 'Eaton', 'Palisades',
                                'Eaton', 'Palisades', 'Eaton', 'Palisades'), 
                       Var2 = c('Tpct.FA_Hispanic_C', 'Tpct.FA_Hispanic_C', 'Tpct.FA_whitep_C', 'Tpct.FA_whitep_C',
                                            'Tpct.FA_AAp_C', 'Tpct.FA_AAp_C', 'Tpct.FA_Ap_C', 'Tpct.FA_Ap_C', 'ww_bbg_pct_noneng_C', 'ww_bbg_pct_noneng_C',
                                            'Tpct.FA_renter_occ_C', 'Tpct.FA_renter_occ_C', 'ww_pct_bbg_noschooling_C','ww_pct_bbg_noschooling_C',
                                            'ww_bbg_pct_highsch_C', 'ww_bbg_pct_highsch_C', 'ww_bbg_pct_associate_C', 'ww_bbg_pct_associate_C',
                                            'ww_bbg_pct_bachelor_C', 'ww_bbg_pct_bachelor_C', 'ww_bbg_pct_graduate.Prof_C', 'ww_bbg_pct_graduate.Prof_C',
                                            'ww_bbg_pct_belowpoverty_C', 'ww_bbg_pct_belowpoverty_C', 'PercapitaInc', 'PercapitaInc'),
                       value = c(NA, NA, NA, NA, 
                                 NA, NA, NA, NA, NA, NA,
                                 NA, NA, NA, NA,
                                 NA, NA, NA, NA,
                                 NA, NA, NA, NA,
                                 NA, NA, NA, NA))

#Add a new row for Homes built after 2008 (%)
new.rows.top <- data.frame(Var1 = c('Eaton', 'Palisades'),
                           Var2 = c('after_2008_pct','after_2008_pct'),
                           value = c(NA, NA))

#Add the missing data
combined.parcel.melt.fill <- combined.parcel.melt |> add_row(new.rows, .after = 4) |> add_row(new.rows.top, .after = 40)

#Parcel scale
figS4b <- ggplot(data = combined.parcel.melt.fill |> mutate(Var2 = as.factor(Var2)), 
                 aes(x = Var1, y = Var2 |> fct_inorder(), fill = value)) +
  geom_tile() +
  scale_fill_gradient2(midpoint = 0, mid ="grey70", 
                       limits = c(-0.5, +0.5), na.value = NA) +
  labs(title = "Parcel", 
       x = "", y = "", fill = "Correlation") +
  theme_bw() +
  theme(plot.title = element_text(hjust = 0.5, colour = "black", face = "bold"), 
        axis.title.x = element_text(face="bold", colour="darkgreen", size = 12),
        axis.title.y = element_text(face="bold", colour="darkgreen", size = 12),
        axis.text.x = element_text(size = 14, face = "bold"),
        axis.text.y = element_blank(),
        legend.title = element_text(face="bold", colour="brown", size = 10)) +
  geom_text(aes(x = Var1, y = Var2, label = signif(value, 2)), color = "black", 
            fontface = "bold", size = 5) +
  scale_x_discrete(labels = c('Eaton', 'Palisades')) #+ scale_y_discrete(labels = parcel.labs.2)
figS4b

figS4 <- ggarrange(figS4a, figS4b, nrow = 1, ncol = 2, common.legend = TRUE, legend = 'right',  widths = c(1.05, 0.45))
figS4

#Save the updated figure
ggsave('FigS4_combined_correlation_plot.png',
       plot = figS4,
       path = 'C://Users//cnorlen//mystuff//la-urban-fires//figures',
       scale = 1,
       width = 20,
       height = 24,
       units = c("cm"),
       dpi = 300
)

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
  xlab('Structure Category') + ylab('Number of Structures') 
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
  theme(legend.position = c(0.2, 0.2),
        axis.text.x = element_text(size = 12), axis.title.x = element_text(size = 14), 
        axis.text.y = element_text(size = 12), axis.title.y = element_text(size = 14))
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
  ylab('Probability Structure Destroyed (%)') + xlab('Number of structures in Zone 0') +
  theme_bw() +
  guides(color = "none", linetype = "none") +
        theme(legend.position = 'none',
              axis.text.x = element_text(size = 12), axis.title.x = element_text(size = 14), 
              axis.text.y = element_text(size = 12), axis.title.y = element_text(size = 14))
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
  ylab('Probability Structure Destroyed (%)') + xlab('Number of structures in Zone 1') +
  theme_bw() +
  theme(legend.position = 'none',
        axis.text.x = element_text(size = 12), axis.title.x = element_text(size = 14), 
        axis.text.y = element_text(size = 12), axis.title.y = element_text(size = 14))
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
  ylab('Probability Structure Destroyed (%)') + xlab('Number of structures in DSB Zone 2') +
  theme_bw() +
  theme(legend.position = 'none',
        axis.text.x = element_text(size = 12), axis.title.x = element_text(size = 14), 
        axis.text.y = element_text(size = 12), axis.title.y = element_text(size = 14))
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
  theme(legend.position = 'none',
        axis.text.x = element_text(size = 12), axis.title.x = element_text(size = 14), 
        axis.text.y = element_text(size = 12), axis.title.y = element_text(size = 14))
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
  theme(legend.position = 'none',
        axis.text.x = element_text(size = 12), axis.title.x = element_text(size = 14), 
        axis.text.y = element_text(size = 12), axis.title.y = element_text(size = 14))
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
  ylab('Probability Home Destroyed (%)') + xlab(expression('Structure Footprint Area (m'^2*' ha'^-1*')')) +
  theme_bw() +
  theme(legend.position = 'none',
        plot.title = element_text(size = 18, face = "bold"),
        axis.text.x = element_text(size = 12), axis.title.x = element_text(size = 14), 
        axis.text.y = element_text(size = 12), axis.title.y = element_text(size = 14))
ps3g

#Pre-fire urban tree cover
ps3h <- ggplot(data = all.join |> filter(DAMAGE_1 != 'Inaccessible' & STRUCTURECATEGORY %in% c('Single Residence', 'Multiple Residence' , 'Mixed Commercial/Residential') &
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
  theme(legend.position = 'inside', legend.position.inside = c(0.2, 0.28), legend.direction = 'vertical',
        axis.text.x = element_text(size = 12), axis.title.x = element_text(size = 14), 
        axis.text.y = element_text(size = 12), axis.title.y = element_text(size = 14))
ps3h

#Total occupants
ps3i <- ggplot(data = all.join |> filter(DAMAGE_1 != 'Inaccessible' & STRUCTURECATEGORY %in% c('Single Residence', 'Multiple Residence' , 'Mixed Commercial/Residential') &
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
ps3i

fs3 <- ggarrange(ps3a, ps3b, ps3c, ps3d, ps3e, ps3f, ps3g, ps3h, ps3i, nrow = 3, ncol = 3, align = "hv", common.legend = FALSE, labels = c('a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i'))
fs3

#Save the figure
ggsave('FigS3_fire_damage_logistic_correlation_grid.png',
       plot = fs3,
       path = 'C://Users//cnorlen//mystuff//la-urban-fires//figures',
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
  geom_sf(data = 
            frap.la |> filter(year >= 1910 & which.fire == 'Palisades') |> st_union() |> st_as_sf() |> mutate(when.fire = '1910-2024'), 
          mapping = aes(color = when.fire), fill = 'gray60', linewidth = 1, alpha = 0.3) +
  scale_color_manual(name = 'Fire History', values = 'gray60') +
  scale_fill_viridis_c(option = 'viridis', name = 'Built After 2008 (%)', limits = c(0, 40)) +
  coord_sf(xlim = c(palisades.bbox$xmin, palisades.bbox$xmax),
           ylim = c(palisades.bbox$ymin, palisades.bbox$ymax),
           crs = c) +
  theme_bw() +
  theme(legend.position = "right", legend.direction="horizontal") +
  guides(fill = guide_colorbar(title.position = "top", order = 2), color = guide_legend(order = 1))
fs4a

#Eaton
fs4b <- ggplot() +
  geom_sf(data = combined.block.sf %>% filter(which.fire == 'Eaton' & !is.na(structure_value_median) & !is.na(destroy_pct) & UR20 == 'U'), color = 'black', 
          mapping = aes(fill = after_2008_pct)) +
  geom_sf(data = 
            frap.la |> filter(year >= 1910 & which.fire == 'Eaton') |> st_union() |> st_as_sf() |> mutate(when.fire = '1910-2024'), 
          mapping = aes(color = when.fire), fill = 'gray60', linewidth = 1, alpha = 0.3) +
  scale_color_manual(name = 'Fire History', values = 'gray60') +
  scale_fill_viridis_c(option = 'viridis', name = 'Built After 2008 (%)', limits = c(0, 40)) +
  coord_sf(xlim = c(eaton.bbox$xmin, eaton.bbox$xmax),
           ylim = c(eaton.bbox$ymin, eaton.bbox$ymax),
           crs = c) +
  theme_bw() +
  theme(legend.position = "none", legend.direction="horizontal", legend.position.inside = c(0.8, 0.8)) +
  guides(fill = guide_colorbar(title.position = "top"))
fs4b

fs4 <- ggarrange(fs4a, fs4b, nrow = 2, ncol = 1, common.legend = FALSE, labels = c('a', 'b'))
fs4

#Save the figure
ggsave('FigS4_map_after_2008_pct.png',
       plot = fs4,
       path = 'C://Users//cnorlen//mystuff//la-urban-fires//figures',
       scale = 1,
       width = 17,
       height = 17,
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
  ylab('Homes Destroyed (%)') + xlab('Pre-2025 Burned Area Proportion (%)') +
  theme_bw() +
  theme(legend.position = 'none',
        axis.text.x = element_text(size = 12), axis.title.x = element_text(size = 14), 
        axis.text.y = element_text(size = 12), axis.title.y = element_text(size = 14))
ps5a

ps5b <- ggplot(data = combined.block.sf |> as.data.frame() |>  filter(as.numeric(fire.area.2025.pct) > 0 & !is.na(structure.count) & !is.na(structure_value_median) & UR20 == 'U'), mapping = aes(color = which.fire, x = year.built.median, y = destroy_pct)) +
  geom_point(size = 1, alpha = 0.5) +
  stat_cor(mapping = aes(label = paste(after_stat(rr.label), after_stat(p.label), sep = "~`,`~"), 
                         color = which.fire), label.x.npc = 0.05, label.y.npc = 0.99, p.accuracy = 0.01) +
  geom_smooth(method = 'lm', mapping = aes(linetype = which.fire, color = which.fire)) +
  scale_color_brewer(palette = 'Dark2', type = 'seq', name = 'Fire Name') +
  scale_linetype(name = 'Fire Name') +
  ylim(0, 119) +
  ylab('Homes Destroyed (%)') + xlab('Median Year Structure Built') +
  theme_bw() +
  theme(legend.position = 'none',
        axis.text.x = element_text(size = 12), axis.title.x = element_text(size = 14), 
        axis.text.y = element_text(size = 12), axis.title.y = element_text(size = 14))
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
  ylab('Homes Destroyed (%)') + xlab('Median Structure Replacement Value ($1000)') +
  theme_bw() +
  theme(legend.position = 'inside', legend.position.inside = c(0.85, 0.85), legend.background = element_blank(), 
              axis.text.x = element_text(size = 12), axis.title.x = element_text(size = 14), 
              axis.text.y = element_text(size = 12), axis.title.y = element_text(size = 14))
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
  ylab('Homes Destroyed (%)') + xlab('Homes Built after 2008 (%)') +
  theme_bw() +
  theme(legend.position = 'none',
        axis.text.x = element_text(size = 12), axis.title.x = element_text(size = 14), 
        axis.text.y = element_text(size = 12), axis.title.y = element_text(size = 14))
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
  ylab('Homes Destroyed (%)') + xlab('Mean Structures in DSB Zones 0 & 1 (0-9.1m)') +
  theme_bw() +
  theme(legend.position = 'none',
        axis.text.x = element_text(size = 12), axis.title.x = element_text(size = 14), 
        axis.text.y = element_text(size = 12), axis.title.y = element_text(size = 14))
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
  ylab('Homes Destroyed (%)') + xlab('Mean Structures in DSB Zones 0, 1 & 2 (0-30.5m)') +
  theme_bw() +
  theme(legend.position = 'none',
        axis.text.x = element_text(size = 12), axis.title.x = element_text(size = 14), 
        axis.text.y = element_text(size = 12), axis.title.y = element_text(size = 14))
ps5f

fs5 <- ggarrange(ps5a, ps5b, ps5c, ps5d, ps5e, ps5f, nrow = 2, ncol = 3, align = "hv", common.legend = FALSE, labels = c('a', 'b', 'c', 'd', 'e', 'f'))
fs5

#Save the figure
ggsave('FigS5_fire_damage_urban_morphology_correlation_grid.png',
       plot = fs5,
       path = 'C://Users//cnorlen//mystuff//la-urban-fires//figures',
       scale = 1,
       width = 38,
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
  ylab('Homes Destroyed (%)') + xlab('Below Poverty (%)') +
  theme_bw() +
  theme(legend.position = 'none',
        axis.text.x = element_text(size = 12), axis.title.x = element_text(size = 14), 
        axis.text.y = element_text(size = 12), axis.title.y = element_text(size = 14))
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
  ylab('Homes Destroyed (%)') + xlab('White (%)') +
  theme_bw() +
  theme(legend.position = 'none',
        axis.text.x = element_text(size = 12), axis.title.x = element_text(size = 14), 
        axis.text.y = element_text(size = 12), axis.title.y = element_text(size = 14))
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
  ylab('Homes Destroyed (%)') + xlab('Age 65+ years old (%)') +
  theme_bw() +
  theme(legend.position = 'inside', legend.position.inside = c(0.85, 0.85), legend.background = element_blank(), 
              axis.text.x = element_text(size = 12), axis.title.x = element_text(size = 14), 
              axis.text.y = element_text(size = 12), axis.title.y = element_text(size = 14))
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
  ylab('Homes Destroyed (%)') + xlab('Hispanic (%)') +
  theme_bw() +
  theme(legend.position = 'none',
        axis.text.x = element_text(size = 12), axis.title.x = element_text(size = 14), 
        axis.text.y = element_text(size = 12), axis.title.y = element_text(size = 14))
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
  ylab('Homes Destroyed (%)') + xlab('Asian (%)') +
  theme_bw() +
  theme(legend.position = 'none',
        axis.text.x = element_text(size = 12), axis.title.x = element_text(size = 14), 
        axis.text.y = element_text(size = 12), axis.title.y = element_text(size = 14))
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
  ylab('Homes Destroyed (%)') + xlab("Less than Bachelor's Degree (%)") +
  theme_bw() +
  theme(legend.position = 'none',
        axis.text.x = element_text(size = 12), axis.title.x = element_text(size = 14), 
        axis.text.y = element_text(size = 12), axis.title.y = element_text(size = 14))
ps6f

fs6 <- ggarrange(ps6a, ps6b, ps6c, ps6d, ps6e, ps6f, nrow = 2, ncol = 3, align = "hv", common.legend = FALSE, labels = c('a', 'b', 'c', 'd', 'e', 'f'))0

#Save the figure
ggsave('FigS6_fire_damage_socioeconomic_correlation_grid.png',
       plot = fs6,
       path = 'C://Users//cnorlen//mystuff//la-urban-fires//figures',
       scale = 1,
       width = 38,
       height = 24,
       units = c("cm"),
       dpi = 300
)