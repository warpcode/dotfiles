# Profiling Tools and Techniques

**Purpose**: Guide for profiling applications to identify performance bottlenecks

## PROFILING TOOLS

### Language-Specific Profilers

#### PHP Profiling
- **Xdebug**: Step debugger and profiler
  - Install: `pecl install xdebug`
  - Enable: `xdebug.profiler_enable = 1` in php.ini
  - Output: Files in `xdebug.profiler_output_dir`
  - Analyze: KCacheGrind, QCacheGrind, Webgrind
- **Blackfire**: Commercial PHP profiler
  - Install: Blackfire agent and PHP probe
  - Use: `blackfire run php script.php`
  - Features: Timeline, call graph, memory profiling
  - Web dashboard: Detailed performance analysis
- **Tideways**: PHP profiling service
  - Features: Timeline, flame graphs, memory profiling
  - Integration: Works with Blackfire
- **XHProf**: Facebook's PHP profiler
  - Install: `pecl install xhprof`
  - Use: `xhprof_enable()`, `xhprof_disable()`
  - Analyze: XHProf UI

#### Python Profiling
- **cProfile**: Built-in Python profiler
  - Use: `python -m cProfile script.py`
  - Output: Statistics or pstats
  - Analyze: `pstats`, `snakeviz`, `gprof2dot`
- **py-spy**: Sampling profiler for Python
  - Install: `pip install py-spy`
  - Use: `py-spy top --pid <pid>`
  - Features: Low overhead, flame graphs
  - Visualize: `py-spy record --pid <pid> -o profile.svg`
- **line_profiler**: Line-by-line profiling
  - Install: `pip install line_profiler`
  - Use: `@profile` decorator
  - Run: `kernprof -l -v script.py`
- **memory_profiler**: Memory profiling for Python
  - Install: `pip install memory_profiler`
  - Use: `@profile` decorator
  - Run: `python -m memory_profiler script.py`

#### JavaScript/Node.js Profiling
- **Chrome DevTools**: Browser profiling
  - Performance tab: Timeline, flame graph
  - Memory tab: Heap snapshots, allocation tracking
  - Coverage tab: Code coverage
- **clinic.js**: Node.js profiling suite
  - Install: `npm install -g clinic`
  - Use: `clinic doctor -- node server.js`
  - Tools: `clinic doctor`, `clinic flame`, `clinic heapprofiler`
- **0x**: Node.js flame graph profiler
  - Install: `npm install -g 0x`
  - Use: `0x server.js`
  - Features: Flame graphs, CPU profiling
- **Node.js built-in**: `--prof` flag
  - Use: `node --prof server.js`
  - Output: `isolate-*.log` files
  - Analyze: `node --prof-process isolate-*.log`

#### Java Profiling
- **JProfiler**: Commercial Java profiler
  - Features: CPU, memory, thread profiling
  - Integration: Works with all major IDEs
- **VisualVM**: Free Java profiler
  - Install: Included with JDK
  - Use: `jvisualvm`
  - Features: CPU, memory, thread dumps, heap dumps
- **Java Mission Control**: JDK monitoring tool
  - Features: JMX monitoring, flight recorder
  - Use: `jmc`
- **Async Profiler**: Low-overhead profiler
  - Features: CPU, allocation profiling
  - Use: `java -jar async-profiler.jar start PID`
  - Output: Flame graphs, JFR

#### Go Profiling
- **pprof**: Go's built-in profiler
  - Import: `import _ "net/http/pprof"`
  - Use: `go tool pprof http://localhost:6060/debug/pprof/profile`
  - Features: CPU, heap, goroutine profiling
  - Visualize: `go tool pprof -web`
- **trace**: Go execution tracer
  - Use: `go test -trace=trace.out`
  - Analyze: `go tool trace trace.out`
- **benchstat**: Benchmark comparison tool
  - Use: `go test -bench=. -benchmem | benchstat`

