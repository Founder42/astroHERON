"""Core utilities, constants, data structures, and formatting for SpecFitAssist."""

from __future__ import annotations
import math
import json
from dataclasses import dataclass
from typing import Callable, Sequence, Tuple, Optional, Any, Dict

import astropy.constants as const
import astropy.units as u

# Authoritative physical constants (CODATA 2018 via astropy)
HC_KEV_AA: float = float((const.h * const.c).to(u.keV * u.AA).value)   # ~12.398419843320026 keV * AA
C_KMS: float = float(const.c.to(u.km / u.s).value)                     # ~299792.458 km/s
FWHM_SIGMA_RATIO: float = 2.0 * math.sqrt(2.0 * math.log(2.0))        # ~2.3548200450309493


_UNIT_ALIASES = {
    "a": u.AA,
    "aa": u.AA,
    "angstrom": u.AA,
    "ang": u.AA,
    "armstrong": u.AA,
    "å": u.AA,
    "kev": u.keV,
    "ev": u.eV,
    "mev": u.MeV,
    "gev": u.GeV,
    "nm": u.nm,
    "um": u.micron,
    "micron": u.micron,
    "cm": u.cm,
    "m": u.m,
    "km/s": u.km / u.s,
    "kms": u.km / u.s,
}


def parse_unit(unit_str: str) -> u.Unit:
    """Parse unit string with case-insensitivity and support for astronomy aliases."""
    s = unit_str.strip()
    s_lower = s.lower()
    if s_lower in _UNIT_ALIASES:
        return _UNIT_ALIASES[s_lower]
    return u.Unit(s)



def is_energy_unit(unit_obj: u.Unit) -> bool:
    """Check whether a unit is dimensionally an energy."""
    return unit_obj.is_equivalent(u.eV)


def is_wavelength_unit(unit_obj: u.Unit) -> bool:
    """Check whether a unit is dimensionally a length (wavelength)."""
    return unit_obj.is_equivalent(u.m)


@dataclass
class AsymValue:
    """Represents a central value with asymmetric uncertainty bounds (value - err_lo, value + err_hi)."""
    value: float
    err_lo: float = 0.0
    err_hi: float = 0.0
    unit: str = ""

    def __post_init__(self) -> None:
        self.value = float(self.value)
        # Requirement: Take absolute value of lower bound error if user enters negative
        self.err_lo = abs(float(self.err_lo))
        self.err_hi = abs(float(self.err_hi))

    @property
    def has_err(self) -> bool:
        return self.err_lo > 0.0 or self.err_hi > 0.0

    @property
    def bounds(self) -> Tuple[float, float]:
        """Return (lower_bound, upper_bound)."""
        return (self.value - self.err_lo, self.value + self.err_hi)

    def to_dict(self) -> Dict[str, Any]:
        return {
            "value": self.value,
            "err_lo": self.err_lo,
            "err_hi": self.err_hi,
            "bounds": list(self.bounds),
            "unit": self.unit,
            "has_err": self.has_err,
        }

    @classmethod
    def from_dict(cls, d: Dict[str, Any]) -> AsymValue:
        """Construct an AsymValue safely ignoring auxiliary keys like 'bounds' and 'has_err'."""
        return cls(
            value=float(d["value"]),
            err_lo=float(d.get("err_lo", 0.0)),
            err_hi=float(d.get("err_hi", 0.0)),
            unit=str(d.get("unit", "")),
        )


    def format_str(self, precision: int = 5) -> str:
        fmt = f"{{:.{precision}g}}"
        val_str = fmt.format(self.value)
        unit_str = f" {self.unit}" if self.unit else ""
        if self.has_err:
            lo_str = fmt.format(self.err_lo)
            hi_str = fmt.format(self.err_hi)
            return f"{val_str} (-{lo_str} / +{hi_str}){unit_str}"
        return f"{val_str}{unit_str}"


def propagate_bounds(
    f: Callable[[float], float],
    x: AsymValue,
    unit: str = "",
    check_positive: bool = False,
) -> AsymValue:
    """
    Propagate uncertainties of a monotonic function f through exact endpoint mapping.
    
    If f is decreasing (e.g. lambda = hc / E), the mapped bounds are automatically swapped:
    y_a = f(x - err_lo), y_b = f(x + err_hi)
    min_y = min(y_a, y_b), max_y = max(y_a, y_b)
    new_err_lo = y_0 - min_y
    new_err_hi = max_y - y_0
    """
    if check_positive and (x.value - x.err_lo) <= 0:
        raise ValueError(
            f"Physical lower bound must be strictly positive for this transformation (got {x.value - x.err_lo} <= 0)."
        )

    y0 = f(x.value)
    if not x.has_err:
        return AsymValue(value=y0, err_lo=0.0, err_hi=0.0, unit=unit)

    val_lo, val_hi = x.bounds
    if check_positive and val_lo <= 0:
        raise ValueError(
            f"Lower bound must be strictly positive (got {val_lo} <= 0)."
        )

    ya = f(val_lo)
    yb = f(val_hi)

    lo = min(ya, yb)
    hi = max(ya, yb)

    return AsymValue(
        value=y0,
        err_lo=abs(y0 - lo),
        err_hi=abs(hi - y0),
        unit=unit,
    )


def render_table(title: str, rows: Sequence[Tuple[str, str]], notes: Optional[Sequence[str]] = None) -> str:
    """Format output rows into an attractive ASCII/Unicode box table."""
    # Determine column widths
    label_w = max(len(r[0]) for r in rows) if rows else 12
    label_w = max(label_w, 12)
    val_w = max(len(r[1]) for r in rows) if rows else 20
    val_w = max(val_w, 20)

    # Box width
    inner_w = max(label_w + val_w + 3, len(title) + 6)
    if notes:
        for n in notes:
            inner_w = max(inner_w, len(n) + 2)

    val_w = inner_w - label_w - 3

    lines = []
    # Header
    title_part = f" SpecFitAssist · {title} "
    lines.append(f"┌─{title_part}" + "─" * max(0, inner_w - len(title_part) - 1) + "┐")

    # Data rows
    for label, val in rows:
        pad_lbl = label.ljust(label_w)
        pad_val = val.ljust(val_w)
        lines.append(f"│ {pad_lbl} : {pad_val} │")

    # Notes section
    if notes:
        lines.append("├" + "─" * inner_w + "┤")
        for n in notes:
            lines.append(f"│ {n.ljust(inner_w - 2)} │")

    lines.append("└" + "─" * inner_w + "┘")
    return "\n".join(lines)


def render_json(data: Dict[str, Any]) -> str:
    """Output machine-readable JSON string."""
    return json.dumps(data, indent=2, ensure_ascii=False)
