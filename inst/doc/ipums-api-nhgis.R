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

# We do not expose detailed pagination options to users, but we do not want
# to save a full record of summary metadata in a .yml fixture for this
# vignette. This helper allows us to request just a few records, which
# we pretend is the full set of records for the purposes of the vignette.
get_truncated_metadata <- function(collection,
                                   type,
                                   page_size = 10,
                                   max_pages = 1,
                                   api_key = Sys.getenv("IPUMS_API_KEY")) {
  url <- ipumsr:::api_request_url(
    collection = collection,
    path = ipumsr:::metadata_request_path(collection, type),
    queries = list(pageNumber = 1, pageSize = page_size)
  )

  responses <- ipumsr:::ipums_api_paged_request(
    url = url,
    max_pages = max_pages,
    delay = 0,
    api_key = api_key
  )

  metadata <- purrr::map_dfr(
    responses,
    function(res) {
      content <- jsonlite::fromJSON(
        httr::content(res, "text"),
        simplifyVector = TRUE
      )

      content$data
    }
  )

  # Recursively convert all metadata data.frames to tibbles and all
  # camelCase names to snake_case
  ipumsr:::convert_metadata(metadata)
}

## ----message=FALSE------------------------------------------------------------
library(ipumsr)
library(dplyr)
library(purrr)

## ----echo=FALSE, results="hide", message=FALSE--------------------------------
insert_cassette("nhgis-metadata-summary")

## -----------------------------------------------------------------------------
ds <- get_metadata_nhgis(type = "datasets")

head(ds)

## -----------------------------------------------------------------------------
ds %>%
  filter(
    group == "1900 Census",
    grepl("Agriculture", description)
  )

## ----echo=FALSE, results="hide", message=FALSE--------------------------------
# Secretly get truncated number of tst records because otherwise the .yml
# fixture becomes very large.

# Make sure that any code that uses this metadata is consistent with the output
# that would be obtained were the entire metadata set loaded!
tst <- get_truncated_metadata("nhgis", "time_series_tables")

## ----eval=FALSE---------------------------------------------------------------
#  tst <- get_metadata_nhgis("time_series_tables")

## -----------------------------------------------------------------------------
head(tst)

## -----------------------------------------------------------------------------
tst$years[[1]]
tst$geog_levels[[1]]

## -----------------------------------------------------------------------------
# Iterate over each `years` entry, identifying whether that entry
# contains "1840" in its `name` column.
tst %>%
  filter(map_lgl(years, ~ "1840" %in% .x$name))

## ----echo=FALSE, results="hide", message=FALSE--------------------------------
eject_cassette("nhgis-metadata-summary")

## ----echo=FALSE, results="hide", message=FALSE--------------------------------
insert_cassette("nhgis-metadata-detailed")

## -----------------------------------------------------------------------------
cAg_meta <- get_metadata_nhgis(dataset = "1900_cAg")

## -----------------------------------------------------------------------------
cAg_meta$data_tables
cAg_meta$geog_levels

## -----------------------------------------------------------------------------
get_metadata_nhgis(dataset = "1900_cAg", data_table = "NT2")

## ----echo=FALSE, results="hide", message=FALSE--------------------------------
eject_cassette("nhgis-metadata-detailed")

## -----------------------------------------------------------------------------
cAg_meta$data_tables

## -----------------------------------------------------------------------------
dataset <- ds_spec(
  "1900_cAg",
  data_tables = c("NT1", "NT2"),
  geog_levels = "state"
)

str(dataset)

## -----------------------------------------------------------------------------
nhgis_ext <- define_extract_nhgis(
  description = "Example farm data in 1900",
  datasets = dataset
)

nhgis_ext

## -----------------------------------------------------------------------------
define_extract_nhgis(
  description = "Example time series table request",
  time_series_tables = tst_spec(
    "CW3",
    geog_levels = c("county", "tract"),
    years = c("1990", "2000")
  )
)

## -----------------------------------------------------------------------------
define_extract_nhgis(
  description = "Example shapefiles request",
  shapefiles = c("us_county_2021_tl2021", "us_county_2020_tl2020")
)

## -----------------------------------------------------------------------------
define_extract_nhgis(
  description = "Slightly more complicated extract request",
  datasets = list(
    ds_spec("2018_ACS1", "B01001", "state"),
    ds_spec("2019_ACS1", "B01001", "state")
  ),
  shapefiles = c("us_state_2018_tl2018", "us_state_2019_tl2019")
)

## -----------------------------------------------------------------------------
ds_names <- c("2019_ACS1", "2018_ACS1")
tables <- c("B01001", "B01002")
geogs <- c("county", "state")

# For each dataset to include, create a specification with the
# data tabels and geog levels indicated above
datasets <- purrr::map(
  ds_names,
  ~ ds_spec(name = .x, data_tables = tables, geog_levels = geogs)
)

nhgis_ext <- define_extract_nhgis(
  description = "Slightly more complicated extract request",
  datasets = datasets
)

nhgis_ext

## ----eval=FALSE---------------------------------------------------------------
#  nhgis_ext_submitted <- submit_extract(nhgis_ext)

