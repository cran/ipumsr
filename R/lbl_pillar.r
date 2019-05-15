# This file is part of the Minnesota Population Center's ipumsr.
# For copyright and licensing information, see the NOTICE and LICENSE files
# in this project's top-level directory, and also on-line at:
#   https://github.com/mnpopcenter/ipumsr

# Implement pillar printing for haven_labelled objects - can
# be deleted if/when https://github.com/tidyverse/haven/pull/390
# or equivalent is merged

#' @importFrom pillar pillar_shaft
#' @export
pillar_shaft.haven_labelled <- function(
  x,
  show_labels = getOption("ipumsr.show_pillar_labels", TRUE),
  ...
) {
  if (!isTRUE(show_labels) | !pillar_print_pkgs_available()) {
    return(pillar::pillar_shaft(unclass(x)))
  }

  if (is.numeric(x)) {
    val <- val_num_pillar_info(x)
    lbl <- lbl_pillar_info(x)

    pillar::new_pillar_shaft(
      list(val = val, lbl = lbl),
      min_width = max(val$disp_short$lhs_ws + val$disp_short$main_wid + lbl$wid_short),
      width = max(val$disp_full$lhs_ws + val$disp_full$main_wid + lbl$wid_full),
      subclass = "pillar_shaft_haven_labelled_num"
    )
  } else {
    val <- val_chr_pillar_info(x)
    lbl <- lbl_pillar_info(x)

    pillar::new_pillar_shaft(
      list(val = val, lbl = lbl),
      min_width = max(val$wid_short + lbl$wid_short),
      width =  max(val$wid_full + lbl$wid_full),
      subclass = "pillar_shaft_haven_labelled_chr"
    )
  }
}

val_num_pillar_info <- function(x) {
  val_pillar <- pillar::pillar_shaft(custom_zap_labels(x))

  disp_short <- num_disp_components(x, val_pillar, attr(val_pillar, "min_width"))
  disp_full <- num_disp_components(x, val_pillar, attr(val_pillar, "width"))

  if (is.double(x)) {
    na_display <- character(length(x))
    na_display[haven::is_tagged_na(x)] <- pillar::style_na(
      paste0("(", haven::na_tag(x[haven::is_tagged_na(x)]), ")")
    )

    disp_short <- add_text(disp_short, na_display)
    disp_full <- add_text(disp_full, na_display)
  }

  list(
    disp_short = disp_short,
    disp_full = disp_full
  )
}

num_disp_components <- function(x, pillar, width) {
  display <- format(pillar, width)
  # Sometimes there's an extra leading space from pillar
  display <- trim_ws_lhs(display)
  # exponent notation formatting hinders stripping white space in NAs
  display[is.na(unclass(x))] <- crayon::strip_style(display[is.na(unclass(x))])

  display_untrimmed_wid <- pillar::get_extent(display)
  display_max_wid <- max(display_untrimmed_wid)
  display <- trim_ws_rhs(display)
  main_wid <- pillar::get_extent(display)
  display_trimmed_rhs <- display_untrimmed_wid - main_wid

  display[is.na(unclass(x))] <- pillar::style_na(display[is.na(unclass(x))])
  list(
    lhs_ws = max(main_wid + display_trimmed_rhs) - (main_wid + display_trimmed_rhs),
    main_wid = main_wid,
    main_txt = display,
    rhs_ws = display_trimmed_rhs
  )
}

add_text <- function(display, new_text) {
  new_wid <- pillar::get_extent(new_text)
  wid_avail <- pmin(display$lhs_ws, new_wid)
  wid_needed <- new_wid - wid_avail
  display$lhs_ws <- display$lhs_ws + max(wid_needed) - wid_avail - wid_needed

  display$main_txt <- paste0(display$main_txt, new_text)
  display$main_wid <- pillar::get_extent(display$main_txt)
  display
}

val_chr_pillar_info <- function(x) {
  MIN_CHR_DISPLAY <- 4
  val_pillar <- pillar::pillar_shaft(custom_zap_labels(x))
  disp_full <- trim_ws_rhs(format(val_pillar, attr(val_pillar, "width")))
  wid_full <- pillar::get_extent(disp_full)

  list(
    val_pillar = val_pillar,
    wid_short = pmin(MIN_CHR_DISPLAY, wid_full),
    disp_full = disp_full,
    wid_full = wid_full
  )
}

lbl_pillar_info <- function(x) {
  MIN_LBL_DISPLAY <- 6
  labels <- attr(x, "labels")
  if (length(labels) > 0) {
    names(labels) <- pillar::style_subtle(paste0(" [", names(labels), "]"))
    attr(x, "labels") <- labels
    label_display <- get_label_text(x)
    label_display[is.na(label_display)] <- ""
  } else {
    label_display <- character(length(x))
  }
  label_widths <- pillar::get_extent(label_display)
  label_min_widths <- ifelse(label_widths > 0, pmin(MIN_LBL_DISPLAY, label_widths), 0)

  if (inherits(x, "haven_labelled_spss")) {
    MIN_NA_DISPLAY <- 4
    na_display <- character(length(x))
    na_display[is.na(x) & !is.na(unclass(x))] <- pillar::style_na(" (NA)")
    na_widths <- pillar::get_extent(na_display)

    label_display <- paste0(na_display, label_display)
    label_widths <- label_widths + na_widths
    label_min_widths <- label_min_widths + ifelse(label_widths > 0, pmin(MIN_NA_DISPLAY, label_widths), 0)
  }

  ret <- list(
    wid_short = label_min_widths,
    disp_full = label_display,
    wid_full = label_widths
  )
  ret
}

