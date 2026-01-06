# Prompt Optimization Guide

## Systematic Refinement Process

### 1. Baseline Establishment

```python
import time
from typing import Dict, List, Any
import statistics

def establish_baseline(prompt: str, test_cases: List[Dict[str, Any]]) -> Dict[str, float]:
    """Establish baseline performance metrics for a prompt."""
    results = {
        'accuracy': [],
        'tokens': [],
        'latency': [],
        'success': []
    }

    for test_case in test_cases:
        try:
            start_time = time.time()
            # Assuming you have an LLM client
            response = call_llm(prompt.format(**test_case['input']))
            latency = time.time() - start_time

            # Calculate metrics
            accuracy = calculate_accuracy(response, test_case['expected'])
            token_count = estimate_tokens(response)
            is_success = validate_response(response, test_case.get('validation_rules', {}))

            results['accuracy'].append(accuracy)
            results['tokens'].append(token_count)
            results['latency'].append(latency)
            results['success'].append(1 if is_success else 0)

        except Exception as e:
            print(f"Error processing test case: {e}")
            # Record failure metrics
            results['accuracy'].append(0)
            results['tokens'].append(0)
            results['latency'].append(10.0)  # Max timeout
            results['success'].append(0)

    return {
        'avg_accuracy': statistics.mean(results['accuracy']),
        'avg_tokens': statistics.mean(results['tokens']),
        'avg_latency': statistics.mean(results['latency']),
        'success_rate': statistics.mean(results['success']),
        'accuracy_std': statistics.stdev(results['accuracy']) if len(results['accuracy']) > 1 else 0,
        'latency_p95': sorted(results['latency'])[int(len(results['latency']) * 0.95)]
    }

# Helper functions
def call_llm(prompt: str) -> str:
    """Placeholder for LLM API call."""
    # In practice: return openai.ChatCompletion.create(...) or similar
    return "Mock LLM response"

def calculate_accuracy(response: str, expected: str) -> float:
    """Calculate semantic similarity (placeholder)."""
    # In practice: use sentence transformers or exact match
    return 1.0 if response.strip().lower() == expected.strip().lower() else 0.0

def estimate_tokens(text: str) -> int:
    """Estimate token count (placeholder)."""
    # In practice: use tiktoken or similar
    return len(text.split()) * 1.3  # Rough approximation

def validate_response(response: str, rules: Dict[str, Any]) -> bool:
    """Validate response against rules."""
    if 'max_length' in rules and len(response) > rules['max_length']:
        return False
    if 'required_keywords' in rules:
        for keyword in rules['required_keywords']:
            if keyword.lower() not in response.lower():
                return False
    return True

# Usage example
test_cases = [
    {
        'input': {'query': 'What is 2+2?'},
        'expected': '4',
        'validation_rules': {'max_length': 10}
    }
]

baseline_metrics = establish_baseline("Calculate: {query}", test_cases)
print(f"Baseline accuracy: {baseline_metrics['avg_accuracy']:.2f}")
```

### Good vs Bad Baseline Practices

```python
### ❌ WRONG - Insufficient Test Coverage
```python
def bad_baseline(prompt, test_cases):
    # Only tests 3 cases, no error handling
    results = []
    for case in test_cases[:3]:  # Too few cases!
        result = llm_call(prompt.format(**case))
        results.append(result == case['expected'])  # Exact match only
    return sum(results) / len(results)  # No statistical analysis
```

### ✅ CORRECT - Comprehensive Baseline
```python
def good_baseline(prompt, test_cases, num_runs=3):
    """Run multiple times per case, handle errors, collect statistics."""
    all_results = []

    for case in test_cases:
        case_results = []
        for _ in range(num_runs):  # Multiple runs for consistency
            try:
                response = call_llm_with_timeout(prompt.format(**case['input']), timeout=30)
                accuracy = semantic_similarity(response, case['expected'])
                case_results.append({
                    'accuracy': accuracy,
                    'tokens': count_tokens(response),
                    'latency': measure_latency()
                })
            except TimeoutError:
                case_results.append({'accuracy': 0, 'tokens': 0, 'latency': 30, 'error': 'timeout'})
            except Exception as e:
                case_results.append({'accuracy': 0, 'tokens': 0, 'latency': 10, 'error': str(e)})

        all_results.append(case_results)

    # Calculate comprehensive statistics
    return analyze_baseline_statistics(all_results)
