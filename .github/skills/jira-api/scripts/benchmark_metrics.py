import time
from datetime import datetime, timezone
from jira.metrics import calculate_metrics

def main():
    histories = []
    for i in range(150):
        items = []
        for j in range(15):
            if j == 2:
                items.append({"field": "status", "fromString": f"Status_{i}", "toString": f"Status_{i+1}"})
            else:
                items.append({"field": f"field_{j}", "fromString": "x", "toString": "y"})
        histories.append({
            "created": f"2023-05-15T{(i % 12) + 9:02d}:00:00.000+0000",
            "items": items
        })

    issue = {
        "fields": {"created": "2023-05-15T08:00:00.000+0000"},
        "changelog": {"histories": histories}
    }
    status_map = {f"Status_{i}": "In Progress" if i % 2 == 0 else "Done" for i in range(155)}
    now = datetime(2023, 6, 1, tzinfo=timezone.utc)

    # Warmup
    for _ in range(10):
        calculate_metrics(issue, status_map, now)

    iterations = 1000
    start = time.perf_counter()
    for _ in range(iterations):
        calculate_metrics(issue, status_map, now)
    elapsed = time.perf_counter() - start

    print(f"Executed {iterations} iterations of calculate_metrics in {elapsed:.4f} seconds ({elapsed / iterations * 1000:.4f} ms/op).")

if __name__ == "__main__":
    main()
