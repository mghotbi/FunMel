# FunMel: plate-image measurements and matched-control assessment

FunMel retains the layout-based image workflow originally developed as
MycoHalo. It measures four expected Zymoseptoria colonies using their
detected boundaries, CIELAB colour, shape and edge-to-centre profiles.
It does not identify organisms from photographs. Central-model class
labels require biological interpretation and quality-control review.

## Details

Metadata links each independent plate to its own control set. Use
[`validate_metadata()`](https://mghotbi.github.io/FunMel/reference/validate_metadata.md),
[`analyze_plates()`](https://mghotbi.github.io/FunMel/reference/analyze_plates.md),
[`melanization_coefficient()`](https://mghotbi.github.io/FunMel/reference/melanization_coefficient.md)
and
[`assess_experiment()`](https://mghotbi.github.io/FunMel/reference/assess_experiment.md)
in sequence. The mixed model uses lme4 with lmerTest Satterthwaite
contrasts; descriptions remain available when inference is unsupported.
See vignette('FunMel') and
[`example_experiment()`](https://mghotbi.github.io/FunMel/reference/example_experiment.md).

## See also

Useful links:

- <https://github.com/mghotbi/FunMel>

- Report bugs at <https://github.com/mghotbi/FunMel/issues>

## Author

**Maintainer**: Mitra Ghotbi <mitra.ghotbi@gmail.com>
([ORCID](https://orcid.org/0000-0001-9185-9993))

Authors:

- Mitra Ghotbi <mitra.ghotbi@gmail.com>
  ([ORCID](https://orcid.org/0000-0001-9185-9993))
