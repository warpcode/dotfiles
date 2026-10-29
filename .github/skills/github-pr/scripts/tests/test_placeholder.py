#!/usr/bin/env python3
"""Dummy test module to satisfy unittest discovery for python test runner."""
import unittest

class TestDummy(unittest.TestCase):
    def test_noop(self):
        pass

if __name__ == "__main__":
    unittest.main()
