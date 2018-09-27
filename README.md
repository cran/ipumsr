
<!-- README.md is generated from README.Rmd. Please edit that file -->

# ipumsr <img src="tools/logo.png" align="right" height="149" width="128.5"/>

[![Project
Status:Active](http://www.repostatus.org/badges/latest/active.svg)](http://www.repostatus.org/#active)
[![CRAN\_Status\_Badge](http://www.r-pkg.org/badges/version/ipumsr)](http://cran.r-project.org/web/packages/ipumsr)
[![Travis-CI Build
Status](https://travis-ci.org/mnpopcenter/ipumsr.svg?branch=master)](https://travis-ci.org/mnpopcenter/ipumsr)
[![AppVeyor Build
Status](https://ci.appveyor.com/api/projects/status/github/mnpopcenter/ipumsr?branch=master&svg=true)](https://ci.appveyor.com/project/mnpopcenter/ipumsr)
[![Coverage
Status](https://codecov.io/gh/mnpopcenter/ipumsr/master.svg)](https://codecov.io/github/mnpopcenter/ipumsr?branch=master)

The ipumsr package helps import IPUMS extracts from the [IPUMS
website](https://www.ipums.org) into R. IPUMS provides census and survey
data from around the world integrated across time and space. IPUMS
integration and documentation makes it easy to study change, conduct
comparative research, merge information across data types, and analyze
individuals within family and community context. Data and services are
available free of charge.

The ipumsr package can be installed by running the following command:

``` r
install.packages("ipumsr")
```

Or, you can install the development version using the following
commands:

``` r
if (!require(devtools)) install.packages("devtools")

devtools::install_github("mnpopcenter/ipumsr")
```

## Learning More

The vignettes are a great place to learn more about ipumsr and IPUMS
data:

  - For a general introduction see the
    [**ipums**](https://cran.r-project.org/package=ipumsr/vignettes/ipums.html)
    vignette.

  - For a more detailed look at some of the features, see these
    vignettes:
    
      - [**value-labels**](https://cran.r-project.org/package=ipumsr/vignettes/value-labels.html)
          - Provides guidance for using the value labels provided by
            IPUMS
      - [**ipums-geography**](https://cran.r-project.org/package=ipumsr/vignettes/ipums-geography.html)
          - Provides guidance for using R as GIS tool with IPUMS data
      - **ipums-bigdata**
          - How to handle large IPUMS data extracts and examples of
            using the chunked versions of microdata reading functions.

  - Or to see examples of how to work through data from particular
    projects, see these
        vignettes:
    
      - [**ipums-cps**](https://cran.r-project.org/package=ipumsr/vignettes/ipums-cps.html)
          - An example of using CPS data with the ipumsr
        package
      - [**ipums-nhgis**](https://cran.r-project.org/package=ipumsr/vignettes/ipums-nhgis.html)
          - An example of using NHGIS data with the ipumsr
        package
      - [**ipums-terra**](https://cran.r-project.org/package=ipumsr/vignettes/ipums-terra.html)
          - An example of using IPUMS Terra Data with the ipumsr package
      - And more project-specific examples are available on the Data
        Training Exercises section of the [IPUMS
        website](https://www.ipums.org/exercises.shtml).

You can access them with the `vignette()` command (eg
`vignette("value-labels")`).

If you are installing from github and want the vignettes, you’ll need to
run the following commands first:

``` r
devtools::install_github("mnpopcenter/ipumsr/ipumsexamples")
devtools::install_github("mnpopcenter/ipumsr", build_vignettes = TRUE)
```

## Development

We greatly appreciate bug reports, suggestions or pull requests. They
can be submitted via github, or by email to <ipums@umn.edu>

Before contributing, please be sure to read the [Contributing
Guidelines](https://github.com/mnpopcenter/ipumsr/blob/master/CONTRIBUTING.md)
and the [Code of
Conduct](https://github.com/mnpopcenter/ipumsr/blob/master/CONDUCT.md).
