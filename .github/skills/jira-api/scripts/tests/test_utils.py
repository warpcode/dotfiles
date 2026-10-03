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

        # Test with negative offset without colon
        ts = "2023-05-14T09:16:37.070-0500"
        dt = parse_jira_time(ts)
        self.assertEqual(dt.hour, 14)  # 09:00 - (-05:00) = 14:00 UTC

        # Test with negative offset with colon
        ts = "2023-05-14T09:16:37.070-05:00"
        dt = parse_jira_time(ts)
        self.assertEqual(dt.hour, 14)

        # Edge cases: None and empty input
        self.assertIsNone(parse_jira_time(None))
        self.assertIsNone(parse_jira_time(""))

        # Edge cases: Invalid timestamp format
        self.assertIsNone(parse_jira_time("invalid-date"))
        self.assertIsNone(parse_jira_time("2023-99-99T99:99:99"))

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

        # Invalid/empty ranges
        self.assertEqual(get_work_seconds(None, end), 0)
        self.assertEqual(get_work_seconds(start, None), 0)
        self.assertEqual(get_work_seconds(end, start), 0)
        self.assertEqual(get_work_seconds(start, start), 0)

        # Weekend range (Sat 10:00 to Sun 18:00)
        sat = datetime(2023, 5, 13, 10, 0, tzinfo=timezone.utc)
        sun = datetime(2023, 5, 14, 18, 0, tzinfo=timezone.utc)
        self.assertEqual(get_work_seconds(sat, sun), 0)

        # Same-day weekend
        self.assertEqual(get_work_seconds(sat, sat + timedelta(hours=2)), 0)

        # Multi-week span (Mon 09:00 May 15 to Mon 09:00 May 29 = 2 full work weeks = 10 work days)
        start_2w = datetime(2023, 5, 15, 9, 0, tzinfo=timezone.utc)
        end_2w = datetime(2023, 5, 29, 9, 0, tzinfo=timezone.utc)
        self.assertEqual(get_work_seconds(start_2w, end_2w), 10 * SECONDS_PER_WORK_DAY)

        # Outside work hours (Mon 06:00 to Mon 08:00)
        early1 = datetime(2023, 5, 15, 6, 0, tzinfo=timezone.utc)
        early2 = datetime(2023, 5, 15, 8, 0, tzinfo=timezone.utc)
        self.assertEqual(get_work_seconds(early1, early2), 0)

        # Multi-day first-day and last-day work-window clamps
        # Mon 07:00 May 15 -> Wed 19:00 May 17
        # Mon: 09:00-17:30 (8.5h = 30600s)
        # Tue: 09:00-17:30 (8.5h = 30600s)
        # Wed: 09:00-17:30 (8.5h = 30600s)
        # Total: 3 * 30600 = 91800s
        m_start = datetime(2023, 5, 15, 7, 0, tzinfo=timezone.utc)
        m_end = datetime(2023, 5, 17, 19, 0, tzinfo=timezone.utc)
        self.assertEqual(get_work_seconds(m_start, m_end), 3 * SECONDS_PER_WORK_DAY)

        # Mon 16:00 May 15 -> Wed 20:00 May 17
        # Mon: 16:00-17:30 (1.5h = 5400s)
        # Tue: 09:00-17:30 (8.5h = 30600s)
        # Wed: 09:00-17:30 (8.5h = 30600s)
        # Total: 5400 + 30600 + 30600 = 66600s
        p_start = datetime(2023, 5, 15, 16, 0, tzinfo=timezone.utc)
        p_end = datetime(2023, 5, 17, 20, 0, tzinfo=timezone.utc)
        self.assertEqual(get_work_seconds(p_start, p_end), 5400 + 2 * SECONDS_PER_WORK_DAY)

        # Non-week-multiple mid range ending on a weekday to pin _count_weekdays inclusive +1 boundary
        # Mon 09:00 May 15 -> Sat 09:00 May 20
        # First day (Mon): 8.5h = SECONDS_PER_WORK_DAY
        # Mid range (Tue 05-16..Fri 05-19 = 4 weekdays) = 4 * SECONDS_PER_WORK_DAY
        # Last day (Sat): 0 (weekend)
        # Total: 5 * SECONDS_PER_WORK_DAY
        mid_inc_start = datetime(2023, 5, 15, 9, 0, tzinfo=timezone.utc)
        mid_inc_end = datetime(2023, 5, 20, 9, 0, tzinfo=timezone.utc)
        self.assertEqual(get_work_seconds(mid_inc_start, mid_inc_end), 5 * SECONDS_PER_WORK_DAY)

    def test_format_duration(self):
        self.assertEqual(format_duration(3600), "1h")
        self.assertEqual(format_duration(60), "1m")
        self.assertEqual(format_duration(SECONDS_PER_WORK_DAY), "1d")
        self.assertEqual(format_duration(SECONDS_PER_WORK_DAY + 3600 + 60), "1d 1h 1m")

if __name__ == "__main__":
    unittest.main()
