# Analyze all photographs in a prepared experiment

Reads the editable project metadata, applies the fungal or control
layout per row, writes QC images and saves measurements. Review flags
are reset for this new analysis; coefficients are withheld until
finish_experiment().

## Usage

``` r
run_experiment(project, n_spots = NULL, spot_radius_mm = 0.5, ...)
```

## Arguments

- project:

  A funmel_project, its current folder, project.rds, or a saved analysis
  beside project.rds. Use load_experiment() after moving a project.

- n_spots:

  Optional number of circular spots per target colony; NULL uses
  whole-colony pixels only. Spot and whole-colony results are kept
  separate.

- spot_radius_mm:

  Radius of each optional circular ROI (mm).

- ...:

  Other analyze_plate() settings, such as dish_diameter_mm and max_dim.

## Value

Batch result saved to image_analysis.rds and CSV tables.

## Details

Dish diameter and any supplied pixel scale must be finite positive
numeric scalars. Invalid settings stop before image processing or
changes to project QC flags. Missing project metadata must be restored
or its recorded path corrected. A batch with failed images saves error
reports and warns; it does not report success. Inspect result\$failed
and resolve every failed image before finalization.
