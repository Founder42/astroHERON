"""Main CLI dispatcher for SpecFitAssist.

Supports both hierarchical syntax:
    python -m SpecFitAssist spec convert ...
    python -m SpecFitAssist err lin2log ...
and direct shorthand syntax:
    python -m SpecFitAssist convert ...
    python -m SpecFitAssist width ...
    python -m SpecFitAssist redshift ...
    python -m SpecFitAssist lin2log ...
    python -m SpecFitAssist log2lin ...
"""

from __future__ import annotations
import sys
import argparse
from typing import List, Optional

from ._core import AsymValue, render_table, render_json
from .spec_convert import convert_val, calc_line_width, calc_redshift
from .log_error import lin2log, log2lin


def _handle_convert(args: argparse.Namespace) -> None:
    val = float(args.val)
    err_lo = float(args.err_lo) if args.err_lo is not None else 0.0
    err_hi = float(args.err_hi) if args.err_hi is not None else err_lo

    asym_in = AsymValue(value=val, err_lo=err_lo, err_hi=err_hi, unit=args.unit)
    res = convert_val(asym_in, from_unit_str=args.unit, to_unit_str=args.to_unit)

    if args.json:
        print(render_json({
            "input": asym_in.to_dict(),
            "output": res.to_dict(),
        }))
        return

    rows = [
        ("Input Value", asym_in.format_str()),
        ("Converted Value", res.format_str()),
    ]
    notes = [
        f"Domain conversion: '{args.unit}' -> '{res.unit}'",
        "Exact endpoint mapping applied; uncertainty bounds swapped for E <-> lambda."
    ]
    print(render_table("spec convert", rows, notes))


def _handle_width(args: argparse.Namespace) -> None:
    center = float(args.center)
    w_val = float(args.width)
    err_lo = float(args.err_lo) if args.err_lo is not None else 0.0
    err_hi = float(args.err_hi) if args.err_hi is not None else err_lo

    w_asym = AsymValue(value=w_val, err_lo=err_lo, err_hi=err_hi, unit=args.width_unit)
    res = calc_line_width(
        center_val=center,
        center_unit_str=args.center_unit,
        width=w_asym,
        width_unit_str=args.width_unit,
        width_type=args.width_type,
    )

    if args.json:
        print(render_json(res))
        return

    v_sig = AsymValue.from_dict(res["v_sigma"])
    v_fwhm = AsymValue.from_dict(res["v_fwhm"])
    eq_w = AsymValue.from_dict(res["equiv_width_in_center_unit"])

    rows = [
        ("Line Center", f"{center:.5g} {args.center_unit} (= {res['center_in_width_unit']['value']:.5g} {args.width_unit})"),
        ("Input Width", f"{w_asym.format_str()} ({args.width_type.upper()})"),
        ("Equiv Width in Center Unit", eq_w.format_str()),
        ("Sigma Velocity (v_sigma)", v_sig.format_str()),
        ("FWHM Velocity (v_fwhm)", v_fwhm.format_str()),
        ("Resolving Power (R)", f"{res['resolving_power']:.5g}"),
    ]
    notes = [
        "Formula: v = c * (delta / center); unified to width's unit before calculation.",
        f"FWHM / Sigma ratio = 2*sqrt(2*ln(2)) ~ 2.35482.",
    ]
    print(render_table("spec width", rows, notes))


def _handle_redshift(args: argparse.Namespace) -> None:
    rest = float(args.rest)
    obs_val = float(args.obs)
    err_lo = float(args.err_lo) if args.err_lo is not None else 0.0
    err_hi = float(args.err_hi) if args.err_hi is not None else err_lo
    z0 = float(args.z0) if args.z0 is not None else 0.0

    obs_asym = AsymValue(value=obs_val, err_lo=err_lo, err_hi=err_hi, unit=args.unit)
    res = calc_redshift(rest_val=rest, obs=obs_asym, unit_str=args.unit, z0=z0)

    if args.json:
        print(render_json(res))
        return

    z_val = AsymValue.from_dict(res["z"])
    v_cz = AsymValue.from_dict(res["v_nonrel"])
    v_rel = AsymValue.from_dict(res["v_rel"])


    rows = [
        ("Rest Centroid (E0)", f"{rest:.5g} {args.unit}"),
        ("Obs Centroid (E)", obs_asym.format_str()),
        ("Source Redshift (z0)", f"{z0:.6g}"),
        ("Derived Redshift (z)", z_val.format_str(precision=6)),
        ("v = c * z (non-rel)", v_cz.format_str()),
        ("v (relativistic)", v_rel.format_str()),
        ("Rel Discrepancy (Δv/v_rel)", f"{res['delta_v_pct']:+.2f} %"),
        ("Shift Classification", res["shift_type"]),
    ]
    notes = [
        "Exact formula: z = E0 / [E * (1+z0)] - 1 (Energy) or z = λ / [λ0 * (1+z0)] - 1 (Wavelength).",
        "Sign convention: +z = redshift (receding), -z = blueshift (approaching / outflow).",
    ]
    print(render_table("spec redshift", rows, notes))


