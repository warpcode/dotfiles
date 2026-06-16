import unittest
import sys
import os
from datetime import datetime, timezone

# Add parent directory to sys.path to find the jira package
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from jira.metrics import calculate_metrics

class TestMetrics(unittest.TestCase):
    def test_calculate_metrics(self):
        # Mock issue data
        issue = {
            "fields": {
                "created": "2023-05-15T09:00:00.000+0000",
                "status": {"name": "Done"}
            },
            "changelog": {
                "histories": [
                    {
                        "created": "2023-05-15T10:00:00.000+0000",
                        "items": [{"field": "status", "fromString": "To Do", "toString": "In Progress"}]
                    },
                    {
                        "created": "2023-05-15T11:00:00.000+0000",
                        "items": [{"field": "status", "fromString": "In Progress", "toString": "Done"}]
                    }
                ]
            }
        }

        status_map = {
            "To Do": "To Do",
            "In Progress": "In Progress",
            "Done": "Done"
        }

        now = datetime(2023, 5, 15, 12, 0, tzinfo=timezone.utc)
        metrics = calculate_metrics(issue, status_map, now=now)

        self.assertIsNotNone(metrics)
        self.assertEqual(metrics["transition_count"], 2)
        # 9:00 to 10:00 (To Do) = 3600s
        # 10:00 to 11:00 (In Progress) = 3600s
        # 11:00 to 12:00 (Done) = 3600s
        self.assertEqual(metrics["time_in_category_seconds"]["To Do"], 3600)
        self.assertEqual(metrics["time_in_category_seconds"]["In Progress"], 3600)
        self.assertEqual(metrics["time_in_category_seconds"]["Done"], 3600)

        # Lead time: created (9:00) to first Done (11:00) = 2 hours = 7200s
        self.assertEqual(metrics["lead_time_seconds"], 7200)
        # Cycle time: first In Progress (10:00) to first Done (11:00) = 1 hour = 3600s
        self.assertEqual(metrics["cycle_time_seconds"], 3600)

if __name__ == "__main__":
    unittest.main()
