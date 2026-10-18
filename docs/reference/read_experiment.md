# Read saved experiment tables

Projects store filenames, whereas saved analysis objects contain
measurement tables such as result\$spots. No images are processed and no
metadata is edited.

## Usage

``` r
read_experiment(project, finalized = FALSE)
```

## Arguments

- project:

  Project object, current project folder, project.rds, or analysis RDS.

- finalized:

  TRUE reads finalized results from a project. FALSE prefers original
  measurements and falls back to finalized measurements if needed. An
  explicitly selected analysis RDS is read as supplied in either mode.

## Value

Saved batch result with colonies, plates, spots and metadata.

## Examples

``` r
if (FALSE) { # \dontrun{
project <- load_experiment()
result <- read_experiment(project)
head(result$spots)
} # }
```
