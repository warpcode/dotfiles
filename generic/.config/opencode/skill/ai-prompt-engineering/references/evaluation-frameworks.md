# Evaluation Frameworks Guide

Implement comprehensive evaluation systems to measure, compare, and optimize prompt performance through automated testing and benchmarking.

## Automated Testing Infrastructure

Build robust evaluation pipelines for continuous prompt assessment.

### Test Suite Architecture

```python
from typing import Dict, List, Any
from dataclasses import dataclass
import json
import statistics

@dataclass
class TestCase:
    id: str
    input: str
    expected_output: str
    category: str
    difficulty: str

@dataclass
class TestResult:
    test_case_id: str
    actual_output: str
    score: float
    latency: float
    tokens_used: int
    metadata: Dict[str, Any]

class PromptEvaluator:
    def __init__(self, test_cases: List[TestCase]):
        self.test_cases = test_cases
        self.results_history = []

    def evaluate_prompt(self, prompt_function, test_subset: List[str] = None) -> Dict[str, Any]:
        """Evaluate a prompt function against test cases."""

        test_set = self.test_cases
        if test_subset:
            test_set = [tc for tc in self.test_cases if tc.id in test_subset]

        results = []
        total_latency = 0
        total_tokens = 0

        for test_case in test_set:
            # Execute prompt
            start_time = time.time()
            actual_output = prompt_function(test_case.input)
            latency = time.time() - start_time

            # Score result
            score = self._calculate_score(actual_output, test_case.expected_output)

            # Estimate tokens (simplified)
            tokens_used = len(actual_output.split()) + len(test_case.input.split())

            result = TestResult(
                test_case_id=test_case.id,
                actual_output=actual_output,
                score=score,
                latency=latency,
                tokens_used=tokens_used,
                metadata={'category': test_case.category, 'difficulty': test_case.difficulty}
            )

            results.append(result)
            total_latency += latency
            total_tokens += tokens_used

        # Calculate aggregate metrics
        scores = [r.score for r in results]
        latencies = [r.latency for r in results]

        evaluation_summary = {
            'total_tests': len(results),
            'average_score': statistics.mean(scores),
            'median_score': statistics.median(scores),
            'score_std_dev': statistics.stdev(scores) if len(scores) > 1 else 0,
            'average_latency': total_latency / len(results),
            'median_latency': statistics.median(latencies),
            'total_tokens': total_tokens,
            'average_tokens': total_tokens / len(results),
            'results': [self._result_to_dict(r) for r in results]
        }

        self.results_history.append(evaluation_summary)
        return evaluation_summary

    def _calculate_score(self, actual: str, expected: str) -> float:
        """Calculate similarity score between actual and expected output."""
        # Simplified semantic similarity - in practice use embeddings
        actual_words = set(actual.lower().split())
        expected_words = set(expected.lower().split())

        intersection = actual_words.intersection(expected_words)
        union = actual_words.union(expected_words)

        return len(intersection) / len(union) if union else 0

    def _result_to_dict(self, result: TestResult) -> Dict:
        """Convert TestResult to dictionary."""
        return {
            'test_case_id': result.test_case_id,
            'score': result.score,
            'latency': result.latency,
            'tokens_used': result.tokens_used,
            'metadata': result.metadata
        }
```

### Benchmark Dataset Management

```python
class BenchmarkManager:
    def __init__(self, benchmark_dir: str):
        self.benchmark_dir = benchmark_dir
        self.benchmarks = self._load_benchmarks()

    def _load_benchmarks(self) -> Dict[str, List[TestCase]]:
        """Load benchmark datasets from disk."""
        benchmarks = {}
        benchmark_files = ['truthful_qa.json', 'gsm8k.json', 'human_eval.json']

        for filename in benchmark_files:
            filepath = f"{self.benchmark_dir}/{filename}"
            try:
                with open(filepath, 'r') as f:
                    data = json.load(f)
                    benchmarks[filename.replace('.json', '')] = [
                        TestCase(**item) for item in data
                    ]
            except FileNotFoundError:
                print(f"Benchmark file {filename} not found")

        return benchmarks

    def get_benchmark(self, name: str, subset_size: int = None) -> List[TestCase]:
        """Retrieve a benchmark dataset, optionally with subset."""
        if name not in self.benchmarks:
            raise ValueError(f"Benchmark '{name}' not found")

        benchmark = self.benchmarks[name]
        if subset_size and subset_size < len(benchmark):
            # Random subset for faster evaluation
            import random
            return random.sample(benchmark, subset_size)

        return benchmark

    def add_custom_benchmark(self, name: str, test_cases: List[TestCase]):
        """Add a custom benchmark dataset."""
        self.benchmarks[name] = test_cases

        # Save to disk
        filepath = f"{self.benchmark_dir}/{name}.json"
        with open(filepath, 'w') as f:
            json.dump([{
                'id': tc.id,
                'input': tc.input,
                'expected_output': tc.expected_output,
                'category': tc.category,
                'difficulty': tc.difficulty
            } for tc in test_cases], f, indent=2)
```

