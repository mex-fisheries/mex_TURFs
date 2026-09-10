# mex_TURFs

## Overview

This repository contains code and data used to clean, standardize, and merge spatial datasets describing Mexican Territorial Use Rights for Fisheries (TURFs).

The repository combines two primary data sources:

1. A national TURF dataset compiled by Dr. Eréndira Aceves-Bueno (Ere).
2. A Quintana Roo lobster TURF dataset compiled by Stuart.

The final product is a cleaned geospatial dataset containing standardized species information, including Spanish common names, English common names, scientific names, and WoRMS Aphia IDs.

---
The final product is a cleaned geospatial dataset containing standardized species information, including Spanish common names, English common names, scientific names, and WoRMS Aphia IDs.

## TURF Distribution

![](figures/mex_turfs_map.png)

---

## Repository Structure

### Scripts

The `scripts/` folder contains the data-cleaning pipeline:

- `clean_ere.R`  
  Cleans and standardizes Ere's TURF dataset.

- `clean_stuart.R`  
  Cleans and standardizes Stuart's Quintana Roo TURF dataset.

- `merge_ere_stuart.R`  
  Identifies overlapping TURFs, replaces duplicated Ere polygons with Stuart polygons where appropriate, and exports the final merged dataset.

- `build_map.R`
  Creates a map of the cleaned TURF polygons for visualization in the repository README.
### Data

The `data/` folder is organized into three subdirectories:

#### `data/raw/`

Original source datasets used as inputs to the cleaning workflow.

- `TURFcoopsMX.Rda`  
  Original national TURF dataset compiled by Ere.

- `TURFs_QRoo.gpkg`  
  Original Quintana Roo TURF dataset compiled by Stuart.

#### `data/processed/`

Intermediate files generated during the cleaning workflow:

- `unique_species_lookup_edited.xlsx`  
  Manually curated lookup table linking the Spanish common names found in Ere's original TURF database to scientific names, English common names, and WoRMS Aphia IDs. This table serves as the reference used to standardize species information during cleaning.

- `subid_species_joined.csv`  
  Intermediate non-spatial table created by matching species records from Ere's TURF database to `unique_species_lookup_edited.xlsx`. Each row represents a unique `sub_id × species` combination and contains the original species entry together with standardized Spanish common names, scientific names, English common names, and WoRMS Aphia IDs.

- `ere_species_cleaned.gpkg`  
  Cleaned spatial dataset created by joining `subid_species_joined.csv` back to Ere's original TURF polygons using `sub_id`. The resulting dataset contains one row per `sub_id × species` combination, with standardized species information attached to the corresponding TURF geometry.

- `stuart_species_cleaned.gpkg`  
  Cleaned spatial dataset created from the Quintana Roo TURF database. Species information for Caribbean spiny lobster (*Panulirus argus*) was standardized and corresponding Spanish names, English names, scientific names, and WoRMS Aphia IDs were added directly to each TURF polygon.

#### `data/output/`

Final cleaned datasets produced by the pipeline.

- `mex_turfs_combined.gpkg`  
  Final merged TURF dataset combining the cleaned Ere and Stuart datasets after resolving overlapping TURFs.

---

## Workflow

The data-cleaning workflow proceeds in three steps:

### 1. Clean Ere's TURF dataset

`clean_ere.R`

- Loads Ere's raw TURF dataset.
- Converts target species columns from wide to long format.
- Standardizes species information.
- Joins scientific names, English names, and Aphia IDs.
- Exports a cleaned spatial dataset.

Output:

- `data/processed/ere_species_cleaned.gpkg`

### 2. Clean Stuart's TURF dataset

`clean_stuart.R`

- Loads Stuart's Quintana Roo TURF dataset.
- Standardizes attribute names and species information.
- Exports a cleaned spatial dataset.

Output:

- `data/processed/stuart_species_cleaned.gpkg`

### 3. Merge cleaned datasets

`merge_ere_stuart.R`

- Identifies TURFs represented in both datasets.
- Replaces duplicated Ere polygons with Stuart polygons.
- Exports the final merged dataset.

Output:

- `data/output/mex_turfs_combined.gpkg`

---

## Final Output

The primary output of this repository is:

`data/output/mex_turfs_combined.gpkg`

Each row represents a unique TURF polygon × species combination.

### Variables

| Variable | Description |
|-----------|-------------|
| `sub_id` | Unique identifier for a TURF polygon; primary key used throughout the cleaning workflow |
| `turf_id` | Original TURF identifier from the source dataset; may appear more than once when a TURF is associated with multiple species |
| `owner` | Name of the cooperative associated with the TURF |
| `state` | Mexican state abbreviation |
| `source` | Data source (`Ere` or `Stuart`) |
| `species` | Original species field from the source dataset |
| `common_name_spanish` | Spanish common name |
| `common_name_english` | English common name |
| `scientific_name` | Scientific name |
| `aphia_id` | WoRMS Aphia ID |
| `geom` | Polygon geometry |

---

## Data Sources

### Ere TURF Dataset

National dataset of Mexican TURFs compiled by Dr. Eréndira Aceves-Bueno et al.

### Stuart Quintana Roo TURF Dataset

Spatial dataset of lobster TURFs in Quintana Roo compiled by Stuart.

---

## Reproducibility

The workflow is documented in the repository `Makefile`.

Running the scripts in the order described above reproduces the intermediate and final outputs.
