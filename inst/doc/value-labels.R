## ----setup, include = FALSE---------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>"
)

## ----message=FALSE------------------------------------------------------------
library(ipumsr)

ddi <- read_ipums_ddi(ipums_example("cps_00160.xml"))
cps <- read_ipums_micro(ddi, verbose = FALSE)

cps[, 1:5]

## -----------------------------------------------------------------------------
is.labelled(cps$STATEFIP)

## -----------------------------------------------------------------------------
# Labels print when accessing the column
head(cps$MONTH)

# Get labels alone
ipums_val_labels(cps$MONTH)

## -----------------------------------------------------------------------------
head(cps$AGE)

## -----------------------------------------------------------------------------
cps$AGE_FACTOR <- as_factor(cps$AGE)

age0_factor <- cps[cps$AGE == 0, ]$AGE_FACTOR

# The levels look the same
unique(age0_factor)

# But the values have changed
unique(as.numeric(age0_factor))

## -----------------------------------------------------------------------------
age85_factor <- cps[cps$AGE == 85, ]$AGE_FACTOR

unique(as.numeric(age85_factor))

## -----------------------------------------------------------------------------
mean(cps$AGE)

mean(as.numeric(cps$AGE_FACTOR))

## -----------------------------------------------------------------------------
ipums_val_labels(cps$HEALTH)

HEALTH2 <- ifelse(cps$HEALTH > 3, 3, cps$HEALTH)
ipums_val_labels(HEALTH2)

## -----------------------------------------------------------------------------
ipums_val_labels(cps$MONTH)

cps$MONTH <- as_factor(cps$MONTH)

## ----eval=FALSE---------------------------------------------------------------
#  cps <- as_factor(cps)
#  
#  # ... further preparation of variables as factors

## -----------------------------------------------------------------------------
inctot_num <- zap_labels(cps$INCTOT)

typeof(inctot_num)

ipums_val_labels(inctot_num)

## -----------------------------------------------------------------------------
ipums_val_labels(cps$INCTOT)

## -----------------------------------------------------------------------------
ipums_val_labels(cps$INCTOT)

## -----------------------------------------------------------------------------
# Convert to NA using function that returns TRUE for all labelled values equal to 99999999
inctot_na <- lbl_na_if(
  cps$INCTOT,
  function(.val, .lbl) .val == 999999999
)

# All 99999999 values have been converted to NA
any(inctot_na == 999999999, na.rm = TRUE)

# And the label has been removed:
ipums_val_labels(inctot_na)

## -----------------------------------------------------------------------------
# Convert to NA for labels that contain "N.I.U."
inctot_na2 <- lbl_na_if(
  cps$INCTOT,
  function(.val, .lbl) grepl("N.I.U.", .lbl)
)

# Same result
all(inctot_na2 == inctot_na, na.rm = TRUE)

## ----eval=FALSE---------------------------------------------------------------
#  lbl_na_if(cps$INCTOT, ~ .val == 999999999)

## -----------------------------------------------------------------------------
x <- lbl_na_if(cps$INCTOT, ~ .val >= 0)

# Unlabelled values greater than the cutoff are still present:
length(which(x > 0))

## -----------------------------------------------------------------------------
ipums_val_labels(cps$MIGRATE1)

cps$MIGRATE1 <- lbl_relabel(
  cps$MIGRATE1,
  lbl(0, "NIU / Missing / Unknown") ~ .val %in% c(0, 2, 9),
  lbl(1, "Stayed in state") ~ .val %in% c(1, 3, 4)
)

ipums_val_labels(cps$MIGRATE1)

## -----------------------------------------------------------------------------
head(ipums_val_labels(cps$EDUC), 15)

## -----------------------------------------------------------------------------
# %/% refers to integer division, which divides but discards the remainder
10 %/% 10
11 %/% 10

# Convert to groups by tens digit
cps$EDUC2 <- lbl_collapse(cps$EDUC, ~ .val %/% 10)

ipums_val_labels(cps$EDUC2)

## -----------------------------------------------------------------------------
ipums_val_labels(cps$STATEFIP)

ipums_val_labels(lbl_clean(cps$STATEFIP))

## -----------------------------------------------------------------------------
x <- haven::labelled(
  c(100, 200, 105, 990, 999, 230),
  c(`Unknown` = 990, NIU = 999)
)

lbl_add(
  x,
  lbl(100, "$100"),
  lbl(105, "$105"),
  lbl(200, "$200"),
  lbl(230, "$230")
)

## -----------------------------------------------------------------------------
# `.` refers to each label value
lbl_add_vals(x, ~ paste0("$", .))

## -----------------------------------------------------------------------------
age <- c(10, 12, 16, 18, 20, 22, 25, 27)

# Group age values into two label groups.
# Values not captured by the right hand side functions remain unlabelled
lbl_define(
  age,
  lbl(1, "Pre-college age") ~ .val < 18,
  lbl(2, "College age") ~ .val >= 18 & .val <= 22
)

