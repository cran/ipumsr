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

modify_ready_extract_cassette_file <- function(cassette_file_name,
                                               fixture_path = NULL,
                                               n_requests = 1) {
  fixture_path <- fixture_path %||% vcr::vcr_test_path("fixtures")

  ready_extract_cassette_file <- file.path(
    fixture_path, cassette_file_name
  )

  ready_lines <- readLines(ready_extract_cassette_file)
  request_lines <- which(grepl("^- request:", ready_lines))

  start_line <- request_lines[length(request_lines) - n_requests + 1]

  writeLines(
    c(
      ready_lines[[1]],
      ready_lines[start_line:length(ready_lines)]
    ),
    con = ready_extract_cassette_file
  )
}

## ----message=FALSE------------------------------------------------------------
library(ipumsr)
library(dplyr)
library(purrr)

## -----------------------------------------------------------------------------
ipums_data_collections()

## ----eval=FALSE---------------------------------------------------------------
#  # Save key in .Renviron for use across sessions
#  set_ipums_api_key("paste-your-key-here", save = TRUE)

## -----------------------------------------------------------------------------
usa_extract_definition <- define_extract_micro(
  collection = "usa",
  description = "USA extract for API vignette",
  samples = c("us2018a", "us2019a"),
  variables = c("AGE", "SEX", "RACE", "STATEFIP", "MARST")
)

usa_extract_definition

## -----------------------------------------------------------------------------
class(usa_extract_definition)

## -----------------------------------------------------------------------------
names(usa_extract_definition$samples)
names(usa_extract_definition$variables)
usa_extract_definition$data_format

## -----------------------------------------------------------------------------
usa_extract_definition$status
usa_extract_definition$number

## ----include=FALSE------------------------------------------------------------
insert_cassette("submit-placeholder-extract-usa")

# We submit these extracts so that the output of requests for things like
# `get_extract_history` below is more "natural".
# Otherwise the output is a bunch of duplicate extract requests for the
# primary extract in this vignette, as this vignette usually gets rebuilt
# several times during editing before it is complete.
submit_extract(
  define_extract_micro(
    "usa",
    description = "Data from 2017 PRCS",
    samples = "us2017b",
    variables = c("RACE", "YEAR")
  )
)

submit_extract(
  define_extract_micro(
    "usa",
    description = "Data from long ago",
    samples = "us1880a",
    variables = c("SEX", "AGE", "LABFORCE")
  )
)

eject_cassette("submit-placeholder-extract-usa")

## ----echo=FALSE, results="hide", message=FALSE--------------------------------
insert_cassette("submit-extract")

## -----------------------------------------------------------------------------
usa_extract_submitted <- submit_extract(usa_extract_definition)

## -----------------------------------------------------------------------------
usa_extract_submitted$number
usa_extract_submitted$status

## -----------------------------------------------------------------------------
names(usa_extract_submitted$variables)

## -----------------------------------------------------------------------------
usa_extract_submitted <- get_last_extract_info("usa")

usa_extract_submitted$number

## ----echo=FALSE, results="hide", message=FALSE--------------------------------
eject_cassette("submit-extract")

## ----echo=FALSE, results="hide", message=FALSE--------------------------------
insert_cassette("wait-for-extract")

usa_extract_complete <- wait_for_extract(usa_extract_submitted)

eject_cassette("wait-for-extract")

# Leave an extract request to simulate wait_for_extract() output for USA
modify_ready_extract_cassette_file(
  "wait-for-extract.yml",
  fixture_path = "fixtures",
  n_requests = 2
)

## ----echo=FALSE, results="hide", message=FALSE--------------------------------
insert_cassette("wait-for-extract")

## -----------------------------------------------------------------------------
usa_extract_complete <- wait_for_extract(usa_extract_submitted)

## -----------------------------------------------------------------------------
usa_extract_complete$status