```

### 2. Iterative Refinement Workflow
```
Initial Prompt → Test → Analyze Failures → Refine → Test → Repeat
```

```python
class PromptOptimizer:
    def __init__(self, initial_prompt, test_suite):
        self.prompt = initial_prompt
        self.test_suite = test_suite
        self.history = []

    def optimize(self, max_iterations=10):
        for i in range(max_iterations):
            # Test current prompt
            results = self.evaluate_prompt(self.prompt)
            self.history.append({
                'iteration': i,
                'prompt': self.prompt,
                'results': results
            })

            # Stop if good enough
            if results['accuracy'] > 0.95:
                break

            # Analyze failures
            failures = self.analyze_failures(results)

            # Generate refinement suggestions
            refinements = self.generate_refinements(failures)

            # Apply best refinement
            self.prompt = self.select_best_refinement(refinements)

        return self.get_best_prompt()
```

### 3. A/B Testing Framework

```python
import random
import numpy as np
import statistics
from typing import Dict, List, Any, Tuple
from dataclasses import dataclass
import time

@dataclass
class ABTestResult:
    variant: str
    response: str
    accuracy: float
    latency: float
    tokens: int
    error: str = None

class RobustPromptABTest:
    def __init__(self, variant_a: str, variant_b: str, llm_client=None):
        self.variant_a = variant_a
        self.variant_b = variant_b
        self.llm_client = llm_client or self._default_llm_client()

    def _default_llm_client(self):
        """Placeholder LLM client."""
        class MockLLM:
            def complete(self, prompt, **kwargs):
                time.sleep(0.1)  # Simulate latency
                return f"Response to: {prompt[:50]}..."
        return MockLLM()

    def run_balanced_test(self, test_queries: List[Dict[str, Any]],
                         metrics: List[str] = None,
                         min_samples_per_variant: int = 30) -> Dict[str, Any]:
        """Run balanced A/B test ensuring equal sample sizes."""

        if metrics is None:
            metrics = ['accuracy', 'latency', 'tokens']

        results = {'A': [], 'B': []}

        # Continue testing until we have enough samples
        query_index = 0
        while len(results['A']) < min_samples_per_variant or len(results['B']) < min_samples_per_variant:
            query = test_queries[query_index % len(test_queries)]

            # Balanced assignment: alternate when counts are equal, random otherwise
            if len(results['A']) == len(results['B']):
                variant = 'A' if random.random() < 0.5 else 'B'
            elif len(results['A']) < len(results['B']):
                variant = 'A'
            else:
                variant = 'B'

            # Run test
            result = self._run_single_test(variant, query)
            results[variant].append(result)

            query_index += 1

        return self._analyze_results(results, metrics)

    def _run_single_test(self, variant: str, query: Dict[str, Any]) -> ABTestResult:
        """Run a single test case."""
        prompt_template = self.variant_a if variant == 'A' else self.variant_b

        try:
            start_time = time.time()
            formatted_prompt = prompt_template.format(**query.get('input', {}))
            response = self.llm_client.complete(formatted_prompt)
            latency = time.time() - start_time

            accuracy = self._calculate_accuracy(response, query.get('expected', ''))
            tokens = self._estimate_tokens(response)

            return ABTestResult(variant, response, accuracy, latency, tokens)

        except Exception as e:
            return ABTestResult(variant, "", 0, 10.0, 0, str(e))

    def _calculate_accuracy(self, response: str, expected: str) -> float:
        """Calculate accuracy score."""
        if not expected:
            return 1.0 if response else 0.0

        # Simple semantic similarity (in practice, use embeddings)
        response_words = set(response.lower().split())
        expected_words = set(expected.lower().split())
        intersection = response_words.intersection(expected_words)
        union = response_words.union(expected_words)
        return len(intersection) / len(union) if union else 0

    def _estimate_tokens(self, text: str) -> int:
        """Estimate token count."""
        return len(text.split()) * 1.3  # Rough approximation

    def _analyze_results(self, results: Dict[str, List[ABTestResult]],
                        metrics: List[str]) -> Dict[str, Any]:
        """Analyze test results with statistical rigor."""

        analysis = {}

        for metric in metrics:
            a_values = [getattr(r, metric) for r in results['A'] if r.error is None]
            b_values = [getattr(r, metric) for r in results['B'] if r.error is None]

            if not a_values or not b_values:
                analysis[metric] = {'error': 'Insufficient valid data'}
                continue

            # Basic statistics
            a_mean, a_std = statistics.mean(a_values), statistics.stdev(a_values) if len(a_values) > 1 else 0
            b_mean, b_std = statistics.mean(b_values), statistics.stdev(b_values) if len(b_values) > 1 else 0

            # Statistical significance (simplified t-test)
            try:
                t_stat = (b_mean - a_mean) / np.sqrt((a_std**2/len(a_values)) + (b_std**2/len(b_values)))
                # Approximate p-value (two-tailed)
                p_value = 2 * (1 - self._normal_cdf(abs(t_stat)))
                significant = p_value < 0.05
            except:
                t_stat, p_value, significant = 0, 1, False

            improvement = (b_mean - a_mean) / a_mean if a_mean != 0 else 0

            analysis[metric] = {
                'A_mean': a_mean, 'A_std': a_std, 'A_samples': len(a_values),
                'B_mean': b_mean, 'B_std': b_std, 'B_samples': len(b_values),
                'improvement': improvement,
                'improvement_pct': improvement * 100,
                't_statistic': t_stat,
                'p_value': p_value,
                'statistically_significant': significant,
                'winner': 'B' if b_mean > a_mean else 'A',
                'confidence_level': '95%' if significant else 'Not significant'
            }

        # Overall assessment
        significant_improvements = sum(1 for m in analysis.values()
                                     if isinstance(m, dict) and m.get('statistically_significant', False))

        analysis['summary'] = {
            'total_metrics': len(metrics),
            'significant_improvements': significant_improvements,
            'recommendation': 'Deploy B' if significant_improvements >= len(metrics) // 2 else 'Keep A',
            'confidence': 'High' if significant_improvements > len(metrics) // 2 else 'Low'
        }

        return analysis

    def _normal_cdf(self, x: float) -> float:
        """Approximate normal CDF for p-value calculation."""
        return 0.5 * (1 + np.sign(x) * np.sqrt(1 - np.exp(-2 * x**2 / np.pi)))