#' @export
format.pillar_shaft_haven_labelled_num <- function(x, width, ...) {
  vshort <- x$val$disp_short
  vfull <- x$val$disp_full
  lbl_wid <- pmax(0, x$lbl$wid_short - vfull$rhs_ws)

  if (width >= max(vfull$lhs_ws +vfull$main_wid + lbl_wid)) {
    lbl_width <- width - (vfull$lhs_ws + vfull$main_wid)
    lbl <- str_trunc(x$lbl$disp_full, lbl_width, subtle = TRUE)
    out <- paste_with_align(vfull$main_txt, lbl, vfull$lhs_ws, vfull$rhs_ws)
  } else {
    lbl_width <- width - (vshort$lhs_ws + vshort$main_wid)
    lbl <- str_trunc(x$lbl$disp_full, lbl_width, subtle = TRUE)
    out <- paste_with_align(vshort$main_txt, lbl, vshort$lhs_ws, vshort$rhs_ws)
  }
  pillar::new_ornament(out, width = width, align = "right")
}

#' @export
format.pillar_shaft_haven_labelled_chr <- function(x, width, ...) {
  if (width >= max(x$val$wid_full + x$lbl$wid_short)) {
    lbl_width <- width - x$val$wid_full
    lbl <- str_trunc(x$lbl$disp_full, lbl_width, subtle = TRUE)
    out <- paste0(x$val$disp_full, lbl)
  } else {
    val_widths <- pmin(x$val$wid_full, width - x$lbl$wid_short)
    val_display <- str_trunc(x$val$disp_full, val_widths)
    lbl <- str_trunc(x$lbl$disp_full, width - val_widths, subtle = TRUE)
    out <- paste0(val_display, lbl)
  }
  pillar::new_ornament(out, width = width, align = "left")
}

str_trunc <- function(x, widths, subtle = FALSE) {
  str_width <- pillar::get_extent(x)
  too_wide <- which(!is.na(x) & str_width > widths)

  continue_symbol <- cli::symbol$continue
  if (subtle) continue_symbol <- pillar::style_subtle(continue_symbol)

  truncated <- Map(x[too_wide], widths[too_wide], f = function(item, wid) {
    paste0(crayon::col_substr(item, 1, wid - 1), continue_symbol)
  })
  truncated <- as.vector(truncated, "character")
  x[too_wide] <- truncated

  x
}

trim_ws_rhs <- function(x) {
  sub("[ \t\r\n]+$", "", x)
}

trim_ws_lhs <- function(x) {
  sub("^[ \t\r\n]+", "", x)
}

pad_space <- function(n) {
  vapply(n, function(x) paste(rep(" ", x), collapse = ""), "")
}

paste_with_align <- function(x, y, lhs_ws, rhs_ws) {
  y_wid <- pillar::get_extent(y)
  added_chars <- max(y_wid - rhs_ws)
  rhs_ws <- added_chars - (y_wid - rhs_ws)

  paste0(pad_space(lhs_ws), x, y, pad_space(rhs_ws))
}

pillar_print_pkgs_available <- function() {
  requireNamespace("crayon", quietly = TRUE) &
    requireNamespace("cli", quietly = TRUE)
}

# I forget exactly why this is needed, but it is.
# Adapted from haven:::zap_labels.haven_labelled
custom_zap_labels <- function(x) {
  attr(x, "labels") <- NULL
  class(x) <- NULL
  x
}

# Replacement for  bug in as_factor for type = "labelled" that
# doesn't allow duplicate labels (we don't actually need the
# factor so just get character vector)
get_label_text <- function(x) {
  label <- attr(x, "label", exact = TRUE)
  labels <- attr(x, "labels")

  levs <- unname(labels)
  labs <- names(labels)
  as.character(haven_replace_with(x, levs, labs))
}

# Adpated from haven:::replace_with
haven_replace_with <- function(x, from, to) {
  stopifnot(length(from) == length(to))
  out <- x
  matches <- match(x, from, incomparables = NA)
  if (anyNA(matches)) {
    out[!is.na(matches)] <- to[matches[!is.na(matches)]]
  }
  else {
    out <- to[matches]
  }
  tagged <- haven::is_tagged_na(x)
  if (!any(tagged)) {
    return(out)
  }
  matches <- match(haven::na_tag(x), haven::na_tag(from), incomparables = NA)
  out[!is.na(matches)] <- to[matches[!is.na(matches)]]
  out
}
