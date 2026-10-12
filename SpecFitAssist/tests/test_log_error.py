"""Unit tests for log_error.py."""

import unittest
import math

from SpecFitAssist.log_error import lin2log, log2lin


class TestLogError(unittest.TestCase):
    def test_lin2log_errors_mode(self):
        # 3.2e42 (-0.5e42 / +0.8e42)
        res = lin2log(3.2e42, -0.5e42, 0.8e42, mode="errors")
        self.assertAlmostEqual(res["log_val"], math.log10(3.2e42), places=7)
        self.assertAlmostEqual(res["delta_log_lo"], math.log10(3.2e42) - math.log10(2.7e42), places=7)
        self.assertAlmostEqual(res["delta_log_hi"], math.log10(4.0e42) - math.log10(3.2e42), places=7)
        self.assertFalse(res["is_infinite_lo"])

    def test_lin2log_bounds_mode(self):
        # 3.2e42 with bounds [2.7e42, 4.0e42]
        res = lin2log(3.2e42, 2.7e42, 4.0e42, mode="bounds")
        self.assertAlmostEqual(res["log_val"], math.log10(3.2e42), places=7)
        self.assertAlmostEqual(res["delta_log_lo"], math.log10(3.2e42) - math.log10(2.7e42), places=7)
        self.assertAlmostEqual(res["delta_log_hi"], math.log10(4.0e42) - math.log10(3.2e42), places=7)

    def test_lin2log_infinite_lower_bound(self):
        # 1.0 with err_lo = 1.5 -> v_lo = -0.5 <= 0 -> log lower is -inf
        res = lin2log(1.0, 1.5, 0.5, mode="errors")
        self.assertTrue(res["is_infinite_lo"])
        self.assertEqual(res["delta_log_lo"], float("inf"))
        self.assertIsNotNone(res["warning"])

    def test_log2lin_errors_mode(self):
        # log_val = 42.5 (-0.1 / +0.2)
        res = log2lin(42.5, -0.1, 0.2, mode="errors")
        expected_v = 10.0 ** 42.5
        expected_err_lo = expected_v - (10.0 ** 42.4)
        expected_err_hi = (10.0 ** 42.7) - expected_v
        self.assertAlmostEqual(res["lin_val"], expected_v, delta=expected_v * 1e-12)
        self.assertAlmostEqual(res["err_lo"], expected_err_lo, delta=expected_err_lo * 1e-12)
        self.assertAlmostEqual(res["err_hi"], expected_err_hi, delta=expected_err_hi * 1e-12)

    def test_log2lin_bounds_mode(self):
        # log_val = 42.5 with bounds [42.4, 42.7]
        res = log2lin(42.5, 42.4, 42.7, mode="bounds")
        expected_v = 10.0 ** 42.5
        expected_err_lo = expected_v - (10.0 ** 42.4)
        expected_err_hi = (10.0 ** 42.7) - expected_v
        self.assertAlmostEqual(res["lin_val"], expected_v, delta=expected_v * 1e-12)
        self.assertAlmostEqual(res["err_lo"], expected_err_lo, delta=expected_err_lo * 1e-12)
        self.assertAlmostEqual(res["err_hi"], expected_err_hi, delta=expected_err_hi * 1e-12)

    def test_roundtrip_lin_log(self):
        v = 5.67e38
        elo = 1.2e38
        ehi = 2.4e38
        l_res = lin2log(v, elo, ehi, mode="errors")
        lin_res = log2lin(l_res["log_val"], l_res["delta_log_lo"], l_res["delta_log_hi"], mode="errors")
        self.assertAlmostEqual(lin_res["lin_val"], v, delta=v * 1e-12)
        self.assertAlmostEqual(lin_res["err_lo"], elo, delta=elo * 1e-12)
        self.assertAlmostEqual(lin_res["err_hi"], ehi, delta=ehi * 1e-12)


if __name__ == "__main__":
    unittest.main()