#### Rust Profiling
- **flamegraph**: Flame graph generation for Rust
  - Install: `cargo install flamegraph`
  - Use: `cargo flamegraph`
  - Output: SVG flame graph
- **perf**: Linux profiling tool
  - Use: `perf record ./target/release/binary`
  - Analyze: `perf report`, `perf script`
- **heaptrack**: Memory tracking
  - Install: `heaptrack ./binary`
  - Output: Memory usage analysis

#### C/C++ Profiling
- **gprof**: GNU profiler
  - Compile: `gcc -pg program.c`
  - Run: `./a.out`
  - Analyze: `gprof a.out gmon.out > analysis.txt`
- **valgrind**: Memory profiling and debugging
  - Install: `apt-get install valgrind`
  - Use: `valgrind ./program`
  - Tools: `memcheck`, `cachegrind`, `callgrind`
- **perf**: Linux profiling tool
  - Use: `perf stat ./program`
  - Use: `perf record ./program`
  - Analyze: `perf report`

## PROFILING WORKFLOW

### 1. Identify Performance Issue
- Slow response times
- High CPU usage
- Memory leaks
- Database timeouts
- Resource exhaustion

### 2. Choose Profiling Tool
- **CPU bottlenecks**: CPU profiler (Xdebug, cProfile, clinic.js, pprof)
- **Memory leaks**: Memory profiler (Blackfire, memory_profiler, heapprofiler)
- **I/O bottlenecks**: System profilers (strace, perf, DTrace)
- **Database queries**: Query profiler (EXPLAIN, slow query log)

### 3. Run Profiler
- **Sampling**: Low overhead, statistical sampling
- **Instrumentation**: Accurate but higher overhead
- **Production**: Use sampling profilers (py-spy, async-profiler)
- **Development**: Use instrumentation profilers (Xdebug, cProfile)

### 4. Analyze Results
- **Call Graph**: Identify hot paths
- **Flame Graph**: Visualize call stack
- **Memory Analysis**: Identify memory leaks
- **Time Breakdown**: Time spent in each function

### 5. Optimize
- **Hot Paths**: Optimize frequently called functions
- **Memory Leaks**: Fix memory leaks
- **Inefficient Algorithms**: Replace with better algorithms
- **Caching**: Cache frequently accessed data
- **Database Optimization**: Optimize slow queries

## PROFILING BEST PRACTICES

### Development Profiling
- Use instrumentation profilers (Xdebug, cProfile)
- Enable profiling during development
- Profile before and after optimizations
- Use flame graphs for visualization

### Production Profiling
- Use sampling profilers (py-spy, async-profiler)
- Low overhead (< 5%)
- Don't profile all requests (sample 1-5%)
- Don't profile long-running processes

### Profiling Tips
- Profile realistic workloads
- Profile in production-like environment
- Don't optimize prematurely (measure first)
- Focus on hot paths (80/20 rule)
- Look for N+1 queries, missing indexes
- Check for memory leaks, resource leaks

## COMMON PERFORMANCE ISSUES

### CPU Bottlenecks
- **Symptoms**: High CPU usage, slow response times
- **Detection**: CPU profiling
- **Causes**: Inefficient algorithms, hot loops, excessive calculations
- **Fixes**: Optimize algorithms, cache results, use faster data structures

### Memory Leaks
- **Symptoms**: Increasing memory usage, OOM kills
- **Detection**: Memory profiling, heap snapshots
- **Causes**: Unreleased references, circular references, caching without expiration
- **Fixes**: Fix circular references, clear caches, use weak references

### I/O Bottlenecks
- **Symptoms**: High I/O wait, slow disk/network operations
- **Detection**: System profiling (strace, iostat, netstat)
- **Causes**: Slow disk, network latency, excessive database queries
- **Fixes**: Use caching, batch operations, async I/O

### Database Bottlenecks
- **Symptoms**: Slow queries, database timeouts
- **Detection**: Query profiling, slow query log
- **Causes**: Missing indexes, N+1 queries, inefficient queries
- **Fixes**: Add indexes, optimize queries, use eager loading