# Usage example
test_queries = [
    {'input': {'question': 'What is the capital of France?'}, 'expected': 'Paris'},
    {'input': {'question': 'Calculate 15 * 7'}, 'expected': '105'}
]

ab_test = RobustPromptABTest(
    variant_a="Answer this question: {question}",
    variant_b="Please provide a detailed answer to: {question}"
)

results = ab_test.run_balanced_test(test_queries, min_samples_per_variant=10)
print(f"Winner: {results['summary']['recommendation']}")
print(f"Confidence: {results['summary']['confidence']}")
```

### Good vs Bad A/B Testing

```python
### ❌ WRONG - Biased Test Design
```python
def bad_ab_test(variant_a, variant_b, queries):
    results = {'A': [], 'B': []}
    for query in queries:
        # Always test A first, then B - creates ordering bias!
        result_a = test_prompt(variant_a, query)
        result_b = test_prompt(variant_b, query)
        results['A'].append(result_a)
        results['B'].append(result_b)
    return results  # No statistical analysis
```

### ✅ CORRECT - Rigorous A/B Testing
```python
def good_ab_test(variant_a, variant_b, queries, min_samples=100):
    """Proper A/B testing with randomization and statistics."""
    results = {'A': [], 'B': []}

    # Ensure balanced sample sizes
    target_per_variant = min_samples // 2

    while len(results['A']) < target_per_variant or len(results['B']) < target_per_variant:
        query = random.choice(queries)  # Random query selection

        # Random variant assignment
        variant = 'A' if random.random() < 0.5 else 'B'
        prompt = variant_a if variant == 'A' else variant_b

        try:
            result = run_with_timeout_and_metrics(prompt, query, timeout=30)
            results[variant].append(result)
        except Exception as e:
            # Record failures
            results[variant].append({'error': str(e), 'accuracy': 0})

    # Statistical analysis
    return perform_statistical_analysis(results)
```

