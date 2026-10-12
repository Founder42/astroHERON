# SpecFitAssist: High-Energy Astrophysics Spectral Fitting Assistant

`SpecFitAssist` is a high-precision, deterministic toolkit for common mathematical and physical transformations in high-energy astrophysics spectroscopy (X-ray, UV, optical).

It integrates:
1. **Deterministic Python 3 CLI & API**: Built with `astropy.units` and `astropy.constants` (CODATA 2018).
2. **Deterministic Copilot Skill (`SKILL.md`)**: Enables natural language assistance with **Zero Mental Arithmetic**, delegating all calculations to the Python engine.

---

## 1. Physical Formulations & Principles

### A. Energy ↔ Wavelength Conversion (`convert`)
$$\lambda_0 = \frac{hc}{E_0}, \qquad E_0 = \frac{hc}{\lambda_0}$$
where $hc \approx 12.398419843\text{ keV}\cdot\text{\AA}$.
Because $\lambda(E)$ is strictly monotonic decreasing, asymmetric uncertainty ranges $(x_0, -\sigma_{\rm lo}, +\sigma_{\rm hi})$ undergo exact endpoint mapping with **automatic bound swapping**:
$$\Delta\lambda_{\rm lo} = \lambda_0 - \frac{hc}{E_0 + \Delta E_{\rm hi}}, \qquad \Delta\lambda_{\rm hi} = \frac{hc}{E_0 - \Delta E_{\rm lo}} - \lambda_0$$

### B. Line Broadening & Resolution to Velocity (`width`)
$$v = c\,\frac{\Delta E}{E_0} = c\,\frac{\Delta\lambda}{\lambda_0}$$
- **Default Width Type**: $\sigma$ (Gaussian standard deviation).
- Conversion: $\text{FWHM} = 2\sqrt{2\ln 2}\,\sigma \approx 2.35482\,\sigma$.
- Both $\sigma_v$ and $\text{FWHM}_v$ velocities (in km/s) are reported, along with resolving power $R = E_0 / \Delta E_{\rm FWHM}$.
- Mixed-domain inputs (e.g. line centroid in keV, width in \AA) are unified into the width's unit before calculation, and equivalent widths are reported in both units.

### C. Source-Corrected Line Redshift & Velocities (`redshift`)
Uses the exact relativistic cosmological redshift composition:
$$z = \frac{E_0}{E\,(1+z_0)} - 1 = \frac{\lambda}{\lambda_0\,(1+z_0)} - 1$$
where $z_0$ is the source cosmological redshift (default: 0).
Velocities reported:
- **Non-relativistic**: $v_{\rm nonrel} = c\,z$
- **Relativistic Doppler**: $v_{\rm rel} = c\,\frac{(1+z)^2 - 1}{(1+z)^2 + 1}$
- **Discrepancy**: $\Delta v / v_{\rm rel} = (v_{\rm nonrel} - v_{\rm rel}) / v_{\rm rel}$

Sign convention:
- $z > 0$: Redshift / receding ($+v$).
- $z < 0$: Blueshift / approaching or outflow ($-v$).

### D. Forward Redshift / Blueshift Transformation (`shift`)
Given rest-frame centroid $E_0$ (or $\lambda_0$) and redshift $z$ ($z > 0$ for redshift, $z < 0$ for blueshift):
$$E' = \frac{E_0}{1 + z}, \qquad \lambda' = \lambda_0\,(1 + z)$$
Uncertainty bounds $(E_0, -\Delta E_{\rm lo}, +\Delta E_{\rm hi})$ map directly without bound swapping ($1+z > 0$ is monotonic increasing with respect to $E_0$):
$$\Delta E'_{\rm lo} = \frac{\Delta E_{\rm lo}}{1 + z}, \qquad \Delta E'_{\rm hi} = \frac{\Delta E_{\rm hi}}{1 + z}$$
Physical constraint: $z > -1$. Reports equivalent $v = cz$ and relativistic Doppler velocity.

### E. Linear ↔ Logarithmic Error Transformations (`lin2log`, `log2lin`)
Fixed base: $\log_{10}$.
- **`errors` mode**: Input $(V, \Delta V_{\rm lo}, \Delta V_{\rm hi})$
  $$\log V = \log_{10} V, \quad \Delta L_{\rm lo} = \log_{10} V - \log_{10}(V - \Delta V_{\rm lo}), \quad \Delta L_{\rm hi} = \log_{10}(V + \Delta V_{\rm hi}) - \log_{10} V$$
- **`bounds` mode**: Input $(V, V_{\rm lo}, V_{\rm hi})$
- Output is **always error ranges**, never absolute bounds.
- If $V - \Delta V_{\rm lo} \le 0$, $\Delta L_{\rm lo} = +\infty$ with a warning.

---

## 2. CLI Usage Examples

Execute via Python (using environment `DataReduc`):

```bash
# 1. Energy <-> Wavelength conversion with asymmetric error mapping
python -m SpecFitAssist convert 6.4 -0.02 0.03 --unit keV

# 2. Line broadening to velocity (default: sigma)
python -m SpecFitAssist width 6.7 5 --center-unit keV --width-unit eV --width-type fwhm

# 3. Source-corrected line redshift & velocities
python -m SpecFitAssist redshift -r 6.966 -o 6.90 -0.01 0.012 --unit keV -z 0.0028

# 4. Forward redshift transformation (calculate shifted centroid E' from E0 and z)
python -m SpecFitAssist shift 6.4 -0.02 0.03 -z 0.05 -u keV

# 5. Linear error to Log10 error
python -m SpecFitAssist lin2log 3.2e42 -0.5e42 0.8e42

# 6. Linear bounds to Log10 error
python -m SpecFitAssist lin2log 3.2e42 2.7e42 4.0e42 --mode bounds

# 7. Log10 error to Linear error
python -m SpecFitAssist log2lin 42.5 -0.1 0.2

# All commands support machine-readable JSON:
python -m SpecFitAssist shift 6.4 -0.02 0.03 -z 0.05 -u keV --json
```


---

## 3. Python API

```python
from SpecFitAssist import (
    AsymValue,
    convert_val,
    calc_line_width,
    calc_redshift,
    lin2log,
    log2lin,
)

# E <-> lambda
res = convert_val(AsymValue(6.4, 0.02, 0.03, "keV"), from_unit_str="keV", to_unit_str="AA")
print(res.format_str())  # 1.9373 (-0.0090385 / +0.0060729) Angstrom

# Line width
width_info = calc_line_width(6.7, "keV", AsymValue(5.0, unit="eV"), "eV", width_type="fwhm")
print(width_info["v_fwhm"]["value"])  # 223.7257 km/s

# Redshift
z_info = calc_redshift(6.966, AsymValue(6.90, 0.01, 0.012, "keV"), "keV", z0=0.0028)
print(z_info["v_rel"]["value"])  # 2015.68 km/s
```
