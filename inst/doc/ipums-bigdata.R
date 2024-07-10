## ----eval=FALSE---------------------------------------------------------------
#  # To run the full vignette, you'll also need the following packages. If they
#  # aren't installed already, do so with:
#  install.packages("biglm")
#  install.packages("DBI")
#  install.packages("RSQLite")
#  install.packages("dbplyr")

## ----include=FALSE------------------------------------------------------------
installed_biglm <- requireNamespace("biglm")

installed_db_pkgs <- requireNamespace("DBI") &
  requireNamespace("RSQLite") &
  requireNamespace("dbplyr")

## ----echo=FALSE---------------------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>"
)

## ----eval=TRUE, message=FALSE-------------------------------------------------
library(ipumsr)
library(dplyr)

## -----------------------------------------------------------------------------
define_extract_micro(
  "usa",
  description = "2013 ACS Data for Married Women",
  samples = "us2013a",
  variables = list(
    var_spec("MARST", case_selections = "1"),
    var_spec("SEX", case_selections = "2")
  )
)

## -----------------------------------------------------------------------------
cps_ddi_file <- ipums_example("cps_00097.xml")

## -----------------------------------------------------------------------------
read_ipums_micro(cps_ddi_file, verbose = FALSE) %>%
  mutate(
    HEALTH = as_factor(HEALTH),
    AT_WORK = as_factor(
      lbl_relabel(
        EMPSTAT,
        lbl(1, "Yes") ~ .lbl == "At work",
        lbl(0, "No") ~ .lbl != "At work"
      )
    )
  ) %>%
  group_by(HEALTH, AT_WORK) %>%
  summarize(n = n(), .groups = "drop")

## -----------------------------------------------------------------------------
cb_function <- function(x, pos) {
  x %>%
    mutate(
      HEALTH = as_factor(HEALTH),
      AT_WORK = as_factor(
        lbl_relabel(
          EMPSTAT,
          lbl(1, "Yes") ~ .lbl == "At work",
          lbl(0, "No") ~ .lbl != "At work"
        )
      )
    ) %>%
    group_by(HEALTH, AT_WORK) %>%
    summarize(n = n(), .groups = "drop")
}

## -----------------------------------------------------------------------------
cb <- IpumsDataFrameCallback$new(cb_function)

## -----------------------------------------------------------------------------
chunked_tabulations <- read_ipums_micro_chunked(
  cps_ddi_file,
  callback = cb,
  chunk_size = 1000,
  verbose = FALSE
)

chunked_tabulations

## -----------------------------------------------------------------------------
chunked_tabulations %>%
  group_by(HEALTH, AT_WORK) %>%
  summarize(n = sum(n), .groups = "drop")

## -----------------------------------------------------------------------------
data <- read_ipums_micro(cps_ddi_file, verbose = FALSE) %>%
  mutate(
    HEALTH = as_factor(HEALTH),
    AHRSWORKT = lbl_na_if(AHRSWORKT, ~ .lbl == "NIU (Not in universe)"),
    AT_WORK = as_factor(
      lbl_relabel(
        EMPSTAT,
        lbl(1, "Yes") ~ .lbl == "At work",
        lbl(0, "No") ~ .lbl != "At work"
      )
    )
  ) %>%
  filter(AT_WORK == "Yes")

## -----------------------------------------------------------------------------
model <- lm(AHRSWORKT ~ AGE + I(AGE^2) + HEALTH, data = data)
summary(model)

## ----eval=installed_biglm-----------------------------------------------------
library(biglm)

## ----eval=installed_biglm-----------------------------------------------------
biglm_cb <- IpumsBiglmCallback$new(
  model = AHRSWORKT ~ AGE + I(AGE^2) + HEALTH,
  prep = function(x, pos) {
    x %>%
      mutate(
        HEALTH = as_factor(HEALTH),
        AHRSWORKT = lbl_na_if(AHRSWORKT, ~ .lbl == "NIU (Not in universe)"),
        AT_WORK = as_factor(
          lbl_relabel(
            EMPSTAT,
            lbl(1, "Yes") ~ .lbl == "At work",
            lbl(0, "No") ~ .lbl != "At work"
          )
        )
      ) %>%
      filter(AT_WORK == "Yes")
  }
)

