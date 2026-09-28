# cleaning Ere data 

# loading packages
library(here)
library(tidyverse)
library(janitor)
library(sf)
library(readxl)

# ------------------------------------------------------------------
# Load and standardize raw Ere data
#
# This loads the original Ere TURF dataset and standardizes column
# names so they are easier to use in R.
# ------------------------------------------------------------------

ere_raw <- read_rds(here("data/raw/TURFcoopsMX.Rda"))

ere_working <- ere_raw %>% 
  clean_names()

# ------------------------------------------------------------------
# Create TURF-species table
#
# The original Ere dataset stores target species across multiple
# columns. Here I reshape columns into a long table with one row per
# sub_id x species combination.
# ------------------------------------------------------------------

subid_species <- ere_working %>%
  st_drop_geometry() %>%
  pivot_longer(
    cols = starts_with("especie_objetivo"),
    names_to = "species_number",
    values_to = "species"
  ) %>%
  drop_na(species, sub_id) %>%
  select(sub_id, turf_id, coop, state, species)

# ------------------------------------------------------------------
# Load manually edited species lookup table
#
# This table links Spanish common names to scientific names, English
# common names, and Aphia IDs.
# ------------------------------------------------------------------

unique_spp_lookup_raw <- read_excel(
  here("data/processed/unique_species_lookup_edited.xlsx")
)

# ------------------------------------------------------------------
# Create species lookup key
#
# Extract the Spanish common name from the original species field.
# This creates the key used to join the lookup table.
# ------------------------------------------------------------------

subid_species <- subid_species %>%
  mutate(
    common_name_spanish = str_trim(str_extract(species, "^[^(]+"))
  )

unique_spp_lookup_clean <- unique_spp_lookup_raw %>%
  select(
    common_name_spanish,
    scientific_name,
    common_name_english,
    aphia_id
  )

# ------------------------------------------------------------------
# Add scientific names and Aphia IDs
#
# Join the lookup table to the TURF-species table using Spanish
# common names.
# ------------------------------------------------------------------

subid_species_joined <- subid_species %>%
  left_join(
    unique_spp_lookup_clean,
    by = "common_name_spanish"
  )

# ------------------------------------------------------------------
# Resolve Callinectes exceptions
#
# PDFs for sub_ids 208_1 and 210_1 identify two Callinectes species.
# Replace the generic JAIBA records with species-specific rows.
# ------------------------------------------------------------------

callinectes_exception <- subid_species_joined %>%
  filter(
    sub_id %in% c("208_1", "210_1"),
    common_name_spanish == "JAIBA"
  ) %>%
  select(sub_id, turf_id, coop, state, species, common_name_spanish) %>%
  tidyr::crossing(
    tibble::tibble(
      scientific_name = c("Callinectes sapidus", "Callinectes rathbunae"),
      common_name_english = c("Blue Crab", "Sharptooth Swimming Crab"),
      aphia_id = c("107379", "422039")
    )
  )

subid_species_joined <- subid_species_joined %>%
  filter(
    !(sub_id %in% c("208_1", "210_1") &
        common_name_spanish == "JAIBA")
  ) %>%
  bind_rows(callinectes_exception)
# ------------------------------------------------------------------
# Resolve Panulirus exceptions
#
# RNPA landings identify red and blue lobster for sub_ids
# 22_1, 25_1, and 29_1. 
# 9_1 targets lobster in northern BC, so assign
# Panulirus interruptus based on CNP. 
# ------------------------------------------------------------------

panulirus_exception <- subid_species_joined %>%
  filter(
    sub_id %in% c("22_1", "25_1", "29_1"),
    scientific_name == "Panulirus spp."
  ) %>%
  select(sub_id, turf_id, coop, state, species, common_name_spanish) %>%
  tidyr::crossing(
    tibble::tibble(
      scientific_name = c(
        "Panulirus interruptus",
        "Panulirus inflatus"
      ),
      common_name_english = c(
        "California Spiny Lobster",
        "Blue Spiny Lobster"
      ),
      aphia_id = c("382898", "382897")
    )
  )

