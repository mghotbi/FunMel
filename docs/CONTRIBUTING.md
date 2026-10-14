# Contributing to FunMel

FunMel’s source repository is <https://github.com/mghotbi/FunMel>.
Report reproducible problems through
<https://github.com/mghotbi/FunMel/issues>. Include the package version,
[`sessionInfo()`](https://rdrr.io/r/utils/sessionInfo.html), relevant
metadata structure and an example that can be shared. Avoid posting
private images or credentials.

## Development setup

Work from the package root, where DESCRIPTION is located. Install the
package development tools and declared dependencies:

``` r

install.packages(c("devtools", "testthat", "knitr", "rmarkdown", "png", "withr"))
devtools::install_deps(dependencies=TRUE)
devtools::load_all()
```

Source compilation requires an appropriate compiler and the system
libraries used by magick. Installation instructions are in the README.

## Checks before committing

``` r

devtools::document() # when changing exported functions or roxygen comments
devtools::test()
devtools::check()
```

Alternatively, build and check from a terminal:

``` sh
R CMD build .
R CMD check --no-manual FunMel_0.3.8.tar.gz
```

Inspect warnings, notes and model/image diagnostics; successful software
checks do not establish biological segmentation accuracy or validate a
new assay. Retain matched-control rules and independent plate IDs in any
new examples. For algorithm changes, rerun the simulation validation
script and inspect representative photograph masks. See
inst/guides/RELEASE_CHECKLIST.md for scope.

## Source files and Git

Track authored R/, src/, man/, vignettes/, tests/, inst/, README.md,
NEWS.md, DESCRIPTION and LICENSE. The project includes .gitignore and
.Rbuildignore; these development files are normally excluded from the
installed package. Exclude native compiled objects, local credentials,
private photographs and generated analysis folders. Bundled example and
validation assets are separate from private working folders and should
be reviewed before public distribution.

## Documentation website

``` r

install.packages("pkgdown")
pkgdown::build_site()
```

pkgdown builds the website from the README, generated reference help and
vignettes. It is a development tool, not an analysis dependency.
Configure website URLs and hosting for the repository; review the docs/
ignore rule if using a hosting setup that requires generated files in
Git. Generated website files are not included in this source bundle.
