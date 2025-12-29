# Algorithm Complexity Analysis

**Purpose**: Guide for analyzing and optimizing algorithm complexity

## BIG O NOTATION

### Common Complexities
- **O(1)**: Constant time - Accessing array element, hash map lookup
- **O(log n)**: Logarithmic time - Binary search, balanced tree operations
- **O(n)**: Linear time - Simple loop, linear search
- **O(n log n)**: Linearithmic time - Merge sort, heap sort
- **O(n^2)**: Quadratic time - Nested loops, bubble sort
- **O(2^n)**: Exponential time - Recursive Fibonacci, subset generation
- **O(n!)**: Factorial time - Permutation generation

### Complexity Examples
```python
# O(1) - Constant
def get_first(arr):
    return arr[0]  # Always one operation

# O(log n) - Logarithmic
def binary_search(arr, target):
    # Halves search space each iteration
    low, high = 0, len(arr) - 1
    while low <= high:
        mid = (low + high) // 2

# O(n) - Linear
def linear_search(arr, target):
    for item in arr:  # Worst case: n iterations
        if item == target:
            return item

# O(n^2) - Quadratic
def bubble_sort(arr):
    n = len(arr)
    for i in range(n):  # n iterations
        for j in range(0, n-i-1):  # n iterations
            if arr[j] > arr[j+1]:
                arr[j], arr[j+1] = arr[j+1], arr[j]

# O(n log n) - Linearithmic
def merge_sort(arr):
    if len(arr) <= 1:
        return arr
    mid = len(arr) // 2
    left = merge_sort(arr[:mid])  # log n levels
    right = merge_sort(arr[mid:])
    return merge(left, right)  # n work at each level
```

## COMPLEXITY ANALYSIS

### Time Complexity
- **Definition**: Number of operations as input size grows
- **Analysis**: Count operations in worst case
- **Simplification**: Drop constants, keep dominant term

### Space Complexity
- **Definition**: Memory usage as input size grows
- **Analysis**: Count additional memory used
- **Types**: 
  - **Auxiliary Space**: Extra space excluding input
  - **Total Space**: Input + auxiliary space

### Example Analysis
```python
def find_pairs(arr, target):
    seen = set()  # O(n) space
    pairs = []
    for num in arr:  # O(n) time
        complement = target - num
        if complement in seen:  # O(1) average
            pairs.append((num, complement))
        seen.add(num)
    return pairs
# Time: O(n)
# Space: O(n)
```

## COMMON ALGORITHM COMPLEXITIES

### Sorting Algorithms
- **Quick Sort**: O(n log n) average, O(n^2) worst case
- **Merge Sort**: O(n log n) always, O(n) space
- **Heap Sort**: O(n log n) always, O(1) space
- **Bubble Sort**: O(n^2) time, O(1) space
- **Insertion Sort**: O(n^2) worst, O(n) best (sorted)
- **Selection Sort**: O(n^2) time, O(1) space

### Searching Algorithms
- **Binary Search**: O(log n) time, O(1) space
- **Linear Search**: O(n) time, O(1) space
- **Hash Lookup**: O(1) average, O(n) worst case

### Graph Algorithms
- **BFS/DFS**: O(V + E) where V=vertices, E=edges
- **Dijkstra's**: O((V + E) log V) with heap
- **Floyd-Warshall**: O(V^3) time, O(V^2) space
- **Bellman-Ford**: O(VE) time, O(V) space

### Dynamic Programming
- **Fibonacci (naive)**: O(2^n) time
- **Fibonacci (memoized)**: O(n) time, O(n) space
- **Knapsack**: O(nW) time, O(nW) space
- **LCS**: O(mn) time, O(mn) space

## COMPLEXITY PITFALLS

### Nested Loops
```python
# Bad: O(n^2)
for i in range(n):
    for j in range(n):
        process(i, j)

# Good: O(n) - use hash map
seen = {}
for i in range(n):
    seen[i] = True
```

### Unnecessary Computations
```python
# Bad: O(n^2) - recalculates fibonacci
def fib(n):
    if n <= 1:
        return n
    return fib(n-1) + fib(n-2)

# Good: O(n) - memoization
memo = {0: 0, 1: 1}
def fib_memo(n):
    if n not in memo:
        memo[n] = fib_memo(n-1) + fib_memo(n-2)
    return memo[n]
```

