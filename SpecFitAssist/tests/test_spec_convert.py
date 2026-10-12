"""Unit tests for spec_convert.py."""

import unittest
import math

from SpecFitAssist._core import HC_KEV_AA, C_KMS, FWHM_SIGMA_RATIO, AsymValue
from SpecFitAssist.spec_convert import convert_val, calc_line_width, calc_redshift, calc_shift



class TestSpecConvert(unittest.TestCase):
    def test_convert_kev_to_angstrom(self):
        # 6.4 (-0.02 / +0.03) keV -> AA
        x = AsymValue(value=6.4, err_lo=-0.02, err_hi=0.03, unit="keV")
        res = convert_val(x, from_unit_str="keV", to_unit_str="AA")
        
        expected_val = HC_KEV_AA / 6.4  # ~1.937253
        expected_lo = expected_val - (HC_KEV_AA / 6.43)  # mapped from +0.03 keV
        expected_hi = (HC_KEV_AA / 6.38) - expected_val  # mapped from -0.02 keV
        
        self.assertAlmostEqual(res.value, expected_val, places=6)
        self.assertAlmostEqual(res.err_lo, expected_lo, places=7)
        self.assertAlmostEqual(res.err_hi, expected_hi, places=7)

    def test_convert_roundtrip(self):
        x = AsymValue(value=1.85, err_lo=0.005, err_hi=0.008, unit="AA")
        e = convert_val(x, from_unit_str="AA", to_unit_str="keV")
        x_back = convert_val(e, from_unit_str="keV", to_unit_str="AA")
        
        self.assertAlmostEqual(x.value, x_back.value, places=9)
        self.assertAlmostEqual(x.err_lo, x_back.err_lo, places=9)
        self.assertAlmostEqual(x.err_hi, x_back.err_hi, places=9)

    def test_convert_same_domain(self):
        x = AsymValue(value=6400.0, err_lo=20.0, err_hi=30.0, unit="eV")
        res = convert_val(x, from_unit_str="eV", to_unit_str="keV")
        self.assertAlmostEqual(res.value, 6.4)
        self.assertAlmostEqual(res.err_lo, 0.02)
        self.assertAlmostEqual(res.err_hi, 0.03)

    def test_line_width_sigma(self):
        # Center = 6.7 keV, width = 5 eV (sigma)
        w = AsymValue(value=5.0, err_lo=0.5, err_hi=0.5, unit="eV")
        res = calc_line_width(
            center_val=6.7,
            center_unit_str="keV",
            width=w,
            width_unit_str="eV",
            width_type="sigma",
        )
        # Center in width unit (eV): 6700 eV
        # v_sigma = c * (5.0 / 6700.0) ~ 223.7257 km/s
        expected_v_sig = C_KMS * (5.0 / 6700.0)
        expected_v_fwhm = expected_v_sig * FWHM_SIGMA_RATIO
        self.assertAlmostEqual(res["v_sigma"]["value"], expected_v_sig, places=4)
        self.assertAlmostEqual(res["v_fwhm"]["value"], expected_v_fwhm, places=4)
        self.assertAlmostEqual(res["equiv_width_in_center_unit"]["value"], 0.005, places=6)

    def test_line_width_fwhm(self):
        # Center = 6.7 keV, width = 5 eV (fwhm)
        w = AsymValue(value=5.0, unit="eV")
        res = calc_line_width(
            center_val=6.7,
            center_unit_str="keV",
            width=w,
            width_unit_str="eV",
            width_type="fwhm",
        )
        expected_v_fwhm = C_KMS * (5.0 / 6700.0)
        expected_v_sig = expected_v_fwhm / FWHM_SIGMA_RATIO
        self.assertAlmostEqual(res["v_fwhm"]["value"], expected_v_fwhm, places=4)
        self.assertAlmostEqual(res["v_sigma"]["value"], expected_v_sig, places=4)
        self.assertAlmostEqual(res["resolving_power"], 6700.0 / 5.0, places=4)

    def test_line_width_mixed_wavelength_width(self):
        # Center = 6.7 keV, width = 0.005 AA
        lam0 = HC_KEV_AA / 6.7  # ~1.85051 AA
        w = AsymValue(value=0.005, unit="AA")
        res = calc_line_width(
            center_val=6.7,
            center_unit_str="keV",
            width=w,
            width_unit_str="AA",
            width_type="sigma",
        )
        expected_v = C_KMS * (0.005 / lam0)
        self.assertAlmostEqual(res["v_sigma"]["value"], expected_v, places=4)

    def test_calc_redshift_energy(self):
        # E0 = 6.966 keV, obs = 6.90 (-0.01 / +0.012) keV, z0 = 0.0028
        obs = AsymValue(value=6.90, err_lo=0.01, err_hi=0.012, unit="keV")
        res = calc_redshift(rest_val=6.966, obs=obs, unit_str="keV", z0=0.0028)
        
        # z = 6.966 / (6.90 * (1 + 0.0028)) - 1
        expected_z = 6.966 / (6.90 * 1.0028) - 1.0
        expected_cz = C_KMS * expected_z
        expected_v_rel = C_KMS * (((1.0 + expected_z)**2 - 1.0) / ((1.0 + expected_z)**2 + 1.0))
        
        self.assertAlmostEqual(res["z"]["value"], expected_z, places=7)
        self.assertAlmostEqual(res["v_nonrel"]["value"], expected_cz, places=3)
        self.assertAlmostEqual(res["v_rel"]["value"], expected_v_rel, places=3)
        self.assertEqual(res["shift_type"], "redshift (receding)")

    def test_calc_redshift_wavelength(self):
        # Wavelength: lam0 = 1.85 AA, obs = 1.84 AA (blueshift / outflow)
        obs = AsymValue(value=1.84, unit="AA")
        res = calc_redshift(rest_val=1.85, obs=obs, unit_str="AA", z0=0.0)
        expected_z = (1.84 / 1.85) - 1.0
        self.assertAlmostEqual(res["z"]["value"], expected_z, places=7)
        self.assertTrue(res["z"]["value"] < 0)
        self.assertEqual(res["shift_type"], "blueshift (outflow)")

    def test_calc_shift_energy_redshift(self):
        # E0 = 6.4 (-0.02 / +0.03) keV, z = 0.05
        rest = AsymValue(value=6.4, err_lo=0.02, err_hi=0.03, unit="keV")
        res = calc_shift(rest=rest, z=0.05, unit_str="keV")

        expected_val = 6.4 / 1.05
        expected_lo = 0.02 / 1.05
        expected_hi = 0.03 / 1.05

        self.assertAlmostEqual(res["shifted"]["value"], expected_val, places=6)
        self.assertAlmostEqual(res["shifted"]["err_lo"], expected_lo, places=6)
        self.assertAlmostEqual(res["shifted"]["err_hi"], expected_hi, places=6)
        self.assertEqual(res["shift_type"], "redshift (receding)")
        self.assertAlmostEqual(res["v_nonrel_kms"], C_KMS * 0.05, places=3)

    def test_calc_shift_energy_blueshift(self):
        # E0 = 6.4 keV, z = -0.05 (blueshift)
        rest = AsymValue(value=6.4, unit="keV")
        res = calc_shift(rest=rest, z=-0.05, unit_str="keV")

        expected_val = 6.4 / 0.95
        self.assertAlmostEqual(res["shifted"]["value"], expected_val, places=6)
        self.assertEqual(res["shift_type"], "blueshift (approaching / outflow)")
        self.assertTrue(res["v_nonrel_kms"] < 0)

    def test_calc_shift_wavelength(self):
        # lambda0 = 1215.67 AA, z = 0.1
        rest = AsymValue(value=1215.67, err_lo=0.1, err_hi=0.2, unit="AA")
        res = calc_shift(rest=rest, z=0.1, unit_str="AA")

        expected_val = 1215.67 * 1.1
        expected_lo = 0.1 * 1.1
        expected_hi = 0.2 * 1.1

        self.assertAlmostEqual(res["shifted"]["value"], expected_val, places=5)
        self.assertAlmostEqual(res["shifted"]["err_lo"], expected_lo, places=5)
        self.assertAlmostEqual(res["shifted"]["err_hi"], expected_hi, places=5)

    def test_calc_shift_invalid_z(self):
        rest = AsymValue(value=6.4, unit="keV")
        with self.assertRaises(ValueError):
            calc_shift(rest=rest, z=-1.0, unit_str="keV")
        with self.assertRaises(ValueError):
            calc_shift(rest=rest, z=-1.5, unit_str="keV")

    def test_calc_shift_and_redshift_roundtrip(self):
        # Shift E0 by z=0.035, then compute redshift of shifted line -> recover z=0.035
        rest = AsymValue(value=6.7, unit="keV")
        shift_res = calc_shift(rest=rest, z=0.035, unit_str="keV")
        shifted_obs = AsymValue(value=shift_res["shifted"]["value"], unit="keV")
        
        redshift_res = calc_redshift(rest_val=6.7, obs=shifted_obs, unit_str="keV", z0=0.0)
        self.assertAlmostEqual(redshift_res["z"]["value"], 0.035, places=9)


if __name__ == "__main__":
    unittest.main()

