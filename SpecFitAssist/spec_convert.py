"""Spectroscopy conversions, line widths, and redshift calculators."""

from __future__ import annotations
import math
from typing import Optional, Dict, Any, Tuple

import astropy.units as u

try:
    from ._core import (
        HC_KEV_AA,
        C_KMS,
        FWHM_SIGMA_RATIO,
        AsymValue,
        parse_unit,
        is_energy_unit,
        is_wavelength_unit,
        propagate_bounds,
        render_table,
        render_json,
    )
except ImportError:
    from _core import (
        HC_KEV_AA,
        C_KMS,
        FWHM_SIGMA_RATIO,
        AsymValue,
        parse_unit,
        is_energy_unit,
        is_wavelength_unit,
        propagate_bounds,
        render_table,
        render_json,
    )



def convert_val(x: AsymValue, from_unit_str: str, to_unit_str: Optional[str] = None) -> AsymValue:
    """
    Convert an energy or wavelength (with optional asymmetric errors) to the opposing or specified unit.
    Uses exact endpoint mapping; uncertainties are swapped when converting between energy and wavelength.
    """
    from_u = parse_unit(from_unit_str)

    if to_unit_str is None:
        if is_energy_unit(from_u):
            to_u = u.AA
        elif is_wavelength_unit(from_u):
            to_u = u.keV
        else:
            raise ValueError(f"Unit '{from_unit_str}' is neither energy nor wavelength.")
    else:
        to_u = parse_unit(to_unit_str)

    # 1. Same physical domain: Energy -> Energy
    if is_energy_unit(from_u) and is_energy_unit(to_u):
        factor = float((1.0 * from_u).to(to_u).value)
        return propagate_bounds(lambda v: v * factor, x, unit=to_u.to_string())

    # 2. Same physical domain: Wavelength -> Wavelength
    if is_wavelength_unit(from_u) and is_wavelength_unit(to_u):
        factor = float((1.0 * from_u).to(to_u).value)
        return propagate_bounds(lambda v: v * factor, x, unit=to_u.to_string())

    # 3. Cross-domain: Energy -> Wavelength
    if is_energy_unit(from_u) and is_wavelength_unit(to_u):
        def f_e2w(val_e: float) -> float:
            e_kev = (val_e * from_u).to(u.keV).value
            lam_aa = HC_KEV_AA / e_kev
            return float((lam_aa * u.AA).to(to_u).value)

        return propagate_bounds(f_e2w, x, unit=to_u.to_string(), check_positive=True)

    # 4. Cross-domain: Wavelength -> Energy
    if is_wavelength_unit(from_u) and is_energy_unit(to_u):
        def f_w2e(val_w: float) -> float:
            lam_aa = (val_w * from_u).to(u.AA).value
            e_kev = HC_KEV_AA / lam_aa
            return float((e_kev * u.keV).to(to_u).value)

        return propagate_bounds(f_w2e, x, unit=to_u.to_string(), check_positive=True)

    raise ValueError(f"Incompatible unit conversion from '{from_unit_str}' to '{to_unit_str}'.")


def calc_line_width(
    center_val: float,
    center_unit_str: str,
    width: AsymValue,
    width_unit_str: str,
    width_type: str = "sigma",
) -> Dict[str, Any]:
    """
    Calculate line broadening velocity (sigma_v and FWHM_v) and resolution R.
    
    Rule:
    - Default width_type is 'sigma' (per user specification).
    - Always unifies line center into the width's unit first, performs exact calculations,
      and also converts equivalent width back into the center's unit.
    """
    w_type = width_type.lower().strip()
    if w_type not in ("sigma", "fwhm"):
        raise ValueError(f"width_type must be 'sigma' or 'fwhm', got '{width_type}'.")

    c_u = parse_unit(center_unit_str)
    w_u = parse_unit(width_unit_str)

    if center_val <= 0:
        raise ValueError("Line center must be strictly positive.")
    if width.value <= 0:
        raise ValueError("Line width must be strictly positive.")

    # 1. Unify line center to width's unit
    if (is_energy_unit(c_u) and is_energy_unit(w_u)) or (is_wavelength_unit(c_u) and is_wavelength_unit(w_u)):
        center_in_w = float((center_val * c_u).to(w_u).value)
    elif is_energy_unit(c_u) and is_wavelength_unit(w_u):
        c_kev = (center_val * c_u).to(u.keV).value
        lam_aa = HC_KEV_AA / c_kev
        center_in_w = float((lam_aa * u.AA).to(w_u).value)
    elif is_wavelength_unit(c_u) and is_energy_unit(w_u):
        c_aa = (center_val * c_u).to(u.AA).value
        e_kev = HC_KEV_AA / c_aa
        center_in_w = float((e_kev * u.keV).to(w_u).value)
    else:
        raise ValueError("Invalid dimensional combination for center and width units.")

    # 2. Velocity calculations
    # If width is sigma, v_sigma = c * (sigma / center)
    # If width is fwhm, v_fwhm = c * (fwhm / center), v_sigma = v_fwhm / 2.35482
    if w_type == "sigma":
        f_v_sigma = lambda w: C_KMS * (w / center_in_w)
        f_v_fwhm = lambda w: C_KMS * ((w * FWHM_SIGMA_RATIO) / center_in_w)
        r_power = center_in_w / (width.value * FWHM_SIGMA_RATIO)
    else:
        f_v_sigma = lambda w: C_KMS * ((w / FWHM_SIGMA_RATIO) / center_in_w)
        f_v_fwhm = lambda w: C_KMS * (w / center_in_w)
        r_power = center_in_w / width.value

    v_sigma = propagate_bounds(f_v_sigma, width, unit="km/s")
    v_fwhm = propagate_bounds(f_v_fwhm, width, unit="km/s")

    # 3. Calculate equivalent width in center's original unit
    # Map (width / center_in_w) ratio back to center unit
    # For small fractional width dw/w:
    # in center unit, dw_center ≈ center_val * (dw / center_in_w)
    # More precisely:
    if is_energy_unit(c_u) == is_energy_unit(w_u):
        equiv_width_center = propagate_bounds(
            lambda w: float((w * w_u).to(c_u).value), width, unit=c_u.to_string()
        )
    else:
        # Cross-domain: center E0, width in lambda dL
        # E_lo = hc / (L0 + dL_hi), E_hi = hc / (L0 - dL_lo)
        def f_cross(w: float) -> float:
            ratio = w / center_in_w
            return center_val * ratio

        equiv_width_center = propagate_bounds(f_cross, width, unit=c_u.to_string())

    return {
        "center_input": {"value": center_val, "unit": c_u.to_string()},
        "center_in_width_unit": {"value": center_in_w, "unit": w_u.to_string()},
        "width_input": width.to_dict(),
        "width_type": w_type,
        "v_sigma": v_sigma.to_dict(),
        "v_fwhm": v_fwhm.to_dict(),
        "resolving_power": r_power,
        "equiv_width_in_center_unit": equiv_width_center.to_dict(),
    }


