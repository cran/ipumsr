## ----include = FALSE----------------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>"
)

## ----echo=FALSE, results="hide"-----------------------------------------------
library(vcr)

vcr_dir <- "fixtures"

have_api_access <- TRUE

if (!nzchar(Sys.getenv("IPUMS_API_KEY"))) {
  if (dir.exists(vcr_dir) && length(dir(vcr_dir)) > 0) {
    # Fake API token to fool ipumsr API functions
    Sys.setenv("IPUMS_API_KEY" = "foobar")
  } else {
    # If there are no mock files nor API token, can't run API tests
    have_api_access <- FALSE
  }
}

vcr_configure(
  filter_sensitive_data = list(
    "<<<IPUMS_API_KEY>>>" = Sys.getenv("IPUMS_API_KEY")
  ),
  write_disk_path = vcr_dir,
  dir = vcr_dir
)

check_cassette_names()

## ----message=FALSE------------------------------------------------------------
library(ipumsr)
library(dplyr)

## ----echo=FALSE, results="hide", message=FALSE--------------------------------
insert_cassette("micro-sample-ids")

## -----------------------------------------------------------------------------
cps_samps <- get_sample_info("cps")

head(cps_samps)

## -----------------------------------------------------------------------------
ipumsi_samps <- get_sample_info("ipumsi")

ipumsi_samps %>%
  filter(grepl("Mexico", description))

## ----echo=FALSE, results="hide", message=FALSE--------------------------------
eject_cassette("micro-sample-ids")

## -----------------------------------------------------------------------------
cps_extract <- define_extract_micro(
  collection = "cps",
  description = "Example CPS extract",
  samples = c("cps2018_03s", "cps2019_03s"),
  variables = c("AGE", "SEX", "RACE", "STATEFIP")
)

cps_extract

## -----------------------------------------------------------------------------
var <- var_spec("SEX", case_selections = "2")

str(var)

## -----------------------------------------------------------------------------
define_extract_micro(
  "cps",
  description = "Case selection example",
  samples = c("cps2018_03s", "cps2019_03s"),
  variables = list(
    var_spec("SEX", case_selections = "2"),
    var_spec("AGE", attached_characteristics = "head")
  )
)

## -----------------------------------------------------------------------------
str(cps_extract$variables)

## ----eval=FALSE---------------------------------------------------------------
#  define_extract_micro(
#    "cps",
#    description = "Example CPS extract",
#    samples = "cps2018_03s",
#    variables = "AGE"
#  )
#  
#  define_extract_micro(
#    "cps",
#    description = "Example CPS extract",
#    samples = "cps2018_03s",
#    variables = var_spec("AGE")
#  )

## -----------------------------------------------------------------------------
define_extract_micro(
  "cps",
  description = "Case selection example",
  samples = c("cps2018_03s", "cps2019_03s"),
  variables = list(
    var_spec("SEX", case_selections = "2"),
    "AGE"
  )
)

## -----------------------------------------------------------------------------
var <- var_spec("STATEFIP", case_selections = c("27", "19"))

## -----------------------------------------------------------------------------
var$case_selection_type

## -----------------------------------------------------------------------------
# General case selection is the default
var_spec("RACE", case_selections = "8")

## -----------------------------------------------------------------------------
# For detailed case selection, change the `case_selection_type`
var_spec(
  "RACE",
  case_selections = c("811", "812"),
  case_selection_type = "detailed"
)

## -----------------------------------------------------------------------------
define_extract_micro(
  "usa",
  description = "Household level case selection",
  samples = "us2021a",
  variables = var_spec("RACE", case_selections = "8"),
  case_select_who = "households"
)

## -----------------------------------------------------------------------------
var_spec("SEX", attached_characteristics = "spouse")

## -----------------------------------------------------------------------------
var_spec("AGE", attached_characteristics = c("mother", "father"))

## -----------------------------------------------------------------------------
var_spec("RACE", data_quality_flags = TRUE)

## -----------------------------------------------------------------------------
usa_extract <- define_extract_micro(
  "usa",
  description = "Data quality flags",
  samples = "us2021a",
  variables = list(
    var_spec("RACE", case_selections = "8"),
    var_spec("AGE")
  ),
  data_quality_flags = TRUE
)

## -----------------------------------------------------------------------------
define_extract_micro(
  "atus",
  description = "Time use variable demo",
  samples = "at2017",
  time_use_variables = "ACT_PCARE"
)

## ----eval=FALSE---------------------------------------------------------------
#  define_extract_micro(
#    "atus",
#    description = "Time use variable demo",
#    samples = "at2017",
#    time_use_variables = tu_var_spec("MYTUVAR", owner = "user@example.com")
#  )

## ----eval=FALSE---------------------------------------------------------------
#  define_extract_micro(
#    "atus",
#    description = "Time use variable demo",
#    samples = "at2017",
#    time_use_variables = list(
#      "ACT_PCARE",
#      tu_var_spec("MYTUVAR", owner = "user@example.com")
#    )
#  )

## ----eval=FALSE---------------------------------------------------------------
#  define_extract_micro(
#    "nhis",
#    description = "NHIS hierarchical",
#    samples = "ih2002",
#    variables = c("REGION", "AGE", "SEX", "BMI"),
#    data_structure = "hierarchical"
#  )

## ----eval=FALSE---------------------------------------------------------------
#  define_extract_micro(
#    "meps",
#    description = "MEPS rectangular-on-round",
#    samples = "mp2021",
#    variables = c("INCCHLD", "AGERD", "MARSTATRD"),
#    rectangular_on = "R"
#  )

## ----eval=FALSE---------------------------------------------------------------
#  define_extract_micro(
#    "usa",
#    description = "USA household only",
#    samples = "us2022a",
#    variables = "STATEFIP",
#    data_structure = "household_only"
#  )

## ----eval=FALSE---------------------------------------------------------------
#  usa_extract_submitted <- submit_extract(usa_extract)

