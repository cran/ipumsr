# This file is part of the Minnesota Population Center's ipumsr.
# For copyright and licensing information, see the NOTICE and LICENSE files
# in this project's top-level directory, and also on-line at:
#   https://github.com/mnpopcenter/ipumsr


#' Read boundary files from an IPUMS extract
#'
#' Reads the boundary files from an IPUMS extract into R as simple features (sf) objects or
#' SpatialPolygonsDataFrame (sp) objects.
#'
#' @param shape_file Filepath to one or more .shp files, a .zip file from an IPUMS extract
#'    or a path to an unzipped folder.
#' @param shape_layer For .zip extracts with multiple datasets, the name of the
#'   shape files to load. Accepts a character vector specifying the file name, or
#'  \code{\link{dplyr_select_style}} conventions. Can load multiple shape files,
#'    which will be combined.
#' @param vars Which variables in the shape file's data to keep (NULL the default
#'   keeps all)
#' @param encoding The text encoding to use when reading the shape file. Typically
#'   the defaults should read the data correctly, but for some extracts you may
#'   need to set them manually, but if funny characters appear in your data, you
#'   may need to. For microdata projects, the default NULL will look for a .cpg
#'   file to determine the encoding and if none is available, it will default to
#'   latin1. The NHGIS and the IPUMS Terra functions specify the encoding for
#'   those projects (latin1 and UTF-8 respectively).
#' @param bind_multiple If \code{TRUE}, will combine multiple shape files found into
#'   a single object.
#' @param add_layer_var Whether to add a variable named \code{layer} that indicates
#'   which shape_layer the data came from. NULL, the default, uses TRUE if more than
#'   1 layer is found, and FALSE otherwise.
#' @param verbose I \code{TRUE}, will report progress information
#' @return \code{read_ipums_sf} returns a sf object and \code{read_ipums_sp} returns
#'   a SpatialPolygonsDataFrame.
#' @examples
#' shape_file <- ipums_example("nhgis0008_shape_small.zip")
#' # If sf package is availble, can load as sf object
#' if (require(sf)) {
#'   sf_data <- read_ipums_sf(shape_file)
#' }
#'
#' # If sp package is available, can load as SpatialPolygonsDataFrame
#' if (require(sp) && require(rgdal)) {
#'   sp_data <- read_ipums_sp(shape_file)
#' }
#'
#' @family ipums_read
#' @export
read_ipums_sf <- function(
  shape_file, shape_layer = NULL, vars = NULL, encoding = NULL,
  bind_multiple = TRUE, add_layer_var = NULL, verbose = TRUE
) {
  shape_layer <- enquo(shape_layer)
  vars <- enquo(vars)
  load_sf_namespace()

  # For zipped files, make a temp folder that will be cleaned
  shape_temp <- tempfile()
  dir.create(shape_temp)
  on.exit(unlink(shape_temp, recursive = TRUE))

  read_shape_files <- shape_file_prep(shape_file, shape_layer, bind_multiple, shape_temp)

  encoding <- determine_encoding(read_shape_files, encoding)

  out <- purrr::map2(
    read_shape_files,
    encoding,
    function(.x, .y) {
      this_sf <- sf::read_sf(.x, quiet = !verbose, options = paste0("ENCODING=", .y))
      if (!rlang::quo_is_null(vars)) this_sf <- dplyr::select(this_sf, !!vars)
      this_sf
    }
  )
  names(out) <- stringr::str_sub(basename(read_shape_files), 1, -5)
  out <- careful_sf_rbind(out, add_layer_var)

  out
}

# Takes a list of sf's, fills in empty columns for you and binds them together.
# Throws error if types don't match
careful_sf_rbind <- function(sf_list, add_layer_var) {
  if (is.null(add_layer_var)) add_layer_var <- length(sf_list) > 1
  if (add_layer_var) {
    sf_list <- purrr::imap(sf_list, ~dplyr::mutate(.x, layer = .y))
  }

  if (length(sf_list) == 1) {
    return(sf_list[[1]])
  } else {
    # Get var info for all columns
    all_var_info <- purrr::map_df(sf_list, .id = "id", function(x) {
      tibble::tibble(name = names(x), type = purrr::map(x, ~class(.)))
    })

    all_var_info <- dplyr::group_by(all_var_info, .data$name)
    var_type_check <- dplyr::summarize(all_var_info, check = length(unique(.data$type)))
    if (any(var_type_check$check != 1)) {
      stop("Cannot combine shape files because variable types don't match.")
    }
    all_var_info <- dplyr::slice(all_var_info, 1)
    all_var_info <- dplyr::ungroup(all_var_info)
    all_var_info$id <- NULL

    out <- purrr::map(sf_list, function(x) {
      missing_vars <- dplyr::setdiff(all_var_info$name, names(x))
      if (length(missing_vars) == 0) return(x)

      for (vn in missing_vars) {
        vtype <- all_var_info$type[all_var_info$name == vn][[1]]
        if (identical(vtype, "character")) x[[vn]] <- NA_character_
        else if (identical(vtype, "numeric")) x[[vn]] <- NA_real_
        else if (identical(vtype, c("sfc_MULTIPOLYGON", "sfc"))) x[[vn]] <- vector("list", nrow(x))
        else stop("Unexpected variable type in shape file.")
      }
      x
    })
    out <- do.call(rbind, out)
  }
  sf::st_as_sf(tibble::as.tibble(out))
}