def calc_redshift(
    rest_val: float,
    obs: AsymValue,
    unit_str: str,
    z0: float = 0.0,
) -> Dict[str, Any]:
    """
    Calculate source-corrected line redshift and velocities (cz and relativistic Doppler).
    
    Formula (Exact form per decision):
      For Energy:     z = rest / [obs * (1 + z0)] - 1
      For Wavelength: z = obs / [rest * (1 + z0)] - 1
      Non-relativistic velocity: v_nonrel = c * z
      Relativistic Doppler:      v_rel    = c * ((1+z)^2 - 1) / ((1+z)^2 + 1)
      
    Signs:
      z > 0: Redshift (receding / away, +v)
      z < 0: Blueshift (approaching / outflow, -v)
    """
    u_obj = parse_unit(unit_str)
    if rest_val <= 0:
        raise ValueError("Rest-frame line centroid must be strictly positive.")
    if obs.value <= 0:
        raise ValueError("Observed line centroid must be strictly positive.")
    if (1.0 + z0) <= 0:
        raise ValueError(f"1 + z0 must be positive (got z0 = {z0}).")

    is_energy = is_energy_unit(u_obj)
    is_wave = is_wavelength_unit(u_obj)
    if not (is_energy or is_wave):
        raise ValueError(f"Unit '{unit_str}' is neither energy nor wavelength.")

    # Exact redshift function
    if is_energy:
        f_z = lambda e: (rest_val / (e * (1.0 + z0))) - 1.0
    else:
        f_z = lambda lam: (lam / (rest_val * (1.0 + z0))) - 1.0

    z_asym = propagate_bounds(f_z, obs, unit="", check_positive=True)

    # Velocity functions
    f_v_nonrel = lambda val: C_KMS * f_z(val)
    f_v_rel = lambda val: C_KMS * (((1.0 + f_z(val)) ** 2 - 1.0) / ((1.0 + f_z(val)) ** 2 + 1.0))

    v_nonrel_asym = propagate_bounds(f_v_nonrel, obs, unit="km/s", check_positive=True)
    v_rel_asym = propagate_bounds(f_v_rel, obs, unit="km/s", check_positive=True)

    rel_diff_pct = 0.0
    if abs(v_rel_asym.value) > 1e-9:
        rel_diff_pct = ((v_nonrel_asym.value - v_rel_asym.value) / v_rel_asym.value) * 100.0

    shift_type = "redshift (receding)" if z_asym.value >= 0 else "blueshift (outflow)"

    return {
        "rest": {"value": rest_val, "unit": u_obj.to_string()},
        "obs": obs.to_dict(),
        "z0": z0,
        "is_energy": is_energy,
        "z": z_asym.to_dict(),
        "v_nonrel": v_nonrel_asym.to_dict(),
        "v_rel": v_rel_asym.to_dict(),
        "delta_v_pct": rel_diff_pct,
        "shift_type": shift_type,
    }


if __name__ == "__main__":
    import sys
    try:
        from .__main__ import main
    except ImportError:
        import os
        sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
        from SpecFitAssist.__main__ import main
    main()