def _handle_lin2log(args: argparse.Namespace) -> None:
    val = float(args.val)
    a = float(args.a)
    b = float(args.b)
    res = lin2log(val=val, a=a, b=b, mode=args.mode)

    if args.json:
        print(render_json(res))
        return

    log_v = res["log_val"]
    d_lo = res["delta_log_lo"]
    d_hi = res["delta_log_hi"]
    d_lo_str = "inf" if res["is_infinite_lo"] else f"{d_lo:.5g}"

    rows = [
        ("Linear Input", f"{val:.5g} (mode: {args.mode})"),
        ("Linear Bounds", f"[{res['input']['v_lo']:.5g}, {res['input']['v_hi']:.5g}]"),
        ("Log10 Central Value", f"{log_v:.6g}"),
        ("Log10 Error Ranges", f"(-{d_lo_str} / +{d_hi:.5g})"),
        ("Log10 Representation", f"{log_v:.6g} (-{d_lo_str} / +{d_hi:.5g})"),
    ]
    notes = [
        "Base: log10. Output is always error ranges (delta_log_lo, delta_log_hi).",
    ]
    if res["warning"]:
        notes.append(f"WARNING: {res['warning']}")
    print(render_table("err lin2log", rows, notes))


def _handle_log2lin(args: argparse.Namespace) -> None:
    log_val = float(args.log_val)
    a = float(args.a)
    b = float(args.b)
    res = log2lin(log_val=log_val, a=a, b=b, mode=args.mode)

    if args.json:
        print(render_json(res))
        return

    v = res["lin_val"]
    e_lo = res["err_lo"]
    e_hi = res["err_hi"]

    rows = [
        ("Log10 Input", f"{log_val:.6g} (mode: {args.mode})"),
        ("Log10 Bounds", f"[{res['input']['log_lo']:.6g}, {res['input']['log_hi']:.6g}]"),
        ("Linear Central Value", f"{v:.5g}"),
        ("Linear Error Ranges", f"(-{e_lo:.5g} / +{e_hi:.5g})"),
        ("Linear Representation", f"{v:.5g} (-{e_lo:.5g} / +{e_hi:.5g})"),
    ]
    notes = [
        "Base: 10^x. Output is always linear error ranges (err_lo, err_hi).",
    ]
    print(render_table("err log2lin", rows, notes))


import re

class AstroArgumentParser(argparse.ArgumentParser):
    """Custom ArgumentParser recognizing negative numbers in scientific notation as positionals."""
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self._negative_number_matcher = re.compile(r'^-\d+$|^-\d*\.\d+$|^-\d*(\.\d+)?[eE][+-]?\d+$')