## Optimization Strategies

### Token Reduction

```python
import re
from typing import List, Tuple, Dict
from collections import Counter

class TokenOptimizer:
    def __init__(self):
        self.optimizations = [
            # Phrase replacements
            (r'\bin order to\b', 'to'),
            (r'\bdue to the fact that\b', 'because'),
            (r'\bat this point in time\b', 'now'),
            (r'\bit is important to note that\b', 'note that'),
            (r'\bplease note that\b', 'note that'),

            # Instruction consolidation patterns
            (r'First, (.*?)\nThen, (.*?)\nFinally, (.*?)$', r'Steps: 1) \1 2) \2 3) \3'),

            # Filler word removal
            (r'\s+actually\s+', ' '),
            (r'\s+basically\s+', ' '),
            (r'\s+really\s+', ' '),
            (r'\s+very\s+', ' '),
            (r'\s+quite\s+', ' '),
        ]

    def optimize_prompt(self, prompt: str, target_reduction: float = 0.2) -> Dict[str, Any]:
        """Optimize prompt for token efficiency with error handling."""
        original_tokens = self._estimate_tokens(prompt)
        optimized = prompt

        # Apply optimizations
        for pattern, replacement in self.optimizations:
            try:
                optimized = re.sub(pattern, replacement, optimized, flags=re.IGNORECASE)
            except re.error as e:
                print(f"Regex error in pattern {pattern}: {e}")
                continue

        # Clean up extra whitespace
        optimized = re.sub(r'\s+', ' ', optimized.strip())

        # Restore critical formatting
        optimized = self._restore_critical_formatting(optimized, prompt)

        new_tokens = self._estimate_tokens(optimized)
        reduction = (original_tokens - new_tokens) / original_tokens

        # If we didn't achieve target reduction, try more aggressive optimizations
        if reduction < target_reduction:
            optimized = self._aggressive_optimization(optimized)

        final_tokens = self._estimate_tokens(optimized)
        final_reduction = (original_tokens - final_tokens) / original_tokens

        return {
            'original_prompt': prompt,
            'optimized_prompt': optimized,
            'original_tokens': original_tokens,
            'optimized_tokens': final_tokens,
            'reduction': final_reduction,
            'reduction_pct': final_reduction * 100,
            'success': final_reduction >= target_reduction * 0.5  # At least 50% of target
        }

    def _estimate_tokens(self, text: str) -> int:
        """Estimate token count using GPT-style approximation."""
        # Rough approximation: ~4 characters per token for English text
        return max(1, len(text) // 4)

    def _restore_critical_formatting(self, optimized: str, original: str) -> str:
        """Restore critical formatting that may have been lost."""
        # Restore list formatting if it was consolidated
        if 'Steps:' in optimized and '\n' not in optimized:
            # Convert "Steps: 1) ... 2) ... 3) ..." back to multi-line
            optimized = optimized.replace('Steps: ', 'Steps:\n')

        # Ensure proper spacing around punctuation
        optimized = re.sub(r'([.!?])(\w)', r'\1 \2', optimized)

        return optimized

    def _aggressive_optimization(self, prompt: str) -> str:
        """Apply more aggressive optimizations when needed."""
        aggressive_opts = [
            # Remove optional polite phrases
            (r'\bplease\s+', ''),
            (r'\bcould you\s+', ''),
            (r'\bwould you\s+', ''),

            # Shorten common phrases
            (r'\bfor example\b', 'e.g.'),
            (r'\bthat is\b', 'i.e.'),
            (r'\bwith regard to\b', 'regarding'),
        ]

        for pattern, replacement in aggressive_opts:
            prompt = re.sub(pattern, replacement, prompt, flags=re.IGNORECASE)

        return prompt.strip()

# Usage with error handling
optimizer = TokenOptimizer()

test_prompt = """
Please provide a detailed analysis of the following text. First, identify the main topic.
Then, extract key arguments. Finally, provide a conclusion. It is important to note that
you should base your analysis on the provided text only.
"""

try:
    result = optimizer.optimize_prompt(test_prompt, target_reduction=0.15)
    print(f"Token reduction: {result['reduction_pct']:.1f}%")
    print(f"Optimized: {result['optimized_prompt']}")
except Exception as e:
    print(f"Optimization failed: {e}")
    # Fallback: return original prompt
    result = {'optimized_prompt': test_prompt, 'error': str(e)}
```

