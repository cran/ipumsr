## ----setup, include = FALSE---------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>"
)
library(ipumsr)

## -----------------------------------------------------------------------------
cps_extract_request <- define_extract_cps(
  description = "2018-2019 CPS Data",
  samples = c("cps2018_05s", "cps2019_05s"),
  variables = c("SEX", "AGE", "YEAR")
)

nhgis_extract_request <- define_extract_nhgis(
  description = "NHGIS Data via IPUMS API",
  datasets = ds_spec(
    "1990_STF1",
    data_tables = c("NP1", "NP2", "NP3"),
    geog_levels = "state"
  )
)

## ----eval = FALSE-------------------------------------------------------------
#  submitted_extract <- submit_extract(extract_request)
#  downloadable_extract <- wait_for_extract(submitted_extract)
#  data_files <- download_extract(downloadable_extract)

## ----eval=FALSE---------------------------------------------------------------
#  past_extracts <- get_extract_history("nhgis")

## -----------------------------------------------------------------------------
cps_file <- ipums_example("cps_00157.xml")
cps_data <- read_ipums_micro(cps_file)

head(cps_data)

## -----------------------------------------------------------------------------
nhgis_file <- ipums_example("nhgis0972_csv.zip")
nhgis_data <- read_nhgis(nhgis_file)

head(nhgis_data)

## ----eval = requireNamespace("sf")--------------------------------------------
shp_file <- ipums_example("nhgis0972_shape_small.zip")
nhgis_shp <- read_ipums_sf(shp_file)

head(nhgis_shp)

## -----------------------------------------------------------------------------
cps_meta <- read_ipums_ddi(cps_file)
nhgis_meta <- read_nhgis_codebook(nhgis_file)

## -----------------------------------------------------------------------------
ipums_var_info(cps_meta)

## -----------------------------------------------------------------------------
ipums_var_desc(cps_data$INCTOT)

ipums_val_labels(cps_data$STATEFIP)

## -----------------------------------------------------------------------------
# Remove labels for values that do not appear in the data
cps_data$STATEFIP <- lbl_clean(cps_data$STATEFIP)

ipums_val_labels(cps_data$STATEFIP)

## -----------------------------------------------------------------------------
# Combine North and South Dakota into a single value/label pair
cps_data$STATEFIP <- lbl_relabel(
  cps_data$STATEFIP,
  lbl("38_46", "Dakotas") ~ grepl("Dakota", .lbl)
)

ipums_val_labels(cps_data$STATEFIP)

