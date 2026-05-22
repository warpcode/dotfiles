import unittest
import sys
import os
from datetime import datetime, timezone, timedelta

# Add parent directory to sys.path to find the jira package
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from jira.utils import parse_jira_time, get_work_seconds, format_duration, SECONDS_PER_WORK_DAY

class TestUtils(unittest.TestCase):
    def test_parse_jira_time(self):
        # Test with HHMM offset
        ts = "2023-05-14T09:16:37.070+0100"
        dt = parse_jira_time(ts)
        self.assertEqual(dt.year, 2023)
        self.assertEqual(dt.month, 5)
        self.assertEqual(dt.day, 14)
        self.assertEqual(dt.hour, 8)  # UTC

        # Test with colon in offset
        ts = "2023-05-14T09:16:37.070+01:00"
        dt = parse_jira_time(ts)
        self.assertEqual(dt.hour, 8)

        # Test with Z suffix
        ts = "2023-05-14T09:16:37.070Z"
        dt = parse_jira_time(ts)
        self.assertEqual(dt.hour, 9)

    def test_get_work_seconds(self):
        # Mon 9:00 to Mon 10:00 (1 hour = 3600s)
        start = datetime(2023, 5, 15, 9, 0, tzinfo=timezone.utc)
        end = datetime(2023, 5, 15, 10, 0, tzinfo=timezone.utc)
        self.assertEqual(get_work_seconds(start, end), 3600)

        # Fri 17:00 to Mon 10:00
        # Fri: 17:00 to 17:30 (30 min = 1800s)
        # Sat/Sun: 0
        # Mon: 9:00 to 10:00 (1 hour = 3600s)
        # Total: 5400s
        start = datetime(2023, 5, 12, 17, 0, tzinfo=timezone.utc)
        end = datetime(2023, 5, 15, 10, 0, tzinfo=timezone.utc)
        self.assertEqual(get_work_seconds(start, end), 5400)

    def test_format_duration(self):
        self.assertEqual(format_duration(3600), "1h")
        self.assertEqual(format_duration(60), "1m")
        self.assertEqual(format_duration(SECONDS_PER_WORK_DAY), "1d")
        self.assertEqual(format_duration(SECONDS_PER_WORK_DAY + 3600 + 60), "1d 1h 1m")

if __name__ == "__main__":
    unittest.main()