## A/B Testing Framework

Compare prompt variations systematically to identify optimal configurations.

### Experiment Design

```python
from abc import ABC, abstractmethod
import numpy as np

class Experiment(ABC):
    @abstractmethod
    def run_trial(self, variant: str, test_input: str) -> Dict[str, Any]:
        pass

    @abstractmethod
    def analyze_results(self, results: List[Dict]) -> Dict[str, Any]:
        pass

class PromptABTest(Experiment):
    def __init__(self, variants: Dict[str, callable]):
        self.variants = variants  # {'variant_a': prompt_func_a, 'variant_b': prompt_func_b}

    def run_trial(self, variant: str, test_input: str) -> Dict[str, Any]:
        """Run a single trial for a prompt variant."""
        if variant not in self.variants:
            raise ValueError(f"Unknown variant: {variant}")

        start_time = time.time()
        output = self.variants[variant](test_input)
        latency = time.time() - start_time

        return {
            'variant': variant,
            'input': test_input,
            'output': output,
            'latency': latency,
            'timestamp': time.time()
        }

    def run_experiment(self, test_cases: List[str], trials_per_case: int = 3) -> List[Dict]:
        """Run complete A/B experiment."""
        results = []

        for test_input in test_cases:
            for _ in range(trials_per_case):
                for variant in self.variants.keys():
                    result = self.run_trial(variant, test_input)
                    results.append(result)

        return results

    def analyze_results(self, results: List[Dict]) -> Dict[str, Any]:
        """Analyze experiment results for statistical significance."""
        variant_results = {}
        for variant in self.variants.keys():
            variant_data = [r for r in results if r['variant'] == variant]

            latencies = [r['latency'] for r in variant_data]
            output_lengths = [len(r['output']) for r in variant_data]

            variant_results[variant] = {
                'trials': len(variant_data),
                'avg_latency': statistics.mean(latencies),
                'std_latency': statistics.stdev(latencies) if len(latencies) > 1 else 0,
                'avg_output_length': statistics.mean(output_lengths),
                'min_latency': min(latencies),
                'max_latency': max(latencies)
            }

        # Simple statistical comparison (in practice, use proper statistical tests)
        variants_list = list(variant_results.keys())
        if len(variants_list) == 2:
            v1, v2 = variants_list
            latency_diff = variant_results[v1]['avg_latency'] - variant_results[v2]['avg_latency']

            variant_results['comparison'] = {
                'latency_difference': latency_diff,
                'winner': v1 if latency_diff < 0 else v2,
                'improvement_pct': abs(latency_diff) / max(variant_results[v1]['avg_latency'],
                                                          variant_results[v2]['avg_latency']) * 100
            }

        return variant_results
```

### Multi-Armed Bandit Testing

```python
class BanditTester:
    def __init__(self, variants: Dict[str, callable], epsilon: float = 0.1):
        self.variants = variants
        self.epsilon = epsilon  # Exploration rate
        self.variant_stats = {name: {'trials': 0, 'rewards': 0} for name in variants.keys()}

    def select_variant(self) -> str:
        """Select variant using epsilon-greedy strategy."""
        if np.random.random() < self.epsilon:
            # Explore: random selection
            return np.random.choice(list(self.variants.keys()))
        else:
            # Exploit: select best performing
            return max(self.variant_stats.keys(),
                      key=lambda v: self.variant_stats[v]['rewards'] / max(1, self.variant_stats[v]['trials']))

    def run_adaptive_test(self, test_inputs: List[str], reward_function: callable) -> Dict[str, Any]:
        """Run adaptive testing with multi-armed bandit approach."""
        results = []

        for test_input in test_inputs:
            # Select variant
            selected_variant = self.select_variant()

            # Run test
            start_time = time.time()
            output = self.variants[selected_variant](test_input)
            latency = time.time() - start_time

            # Calculate reward
            reward = reward_function(output, test_input)

            # Update statistics
            self.variant_stats[selected_variant]['trials'] += 1
            self.variant_stats[selected_variant]['rewards'] += reward

            results.append({
                'variant': selected_variant,
                'input': test_input,
                'output': output,
                'latency': latency,
                'reward': reward
            })

        return {
            'results': results,
            'final_stats': self.variant_stats,
            'best_variant': max(self.variant_stats.keys(),
                              key=lambda v: self.variant_stats[v]['rewards'] / self.variant_stats[v]['trials'])
        }
```

