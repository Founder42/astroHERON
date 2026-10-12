"""Logarithmic (log10) and linear error/bounds conversions."""

from __future__ import annotations
import math
from typing import Dict, Any

try:
    from ._core import AsymValue, render_table, render_json
except ImportError:
    from _core import AsymValue, render_table, render_json




def lin2log(
    val: float,
    a: float,
    b: float,
    mode: str = "errors",
) -> Dict[str, Any]:
    """
    Convert linear value and uncertainties to log10 space.
    
    Parameters:
    -----------
    val : float
        Linear central value (must be > 0).
    a : float
        In 'errors' mode: lower error range (delta_lo). Automatically converted to abs(a).
        In 'bounds' mode: absolute lower bound (val_lo).
    b : float
        In 'errors' mode: upper error range (delta_hi).
        In 'bounds' mode: absolute upper bound (val_hi).
    mode : str
        'errors' or 'bounds'. Default: 'errors'.
        
    Returns:
    --------
    Dict containing log10 central value and log10 error ranges (delta_log_lo, delta_log_hi).
    Output is ALWAYS error ranges, per user specification.
    """
    if val <= 0:
        raise ValueError(f"Linear central value must be strictly positive (got {val} <= 0).")

    mode_clean = mode.lower().strip()
    if mode_clean not in ("errors", "bounds"):
        raise ValueError(f"Mode must be 'errors' or 'bounds', got '{mode}'.")

    if mode_clean == "errors":
        err_lo = abs(float(a))
        err_hi = abs(float(b))
        v_lo = val - err_lo
        v_hi = val + err_hi
    else:
        v_lo = float(a)
        v_hi = float(b)
        if not (v_lo < val < v_hi):
            raise ValueError(
                f"In 'bounds' mode, must satisfy val_lo < val < val_hi (got {v_lo} < {val} < {v_hi} is False)."
            )
        err_lo = val - v_lo
        err_hi = v_hi - val

    log_val = math.log10(val)
    log_hi = math.log10(v_hi)
    delta_log_hi = log_hi - log_val

    is_infinite_lo = False
    warning_msg = None

    if v_lo <= 0:
        delta_log_lo = float("inf")
        is_infinite_lo = True
        warning_msg = f"Linear lower bound ({v_lo:.5g}) <= 0; log10 lower error range extends to -inf."
    else:
        log_lo = math.log10(v_lo)
        delta_log_lo = log_val - log_lo

    return {
        "input": {
            "val": val,
            "a": a,
            "b": b,
            "mode": mode_clean,
            "err_lo": err_lo,
            "err_hi": err_hi,
            "v_lo": v_lo,
            "v_hi": v_hi,
        },
        "log_val": log_val,
        "delta_log_lo": delta_log_lo,
        "delta_log_hi": delta_log_hi,
        "is_infinite_lo": is_infinite_lo,
        "warning": warning_msg,
    }


def log2lin(
    log_val: float,
    a: float,
    b: float,
    mode: str = "errors",
) -> Dict[str, Any]:
    """
    Convert log10 value and uncertainties to linear space.
    
    Parameters:
    -----------
    log_val : float
        Central value in log10 space.
    a : float
        In 'errors' mode: lower log error range (delta_log_lo). Automatically converted to abs(a).
        In 'bounds' mode: absolute lower log bound (log_val_lo).
    b : float
        In 'errors' mode: upper log error range (delta_log_hi).
        In 'bounds' mode: absolute upper log bound (log_val_hi).
    mode : str
        'errors' or 'bounds'. Default: 'errors'.
        
    Returns:
    --------
    Dict containing linear central value and linear error ranges (err_lo, err_hi).
    Output is ALWAYS error ranges, per user specification.
    """
    mode_clean = mode.lower().strip()
    if mode_clean not in ("errors", "bounds"):
        raise ValueError(f"Mode must be 'errors' or 'bounds', got '{mode}'.")

    if mode_clean == "errors":
        delta_log_lo = abs(float(a))
        delta_log_hi = abs(float(b))
        log_lo = log_val - delta_log_lo
        log_hi = log_val + delta_log_hi
    else:
        log_lo = float(a)
        log_hi = float(b)
        if not (log_lo < log_val < log_hi):
            raise ValueError(
                f"In 'bounds' mode, must satisfy log_lo < log_val < log_hi (got {log_lo} < {log_val} < {log_hi} is False)."
            )
        delta_log_lo = log_val - log_lo
        delta_log_hi = log_hi - log_val

    lin_val = 10.0 ** log_val
    lin_lo = 10.0 ** log_lo
    lin_hi = 10.0 ** log_hi

    err_lo = lin_val - lin_lo
    err_hi = lin_hi - lin_val

    return {
        "input": {
            "log_val": log_val,
            "a": a,
            "b": b,
            "mode": mode_clean,
            "delta_log_lo": delta_log_lo,
            "delta_log_hi": delta_log_hi,
            "log_lo": log_lo,
            "log_hi": log_hi,
        },
        "lin_val": lin_val,
        "err_lo": err_lo,
        "err_hi": err_hi,
        "lin_lo": lin_lo,
        "lin_hi": lin_hi,
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