### Error Scenarios in Token Optimization

```python
### ❌ WRONG - Optimization Breaks Prompt Logic
```python
def bad_token_optimization(prompt):
    # Blindly removes words without checking context
    replacements = [('the', ''), ('a', ''), ('an', '')]  # Removes articles!
    for old, new in replacements:
        prompt = prompt.replace(old, new)
    return prompt  # Results in gibberish: "quick brown fox jumps over lazy dog"
```

### ✅ CORRECT - Context-Aware Optimization
```python
def safe_token_optimization(prompt):
    """Optimize tokens while preserving meaning."""
    # Analyze prompt structure first
    structure = analyze_prompt_structure(prompt)

    if structure['has_lists']:
        # Don't remove articles from list items
        return prompt

    if structure['has_examples']:
        # Keep examples intact
        return prompt

    # Safe optimizations only
    safe_opts = [
        (r'\s+', ' '),  # Multiple spaces to single
        (r'^\s+', ''),  # Leading whitespace
        (r'\s+$', ''),  # Trailing whitespace
    ]

    for pattern, replacement in safe_opts:
        prompt = re.sub(pattern, replacement, prompt)

    return prompt
```

### Latency Reduction
```python
def optimize_for_latency(prompt):
    strategies = {
        'shorter_prompt': reduce_token_count(prompt),
        'streaming': enable_streaming_response(prompt),
        'caching': add_cacheable_prefix(prompt),
        'early_stopping': add_stop_sequences(prompt)
    }

    # Test each strategy
    best_strategy = None
    best_latency = float('inf')

    for name, modified_prompt in strategies.items():
        latency = measure_average_latency(modified_prompt)
        if latency < best_latency:
            best_latency = latency
            best_strategy = modified_prompt

    return best_strategy
```

### Accuracy Improvement

```python
from typing import List, Dict, Any
import re
from collections import Counter

