import time
from datetime import datetime, timezone
from jira.metrics import calculate_metrics

def generate_issue(num_histories=150, items_per_history=15, status_items_per_history=1):
    histories = []
    for i in range(num_histories):
        items = []
        for s in range(status_items_per_history):
            items.append({"field": "status", "fromString": f"Status_{i}_{s}", "toString": f"Status_{i}_{s+1}"})
        for j in range(items_per_history - status_items_per_history):
            items.append({"field": f"field_{j}", "fromString": "x", "toString": "y"})
        histories.append({
            "created": f"2023-05-15T{(i % 12) + 9:02d}:00:00.000+0000",
            "items": items
        })

    issue = {
        "fields": {"created": "2023-05-15T08:00:00.000+0000"},
        "changelog": {"histories": histories}
    }
    status_map = {f"Status_{i}_{s}": "In Progress" if i % 2 == 0 else "Done" for i in range(num_histories) for s in range(status_items_per_history + 1)}
    return issue, status_map

def main():
    now = datetime(2023, 6, 1, tzinfo=timezone.utc)
    iterations = 1000

    for status_count in (1, 2, 3):
        issue, status_map = generate_issue(num_histories=150, status_items_per_history=status_count)

        # Warmup
        for _ in range(10):
            calculate_metrics(issue, status_map, now)

        start = time.perf_counter()
        for _ in range(iterations):
            calculate_metrics(issue, status_map, now)
        elapsed = time.perf_counter() - start

        print(f"[{status_count} status item(s)/history] {iterations} iterations: {elapsed:.4f}s ({elapsed / iterations * 1000:.4f} ms/op)")

if __name__ == "__main__":
    main()
