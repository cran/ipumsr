test_that("can set attributes altogether", {
  data <- read_ipums_micro(
    read_ipums_ddi(ipums_example("cps_00157.xml")),
    verbose = FALSE
  )

  expect_equal(attr(data[[1]], "label"), "Survey year")
  expect_equal(
    attr(data[[1]], "var_desc"),
    paste0(
      "YEAR reports the year in which the survey was conducted.  ",
      "YEARP is repeated on person records."
    )
  )
  expect_true(is.labelled(data[["STATEFIP"]]))
  expect_equal(
    attr(data[["STATEFIP"]], "labels")[1],
    c("Alabama" = 1)
  )
})

test_that("setting variable attributes one at a time (#34)", {
  ddi <- read_ipums_ddi(ipums_example("cps_00157.xml"))
  data <- read_ipums_micro(ddi, var_attrs = NULL, verbose = FALSE)

  all_attributes <- set_ipums_var_attributes(data, ddi)
  just_var_lbl <- set_ipums_var_attributes(data, ddi, "var_label")
  just_var_desc <- set_ipums_var_attributes(data, ddi, "var_desc")
  just_val_lbls <- set_ipums_var_attributes(data, ddi, "val_labels")

  # Make sure we didn't put attributes on original dataset
  expect_true(
    !identical(attributes(data[[1]]), attributes(all_attributes[[1]]))
  )

  # just_var_lbl ----
  expect_equal(
    lapply(all_attributes, function(x) attr(x, "label")),
    lapply(just_var_lbl, function(x) attr(x, "label"))
  )

  expect_equal(
    lapply(data, function(x) attr(x, "var_desc")),
    lapply(just_var_lbl, function(x) attr(x, "var_desc"))
  )

  expect_equal(
    lapply(data, function(x) class(x)),
    lapply(just_var_lbl, function(x) class(x))
  )

  expect_equal(
    lapply(data, function(x) attr(x, "labels")),
    lapply(just_var_lbl, function(x) attr(x, "labels"))
  )

  # just_var_desc
  expect_equal(
    lapply(data, function(x) attr(x, "label")),
    lapply(just_var_desc, function(x) attr(x, "label"))
  )

  expect_equal(
    lapply(all_attributes, function(x) attr(x, "var_desc")),
    lapply(just_var_desc, function(x) attr(x, "var_desc"))
  )

  expect_equal(
    lapply(data, function(x) class(x)),
    lapply(just_var_desc, function(x) class(x))
  )

  expect_equal(
    lapply(data, function(x) attr(x, "labels")),
    lapply(just_var_desc, function(x) attr(x, "labels"))
  )

  # just_val_lbls
  expect_equal(
    lapply(data, function(x) attr(x, "label", exact = TRUE)),
    lapply(just_val_lbls, function(x) attr(x, "label", exact = TRUE))
  )

  expect_equal(
    lapply(data, function(x) attr(x, "var_desc")),
    lapply(just_val_lbls, function(x) attr(x, "var_desc"))
  )

  expect_equal(
    lapply(all_attributes, function(x) class(x)),
    lapply(just_val_lbls, function(x) class(x))
  )

  expect_equal(
    lapply(all_attributes, function(x) attr(x, "labels")),
    lapply(just_val_lbls, function(x) attr(x, "labels"))
  )
})