# 9_1 is in northern Baja California, so use red lobster
panulirus_9 <- subid_species_joined %>%
  filter(
    sub_id == "9_1",
    scientific_name == "Panulirus spp."
  ) %>%
  select(sub_id, turf_id, coop, state, species, common_name_spanish) %>%
  mutate(
    scientific_name = "Panulirus interruptus",
    common_name_english = "California Spiny Lobster",
    aphia_id = "382898"
  )

# Remove the generic Panulirus rows and replace them
# with the species assignments above
subid_species_joined <- subid_species_joined %>%
  filter(
    !(sub_id %in% c("9_1", "22_1", "25_1", "29_1") &
        scientific_name == "Panulirus spp.")
  ) %>%
  bind_rows(
    panulirus_exception,
    panulirus_9
  )
# ------------------------------------------------------------------
# Add target species for TURFs previously listed as NODATA
#
# Species were identified using RNPA landings.
# ------------------------------------------------------------------

#get TURF info for the 6 NODATA sub_ids
nodata_turfs <- ere_working %>%
  st_drop_geometry() %>%
  filter(
    sub_id %in% c(
      "11_1", "17_1", "20_1",
      "212_1", "30_1", "6_1"
    )
  ) %>%
  select(sub_id, turf_id, coop, state) %>%
  distinct()

#assign AphiaIDs from RNPA landings for each subid
nodata_species <- tibble(
  sub_id = c(
    "11_1",
    "17_1",
    "20_1",
    "212_1",
    "30_1",
    "6_1"
  ),
  aphia_id = list(
    c("445308", "445325", "528084", "591102", "240747", "382898", "144135", "372718"),
    c("445308", "445325", "528084", "382898", "372718"),
    c("445325", "528084", "382898", "140605", "372718"),
    c("445308", "445325", "528084", "382898", "382897", "140605"),
    c("445325", "528084", "382898", "382897", "140605"),
    c("445308", "445325", "528084", "382898")
  )
)


# Put each AphiaID in its own row and add species info from lookup
nodata_species <- nodata_species %>%
  unnest(aphia_id) %>%
  left_join(
    unique_spp_lookup_clean %>%
      filter(common_name_spanish != "ABULON"), #Remove generic ABULON names so the specie-specific names are used
    by = "aphia_id"
  )

# Add TURF info to the new species records
nodata_species <- nodata_species %>%
  left_join(
    nodata_turfs,
    by = "sub_id"
  )

# Add species column to match the existing data
nodata_species <- nodata_species %>%
  mutate(species = common_name_spanish)

# Replace NODATA rows with the new species records
subid_species_joined <- subid_species_joined %>%
  filter(
    !(sub_id %in% c("11_1", "17_1", "20_1", "212_1", "30_1", "6_1") &
        species == "NODATA")
  ) %>%
  bind_rows(
    nodata_species %>%
      select(all_of(names(subid_species_joined)))
  )
# ------------------------------------------------------------------
# Export cleaned TURF-species table
#
# Save the cleaned sub_id x species table containing Spanish names,
# scientific names, English names, and Aphia IDs. This table does
# not contain polygon geometry.
# ------------------------------------------------------------------

write_csv(
  subid_species_joined,
  "data/processed/subid_species_joined.csv"
)

# ------------------------------------------------------------------
# Create final cleaned Ere spatial dataset
#
# Join cleaned species information back to the TURF polygons and keep
# only the columns needed for the final Ere dataset.
# ------------------------------------------------------------------

ere_species_gpkg <- ere_working %>%
  select(
    sub_id,
    turf_id,
    coop,
    state,
    ano,
    clave_de_la_unidad_economica,
    geometry
  ) %>%
  mutate(source = "Ere") %>%
  left_join(
    subid_species_joined %>%
      select(
        sub_id,
        species,
        common_name_spanish,
        scientific_name,
        common_name_english,
        aphia_id
      ),
    by = "sub_id"
  )

# ------------------------------------------------------------------
# Export cleaned Ere geopackage
# ------------------------------------------------------------------

write_sf(
  ere_species_gpkg,
  "data/processed/ere_species_cleaned.gpkg",
  delete_dsn = TRUE
)
