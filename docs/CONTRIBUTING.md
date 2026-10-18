# Contributing to FunMel

Report bugs with a reproducible example, the FunMel version and
[`sessionInfo()`](https://rdrr.io/r/utils/sessionInfo.html).

From the package source folder, run:

``` r

devtools::document()
testthat::test_local()
devtools::check()
```

Build the documentation website with:

``` r

source("inst/scripts/build_website.R")
```

Check the tutorials, treatment/control matching, metadata preservation
and figure exports before submitting changes. Keep private data and
compiled objects out of Git.
