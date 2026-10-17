import timeit

# Baseline: tuple membership check as currently in executable_ai-guard-wrapper.py
baseline_code = """
route = 'post-tool'
res = route in ('output', 'post-tool', 'PostToolUse')
"""

# Optimized: set literal membership check
optimized_code = """
route = 'post-tool'
res = route in {'output', 'post-tool', 'PostToolUse'}
"""

def run_benchmark():
    number = 10_000_000
    t_baseline = timeit.timeit(baseline_code, number=number)
    t_optimized = timeit.timeit(optimized_code, number=number)

    print(f"Iterations: {number:,}")
    print(f"Baseline (tuple check):   {t_baseline:.6f} s")
    print(f"Optimized (set check):     {t_optimized:.6f} s")
    improvement = (t_baseline - t_optimized) / t_baseline * 100
    print(f"Improvement: {improvement:.2f}%")

if __name__ == "__main__":
    run_benchmark()