## Performance Metrics and KPIs

Define and track key performance indicators for prompt evaluation.

### Comprehensive Metrics Suite

```python
class MetricsCalculator:
    def __init__(self):
        self.metric_functions = {
            'accuracy': self._calculate_accuracy,
            'precision': self._calculate_precision,
            'recall': self._calculate_recall,
            'f1_score': self._calculate_f1,
            'semantic_similarity': self._calculate_semantic_similarity,
            'readability': self._calculate_readability,
            'toxicity': self._calculate_toxicity,
            'factual_accuracy': self._calculate_factual_accuracy
        }

    def calculate_metrics(self, predictions: List[str], references: List[str],
                         inputs: List[str] = None) -> Dict[str, float]:
        """Calculate comprehensive metrics for predictions vs references."""
        metrics = {}

        for metric_name, func in self.metric_functions.items():
            try:
                metrics[metric_name] = func(predictions, references, inputs)
            except Exception as e:
                print(f"Error calculating {metric_name}: {e}")
                metrics[metric_name] = None

        return metrics

    def _calculate_accuracy(self, predictions: List[str], references: List[str], inputs=None) -> float:
        """Calculate exact match accuracy."""
        correct = sum(1 for pred, ref in zip(predictions, references) if pred.strip() == ref.strip())
        return correct / len(predictions) if predictions else 0

    def _calculate_semantic_similarity(self, predictions: List[str], references: List[str], inputs=None) -> float:
        """Calculate average semantic similarity."""
        # Placeholder - would use sentence transformers
        similarities = []
        for pred, ref in zip(predictions, references):
            # Simplified word overlap
            pred_words = set(pred.lower().split())
            ref_words = set(ref.lower().split())
            similarity = len(pred_words.intersection(ref_words)) / len(pred_words.union(ref_words))
            similarities.append(similarity)

        return statistics.mean(similarities)

    def _calculate_readability(self, predictions: List[str], references=None, inputs=None) -> float:
        """Calculate average readability score."""
        scores = []
        for text in predictions:
            # Simplified readability (avg sentence length)
            sentences = text.split('.')
            avg_sentence_length = statistics.mean(len(s.split()) for s in sentences if s.strip())
            # Lower is more readable (shorter sentences)
            readability_score = max(0, 100 - avg_sentence_length * 2)
            scores.append(readability_score)

        return statistics.mean(scores)

    def _calculate_toxicity(self, predictions: List[str], references=None, inputs=None) -> float:
        """Calculate toxicity score (placeholder for actual toxicity detection)."""
        # Placeholder - would use toxicity classification model
        toxic_words = ['hate', 'stupid', 'idiot', 'worst', 'terrible']
        toxicity_scores = []

        for text in predictions:
            toxic_count = sum(1 for word in toxic_words if word in text.lower())
            toxicity_scores.append(min(1.0, toxic_count / len(text.split()) * 10))

        return statistics.mean(toxicity_scores)
```

### Custom Metrics Definition

```python
class CustomMetricsEngine:
    def __init__(self):
        self.custom_metrics = {}

    def register_metric(self, name: str, function: callable, description: str):
        """Register a custom evaluation metric."""
        self.custom_metrics[name] = {
            'function': function,
            'description': description
        }

    def calculate_custom_metrics(self, predictions: List[str], references: List[str],
                               inputs: List[str] = None, context: Dict = None) -> Dict[str, float]:
        """Calculate all registered custom metrics."""
        results = {}

        for name, config in self.custom_metrics.items():
            try:
                func = config['function']
                result = func(predictions, references, inputs, context)
                results[name] = result
            except Exception as e:
                print(f"Error in custom metric {name}: {e}")
                results[name] = None

        return results

# Example custom metrics
def creativity_score(predictions: List[str], references=None, inputs=None, context=None) -> float:
    """Measure creativity based on unique phrase usage."""
    unique_phrases = set()
    total_phrases = 0

    for pred in predictions:
        phrases = pred.split(',')
        total_phrases += len(phrases)
        unique_phrases.update(phrase.strip() for phrase in phrases)

    return len(unique_phrases) / total_phrases if total_phrases > 0 else 0

def task_completion_score(predictions: List[str], references=None, inputs=None, context=None) -> float:
    """Measure task completion based on required elements."""
    required_elements = context.get('required_elements', [])
    scores = []

    for pred in predictions:
        completed = sum(1 for element in required_elements if element.lower() in pred.lower())
        scores.append(completed / len(required_elements) if required_elements else 1.0)

    return statistics.mean(scores)
```

