"""Unit tests for _core.py."""

import unittest
import math
import astropy.units as u

from SpecFitAssist._core import (
    HC_KEV_AA,
    C_KMS,
    FWHM_SIGMA_RATIO,
    AsymValue,
    parse_unit,
    is_energy_unit,
    is_wavelength_unit,
    propagate_bounds,
)


class TestCore(unittest.TestCase):
    def test_constants(self):
        self.assertAlmostEqual(HC_KEV_AA, 12.398419843320026, places=6)
        self.assertAlmostEqual(C_KMS, 299792.458, places=3)
        self.assertAlmostEqual(FWHM_SIGMA_RATIO, 2.354820045, places=6)

    def test_asym_value_abs_error(self):
        # Requirement: negative lower error must be converted to absolute value
        v = AsymValue(value=6.4, err_lo=-0.02, err_hi=0.03, unit="keV")
        self.assertEqual(v.value, 6.4)
        self.assertEqual(v.err_lo, 0.02)
        self.assertEqual(v.err_hi, 0.03)
        self.assertTrue(v.has_err)
        self.assertAlmostEqual(v.bounds[0], 6.38)
        self.assertAlmostEqual(v.bounds[1], 6.43)

    def test_asym_value_dict_roundtrip(self):
        v = AsymValue(value=10.0, err_lo=0.5, err_hi=0.8, unit="eV")
        d = v.to_dict()
        v2 = AsymValue.from_dict(d)
        self.assertEqual(v.value, v2.value)
        self.assertEqual(v.err_lo, v2.err_lo)
        self.assertEqual(v.err_hi, v2.err_hi)
        self.assertEqual(v.unit, v2.unit)

    def test_parse_unit_aliases(self):
        self.assertEqual(parse_unit("A"), u.AA)
        self.assertEqual(parse_unit("AA"), u.AA)
        self.assertEqual(parse_unit("angstrom"), u.AA)
        self.assertEqual(parse_unit("armstrong"), u.AA)
        self.assertEqual(parse_unit("å"), u.AA)
        self.assertEqual(parse_unit("keV"), u.keV)
        self.assertEqual(parse_unit("kev"), u.keV)
        self.assertEqual(parse_unit("eV"), u.eV)
        self.assertEqual(parse_unit("nm"), u.nm)

        self.assertTrue(is_energy_unit(parse_unit("keV")))
        self.assertTrue(is_wavelength_unit(parse_unit("armstrong")))
        self.assertFalse(is_energy_unit(parse_unit("nm")))

    def test_propagate_bounds_increasing(self):
        # f(x) = 2x + 1 is increasing
        x = AsymValue(value=5.0, err_lo=1.0, err_hi=2.0)
        y = propagate_bounds(lambda v: 2 * v + 1, x)
        self.assertEqual(y.value, 11.0)
        self.assertEqual(y.err_lo, 2.0)  # 11 - (2*4 + 1) = 2
        self.assertEqual(y.err_hi, 4.0)  # (2*7 + 1) - 11 = 4

    def test_propagate_bounds_decreasing_swaps_bounds(self):
        # f(x) = 10 / x is strictly decreasing
        x = AsymValue(value=2.0, err_lo=0.5, err_hi=0.5)  # bounds: [1.5, 2.5]
        y = propagate_bounds(lambda v: 10.0 / v, x)
        self.assertEqual(y.value, 5.0)
        # f(1.5) = 6.6667 (upper limit)
        # f(2.5) = 4.0 (lower limit)
        # err_lo = 5.0 - 4.0 = 1.0
        # err_hi = 6.6667 - 5.0 = 1.6667
        self.assertAlmostEqual(y.err_lo, 1.0)
        self.assertAlmostEqual(y.err_hi, 10.0 / 1.5 - 5.0)

    def test_propagate_bounds_check_positive(self):
        x = AsymValue(value=1.0, err_lo=1.5, err_hi=0.5)  # lower bound is -0.5
        with self.assertRaises(ValueError):
            propagate_bounds(lambda v: 1.0 / v, x, check_positive=True)


if __name__ == "__main__":
    unittest.main()
