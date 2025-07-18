//Created by: Carl A. Norlen
//Created date: 04/02/2025
//Updated date: 04/24/2025

//Add NIFC Fire Perimeters for 2025
var fire_perimeter = ee.FeatureCollection("projects/usgs-gee-research/assets/cnorlen/NIFC_Fire_Perimeters")
                       .filter(ee.Filter.or(ee.Filter.eq({name: 'poly_Incid', value: 'Eaton'}),
                                            ee.Filter.eq({name: 'poly_Incid', value: 'PALISADES'}))).map(
                                            function(f) {return f.buffer(100)});

//Converted the two fire perimeters into on geometry to use later                                                                                                                     
var fire_geom = fire_perimeter.geometry();

//Add the polygons for the census blocks
//Filtered for just census blocks intersecting the fire perimeter
var block = ee.FeatureCollection("TIGER/2020/TABBLOCK20").filter(ee.Filter.bounds(fire_perimeter.geometry()))
                                                          //Cut the census blocks to just include the part inside the fire perimeters
                                                         .map(function(f) {return f.intersection(fire_geom)});

//Add the Urban Tree Cover layer
var tree_cover = ee.Image('projects/usgs-gee-research/assets/cnorlen/urban_tree_cover/Los_Angeles_and_Long_Beach_and_Anaheim_canopy2022');

//Add the LA Parcel Data
var la_parcels = ee.FeatureCollection('projects/usgs-gee-research/assets/cnorlen/LACounty_Parcels').filter(ee.Filter.bounds(fire_perimeter.geometry())); 

//Create a reducer to calculate the tree cover by census block
var tree_cover_block_summary = tree_cover.unmask().reduceRegions({collection: block, 
                                                   reducer: ee.Reducer.sum().combine({
                                                   reducer2: ee.Reducer.count(), sharedInputs: true}), 
                                                   scale: 0.6});

var tree_cover_parcel_summary = tree_cover.unmask().reduceRegions({collection: la_parcels, 
                                                   reducer: ee.Reducer.sum().combine({
                                                   reducer2: ee.Reducer.count(), sharedInputs: true}), 
                                                   scale: 0.6});
                                                   
  // export census block data
Export.table.toDrive({
  'collection': tree_cover_block_summary,
  'description': 'tree_cover_block_summary_20250424',//'spatcon_annual_L578_median_500m',
  'folder': 'Urban_Fires', //'earthEngine_outputs',
  //Switch to GEO_JSON
  'fileFormat': 'CSV'
});

  // export Parcel data data
Export.table.toDrive({
  'collection': tree_cover_parcel_summary,
  'description': 'tree_cover_parcel_summary_20250402_v2',//'spatcon_annual_L578_median_500m',
  'folder': 'Urban_Fires', //'earthEngine_outputs',
  //Switch to GEO_JSON
  'fileFormat': 'CSV'
});