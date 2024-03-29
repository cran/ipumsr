# This file is part of the ipumsr R package created by IPUMS.
# For copyright and licensing information, see the NOTICE and LICENSE files
# in this project's top-level directory, and also on-line at:
#   https://github.com/ipums/ipumsr

ddi_filter_vars <- function(ddi, vars, out_type, verbose) {
  if (rlang::quo_is_null(vars)) {
    return(ddi)
  }

  varnames <- ddi$var_info$var_name
  names(varnames) <- varnames
  selected_vars <- varnames[tidyselect::eval_select(vars, varnames)]

  if (length(selected_vars) == 0) {
    rlang::abort(
      "`vars` did not match any variables found in the provided file."
    )
  }

  if (ddi$file_type == "hierarchical" & out_type == "list") {
    key_vars <- purrr::flatten_chr(ddi$rectypes_keyvars$keyvars)
    missing_kv <- dplyr::setdiff(key_vars, selected_vars)

    if (length(missing_kv) > 0) {
      if (verbose) {
        cat(paste0(
          "Adding cross rectype linking vars ('",
          paste(missing_kv, collapse = "', '"),
          "') to data.\n\n"
        ))
      }
      selected_vars <- c(selected_vars, missing_kv)
    }
  } else if (ddi$file_type == "hierarchical" & out_type == "long") {
    if (!ddi$rectype_idvar %in% selected_vars) {
      if (verbose) {
        cat(paste0(
          "Adding rectype id var '",
          ddi$rectype_idvar,
          "' to data.\n\n"
        ))
      }
      selected_vars <- c(selected_vars, ddi$rectype_idvar)
    }
  }

  ddi$var_info <- dplyr::filter(ddi$var_info, .data$var_name %in% selected_vars)
  ddi
}

get_rt_ddi <- function(ddi) {
  out <- ddi
  if (is.null(out$rectype_idvar)) {
    return(NULL)
  }

  out$var_info <- dplyr::filter(
    out$var_info,
    .data$var_name == out$rectype_idvar
  )

  out
}

ddi_to_rtinfo <- function(ddi) {
  if (is.null(ddi) || ddi$file_type == "rectangular") {
    out <- hipread::hip_rt(1, 0)
  } else if (ddi$file_type == "hierarchical") {
    rec_vinfo <- dplyr::filter(
      ddi$var_info,
      .data$var_name == ddi$rectype_idvar
    )

    if (nrow(rec_vinfo) > 1) {
      rlang::abort("Cannot support multiple rectype id variables.")
    }

    out <- hipread::hip_rt(rec_vinfo$start, rec_vinfo$end - rec_vinfo$start + 1)
  } else {
    rlang::abort(paste0("Unexpected file type: \"", ddi$file_type, "\""))
  }
  out
}

ddi_to_colspec <- function(ddi, out_type, verbose) {
  if (ddi$file_type == "rectangular") {
    out <- hipread::hip_fwf_positions(
      ddi$var_info$start,
      ddi$var_info$end,
      ddi$var_info$var_name,
      hipread_type_name_convert(ddi$var_info$var_type),
      imp_dec = ddi$var_info$imp_decim
    )

    if (out_type == "list") {
      if (verbose) {
        cat("Assuming data rectangularized to 'P' record type")
      }
      out <- list("P" = out)
    }
  } else if (ddi$file_type == "hierarchical") {
    col_info_rts <- ddi$var_info$rectypes
    col_info <- ddi$var_info[
      rep(seq_along(col_info_rts), lengths(col_info_rts)),
    ]

    if (is.character(col_info_rts[[1]][1])) {
      col_info$rectypes <- purrr::flatten_chr(col_info_rts)
    } else if (is.integer(col_info_rts[[1]][1])) {
      col_info$rectypes <- purrr::flatten_int(col_info_rts)
    } else if (is.numeric(col_info_rts[[1]][1])) {
      col_info$rectypes <- purrr::flatten_dbl(col_info_rts)
    } else {
      rlang::abort("Unexpected rectype variable type.")
    }

    rts <- unique(col_info$rectypes)
    out <- purrr::map(
      rts,
      function(rt) {
        rt_cinfo <- col_info[col_info$rectypes == rt, ]
        hipread::hip_fwf_positions(
          rt_cinfo$start,
          rt_cinfo$end,
          rt_cinfo$var_name,
          hipread_type_name_convert(rt_cinfo$var_type),
          imp_dec = rt_cinfo$imp_decim
        )
      }
    )
    names(out) <- rts
  } else {
    rlang::abort(paste0("Unexpected file type: \"", ddi$file_type, "\""))
  }

  out
}

ddi_to_readr_colspec <- function(ddi) {
  col_types <- purrr::map(
    ddi$var_info$var_type,
    function(x) {
      if (x == "numeric") {
        out <- readr::col_double()
      } else if (x == "character") {
        out <- readr::col_character()
      } else if (x == "integer") out <- readr::col_integer()
      out
    }
  )
  names(col_types) <- toupper(ddi$var_info$var_name)
  col_types <- do.call(readr::cols_only, col_types)
}

rectype_label_names <- function(cur_names, ddi) {
  # If value labels for rectype are available use them to name data.frames
  rt_lbls <- ddi$var_info$val_labels[[
    which(ddi$var_info$var_name == ddi$rectype_idvar)
  ]]

  matched_lbls <- match(cur_names, rt_lbls$val)
  # If any don't match, don't rename for fear of making thing worse
  if (any(is.na(matched_lbls))) {
    return(cur_names)
  }

  rt_lbls <- rt_lbls$lbl[matched_lbls]
  # Clean up value labels a bit though:
  rt_lbls <- toupper(rt_lbls)
  rt_lbls <- fostr_replace_all(rt_lbls, " RECORD$", "")
  rt_lbls <- fostr_replace_all(rt_lbls, "[[:blank:]]", "_")

  rt_lbls
}

ddi_has_lowercase_var_names <- function(ddi) {
  all(ddi$var_info$var_name == tolower(ddi$var_info$var_name))
}