class AccuracyImprover:
    def __init__(self):
        self.failure_patterns = {
            'format_errors': [
                r'(?i)json.*parse.*error',
                r'(?i)invalid.*format',
                r'(?i)malformed.*output'
            ],
            'factual_errors': [
                r'(?i)hallucinat',
                r'(?i)incorrect.*fact',
                r'(?i)wrong.*answer'
            ],
            'logical_errors': [
                r'(?i)inconsistent',
                r'(?i)contradict',
                r'(?i)logical.*error'
            ],
            'incomplete_responses': [
                r'(?i)incomplete',
                r'(?i)missing.*information',
                r'(?i)partial.*answer'
            ]
        }

    def analyze_failures(self, test_results: List[Dict[str, Any]]) -> Dict[str, List[Dict]]:
        """Analyze test failures to identify patterns."""
        categorized_failures = {
            'format_errors': [],
            'factual_errors': [],
            'logical_errors': [],
            'incomplete_responses': [],
            'other': []
        }

        for result in test_results:
            if not result.get('success', True):
                error_msg = result.get('error', '').lower()
                response = result.get('response', '').lower()

                # Check for pattern matches
                categorized = False
                for category, patterns in self.failure_patterns.items():
                    for pattern in patterns:
                        if re.search(pattern, error_msg) or re.search(pattern, response):
                            categorized_failures[category].append(result)
                            categorized = True
                            break
                    if categorized:
                        break

                if not categorized:
                    categorized_failures['other'].append(result)

        return categorized_failures

    def generate_improvements(self, categorized_failures: Dict[str, List[Dict]],
                            original_prompt: str) -> List[Dict[str, Any]]:
        """Generate specific improvement suggestions based on failure analysis."""
        improvements = []

        # Format errors
        if categorized_failures['format_errors']:
            severity = len(categorized_failures['format_errors']) / len(sum(categorized_failures.values(), []))
            improvements.append({
                'type': 'format_constraint',
                'priority': 'high' if severity > 0.3 else 'medium',
                'suggestion': 'Add explicit format requirements and examples',
                'fix': self._generate_format_fix(categorized_failures['format_errors']),
                'expected_impact': f"Reduce format errors by {min(severity * 100, 80):.0f}%"
            })

        # Factual errors (hallucinations)
        if categorized_failures['factual_errors']:
            improvements.append({
                'type': 'grounding_instruction',
                'priority': 'critical',
                'suggestion': 'Add grounding instructions to prevent hallucinations',
                'fix': 'Base your answer only on the provided context. If information is not available, explicitly state "Not found in provided context."',
                'expected_impact': 'Reduce hallucinations by 60-80%'
            })

        # Logical errors
        if categorized_failures['logical_errors']:
            improvements.append({
                'type': 'verification_step',
                'priority': 'high',
                'suggestion': 'Add self-verification requirement',
                'fix': 'After formulating your answer, verify it is logically consistent and mathematically correct.',
                'expected_impact': 'Reduce logical errors by 50-70%'
            })

        # Incomplete responses
        if categorized_failures['incomplete_responses']:
            improvements.append({
                'type': 'completeness_check',
                'priority': 'medium',
                'suggestion': 'Add completeness requirements',
                'fix': 'Ensure your response fully addresses all parts of the query. List the specific requirements and confirm each is addressed.',
                'expected_impact': 'Reduce incomplete responses by 40-60%'
            })

        # Edge cases
        edge_cases = self._identify_edge_cases(categorized_failures)
        if edge_cases:
            improvements.append({
                'type': 'edge_case_examples',
                'priority': 'medium',
                'suggestion': 'Add examples for common edge cases',
                'fix': self._generate_edge_case_examples(edge_cases),
                'expected_impact': 'Improve edge case handling by 30-50%'
            })

        return sorted(improvements, key=lambda x: self._priority_score(x['priority']), reverse=True)

    def _generate_format_fix(self, format_errors: List[Dict]) -> str:
        """Generate specific format fixes based on error patterns."""
        error_responses = [err.get('response', '') for err in format_errors]

        # Detect common format issues
        if any('json' in resp.lower() for resp in error_responses):
            return 'Output must be valid JSON. Example: {"result": "answer", "confidence": 0.95}'

        if any(':' not in resp and len(resp.split()) > 10 for resp in error_responses):
            return 'Structure your answer with clear sections using headers like "Analysis:", "Conclusion:"'

        return 'Specify exact output format requirements with concrete examples.'

    def _identify_edge_cases(self, categorized_failures: Dict[str, List]) -> List[str]:
        """Identify common edge cases from failures."""
        all_failures = sum(categorized_failures.values(), [])
        inputs = [f.get('input', '') for f in all_failures if f.get('input')]

        edge_indicators = [
            'empty', 'null', 'none', 'zero', 'maximum', 'minimum',
            'special characters', 'unicode', 'very long', 'very short'
        ]

        edge_cases = []
        for indicator in edge_indicators:
            if any(indicator in inp.lower() for inp in inputs):
                edge_cases.append(indicator)

        return list(set(edge_cases))[:3]  # Top 3 edge cases

    def _generate_edge_case_examples(self, edge_cases: List[str]) -> str:
        """Generate examples for identified edge cases."""
        examples = []
        for case in edge_cases:
            if 'empty' in case:
                examples.append('Input: "" → Output: "Please provide input text."')
            elif 'long' in case:
                examples.append('Input: [very long text] → Output: "Input exceeds maximum length. Please provide a shorter query."')
            elif 'special' in case:
                examples.append('Input: "!@#$%" → Output: "Invalid input format. Please use alphanumeric characters."')

        return 'Handle edge cases:\n' + '\n'.join(examples)

    def _priority_score(self, priority: str) -> int:
        """Convert priority to numeric score for sorting."""
        scores = {'critical': 4, 'high': 3, 'medium': 2, 'low': 1}
        return scores.get(priority, 0)

    def apply_improvements(self, original_prompt: str, improvements: List[Dict[str, Any]]) -> str:
        """Apply selected improvements to the prompt."""
        improved_prompt = original_prompt

        for improvement in improvements:
            if improvement['priority'] in ['critical', 'high']:
                # Add improvement to prompt
                addition = f"\n\n{improvement['fix']}"
                improved_prompt += addition

        return improved_prompt