## Automated Evaluation Pipelines

Create continuous evaluation workflows that run automatically.

### CI/CD Integration

```python
class ContinuousEvaluator:
    def __init__(self, evaluator: PromptEvaluator, benchmark_manager: BenchmarkManager):
        self.evaluator = evaluator
        self.benchmark_manager = benchmark_manager
        self.performance_thresholds = {
            'accuracy': 0.8,
            'latency': 2.0,  # seconds
            'toxicity': 0.1
        }

    def run_continuous_evaluation(self, prompt_function, benchmark_name: str) -> Dict[str, Any]:
        """Run continuous evaluation against benchmarks."""
        # Get benchmark
        test_cases = self.benchmark_manager.get_benchmark(benchmark_name, subset_size=50)

        # Run evaluation
        results = self.evaluator.evaluate_prompt(prompt_function)

        # Check against thresholds
        passed = self._check_thresholds(results)

        # Generate report
        report = self._generate_evaluation_report(results, passed)

        return {
            'results': results,
            'passed': passed,
            'report': report,
            'benchmark': benchmark_name,
            'timestamp': time.time()
        }

    def _check_thresholds(self, results: Dict) -> bool:
        """Check if results meet performance thresholds."""
        if results['average_score'] < self.performance_thresholds['accuracy']:
            return False
        if results['average_latency'] > self.performance_thresholds['latency']:
            return False

        # Additional checks could include toxicity, etc.
        return True

    def _generate_evaluation_report(self, results: Dict, passed: bool) -> str:
        """Generate human-readable evaluation report."""
        status = "PASSED" if passed else "FAILED"

        report = f"""
PROMPT EVALUATION REPORT
========================
Status: {status}
Tests Run: {results['total_tests']}
Average Score: {results['average_score']:.3f}
Median Score: {results['median_score']:.3f}
Average Latency: {results['average_latency']:.3f}s
Total Tokens: {results['total_tokens']}

Performance Thresholds:
- Accuracy: >={self.performance_thresholds['accuracy']}
- Latency: <={self.performance_thresholds['latency']}s

Detailed Results:
{chr(10).join(f"- Test {i+1}: Score {r['score']:.3f}, Latency {r['latency']:.3f}s"
              for i, r in enumerate(results['results'][:10]))}
"""

        return report
```

## Best Practices

1. Use diverse test datasets that match real-world usage patterns
2. Implement statistical significance testing for A/B experiments
3. Monitor evaluation metrics over time to detect performance degradation
4. Include both automated and human evaluation in comprehensive testing
5. Version control prompts, test datasets, and evaluation code together
6. Set up automated alerting for performance regressions
7. Document evaluation methodology and metrics definitions
8. Regularly update benchmarks to reflect changing requirements
9. Consider edge cases and adversarial inputs in test suites
10. Balance evaluation speed with thoroughness based on deployment frequency

## Common Mistakes

- Using toy examples instead of realistic test cases
- Not accounting for statistical variance in small test sets
- Optimizing for benchmark performance at the expense of real-world utility
- Failing to update evaluation metrics as requirements evolve
- Not including human evaluation for subjective quality metrics
- Running evaluations too infrequently to catch regressions
- Using inappropriate statistical tests for result significance
- Not considering computational cost of frequent evaluations
- Ignoring evaluation bias from contaminated test sets

## Related Resources

- HELM evaluation framework for comprehensive LLM benchmarking
- OpenAI Evals framework for structured evaluation pipelines
- Hugging Face Evaluate library for metrics computation
- See references/prompt-optimization.md for A/B testing integration
- See references/few-shot-learning.md for evaluation of example selection strategies
- See references/prompt-chaining.md for evaluating multi-step workflows
