//Created by: Carl A. Norlen
//Created Date: 09/08/2025
//Updated Date: 09/08/2025
//Purposed: Download background image for LA Urban Fires publication

//Data Download dates
var startDate = '2025-01-07';
var endDate   = '2025-01-15';

//Map of the region        
var region = ee.Geometry.Rectangle(-118.6865, 34.02217, -118.0118, 34.24633);

var region_buffer = region.buffer(1000);

//Add the region
Map.addLayer(region_buffer, {}, 'Rectangle + 1-km');

//Add functions for calculating veg indices, and merging data L7 and L8
var veg_indices = require('users/cnorlen/subsequent_drought:functions/veg_indices');

//Get Image Collections for Landsat 8 and 9 
var L89 = function(startDate, endDate, region) {

  var dataset_LE08 = ee.ImageCollection('LANDSAT/LC08/C02/T1_L2')
                  .filterDate(startDate, endDate)
                  .filter(ee.Filter.bounds(region))
                  //.map(mask.maskL89sr)
                  //.map(veg_indices.harmonizationRoy)
                  .select('SR_B1', 'SR_B2', 'SR_B3', 'SR_B4', 'SR_B5', 'ST_B6', 'SR_B7');
                  
  var dataset_LE09 = ee.ImageCollection('LANDSAT/LC09/C02/T1_L2')
                  .filterDate(startDate, endDate)
                  .filter(ee.Filter.bounds(region))
                  //.map(mask.maskL89sr)
                  //.map(veg_indices.harmonizationRoy)
                  //Select and rename the bands
                  .select(['SR_B2','SR_B3','SR_B4','SR_B5','SR_B6','ST_B10','SR_B7'],
                  ['SR_B1', 'SR_B2', 'SR_B3', 'SR_B4', 'SR_B5', 'ST_B6', 'SR_B7']);

  var L5789merge = dataset_LE08.merge(dataset_LE09);

  return L5789merge;
};

//var modis = ee.ImageCollection("MODIS/061/MYD09GA").filterDate('2025-01-08', '2025-01-09');

//Map.addLayer(modis, {
//  bands: ['sur_refl_b01', 'sur_refl_b04', 'sur_refl_b03'],
//  min: -100.0,
//  max: 8000.0,
//}, 'MODIS Image (1/8/2025');

// Function to Apply scaling factors to Landsat data
var applyScaleFactors = function applyScaleFactors(image) {
  var opticalBands = image.select('SR_B.').multiply(0.0000275).add(-0.2);
  var thermalBands = image.select('ST_B.*').multiply(0.00341802).add(149.0);
  return image.addBands(opticalBands, null, true)
              .addBands(thermalBands, null, true);
};

//Get the Landsat data and apply scaling factors
var all_landsat = L89(startDate, endDate, region_buffer).map(applyScaleFactors);

//Add teh visualization parameters
var vizParams = {
  bands: ['SR_B3', 'SR_B2', 'SR_B1'],
  min: 0.0,
  max: 0.3,
};

//Clip the image for export
var clipped_image = ee.Image(all_landsat.first()).clip(region_buffer);

//Add the imate to the map
Map.addLayer(clipped_image, vizParams, 'Landsat Images');

//Download the Landsat Image
Export.image.toDrive({image: clipped_image.select(['SR_B1', 'SR_B2', 'SR_B3']), description: "Landsat_Image_20250114_reproject_buffer",
                      fileNamePrefix: "Landsat_Image_20250114_reproject_buffer", folder: 'Urban_Fires', 
                      region: region, scale: 30, maxPixels: 1e9, crs: 'EPSG:4326'});