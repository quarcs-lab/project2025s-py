---
jupytext:
  formats: ipynb,md:myst
  text_representation:
    extension: .md
    format_name: myst
    format_version: 0.13
    jupytext_version: 1.19.1
kernelspec:
  display_name: Python 3
  language: python
  name: python3
---

# Spatial Analysis of Cultural Participation in India

> **Note:** This exploratory notebook is **not part of the rendered manuscript** (it is not registered in `_quarto.yml`); the manuscript's cultural-participation results are produced by `c06_spatial_culture.ipynb`, which supersedes it. Retained for provenance.

This notebook performs an Exploratory Spatial Data Analysis (ESDA) of cultural participation across Indian states using data from the NSS 47th Round (1991-92).
The first critical step is harmonizing region names between the Stata data file (32 states/UTs) and the GeoJSON map (36 regions), then creating a 32-region map consistent with the data.

+++

## Setup

```{code-cell} ipython3
import numpy as np
import pandas as pd
import geopandas as gpd
import matplotlib.pyplot as plt
```

## 1. Load Data

```{code-cell} ipython3
# Load Stata cultural data (NSS 47th Round, 1991-92)
df_stata = pd.read_stata("../data/Cultural_Data_India/Final_state_LC_CH.dta")
print(f"Stata data: {df_stata.shape[0]} states, {df_stata.shape[1]} columns")
print(f"Columns: {list(df_stata.columns)}")
df_stata.head()
```

```{code-cell} ipython3
# Load GeoJSON map (36 regions, ~2014-2019 administrative divisions)
gdf36 = gpd.read_file("../data/maps/india36.geojson")
print(f"GeoJSON: {gdf36.shape[0]} regions")
print(f"Properties: {list(gdf36.columns)}")
gdf36.head()
```

## 2. Name Harmonization

### 2.1 Side-by-side comparison of region names

```{code-cell} ipython3
stata_names = sorted(df_stata["State_num"].unique())
geojson_names = sorted(gdf36["region"].unique())

print(f"Stata: {len(stata_names)} states")
print(f"GeoJSON: {len(geojson_names)} regions")
print()

# Show exact matches
exact_matches = set(stata_names) & set(geojson_names)
print(f"--- Exact matches ({len(exact_matches)}) ---")
for name in sorted(exact_matches):
    print(f"  {name}")

# Show names only in Stata
stata_only = set(stata_names) - set(geojson_names)
print(f"\n--- In Stata only ({len(stata_only)}) ---")
for name in sorted(stata_only):
    print(f"  {name}")

# Show names only in GeoJSON
geojson_only = set(geojson_names) - set(stata_names)
print(f"\n--- In GeoJSON only ({len(geojson_only)}) ---")
for name in sorted(geojson_only):
    print(f"  {name}")
```

### 2.2 Verified name mapping

Each mapping has been verified via web research. We rename GeoJSON names to match the Stata conventions.

| # | Stata name | GeoJSON name | Reason |
|---|-----------|-------------|--------|
| 1 | A & N Islands | Andaman and Nicobar Islands | Survey abbreviation vs full official name |
| 2 | Chandigarh | Chandigarth | **Typo in GeoJSON** — correct spelling is "Chandigarh" |
| 3 | Dadra & Nagar Haveli | Dadra and Nagar Haveli | `&` vs `and` |
| 4 | Daman & Diu | Daman and Diu | `&` vs `and` |
| 5 | Delhi | NCT of Delhi | Short name vs official name |
| 6 | Jammu & Kashmir | Jammu and Kashmir | `&` vs `and` |
| 7 | Lakshdweep | Lakshadweep | **Typo in Stata** — correct is "Lakshadweep"; we use the Stata spelling for consistency |
| 8 | Orissa | Odisha | Old name (pre-2011 rename) |
| 9 | Pondicherry | Puducherry | Old name (pre-2006 rename) |

```{code-cell} ipython3
# Mapping: GeoJSON name -> Stata name (harmonize to Stata conventions)
geojson_to_stata = {
    "Andaman and Nicobar Islands": "A & N Islands",
    "Chandigarth": "Chandigarh",        # Fix GeoJSON typo
    "Dadra and Nagar Haveli": "Dadra & Nagar Haveli",
    "Daman and Diu": "Daman & Diu",
    "NCT of Delhi": "Delhi",
    "Jammu and Kashmir": "Jammu & Kashmir",
    "Lakshadweep": "Lakshdweep",         # Match Stata typo for merge
    "Odisha": "Orissa",                  # Old name used in Stata
    "Puducherry": "Pondicherry",         # Old name used in Stata
}

# Apply name harmonization to GeoJSON
gdf36["region_harmonized"] = gdf36["region"].replace(geojson_to_stata)

# Verify the mapping worked
print("Name changes applied:")
changed = gdf36[gdf36["region"] != gdf36["region_harmonized"]][["region", "region_harmonized"]]
print(changed.to_string(index=False))
```

### 2.3 Compatibility report after harmonization