### Wrong Data Structure
```python
# Bad: O(n) - list lookup
if item in my_list:  # Linear search

# Good: O(1) - set lookup
if item in my_set:  # Hash lookup
```

### Inefficient String Operations
```python
# Bad: O(n^2) - string concatenation in loop
result = ""
for s in strings:
    result += s  # Creates new string each time

# Good: O(n) - join
result = "".join(strings)  # Single allocation
```

### Exponential Algorithms
```python
# Bad: O(2^n) - subset generation
def generate_subsets(arr):
    if not arr:
        return [[]]
    subsets = generate_subsets(arr[1:])
    return subsets + [[arr[0]] + s for s in subsets]

# Good: Use iterative or memoized approach
def generate_subsets_iterative(arr):
    subsets = [[]]
    for item in arr:
        subsets += [s + [item] for s in subsets]
    return subsets
```

## OPTIMIZATION STRATEGIES

### 1. Choose Right Data Structure
- **Hash Map/Set**: O(1) lookup vs O(n) list lookup
- **Tree**: O(log n) operations vs O(n) list
- **Priority Queue**: O(log n) insert/extract vs O(n) list

### 2. Use Memoization
- Cache computed results
- Avoid redundant calculations
- Trade space for time

### 3. Divide and Conquer
- Break problem into subproblems
- Solve subproblems recursively
- Combine results
- Examples: Merge sort, quick sort

### 4. Greedy Algorithms
- Make locally optimal choice
- Don't guarantee global optimum
- Examples: Dijkstra's, Huffman coding

### 5. Dynamic Programming
- Break into overlapping subproblems
- Store subproblem results
- Build up to solution
- Examples: Knapsack, LCS, shortest paths

### 6. Reduce Nested Loops
- Use hash maps to avoid O(n^2)
- Precompute lookups
- Sort and use binary search

### 7. Use Efficient Algorithms
- Sorting: O(n log n) vs O(n^2)
- Searching: O(log n) vs O(n)
- Graph: Use appropriate algorithm

## OPTIMIZATION EXAMPLES

### Problem: Find pairs summing to target
```python
# Bad: O(n^2) - nested loops
def find_pairs_slow(arr, target):
    pairs = []
    for i in range(len(arr)):
        for j in range(i+1, len(arr)):
            if arr[i] + arr[j] == target:
                pairs.append((arr[i], arr[j]))
    return pairs

# Good: O(n) - hash map
def find_pairs_fast(arr, target):
    seen = set()
    pairs = []
    for num in arr:
        complement = target - num
        if complement in seen:
            pairs.append((num, complement))
        seen.add(num)
    return pairs
```

### Problem: Check if string has duplicate characters
```python
# Bad: O(n^2) - nested loops
def has_duplicates_slow(s):
    for i in range(len(s)):
        for j in range(i+1, len(s)):
            if s[i] == s[j]:
                return True
    return False

# Good: O(n) - hash set
def has_duplicates_fast(s):
    seen = set()
    for char in s:
        if char in seen:
            return True
        seen.add(char)
    return False
```

### Problem: Find intersection of two arrays
```python
# Bad: O(n*m) - nested loops
def intersection_slow(arr1, arr2):
    result = []
    for item1 in arr1:
        for item2 in arr2:
            if item1 == item2:
                result.append(item1)
                break
    return result

# Good: O(n + m) - hash set
def intersection_fast(arr1, arr2):
    set2 = set(arr2)
    return [item for item in arr1 if item in set2]
```

## WHEN TO OPTIMIZE

### Don't Optimize Prematurely
- **First**: Write clean, correct code
- **Then**: Profile to find bottlenecks
- **Finally**: Optimize hot paths only
- **Rule**: "Premature optimization is the root of all evil" - Donald Knuth

### When to Optimize
- **Hot Paths**: Code executed frequently
- **Large Inputs**: Code processing large datasets
- **Performance Critical**: User-facing features
- **Verified Bottleneck**: Profiled and confirmed

### When NOT to Optimize
- **Rarely Executed**: One-time initialization
- **Small Inputs**: Small datasets (constant factor dominates)
- **Readability First**: Optimization makes code hard to understand
- **Premature**: Not profiled, suspected but not confirmed