#' @rdname read_ipums_sf
#' @export
read_ipums_sp <- function(
  shape_file, shape_layer = NULL, vars = NULL, encoding = NULL,
  bind_multiple = TRUE, add_layer_var = NULL, verbose = TRUE
) {
  shape_layer <- enquo(shape_layer)
  vars <- enquo(vars)
  load_rgdal_namespace()

  # For zipped files, make a temp folder that will be cleaned
  shape_temp <- tempfile()
  dir.create(shape_temp)
  on.exit(unlink(shape_temp, recursive = TRUE))

  read_shape_files <- shape_file_prep(shape_file, shape_layer, bind_multiple, shape_temp)

  encoding <- determine_encoding(read_shape_files, encoding)

  out <- purrr::map2(
    read_shape_files,
    encoding,
    function(.x, .y) {
      this_sp <- rgdal::readOGR(
        dsn = dirname(.x),
        layer = stringr::str_sub(basename(.x), 1, -5),
        verbose = verbose,
        stringsAsFactors = FALSE,
        encoding = .y,
        use_iconv = TRUE
      )
      if (!rlang::quo_is_null(vars)) this_sp@data <- dplyr::select(this_sp@data, !!vars)
      this_sp
    })
  names(out) <- stringr::str_sub(basename(read_shape_files), 1, -5)
  out <- careful_sp_rbind(out, add_layer_var)

  out
}


# Takes a list of SpatialPolygonsDataFrames, fills in empty columns for you and binds
# them together.
# Throws error if types don't match
careful_sp_rbind <- function(sp_list, add_layer_var) {
  if (is.null(add_layer_var)) add_layer_var <- length(sp_list) > 1
  if (add_layer_var) {
    sp_list <- purrr::imap(sp_list, function(.x, .y) {
      .x@data[["layer"]] <- .y
      .x
    })
  }

  if (length(sp_list) == 1) {
    return(sp_list[[1]])
  } else {
    # Get var info for all columns
    all_var_info <- purrr::map_df(sp_list, .id = "id", function(x) {
      tibble::tibble(name = names(x@data), type = purrr::map(x@data, ~class(.)))
    })

    all_var_info <- dplyr::group_by(all_var_info, .data$name)
    var_type_check <- dplyr::summarize(all_var_info, check = length(unique(.data$type)))
    if (any(var_type_check$check != 1)) {
      stop("Cannot combine shape files because variable types don't match.")
    }
    all_var_info <- dplyr::slice(all_var_info, 1)
    all_var_info <- dplyr::ungroup(all_var_info)
    all_var_info$id <- NULL

    out <- purrr::map(sp_list, function(x) {
      missing_vars <- dplyr::setdiff(all_var_info$name, names(x))
      if (length(missing_vars) == 0) return(x)

      for (vn in missing_vars) {
        vtype <- all_var_info$type[all_var_info$name == vn][[1]]
        if (identical(vtype, "character")) x@data[[vn]] <- NA_character_
        else if (identical(vtype, "numeric")) x@data[[vn]] <- NA_real_
        else stop("Unexpected variable type in shape file.")
      }
      x
    })
    out <- do.call(rbind, out)
  }
  out
}

# Encoding:
# Official spec is that shape files must be latin1. But some GIS software
# add to the spec a cpg file that can specify an encoding.
## NHGIS: Place names in 2010 have accents - and are latin1 encoded,
##        No indication of encoding.
## IPUMSI: Brazil has a cpg file indicating the encoding is ANSI 1252,
##         while China has UTF-8 (but only english characters)
## USA:   Also have cpg files.
## Terrapop: Always UTF-8 (and sometimes has been ruined if the
##           shape file comes from IPUMS International and wasn't
##           UTF-8 to begin with.)
# Current solution: If user specified encoding (or possibly came from
# defaults of functions eg read_terra says UTF-8, but read_nghis says latin1),
# then use that. If not, and a cpg file exists, use that. Else, assume latin1.
determine_encoding <- function(shape_file_vector, encoding = NULL) {
  if (!is.null(encoding)) return(encoding)
  out <- purrr::map_chr(shape_file_vector, function(x) {
    cpg_file <- dir(dirname(x), pattern = "\\.cpg$", ignore.case = TRUE, full.names = TRUE)

    if (length(cpg_file) == 0) return("latin1")

    cpg_text <- readr::read_lines(cpg_file)[1]
    if (stringr::str_detect(cpg_text, "ANSI 1252")) return("CP1252")
    else if (stringr::str_detect(cpg_text, "UTF[[-][|:blank:]]?8")) return("UTF-8")
    else return("latin1")
  })
  out
}