```{code-cell} ipython3
harmonized_names = set(gdf36["region_harmonized"].unique())
stata_name_set = set(stata_names)

matched = harmonized_names & stata_name_set
geojson_unmatched = harmonized_names - stata_name_set
stata_unmatched = stata_name_set - harmonized_names

print(f"=== Compatibility Report ===")
print(f"Matched regions: {len(matched)} of {len(stata_name_set)} Stata states")
print(f"GeoJSON regions without Stata data: {len(geojson_unmatched)}")
print(f"Stata states without GeoJSON match: {len(stata_unmatched)}")

if geojson_unmatched:
    print(f"\nGeoJSON-only (newer states, no data):")
    for name in sorted(geojson_unmatched):
        print(f"  {name}")

if stata_unmatched:
    print(f"\n*** WARNING: Stata states with no GeoJSON match ***")
    for name in sorted(stata_unmatched):
        print(f"  {name}")
else:
    print("\nAll Stata states have a GeoJSON match.")
```

## 3. Create 32-Region Map (Dissolve Newer States)

The 4 newer states that don't exist in the Stata data were carved from parent states after 1991-92:

| Newer state | Carved from | Year |
|------------|-------------|------|
| Chhattisgarh | Madhya Pradesh | 2000 |
| Jharkhand | Bihar | 2000 |
| Uttarakhand | Uttar Pradesh | 2000 |
| Telangana | Andhra Pradesh | 2014 |

We dissolve these back into their parent states to create a 32-region map matching the Stata data.

```{code-cell} ipython3
# Map newer states to their parent states
dissolve_map = {
    "Chhattisgarh": "Madhya Pradesh",
    "Jharkhand": "Bihar",
    "Uttarakhand": "Uttar Pradesh",
    "Telangana": "Andhra Pradesh",
}

# Create dissolve column: use harmonized name, but remap newer states to parents
gdf36["region_dissolve"] = gdf36["region_harmonized"].replace(dissolve_map)

print("Regions to be dissolved:")
dissolved = gdf36[gdf36["region_harmonized"] != gdf36["region_dissolve"]][
    ["region_harmonized", "region_dissolve"]
]
print(dissolved.to_string(index=False))
```

```{code-cell} ipython3
# Dissolve geometries by the dissolve column
# Select only the dissolve key + geometry to avoid duplicate column issues
gdf_prep = gdf36[["region_dissolve", "geometry"]].copy()
gdf32 = gdf_prep.dissolve(by="region_dissolve").reset_index()
gdf32 = gdf32.rename(columns={"region_dissolve": "region"})

print(f"New map: {len(gdf32)} regions")
assert len(gdf32) == 32, f"Expected 32 regions, got {len(gdf32)}"
print("32-region map created successfully.")
```

```{code-cell} ipython3
# Save the 32-region GeoJSON
gdf32.to_file("../data/maps/india32.geojson", driver="GeoJSON")
print("Saved: data/maps/india32.geojson")
```

### 3.1 Verification: boundary plot

```{code-cell} ipython3
fig, axes = plt.subplots(1, 2, figsize=(16, 8))

gdf36.plot(ax=axes[0], edgecolor="black", facecolor="lightblue", linewidth=0.5)
axes[0].set_title(f"Original: {len(gdf36)} regions (india36.geojson)")
axes[0].set_axis_off()

gdf32.plot(ax=axes[1], edgecolor="black", facecolor="lightyellow", linewidth=0.5)
axes[1].set_title(f"Dissolved: {len(gdf32)} regions (india32.geojson)")
axes[1].set_axis_off()

plt.suptitle("Comparison: 36-region vs 32-region maps", fontsize=14, fontweight="bold")
plt.tight_layout()
plt.show()
```

## 4. Merge Cultural Data with Map

```{code-cell} ipython3
# Merge: 32-region GeoJSON + Stata cultural data
gdf_merged = gdf32.merge(df_stata, left_on="region", right_on="State_num", how="left")

# Check for any unmatched regions
n_matched = gdf_merged["State_num"].notna().sum()
n_missing = gdf_merged["State_num"].isna().sum()
print(f"Matched: {n_matched} / {len(gdf32)} regions")
print(f"Missing data: {n_missing}")

if n_missing > 0:
    print("\n*** WARNING: Unmatched regions ***")
    print(gdf_merged[gdf_merged["State_num"].isna()]["region"].tolist())
else:
    print("\nPerfect merge: all 32 regions have cultural data.")

gdf_merged.head()
```

## 5. Choropleth Maps

```{code-cell} ipython3
variables = ["LC_Performance", "LC_Telecast", "SC", "CH_relig", "LC_shows", "Sports"]
var_labels = {
    "LC_Performance": "Live Cultural\nPerformance",
    "LC_Telecast": "Cultural\nTelecast",
    "SC": "Socio-Cultural\nParticipation",
    "CH_relig": "Cultural Heritage\n& Religion",
    "LC_shows": "Live Cultural\nShows",
    "Sports": "Sports\nParticipation",
}

fig, axes = plt.subplots(2, 3, figsize=(18, 14))
axes = axes.flatten()

for i, var in enumerate(variables):
    gdf_merged.plot(
        column=var,
        ax=axes[i],
        legend=True,
        legend_kwds={"shrink": 0.6, "label": var},
        cmap="RdYlGn",
        edgecolor="black",
        linewidth=0.3,
        missing_kwds={"color": "lightgray", "label": "No data"},
    )
    axes[i].set_title(var_labels.get(var, var), fontsize=11, fontweight="bold")
    axes[i].set_axis_off()

plt.suptitle(
    "Cultural Participation Across Indian States (NSS 47th Round, 1991-92)",
    fontsize=14,
    fontweight="bold",
)
plt.tight_layout()
plt.show()
```

```{code-cell} ipython3
# Summary statistics
print("Summary Statistics of Cultural Variables")
print("=" * 60)
print(gdf_merged[variables].describe().round(3))
```
