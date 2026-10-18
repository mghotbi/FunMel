# Open an existing experiment in its current folder

Reconnects internal paths after a complete project folder is moved.
External photograph locations are retained. Loading never edits metadata
or measurements.

## Usage

``` r
load_experiment(path = NULL)
```

## Arguments

- path:

  Project folder, project.rds, or saved analysis beside project.rds.
  NULL opens a chooser; select project.rds.

## Value

A funmel_project with paths relative to its current folder resolved.

## Examples

``` r
if (FALSE) { # \dontrun{
project <- load_experiment() # Select project.rds in its current folder.
result <- read_experiment(project)
head(result$spots)
plot_treatment_comparison(project)
} # }
```
