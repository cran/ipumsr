## ----setup, include = FALSE---------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>"
)

## ---- eval = FALSE------------------------------------------------------------
#  vignette("value-labels", package = "ipumsr")
#  vignette("ipums-geography", package = "ipumsr")
#  vignette("ipums-cps", package = "ipumsr")
#  vignette("ipums-nhgis", package = "ipumsr")
#  vignette("ipums-terra", package = "ipumsr")

## -----------------------------------------------------------------------------
library(ipumsr)
library(dplyr, warn.conflicts = FALSE)

# Note that you can pass in the loaded DDI into the `read_ipums_micro()`
cps_ddi <- read_ipums_ddi(ipums_example("cps_00006.xml"))
cps_data <- read_ipums_micro(cps_ddi, verbose = FALSE)

# Show which variables have labels
cps_data %>%
  select_if(is.labelled)

# Notice how the tibble print function shows the dbl+lbl class on top

# Investigate labels
ipums_val_labels(cps_data$STATEFIP)

# Convert the labels to factors (and drop the unused levels)
cps_data <- cps_data %>%
  mutate(STATE_factor = as_factor(lbl_clean(STATEFIP)))

table(cps_data$STATE_factor, useNA = "always")

## ---- error = TRUE------------------------------------------------------------
# Manipulating the labelled value before as_factor 
# often leads to losing the information...
# Say we want to set Iowa (STATEFIP == 19) to missing
cps_data <- cps_data %>%
  mutate(STATE_factor2 = as_factor(ifelse(STATEFIP == 19, NA, STATEFIP)))

## -----------------------------------------------------------------------------
# ipumsr provides helpers for these kinds of tasks, like lbl_na_if().
# See the value-labels vignette for more information
cps_data <- cps_data %>%
  mutate(STATE_factor3 = as_factor(lbl_na_if(STATEFIP, ~.val == 19)))

# The as_factor function also has a "levels" argument that can 
# put both the labels and values into the factor
cps_data <- cps_data %>%
  mutate(STATE_factor4 = droplevels(as_factor(STATEFIP, levels = "both")))

table(cps_data$STATE_factor4, useNA = "always")


## -----------------------------------------------------------------------------
library(ipumsr)
library(dplyr, warn.conflicts = FALSE)

# Note that you can pass in the loaded DDI into the `read_ipums_micro()`
cps_ddi <- read_ipums_ddi(ipums_example("cps_00006.xml"))
cps_data <- read_ipums_micro(cps_ddi, verbose = FALSE)

# Currently variable description is available for year
ipums_var_desc(cps_data$YEAR)

# But after using ifelse it is gone
cps_data <- cps_data %>%
  mutate(YEAR = ifelse(YEAR == 1962, 62, NA))
ipums_var_desc(cps_data$YEAR)

# So you can use the DDI
ipums_var_desc(cps_ddi, "YEAR")

# The DDI also has file level information that is not available from just
# the data.
ipums_file_info(cps_ddi, "extract_notes") %>% cat()

## -----------------------------------------------------------------------------
library(ipumsr)
library(dplyr, warn.conflicts = FALSE)

# The vars argument for `read_ipums_micro` uses this syntax
# So these are all equivalent
cf <- ipums_example("cps_00006.xml")
read_ipums_micro(cf, vars = c("YEAR", "INCTOT"), verbose = FALSE) %>%
  names()

read_ipums_micro(cf, vars = c(YEAR, INCTOT), verbose = FALSE) %>%
  names()

read_ipums_micro(cf, vars = c(one_of("YEAR"), starts_with("INC")), verbose = FALSE) %>%
  names()

# `data_layer` and `shape_layer` arguments to `read_nhgis()` and terra functions
# also use it.
# (Sometimes extracts have multiple files, though all examples only have one)
nf <- ipums_example("nhgis0008_csv.zip")
ipums_list_files(nf)

ipums_list_files(nf, data_layer = "nhgis0008_csv/nhgis0008_ds135_1990_pmsa.csv")

ipums_list_files(nf, data_layer = contains("ds135"))

## -----------------------------------------------------------------------------
library(ipumsr)
library(dplyr, warn.conflicts = FALSE)

# List data
cps <- read_ipums_micro_list(
  ipums_example("cps_00010.xml"),
  verbose = FALSE
)

cps$PERSON

cps$HOUSEHOLD

# Long data
cps <- read_ipums_micro(
  ipums_example("cps_00010.xml"),
  verbose = FALSE
)

cps

