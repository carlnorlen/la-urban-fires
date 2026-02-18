//Created by: Carl A. Norlen
//Created Date: 03/21/2025
//Updated Date: 02/18/2026
//Purpose: Calculate ammount of overlap between building footprint data

//Add the building footprint data
var la_footprints = ee.FeatureCollection('projects/usgs-gee-research/assets/cnorlen/la_fires_building_footprint');

//Create a function to increase the buffer by 5 feet (zone zero distance)
var buffer_5ft = function(f) {
                 return f.buffer({distance: (5 * 0.3048)});
};

var la_footprints_zone_zero = la_footprints.map(buffer_5ft);

var footprints_list = la_footprints.toList({count: la_footprints.size(), offset: 0});

var zone_zero_list = la_footprints_zone_zero.toList({count: la_footprints.size(), offset: 0});

var first_id = ee.Feature(la_footprints.first()).get('system:index');

//Create a function to filter 
var filter = (la_footprints.filter(ee.Filter.neq({name: 'system:index', value: first_id}))).filterBounds(la_footprints_zone_zero.filter(ee.Filter.eq({name: 'system:index', value: first_id})).geometry());


//Create a function the calculate the number of intersections in zone zero (5 ft)
var zone_zero_intersect = function(f) {
                          var index = f.get('system:index');
                          var footprints = la_footprints;
                          var zone_zero = f.buffer({distance: (5 * 0.3048)});
                          var filter = footprints.filter(ee.Filter.neq({name: 'system:index', value: index})).filterBounds(zone_zero.geometry());
                          return f.set({zone_zero_overlap: ee.Number(filter.size())});
};

//Create a function to calculate the number of intersections in zone one (30 ft)
var zone_one_intersect = function(f) {
                          var index = f.get('system:index');
                          var footprints = la_footprints;
                          var zone_zero = f.buffer({distance: (30 * 0.3048)});
                          var filter = footprints.filter(ee.Filter.neq({name: 'system:index', value: index})).filterBounds(zone_zero.geometry());
                          return f.set({zone_one_overlap: ee.Number(filter.size())});
};

//Create a function to calculate the number of intersections in zone two (100 ft)
var zone_two_intersect = function(f) {
                          var index = f.get('system:index');
                          var footprints = la_footprints;
                          var zone_zero = f.buffer({distance: (100 * 0.3048)});
                          var filter = footprints.filter(ee.Filter.neq({name: 'system:index', value: index})).filterBounds(zone_zero.geometry());
                          return f.set({zone_two_overlap: ee.Number(filter.size())});
};

//Add the zone 0, 1, 2 intersections to the la fires footrpints
var la_footprints_overlap = la_footprints.map(zone_zero_intersect);

la_footprints_overlap = la_footprints_overlap.map(zone_one_intersect);

la_footprints_overlap = la_footprints_overlap.map(zone_two_intersect);

  // export
Export.table.toDrive({
  'collection': la_footprints_overlap,
  'description': 'building_footprint_overlaps',
  'folder': 'Urban_Fires', 
  'fileFormat': 'CSV'
});