def build_parser() -> AstroArgumentParser:
    parser = AstroArgumentParser(
        prog="SpecFitAssist",
        description="High-Energy Astrophysics Spectral Fitting Assistant Toolkit",
    )
    subparsers = parser.add_subparsers(dest="subcommand", help="Module or command", parser_class=AstroArgumentParser)

    # Group: spec
    spec_p = subparsers.add_parser("spec", help="Spectroscopic conversions (E <-> lambda, width, redshift)")
    spec_sub = spec_p.add_subparsers(dest="spec_cmd", parser_class=AstroArgumentParser)

    # Command: convert
    for p in [spec_sub.add_parser("convert", help="Convert energy <-> wavelength"),
              subparsers.add_parser("convert", help="Convert energy <-> wavelength")]:

        p.add_argument("val", type=float, help="Central value (e.g. 6.4)")
        p.add_argument("err_lo", type=float, nargs="?", default=None, help="Lower error (e.g. 0.02 or -0.02)")
        p.add_argument("err_hi", type=float, nargs="?", default=None, help="Upper error (e.g. 0.03)")
        p.add_argument("-u", "--unit", required=True, help="Input unit (e.g. keV, eV, AA, nm)")
        p.add_argument("-t", "--to-unit", default=None, help="Output target unit (default: opposing domain)")
        p.add_argument("--json", action="store_true", help="Output JSON")
        p.set_defaults(func=_handle_convert)

    # Command: width
    for p in [spec_sub.add_parser("width", help="Convert line width / resolution to velocity"),
              subparsers.add_parser("width", help="Convert line width / resolution to velocity")]:
        p.add_argument("center", type=float, help="Line center energy or wavelength")
        p.add_argument("width", type=float, help="Line width value")
        p.add_argument("err_lo", type=float, nargs="?", default=None, help="Lower width error")
        p.add_argument("err_hi", type=float, nargs="?", default=None, help="Upper width error")
        p.add_argument("-cu", "--center-unit", required=True, help="Center unit (e.g. keV)")
        p.add_argument("-wu", "--width-unit", required=True, help="Width unit (e.g. eV, AA)")
        p.add_argument("-wt", "--width-type", default="sigma", choices=["sigma", "fwhm"],
                       help="Type of width (default: sigma)")
        p.add_argument("--json", action="store_true", help="Output JSON")
        p.set_defaults(func=_handle_width)

    # Command: redshift
    for p in [spec_sub.add_parser("redshift", help="Calculate source-corrected redshift and Doppler velocities"),
              subparsers.add_parser("redshift", help="Calculate source-corrected redshift and Doppler velocities")]:
        p.add_argument("-r", "--rest", required=True, type=float, help="Rest-frame line centroid")
        p.add_argument("-o", "--obs", required=True, type=float, help="Observed line centroid")
        p.add_argument("err_lo", type=float, nargs="?", default=None, help="Observed centroid lower error")
        p.add_argument("err_hi", type=float, nargs="?", default=None, help="Observed centroid upper error")
        p.add_argument("-u", "--unit", required=True, help="Spectral unit (e.g. keV or AA)")
        p.add_argument("-z", "--z0", type=float, default=0.0, help="Source cosmological redshift (default: 0.0)")
        p.add_argument("--json", action="store_true", help="Output JSON")
        p.set_defaults(func=_handle_redshift)

    # Group: err
    err_p = subparsers.add_parser("err", help="Logarithmic <-> Linear error and bounds conversions")
    err_sub = err_p.add_subparsers(dest="err_cmd", parser_class=AstroArgumentParser)


    # Command: lin2log
    for p in [err_sub.add_parser("lin2log", help="Convert linear value and errors/bounds to log10"),
              subparsers.add_parser("lin2log", help="Convert linear value and errors/bounds to log10")]:
        p.add_argument("val", type=float, help="Linear central value (must be > 0)")
        p.add_argument("a", type=float, help="Lower error range (mode=errors) or lower bound (mode=bounds)")
        p.add_argument("b", type=float, help="Upper error range (mode=errors) or upper bound (mode=bounds)")
        p.add_argument("-m", "--mode", default="errors", choices=["errors", "bounds"],
                       help="Input format (default: errors)")
        p.add_argument("--json", action="store_true", help="Output JSON")
        p.set_defaults(func=_handle_lin2log)

    # Command: log2lin
    for p in [err_sub.add_parser("log2lin", help="Convert log10 value and errors/bounds to linear"),
              subparsers.add_parser("log2lin", help="Convert log10 value and errors/bounds to linear")]:
        p.add_argument("log_val", type=float, help="Log10 central value")
        p.add_argument("a", type=float, help="Lower log error (mode=errors) or lower log bound (mode=bounds)")
        p.add_argument("b", type=float, help="Upper log error (mode=errors) or upper log bound (mode=bounds)")
        p.add_argument("-m", "--mode", default="errors", choices=["errors", "bounds"],
                       help="Input format (default: errors)")
        p.add_argument("--json", action="store_true", help="Output JSON")
        p.set_defaults(func=_handle_log2lin)

    return parser


def main(argv: Optional[List[str]] = None) -> None:
    parser = build_parser()
    args = parser.parse_args(argv)

    if not hasattr(args, "func"):
        parser.print_help()
        sys.exit(1)

    try:
        args.func(args)
    except Exception as e:
        sys.stderr.write(f"[ERROR] {str(e)}\n")
        sys.exit(1)


if __name__ == "__main__":
    main()
