# Extract and locate the photographs required by metadata

Checks a selected ZIP before extraction, ignores Mac resource-fork
files, resolves extra enclosing folders and requires exactly one path
per expected photograph. Existing extraction folders are not used as
evidence that this ZIP contains an image. Missing/ambiguous files stop
before image analysis.

## Usage

``` r
prepare_photo_archive(photo_zip, metadata, photo_root)
```

## Arguments

- photo_zip:

  Path to the original ZIP of plate photographs.

- metadata:

  Data frame containing file and optionally relative_file. relative_file
  helps distinguish duplicate basenames in nested folders.

- photo_root:

  Parent directory for a fresh extraction subfolder.

## Value

Character vector of existing absolute image paths, in metadata order.