# Usage example
improver = AccuracyImprover()

# Simulate test results with failures
test_results = [
    {'success': False, 'error': 'JSON parse error', 'response': 'invalid json', 'input': 'query1'},
    {'success': False, 'error': 'hallucination detected', 'response': 'made up fact', 'input': 'query2'},
    {'success': False, 'error': 'incomplete response', 'response': 'partial answer', 'input': 'query3'}
]

failures = improver.analyze_failures(test_results)
improvements = improver.generate_improvements(failures, "Original prompt")

for imp in improvements:
    print(f"{imp['priority'].upper()}: {imp['suggestion']} - Impact: {imp['expected_impact']}")

improved_prompt = improver.apply_improvements("Original prompt", improvements)
print(f"Improved prompt: {improved_prompt}")
```

### Good vs Bad Accuracy Improvement

```python
### ❌ WRONG - Over-Correction Creates New Problems
```python
def bad_accuracy_improvement(prompt, failures):
    # Adds so many constraints it confuses the model
    if failures:
        new_prompt = prompt + """
CRITICAL: Follow these 50 rules exactly:
1. Never make mistakes
2. Always be 100% accurate
3. Check everything 3 times
4. Use only approved words
... [47 more rules]
"""
    return new_prompt  # Model becomes paralyzed by over-constraining
```

### ✅ CORRECT - Targeted, Iterative Improvements
```python
def good_accuracy_improvement(prompt, failures, max_improvements=3):
    """Apply only the most impactful improvements."""
    improvements = analyze_failures_smartly(failures)

    # Sort by expected impact and ease of implementation
    prioritized = sorted(improvements,
                        key=lambda x: x['impact'] * x['ease'],
                        reverse=True)

    # Apply only top improvements to avoid over-constraining
    improved_prompt = prompt
    for imp in prioritized[:max_improvements]:
        if imp['confidence'] > 0.7:  # Only high-confidence improvements
            improved_prompt += f"\n\n{imp['fix']}"

    return improved_prompt
```

## Performance Metrics

### Core Metrics
```python
class PromptMetrics:
    @staticmethod
    def accuracy(responses, ground_truth):
        return sum(r == gt for r, gt in zip(responses, ground_truth)) / len(responses)

    @staticmethod
    def consistency(responses):
        # Measure how often identical inputs produce identical outputs
        from collections import defaultdict
        input_responses = defaultdict(list)

        for inp, resp in responses:
            input_responses[inp].append(resp)

        consistency_scores = []
        for inp, resps in input_responses.items():
            if len(resps) > 1:
                # Percentage of responses that match the most common response
                most_common_count = Counter(resps).most_common(1)[0][1]
                consistency_scores.append(most_common_count / len(resps))

        return np.mean(consistency_scores) if consistency_scores else 1.0

    @staticmethod
    def token_efficiency(prompt, responses):
        avg_prompt_tokens = np.mean([count_tokens(prompt.format(**r['input'])) for r in responses])
        avg_response_tokens = np.mean([count_tokens(r['output']) for r in responses])
        return avg_prompt_tokens + avg_response_tokens

    @staticmethod
    def latency_p95(latencies):
        return np.percentile(latencies, 95)
```

### Automated Evaluation
```python
def evaluate_prompt_comprehensively(prompt, test_suite):
    results = {
        'accuracy': [],
        'consistency': [],
        'latency': [],
        'tokens': [],
        'success_rate': []
    }

    # Run each test case multiple times for consistency measurement
    for test_case in test_suite:
        runs = []
        for _ in range(3):  # 3 runs per test case
            start = time.time()
            response = llm.complete(prompt.format(**test_case['input']))
            latency = time.time() - start

            runs.append(response)
            results['latency'].append(latency)
            results['tokens'].append(count_tokens(prompt) + count_tokens(response))

        # Accuracy (best of 3 runs)
        accuracies = [evaluate_accuracy(r, test_case['expected']) for r in runs]
        results['accuracy'].append(max(accuracies))

        # Consistency (how similar are the 3 runs?)
        results['consistency'].append(calculate_similarity(runs))

        # Success rate (all runs successful?)
        results['success_rate'].append(all(is_valid(r) for r in runs))

    return {
        'avg_accuracy': np.mean(results['accuracy']),
        'avg_consistency': np.mean(results['consistency']),
        'p95_latency': np.percentile(results['latency'], 95),
        'avg_tokens': np.mean(results['tokens']),
        'success_rate': np.mean(results['success_rate'])
    }
```

