% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/api_helpers.R
\name{set_ipums_api_key}
\alias{set_ipums_api_key}
\title{Set your IPUMS API key}
\usage{
set_ipums_api_key(api_key, save = overwrite, overwrite = FALSE, unset = FALSE)
}
\arguments{
\item{api_key}{API key associated with your user account.}

\item{save}{If \code{TRUE}, save the key for use in future
sessions by adding it to the \code{.Renviron} file in your home directory.
Defaults to \code{FALSE}, unless \code{overwrite = TRUE}.}

\item{overwrite}{If \code{TRUE}, overwrite any existing value of
\code{IPUMS_API_KEY} in the \code{.Renviron} file with the provided \code{api_key}.
Defaults to \code{FALSE}.}

\item{unset}{If \code{TRUE}, remove the existing value of \code{IPUMS_API_KEY}
from the environment and the \code{.Renviron} file in your home directory.}
}
\value{
The value of \code{api_key}, invisibly.
}
\description{
Set your IPUMS API key as the value associated with the \code{IPUMS_API_KEY}
environment variable.

The key can be stored for the duration of your session or for future
sessions. If saved for future sessions, it is added to the \code{.Renviron}
file in your home directory. If you choose to save your key to \code{.Renviron},
this function will create a backup copy of the file before modifying.

This function is modeled after the \code{census_api_key()} function
from \href{https://walker-data.com/tidycensus/}{tidycensus}.

Learn more about the IPUMS API in \code{vignette("ipums-api")}.
}
\seealso{
\code{\link[=set_ipums_default_collection]{set_ipums_default_collection()}} to set a default collection.
}