## ----eval=installed_biglm-----------------------------------------------------
chunked_model <- read_ipums_micro_chunked(
  cps_ddi_file,
  callback = biglm_cb,
  chunk_size = 1000,
  verbose = FALSE
)

summary(chunked_model)

## -----------------------------------------------------------------------------
data <- read_ipums_micro_yield(cps_ddi_file, verbose = FALSE)

## -----------------------------------------------------------------------------
# Return the first 10 rows of data
data$yield(10)

## -----------------------------------------------------------------------------
# Return the next 10 rows of data
data$yield(10)

## -----------------------------------------------------------------------------
data$cur_pos

## -----------------------------------------------------------------------------
data$is_done()

## -----------------------------------------------------------------------------
data$reset()

## -----------------------------------------------------------------------------
yield_results <- tibble(
  HEALTH = factor(levels = c("Excellent", "Very good", "Good", "Fair", "Poor")),
  AT_WORK = factor(levels = c("No", "Yes")),
  n = integer(0)
)

## -----------------------------------------------------------------------------
while (!data$is_done()) {
  # Yield new data and process
  new <- data$yield(n = 1000) %>%
    mutate(
      HEALTH = as_factor(HEALTH),
      AT_WORK = as_factor(
        lbl_relabel(
          EMPSTAT,
          lbl(1, "Yes") ~ .lbl == "At work",
          lbl(0, "No") ~ .lbl != "At work"
        )
      )
    ) %>%
    group_by(HEALTH, AT_WORK) %>%
    summarize(n = n(), .groups = "drop")

  # Combine the new yield with the previously processed yields
  yield_results <- bind_rows(yield_results, new) %>%
    group_by(HEALTH, AT_WORK) %>%
    summarize(n = sum(n), .groups = "drop")
}

yield_results

## -----------------------------------------------------------------------------
data$reset()

## -----------------------------------------------------------------------------
get_model_data <- function(reset) {
  if (reset) {
    data$reset()
  } else {
    yield <- data$yield(n = 1000)

    if (is.null(yield)) {
      return(yield)
    }

    yield %>%
      mutate(
        HEALTH = as_factor(HEALTH),
        WORK30PLUS = lbl_na_if(AHRSWORKT, ~ .lbl == "NIU (Not in universe)") >= 30,
        AT_WORK = as_factor(
          lbl_relabel(
            EMPSTAT,
            lbl(1, "Yes") ~ .lbl == "At work",
            lbl(0, "No") ~ .lbl != "At work"
          )
        )
      ) %>%
      filter(AT_WORK == "Yes")
  }
}

## ----eval=installed_biglm-----------------------------------------------------
results <- bigglm(
  WORK30PLUS ~ AGE + I(AGE^2) + HEALTH,
  family = binomial(link = "logit"),
  data = get_model_data
)

summary(results)

## ----eval=installed_db_pkgs, results="hide"-----------------------------------
library(DBI)
library(RSQLite)

# Connect to database
con <- dbConnect(SQLite(), path = ":memory:")

# Load file metadata
ddi <- read_ipums_ddi(cps_ddi_file)

# Write data to database in chunks
read_ipums_micro_chunked(
  ddi,
  readr::SideEffectChunkCallback$new(
    function(x, pos) {
      if (pos == 1) {
        dbWriteTable(con, "cps", x)
      } else {
        dbWriteTable(con, "cps", x, row.names = FALSE, append = TRUE)
      }
    }
  ),
  chunk_size = 1000,
  verbose = FALSE
)

## ----eval=installed_db_pkgs---------------------------------------------------
example <- tbl(con, "cps")

example %>%
  filter("AGE" > 25)

## ----eval=installed_db_pkgs---------------------------------------------------
data <- example %>%
  filter("AGE" > 25) %>%
  collect()

# Variable metadata is missing
ipums_val_labels(data$MONTH)

## ----eval=installed_db_pkgs---------------------------------------------------
data <- example %>%
  filter("AGE" > 25) %>%
  ipums_collect(ddi)

ipums_val_labels(data$MONTH)

