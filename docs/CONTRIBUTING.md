# Development and website maintenance

Run from the unpacked source project in a fresh R session:

``` r

install.packages(c("devtools", "roxygen2", "testthat", "pkgdown"))
devtools::document()
devtools::test()
devtools::check()
pkgdown::build_site()
```

Commit R/, man/, tests/, vignettes/, inst/, README.md, \_pkgdown.yml,
pkgdown/ and docs/. Do not commit private photographs, credentials or
compiled objects. The GitHub Pages branch must publish /docs. The
website is built from the README, vignette and generated reference help.
Do not hand-edit generated HTML. A source tarball excludes the website
and project configuration intentionally. Spot/pixel counts are
subsampling counts; validation of an image algorithm is separate from
biological replication and pigment interpretation.
