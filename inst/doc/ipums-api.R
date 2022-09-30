## ---- include = FALSE---------------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>",
  eval = FALSE
)

## -----------------------------------------------------------------------------
#  install.packages("ipumsr")

## -----------------------------------------------------------------------------
#  if (!require(remotes)) install.packages("remotes")
#  remotes::install_github("ipums/ipumsr/ipumsexamples")
#  remotes::install_github(
#    "ipums/ipumsr",
#    build_vignettes = TRUE,
#    dependencies = TRUE
#  )

## ----setup, eval=TRUE, message=FALSE------------------------------------------
library(ipumsr)
library(dplyr) # not necessary to use API functions, but used in some examples
library(purrr) # not necessary to use API functions, but used in some examples

## -----------------------------------------------------------------------------
#  set_ipums_api_key("paste-your-key-here")

## -----------------------------------------------------------------------------
#  set_ipums_api_key("paste-your-key-here", save = TRUE)

## ----eval=TRUE----------------------------------------------------------------
usa_extract_definition <- define_extract_usa(
  description = "USA extract for API vignette",
  samples = c("us2018a","us2019a"),
  variables = c("AGE","SEX","RACE","STATEFIP")
)

cps_extract_definition <- define_extract_cps(
  description = "CPS extract for API vignette",
  samples = c("cps1976_01s", "cps1976_02b"),
  variables = c("YEAR", "MISH", "CPSIDP", "AGE", "SEX", "RACE", "UH_SEX_B1")
)

## -----------------------------------------------------------------------------
#  submit_extract(usa_extract_definition)

## -----------------------------------------------------------------------------
#  submitted_usa_extract <- submit_extract(usa_extract_definition)

## -----------------------------------------------------------------------------
#  submitted_usa_extract$number

## -----------------------------------------------------------------------------
#  submitted_usa_extract <- get_extract_info(submitted_usa_extract)

## -----------------------------------------------------------------------------
#  submitted_usa_extract$status

## -----------------------------------------------------------------------------
#  submitted_usa_extract <- get_last_extract_info("usa")

## -----------------------------------------------------------------------------
#  cps_extract_33 <- get_extract_info("cps:33")

## -----------------------------------------------------------------------------
#  cps_extract_33 <- get_extract_info(c("cps", "33"))

## -----------------------------------------------------------------------------
#  downloadable_cps_extract <- wait_for_extract(cps_extract_33)

## -----------------------------------------------------------------------------
#  downloadable_cps_extract <- wait_for_extract("cps:33")

## -----------------------------------------------------------------------------
#  downloadable_cps_extract <- wait_for_extract(c("cps", "33"))

## -----------------------------------------------------------------------------
#  is_extract_ready(cps_extract_33)
#  is_extract_ready("cps:33")
#  is_extract_ready(c("cps", "33"))

## -----------------------------------------------------------------------------
#  ddi_path <- download_extract(submitted_usa_extract)
#  
#  ddi <- read_ipums_ddi(ddi_path)
#  data <- read_ipums_micro(ddi)

## -----------------------------------------------------------------------------
#  ddi_path <- download_extract("cps:33")
#  ddi_path <- download_extract(c("cps", "33"))

## -----------------------------------------------------------------------------
#  cps_extract_33 <- get_extract_info("cps:33")
#  save_extract_as_json(cps_extract_33, file = "cps_extract_33.json")

## -----------------------------------------------------------------------------
#  clone_of_cps_extract_33 <- define_extract_from_json("cps_extract_33.json")
#  submitted_cps_extract <- submit_extract(clone_of_cps_extract_33)

## -----------------------------------------------------------------------------
#  old_extract <- get_extract_info("usa:33")
#  new_extract <- add_to_extract(
#    old_extract,
#    samples = "us2020a",
#    variables = "RELATE"
#  )

## -----------------------------------------------------------------------------
#  newly_submitted_extract <- submit_extract(new_extract)

## -----------------------------------------------------------------------------
#  newer_extract <- remove_from_extract(new_extract, samples = "us2020a")

## -----------------------------------------------------------------------------
#  second_most_recent_extract <- get_recent_extracts_info_list("usa")[[2]]
#  revised_extract <- add_to_extract(
#    second_most_recent_extract,
#    samples = "us2010a"
#  )

## -----------------------------------------------------------------------------
#  ddi_paths <- get_recent_extracts_info_list("usa") %>%
#    keep(is_extract_ready) %>%
#    map_chr(download_extract)

## -----------------------------------------------------------------------------
#  recent_usa_extracts_tbl <- get_recent_extracts_info_tbl("usa")

## -----------------------------------------------------------------------------
#  recent_usa_extracts_tbl %>%
#    filter(grepl("occupation", description))

## -----------------------------------------------------------------------------
#  recent_usa_extracts_tbl %>%
#    filter(map_lgl(variables, ~"AGE" %in% .x))

## -----------------------------------------------------------------------------
#  identical(
#    extract_list_to_tbl(get_recent_extracts_info_list("usa")),
#    get_recent_extracts_info_tbl("usa")
#  )

## -----------------------------------------------------------------------------
#  data <-
#    define_extract_usa(
#      "USA extract for API vignette",
#      c("us2018a","us2019a"),
#      c("AGE","SEX","RACE","STATEFIP")
#    ) %>%
#      submit_extract() %>%
#      wait_for_extract() %>%
#      download_extract() %>%
#      read_ipums_micro()

