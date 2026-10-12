"""SpecFitAssist: High-Energy Astrophysics Spectral Fitting Assistant Toolkit."""

from ._core import (
    HC_KEV_AA,
    C_KMS,
    FWHM_SIGMA_RATIO,
    AsymValue,
    parse_unit,
    propagate_bounds,
    render_table,
    render_json,
)
from .spec_convert import convert_val, calc_line_width, calc_redshift, calc_shift
from .log_error import lin2log, log2lin

__all__ = [
    "HC_KEV_AA",
    "C_KMS",
    "FWHM_SIGMA_RATIO",
    "AsymValue",
    "parse_unit",
    "propagate_bounds",
    "render_table",
    "render_json",
    "convert_val",
    "calc_line_width",
    "calc_redshift",
    "calc_shift",
    "lin2log",
    "log2lin",
]