# Gather the programming logic around going from an IPUMS download to
# an unzipped folder with a shape file in it (possibly in a temp folder)
shape_file_prep <- function(shape_file, shape_layer, bind_multiple, shape_temp) {
  # Case 1: Shape file specified is a .zip file or a directory
  shape_is_zip <- tools::file_ext(shape_file) == "zip"
  shape_is_dir <- tools::file_ext(shape_file) == ""
  if (shape_is_zip | shape_is_dir) {
    read_shape_files <- character(0) # Start with empty list of files to read
    # Case 1a: First layer has zip files of shape files within it
    shape_zips <- find_files_in(shape_file, "zip", shape_layer, multiple_ok = TRUE)

    if (!bind_multiple && length(shape_zips) > 1) {
      stop(paste(
        custom_format_text(
          "Multiple shape files found, please set the `bind_multiple` ",
          "argument to `TRUE` to combine them together, or use the ",
          "`shape_layer` argument to specify a single layer.",
          indent = 2, exdent = 2
        ),
        custom_format_text(
          paste(shape_zips, collapse = ", "), indent = 4, exdent = 4
        ),
        sep = "\n"
      ))
    }

    if (length(shape_zips) >= 1) {
      if (shape_is_zip) {
        purrr::walk(shape_zips, function(x) {
          utils::unzip(shape_file, x, exdir = shape_temp)
          utils::unzip(file.path(shape_temp, x), exdir = shape_temp)
        })
      } else {
        purrr::walk(file.path(shape_file, shape_zips), function(x) {
          utils::unzip(x, exdir = shape_temp)
        })
      }
      read_shape_files <- dir(shape_temp, "\\.shp$", full.names = TRUE)
    }

    # Case 1b: First layer has .shp files within it
    if (length(read_shape_files) == 0) {
      shape_shps <- find_files_in(shape_file, "shp", shape_layer, multiple_ok = TRUE)

      if (!bind_multiple && length(shape_shps) > 1) {
        stop(paste(
          custom_format_text(
            "Multiple shape files found, please set the `bind_multiple` ",
            "argument to `TRUE` to combine them together, or use the ",
            "`shape_layer` argument to specify a single layer.",
            indent = 2, exdent = 2
          ),
          custom_format_text(
            paste(shape_shps, collapse = ", "), indent = 4, exdent = 4
          ),
          sep = "\n"
        ))
      }

      if (length(shape_shps) >= 1) {
        read_shape_files <- purrr::map_chr(shape_shps, function(x) {
          shape_shp_files <- paste0(
            stringr::str_sub(x, 1, -4),
            # ignore "sbn", "sbx" because R doesn't use them
            c("shp", "dbf", "prj", "shx")
          )

          if (shape_is_zip) {
            utils::unzip(shape_file, shape_shp_files, exdir = shape_temp)

            # If there is a cpg file (encoding information) extract that
            all_files <- utils::unzip(shape_file, list = TRUE)$Name
            cpg_file <- ".cpg" == tolower(purrr::map_chr(all_files, ipums_file_ext))
            if (any(cpg_file)) {
              utils::unzip(shape_file, all_files[cpg_file], exdir = shape_temp)
            }

            file.path(shape_temp, shape_shp_files[1])
          } else {
            file.path(shape_file, shape_shps)
          }
        })
      }

      if (length(read_shape_files) == 0) {
        stop(call. = FALSE, custom_format_text(
          "Directory/zip file not formatted as expected. Please check your `shape_layer` ",
          "argument or unzip and try again.", indent = 2, exdent = 2
        ))
      }
    }
  }

  # Case 2: Shape file specified is a .shp file
  shape_is_shp <- tools::file_ext(shape_file) == "shp"
  if (shape_is_shp) {
    read_shape_files <- shape_file
  }

  if (!shape_is_zip & !shape_is_dir & !shape_is_shp) {
    stop("Expected `shape_file` to be a directory, .zip or .shp file.")
  }
  read_shape_files
}