## Failure Analysis

### Categorizing Failures
```python
class FailureAnalyzer:
    def categorize_failures(self, test_results):
        categories = {
            'format_errors': [],
            'factual_errors': [],
            'logic_errors': [],
            'incomplete_responses': [],
            'hallucinations': [],
            'off_topic': []
        }

        for result in test_results:
            if not result['success']:
                category = self.determine_failure_type(
                    result['response'],
                    result['expected']
                )
                categories[category].append(result)

        return categories

    def generate_fixes(self, categorized_failures):
        fixes = []

        if categorized_failures['format_errors']:
            fixes.append({
                'issue': 'Format errors',
                'fix': 'Add explicit format examples and constraints',
                'priority': 'high'
            })

        if categorized_failures['hallucinations']:
            fixes.append({
                'issue': 'Hallucinations',
                'fix': 'Add grounding instruction: "Base your answer only on provided context"',
                'priority': 'critical'
            })

        if categorized_failures['incomplete_responses']:
            fixes.append({
                'issue': 'Incomplete responses',
                'fix': 'Add: "Ensure your response fully addresses all parts of the question"',
                'priority': 'medium'
            })

        return fixes
```

## Versioning and Rollback

### Prompt Version Control
```python
class PromptVersionControl:
    def __init__(self, storage_path):
        self.storage = storage_path
        self.versions = []

    def save_version(self, prompt, metadata):
        version = {
            'id': len(self.versions),
            'prompt': prompt,
            'timestamp': datetime.now(),
            'metrics': metadata.get('metrics', {}),
            'description': metadata.get('description', ''),
            'parent_id': metadata.get('parent_id')
        }
        self.versions.append(version)
        self.persist()
        return version['id']

    def rollback(self, version_id):
        if version_id < len(self.versions):
            return self.versions[version_id]['prompt']
        raise ValueError(f"Version {version_id} not found")

    def compare_versions(self, v1_id, v2_id):
        v1 = self.versions[v1_id]
        v2 = self.versions[v2_id]

        return {
            'diff': generate_diff(v1['prompt'], v2['prompt']),
            'metrics_comparison': {
                metric: {
                    'v1': v1['metrics'].get(metric),
                    'v2': v2['metrics'].get(metric'),
                    'change': v2['metrics'].get(metric, 0) - v1['metrics'].get(metric, 0)
                }
                for metric in set(v1['metrics'].keys()) | set(v2['metrics'].keys())
            }
        }
```

## Best Practices

1. **Establish Baseline**: Always measure initial performance
2. **Change One Thing**: Isolate variables for clear attribution
3. **Test Thoroughly**: Use diverse, representative test cases
4. **Track Metrics**: Log all experiments and results
5. **Validate Significance**: Use statistical tests for A/B comparisons
6. **Document Changes**: Keep detailed notes on what and why
7. **Version Everything**: Enable rollback to previous versions
8. **Monitor Production**: Continuously evaluate deployed prompts

## Common Optimization Patterns

### Pattern 1: Add Structure
```
Before: "Analyze this text"
After: "Analyze this text for:\n1. Main topic\n2. Key arguments\n3. Conclusion"
```

### Pattern 2: Add Examples
```
Before: "Extract entities"
After: "Extract entities\\n\\nExample:\\nText: Apple released iPhone\\nEntities: {company: Apple, product: iPhone}"
```

### Pattern 3: Add Constraints
```
Before: "Summarize this"
After: "Summarize in exactly 3 bullet points, 15 words each"
```

### Pattern 4: Add Verification
```
Before: "Calculate..."
After: "Calculate... Then verify your calculation is correct before responding."
```

## Tools and Utilities

- Prompt diff tools for version comparison
- Automated test runners
- Metric dashboards
- A/B testing frameworks
- Token counting utilities
- Latency profilers
