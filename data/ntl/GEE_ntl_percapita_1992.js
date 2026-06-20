/*******************************************************************
 * GEE Zonal Statistics: NTL Per Capita by Region (1992)
 *
 * Computes nighttime lights per capita for India's 32 regions
 * using corrected DMSP-OLS data and GlobPOP gridded population.
 *
 * Each dataset is reduced at its own native spatial scale to
 * avoid resampling artifacts from mismatched resolutions.
 *
 * Exports: GeoJSON and CSV to Google Drive
 * Columns: region, sum_ntl, sum_pop, pop_mil, ntl_pc, ln_ntl_pc
 *******************************************************************/

// ---- 1. Load boundaries ----
var india32 = ee.FeatureCollection(
  'projects/ee-carlosmendez777/assets/india/india32'
);

// ---- 2. Load NTL for 1992 ----
// Corrected DMSP Nighttime Lights (Zhao et al., 2020)
var ntl1992 = ee.ImageCollection('BNU/FGS/CCNL/v1')
  .filter(ee.Filter.calendarRange(1992, 1992, 'year'))
  .first()
  .rename('sum_ntl');

// ---- 3. Load Population for 1992 ----
// GlobPOP Global Gridded Population Dataset
var pop1992 = ee.ImageCollection('projects/sat-io/open-datasets/GLOBPOP_COUNT')
  .filter(ee.Filter.calendarRange(1992, 1992, 'year'))
  .first()
  .rename('sum_pop');

// ---- 4. Detect native spatial scales ----
var ntlScale = ntl1992.projection().nominalScale();
var popScale = pop1992.projection().nominalScale();

print('NTL native scale (m):', ntlScale);
print('Population native scale (m):', popScale);

// ---- 5. Zonal statistics — NTL at its native scale ----
var ntlResults = ntl1992.reduceRegions({
  collection: india32,
  reducer: ee.Reducer.sum(),
  scale: ntlScale
});

// ---- 6. Zonal statistics — Population at its native scale ----
var popResults = pop1992.reduceRegions({
  collection: india32,
  reducer: ee.Reducer.sum(),
  scale: popScale
});

// ---- 7. Join NTL and Population results by region ----
var joinFilter = ee.Filter.equals({
  leftField: 'region',
  rightField: 'region'
});

var joined = ee.Join.saveFirst('_pop_match')
  .apply(ntlResults, popResults, joinFilter);

// ---- 8. Merge population into NTL results and compute derived columns ----
// Note: reduceRegions names the output property 'sum' (after the reducer),
// not after the band name, so both results have a 'sum' property.
var results = joined.map(function(f) {
  var popFeature = ee.Feature(f.get('_pop_match'));
  var ntl = ee.Number(f.get('sum'));           // NTL sum from ntlResults
  var pop = ee.Number(popFeature.get('sum'));   // Population sum from popResults
  var popMil = pop.divide(1e6);                // Population in millions
  var ntlpc = ntl.divide(popMil);              // NTL per million people
  return f.set({
    'sum_ntl': ntl,
    'sum_pop': pop,
    'pop_mil': popMil,
    'ntl_pc': ntlpc,
    'ln_ntl_pc': ntlpc.log()
  });
});

// ---- 9. Select columns for export ----
var exportColumns = ['region', 'sum_ntl', 'sum_pop', 'pop_mil', 'ntl_pc', 'ln_ntl_pc'];

// ---- 10. Export as GeoJSON ----
Export.table.toDrive({
  collection: results,
  description: 'india32_ntl_percapita_1992_geojson',
  folder: 'gee',
  fileNamePrefix: 'india32_ntl_percapita_1992',
  fileFormat: 'GeoJSON',
  selectors: exportColumns
});

// ---- 11. Export as CSV ----
Export.table.toDrive({
  collection: results,
  description: 'india32_ntl_percapita_1992_csv',
  folder: 'gee',
  fileNamePrefix: 'india32_ntl_percapita_1992',
  fileFormat: 'CSV',
  selectors: exportColumns
});

// ---- 12. Print preview to console ----
print('NTL Per Capita Results (1992)', results.limit(5));
print('Total features:', results.size());
