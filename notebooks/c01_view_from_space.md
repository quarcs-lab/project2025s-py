---
jupytext:
  formats: ipynb,md:myst
  text_representation:
    extension: .md
    format_name: myst
    format_version: 0.13
    jupytext_version: 1.19.1
kernelspec:
  display_name: Project 2025s (Python 3.10)
  language: python
  name: project2025s
---

<a href="https://code.earthengine.google.com/87ac51fc81a194c7a1dfa299f3251a95"><img src="https://img.shields.io/badge/Open%20in-Google%20Earth%20Engine-4285F4?style=for-the-badge&logo=google-earth&logoColor=white" alt="Open in Google Earth Engine" /></a>

+++

<iframe height="600" width="100%" frameborder="no" src="https://carlos-mendez.projects.earthengine.app/view/rc-dmsp-ntl?height=600">

</iframe>

+++

-   [Open in full view](https://carlos-mendez.projects.earthengine.app/view/rc-dmsp-ntl)

-   [Run source code in Google Earth Engine](https://code.earthengine.google.com/87ac51fc81a194c7a1dfa299f3251a95?hideCode=true)

+++

```javascript
/*******************************************
 * GEE Nighttime Lights Visualization Code
 *******************************************/


/*******************************************
 * Section: Data Loading and Preprocessing
 *******************************************/

// Function to load calibrated nighttime light (NTL) images for a given year
function loadNTL(year) {
  return ee.Image('projects/ee-carlosmendez777/assets/NTL_RC_calibrated/NTL' + year)
    .selfMask(); // Mask out invalid pixels
}

// Load Indian states dataset from geoBoundaries and filter for India
var indianStates = ee.FeatureCollection("projects/earthengine-legacy/assets/projects/sat-io/open-datasets/geoboundaries/CGAZ_ADM1")
  .filter(ee.Filter.eq('shapeGroup', 'IND'));

// Load nighttime lights images for 1996 and 2010
var ntl1996 = loadNTL(1996);
var ntl2010 = loadNTL(2010);

/*******************************************
 * Section: Visualization Parameters
 *******************************************/

// Visualization parameters for nighttime lights
var vis = {
  min: 2.0,
  max: 16.0,
  palette: ['#253494', '#2c7fb8', '#41b6c4', '#a1dab4', '#ffffcc'],
  opacity: 0.75
};

// Dark Basemap style configuration for UI maps
var styledMapType = {
  Dark: [
    { "featureType": "all", "elementType": "labels.text.fill",
      "stylers": [{ "saturation": 36 }, { "color": "#000000" }, { "lightness": 40 }] },
    { "featureType": "all", "elementType": "labels.text.stroke",
      "stylers": [{ "visibility": "on" }, { "color": "#000000" }, { "lightness": 16 }] },
    { "featureType": "all", "elementType": "labels.icon",
      "stylers": [{ "visibility": "off" }] },
    { "featureType": "administrative", "elementType": "geometry.fill",
      "stylers": [{ "color": "#000000" }, { "lightness": 20 }] },
    { "featureType": "administrative", "elementType": "geometry.stroke",
      "stylers": [{ "color": "#000000" }, { "lightness": 17 }, { "weight": 1.2 }] },
    { "featureType": "landscape", "elementType": "geometry",
      "stylers": [{ "color": "#000000" }, { "lightness": 20 }] },
    { "featureType": "poi", "elementType": "geometry",
      "stylers": [{ "color": "#000000" }, { "lightness": 21 }] },
    { "featureType": "road.highway", "elementType": "geometry.fill",
      "stylers": [{ "color": "#000000" }, { "lightness": 17 }] },
    { "featureType": "road.highway", "elementType": "geometry.stroke",
      "stylers": [{ "color": "#000000" }, { "lightness": 29 }, { "weight": 0.2 }] },
    { "featureType": "road.arterial", "elementType": "geometry",
      "stylers": [{ "color": "#000000" }, { "lightness": 18 }] },
    { "featureType": "road.local", "elementType": "geometry",
      "stylers": [{ "color": "#000000" }, { "lightness": 16 }] },
    { "featureType": "transit", "elementType": "geometry",
      "stylers": [{ "color": "#000000" }, { "lightness": 19 }] },
    { "featureType": "water", "elementType": "geometry",
      "stylers": [{ "color": "#000000" }, { "lightness": 17 }] }
  ]
};

/*******************************************
 * Section: Map Initialization and UI Setup
 *******************************************/

var center = { lon: 78.96288, lat: 20.593684, zoom: 6 };
var leftMap = ui.Map(center);
var rightMap = ui.Map(center);

leftMap.setOptions('Dark', {'Dark': styledMapType.Dark});
rightMap.setOptions('Dark', {'Dark': styledMapType.Dark});

var linker = ui.Map.Linker([leftMap, rightMap]);
var splitPanel = ui.SplitPanel({
  firstPanel: leftMap, secondPanel: rightMap,
  orientation: 'horizontal', wipe: true
});

ui.root.clear();
ui.root.add(splitPanel);

/*******************************************
 * Section: Layer Addition
 *******************************************/

leftMap.addLayer(ntl1996.clip(indianStates), vis, 'NTL 1996');
rightMap.addLayer(ntl2010.clip(indianStates), vis, 'NTL 2010');

var stateStyle = { color: 'white', fillColor: '00000000', width: 1 };
leftMap.addLayer(indianStates.style(stateStyle), {}, 'State Boundaries');
rightMap.addLayer(indianStates.style(stateStyle), {}, 'State Boundaries');

leftMap.add(ui.Label({ value: 'Luminosity in 1996',
  style: { fontSize: '25px', backgroundColor: '#f7f7f7', position: 'top-left' } }));
rightMap.add(ui.Label({ value: 'Luminosity in 2010',
  style: { fontSize: '25px', backgroundColor: '#f7f7f7', position: 'top-right' } }));

/*******************************************
 * Section: Legend Creation
 *******************************************/

function createLegendPanel() {
  var legendPanel = ui.Panel({
    style: { position: 'bottom-right', padding: '8px',
             backgroundColor: '#f7f7f7', border: '1px solid #cccccc' }
  });
  legendPanel.add(ui.Label({ value: 'Nighttime Light Intensity',
    style: { fontWeight: 'bold', fontSize: '16px', margin: '0 0 6px 0', padding: '0' } }));
  var colorBar = ui.Thumbnail({
    image: ee.Image.pixelLonLat().select(0),
    params: { bbox: [0, 0, 1, 0.1], dimensions: '200x10', format: 'png',
              min: 0, max: 1, palette: ['#253494', '#2c7fb8', '#41b6c4', '#a1dab4', '#ffffcc'] },
    style: { stretch: 'horizontal', margin: '0 0 6px 0', maxHeight: '24px' }
  });
  legendPanel.add(colorBar);
  var labelPanel = ui.Panel({
    widgets: [
      ui.Label(vis.min.toFixed(1), { margin: '0', fontSize: '12px' }),
      ui.Label(((vis.max - vis.min) / 2 + vis.min).toFixed(1),
        { margin: '0', textAlign: 'center', stretch: 'horizontal', fontSize: '12px' }),
      ui.Label(vis.max.toFixed(1), { margin: '0', fontSize: '12px' })
    ],
    layout: ui.Panel.Layout.flow('horizontal'),
    style: { stretch: 'horizontal' }
  });
  legendPanel.add(labelPanel);
  legendPanel.add(ui.Label('Digital number (DN)',
    { margin: '3px 0 0 0', fontSize: '12px', textAlign: 'center' }));
  return legendPanel;
}

leftMap.add(createLegendPanel());
rightMap.add(createLegendPanel());
```

+++
