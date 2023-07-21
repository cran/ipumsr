## ---- include = FALSE---------------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>"
)

## ---- message=FALSE-----------------------------------------------------------
library(ipumsr)
library(dplyr)

# Example data
cps_ddi_file <- ipums_example("cps_00157.xml")

cps_data <- read_ipums_micro(cps_ddi_file)

head(cps_data)

## -----------------------------------------------------------------------------
ipums_var_info(cps_data)

## -----------------------------------------------------------------------------
attributes(cps_data$MONTH)

ipums_val_labels(cps_data$MONTH)

## -----------------------------------------------------------------------------
cps_ddi <- read_ipums_ddi(cps_ddi_file)

cps_ddi

## -----------------------------------------------------------------------------
# This doesn't actually change the data...
cps_data2 <- cps_data %>%
  mutate(MONTH = ifelse(TRUE, MONTH, MONTH))

# but removes attributes!
ipums_val_labels(cps_data2$MONTH)

## -----------------------------------------------------------------------------
ipums_val_labels(cps_ddi, var = MONTH)

## -----------------------------------------------------------------------------
cps_data2 <- set_ipums_var_attributes(cps_data2, cps_ddi)

ipums_val_labels(cps_data2$MONTH)

## -----------------------------------------------------------------------------
cps_hier_ddi <- read_ipums_ddi(ipums_example("cps_00159.xml"))

read_ipums_micro(cps_hier_ddi)

## -----------------------------------------------------------------------------
read_ipums_micro_list(cps_hier_ddi)

## -----------------------------------------------------------------------------
nhgis_ex1 <- ipums_example("nhgis0972_csv.zip")

nhgis_data <- read_nhgis(nhgis_ex1)

nhgis_data

## -----------------------------------------------------------------------------
attributes(nhgis_data$D6Z001)

## -----------------------------------------------------------------------------
nhgis_cb <- read_nhgis_codebook(nhgis_ex1)

# Most useful metadata for NHGIS is for variable labels:
ipums_var_info(nhgis_cb) %>%
  select(var_name, var_label, var_desc)

## -----------------------------------------------------------------------------
nhgis_cb <- read_nhgis_codebook(nhgis_ex1, raw = TRUE)

cat(nhgis_cb[1:20], sep = "\n")

## -----------------------------------------------------------------------------
nhgis_ex2 <- ipums_example("nhgis0731_csv.zip")

ipums_list_files(nhgis_ex2)

## ---- error=TRUE, message=FALSE-----------------------------------------------
nhgis_data2 <- read_nhgis(nhgis_ex2, file_select = contains("nation"))

nhgis_data3 <- read_nhgis(nhgis_ex2, file_select = contains("ts_nominal_state"))

## -----------------------------------------------------------------------------
attributes(nhgis_data2$AJWBE001)

attributes(nhgis_data3$A00AA1790)

## ---- eval=FALSE--------------------------------------------------------------
#  # Match by file name
#  read_nhgis(nhgis_ex2, file_select = "nhgis0731_csv/nhgis0731_ds239_20185_nation.csv")
#  
#  # Match first file in extract
#  read_nhgis(nhgis_ex2, file_select = 1)

## -----------------------------------------------------------------------------
# Convert MSA codes to character format
read_nhgis(
  nhgis_ex1,
  col_types = c(MSA_CMSAA = "c"),
  verbose = FALSE
)

## -----------------------------------------------------------------------------
nhgis_fwf <- ipums_example("nhgis0730_fixed.zip")

nhgis_fwf_data <- read_nhgis(nhgis_fwf, file_select = matches("ts_nominal"))

nhgis_fwf_data

## ---- eval = requireNamespace("sf")-------------------------------------------
nhgis_shp_file <- ipums_example("nhgis0972_shape_small.zip")

shp_data <- read_ipums_sf(nhgis_shp_file)

head(shp_data)

## ---- eval = requireNamespace("sf")-------------------------------------------
joined_data <- ipums_shape_left_join(
  nhgis_data,
  shp_data,
  by = "GISJOIN"
)

attributes(joined_data$MSA_CMSAA)