## -----------------------------------------------------------------------------
# `download_links` should be populated if the extract is ready for download
names(usa_extract_complete$download_links)

## ----echo=FALSE, results="hide", message=FALSE--------------------------------
eject_cassette("wait-for-extract")

## ----echo=FALSE, results="hide", message=FALSE--------------------------------
insert_cassette("extract-ready")

## -----------------------------------------------------------------------------
is_extract_ready(usa_extract_submitted)

## ----echo=FALSE, results="hide", message=FALSE--------------------------------
eject_cassette("extract-ready")

## ----echo=FALSE, results="hide", message=FALSE--------------------------------
insert_cassette("check-extract-info")

## -----------------------------------------------------------------------------
usa_extract_submitted <- get_extract_info(usa_extract_submitted)

usa_extract_submitted$status

## ----echo=FALSE, results="hide", message=FALSE--------------------------------
eject_cassette("check-extract-info")

## ----eval=FALSE---------------------------------------------------------------
#  # By default, downloads to your current working directory
#  filepath <- download_extract(usa_extract_submitted)

## ----eval=FALSE---------------------------------------------------------------
#  ddi <- read_ipums_ddi(filepath)
#  micro_data <- read_ipums_micro(ddi)

## ----echo=FALSE, results="hide", message=FALSE--------------------------------
insert_cassette("check-extract-history")

## -----------------------------------------------------------------------------
usa_extract <- get_extract_info("usa:47")

# Alternatively:
usa_extract <- get_extract_info(c("usa", 47))

usa_extract

## -----------------------------------------------------------------------------
usa_extracts <- get_extract_history("usa", how_many = 3)

usa_extracts

## -----------------------------------------------------------------------------
is_extract_ready(usa_extracts[[2]])

## -----------------------------------------------------------------------------
purrr::keep(usa_extracts, ~ "MARST" %in% names(.x$variables))
purrr::keep(usa_extracts, is_extract_ready)

## -----------------------------------------------------------------------------
purrr::map_chr(usa_extracts, ~ .x$description)

## ----eval=FALSE---------------------------------------------------------------
#  set_ipums_default_collection("usa") # Set `save = TRUE` to store across sessions

## ----echo=FALSE, results="hide", message=FALSE--------------------------------
set_ipums_default_collection("usa")

## -----------------------------------------------------------------------------
# Check the default collection:
Sys.getenv("IPUMS_DEFAULT_COLLECTION")

## -----------------------------------------------------------------------------
# Most recent USA extract:
usa_last <- get_last_extract_info()

# Request info on extract request "usa:10"
usa_extract_10 <- get_extract_info(10)

# You can still request other collections as usual:
cps_extract_10 <- get_extract_info("cps:10")

## ----echo=FALSE, results="hide", message=FALSE--------------------------------
eject_cassette("check-extract-history")

## ----eval=FALSE---------------------------------------------------------------
#  usa_extract_10 <- get_extract_info("usa:10")
#  save_extract_as_json(usa_extract_10, file = "usa_extract_10.json")

## ----eval=FALSE---------------------------------------------------------------
#  clone_of_usa_extract_10 <- define_extract_from_json("usa_extract_10.json")
#  usa_extract_10_resubmitted <- submit_extract(clone_of_usa_extract_10)

## ----eval=FALSE---------------------------------------------------------------
#  usa_data <- define_extract_micro(
#    "usa",
#    "USA extract for API vignette",
#    samples = c("us2018a", "us2019a"),
#    variables = c("AGE", "SEX", "RACE", "STATEFIP")
#  ) %>%
#    submit_extract() %>%
#    wait_for_extract() %>%
#    download_extract() %>%
#    read_ipums_micro()

## ----eval=FALSE---------------------------------------------------------------
#  nhgis_data <- download_extract(nhgis_extract) %>%
#    purrr::pluck("data") %>% # Select only the tabular data file to read
#    read_nhgis()

