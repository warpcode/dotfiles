# Prompt Chaining Guide

Create sophisticated multi-step workflows that break complex tasks into manageable stages with coordinated AI agents.

## Chain Architecture Patterns

Structure prompt chains for different types of complex reasoning and task execution.

### Linear Chain Pattern

```python
import time
from typing import List, Dict, Any, Callable, Optional
from dataclasses import dataclass

@dataclass
class ChainStep:
    name: str
    prompt_template: str
    max_retries: int = 3
    timeout: float = 30.0

@dataclass
class StepResult:
    step_number: int
    step_name: str
    input_text: str
    output_text: str
    execution_time: float
    success: bool
    error_message: Optional[str] = None

class LinearChain:
    def __init__(self, steps: List[ChainStep], llm_client: Optional[Any] = None):
        self.steps = steps
        self.llm_client = llm_client or self._default_llm_client()

    def _default_llm_client(self) -> Any:
        """Provide default mock LLM client."""
        class MockLLM:
            def complete(self, prompt: str, **kwargs) -> str:
                time.sleep(0.1)  # Simulate latency
                if "analyze" in prompt.lower():
                    return "Analysis complete: Key insights extracted from the data."
                elif "summarize" in prompt.lower():
                    return "Summary: The document contains important information about project requirements."
                elif "recommend" in prompt.lower():
                    return "Recommendation: Proceed with implementation using the proposed architecture."
                else:
                    return f"Processed: {prompt[:50]}..."
        return MockLLM()

    def execute(self, initial_input: str) -> Dict[str, Any]:
        """Execute a linear chain of processing steps with error handling."""

        if not isinstance(initial_input, str) or not initial_input.strip():
            raise ValueError("Initial input must be a non-empty string")

        current_output = initial_input.strip()
        step_results: List[StepResult] = []
        total_execution_time = 0.0

        try:
            for i, step in enumerate(self.steps):
                step_start_time = time.time()

                # Prepare input for this step
                step_input = self._prepare_step_input(current_output, step_results)

                # Execute step with retries
                step_output, success, error_msg = self._execute_step_with_retries(step, step_input)

                execution_time = time.time() - step_start_time
                total_execution_time += execution_time

                # Record step result
                result = StepResult(
                    step_number=i + 1,
                    step_name=step.name,
                    input_text=step_input,
                    output_text=step_output,
                    execution_time=execution_time,
                    success=success,
                    error_message=error_msg
                )
                step_results.append(result)

                # Continue to next step even if current step had issues
                if success:
                    current_output = step_output

            return {
                'final_output': current_output,
                'step_history': [self._step_result_to_dict(r) for r in step_results],
                'total_execution_time': total_execution_time,
                'success': any(r.success for r in step_results),  # At least one step succeeded
                'steps_completed': len([r for r in step_results if r.success])
            }

        except Exception as e:
            return {
                'final_output': f"Chain execution failed: {str(e)}",
                'step_history': [self._step_result_to_dict(r) for r in step_results],
                'total_execution_time': total_execution_time,
                'success': False,
                'error': str(e),
                'steps_completed': len([r for r in step_results if r.success])
            }

    def _prepare_step_input(self, current_output: str, previous_results: list) -> str:
        """Prepare input for next step, incorporating context as needed."""
        if not previous_results:
            return current_output

        # Include relevant context from previous steps
        context = f"Previous work: {previous_results[-1]['output'][:200]}..."
        return f"{context}\n\nCurrent task: {current_output}"

    def _execute_step_with_retries(self, step: ChainStep, input_data: str) -> tuple[str, bool, Optional[str]]:
        """Execute step with retry logic and timeout handling."""

        for attempt in range(step.max_retries):
            try:
                # Format the prompt with input data
                formatted_prompt = step.prompt_template.format(input=input_data)

                # Call LLM with timeout (simplified)
                start_time = time.time()
                response = self.llm_client.complete(formatted_prompt)
                execution_time = time.time() - start_time

                # Check for timeout
                if execution_time > step.timeout:
                    raise TimeoutError(f"Step timed out after {execution_time:.2f}s")

                return response, True, None

            except Exception as e:
                error_msg = f"Attempt {attempt + 1} failed: {str(e)}"
                if attempt == step.max_retries - 1:
                    return "", False, error_msg
                time.sleep(0.5 * (attempt + 1))  # Exponential backoff

        return "", False, "All retry attempts failed"

    def _step_result_to_dict(self, result: StepResult) -> Dict[str, Any]:
        """Convert StepResult to dictionary."""
        return {
            'step_number': result.step_number,
            'step_name': result.step_name,
            'input_length': len(result.input_text),
            'output_length': len(result.output_text),
            'execution_time': result.execution_time,
            'success': result.success,
            'error_message': result.error_message
        }

# Usage example with realistic workflow
analysis_steps = [
    ChainStep(
        name="analyze_requirements",
        prompt_template="Analyze these project requirements and extract key features:\n\n{input}\n\nKey Features:"
    ),
    ChainStep(
        name="design_architecture",
        prompt_template="Based on the analysis above, design a high-level system architecture:\n\n{input}\n\nArchitecture Design:"
    ),
    ChainStep(
        name="create_implementation_plan",
        prompt_template="Create a detailed implementation plan for the architecture:\n\n{input}\n\nImplementation Plan:"
    )
]

# Create and execute chain
chain = LinearChain(analysis_steps)

project_description = """
Build a web application for managing customer support tickets. The system should:
- Allow customers to submit tickets via web form
- Enable support agents to view, assign, and resolve tickets
- Include a knowledge base for common issues
- Generate reports on ticket resolution times
- Support multiple customer organizations
"""

try:
    result = chain.execute(project_description)

    print("Chain Execution Results:")
    print(f"Success: {result['success']}")
    print(f"Steps completed: {result['steps_completed']}")
    print(f"Total execution time: {result['total_execution_time']:.2f}s")
    print(f"Final output preview: {result['final_output'][:200]}...")

    # Expected output:
    # Chain Execution Results:
    # Success: True
    # Steps completed: 3
    # Total execution time: ~0.30s
    # Final output preview: Implementation Plan: 1. Set up project structure with separate modules for customer portal, agent dashboard, and admin panel...

except Exception as e:
    print(f"Chain execution failed: {e}")
    # Handle errors gracefully
    result = {'success': False, 'error': str(e)}
```

### Tree of Thought Pattern

```python
class TreeOfThoughtChain:
    def __init__(self, branching_factor: int = 3, max_depth: int = 3):
        self.branching_factor = branching_factor
        self.max_depth = max_depth

    def execute(self, problem: str) -> dict:
        """Execute tree-of-thought reasoning."""

        # Initial decomposition
        root_ideas = self._generate_initial_ideas(problem)

        # Build reasoning tree
        tree = self._build_reasoning_tree(root_ideas, depth=0)

        # Select best path
        best_path = self._select_optimal_path(tree)

        return {
            'solution': best_path['final_answer'],
            'reasoning_tree': tree,
            'explored_paths': len(tree),
            'confidence': best_path['confidence']
        }

    def _generate_initial_ideas(self, problem: str) -> list:
        """Generate initial solution approaches."""
        prompt = f"""
Break down this problem into {self.branching_factor} different solution approaches:

Problem: {problem}

Approaches:"""

        # Would call LLM here
        return [f"Approach {i+1}" for i in range(self.branching_factor)]

    def _build_reasoning_tree(self, current_ideas: list, depth: int) -> dict:
        """Recursively build reasoning tree."""
        if depth >= self.max_depth:
            return {'leaves': current_ideas}

        tree = {}
        for idea in current_ideas:
            # Generate sub-ideas for each branch
            sub_ideas = self._expand_idea(idea)
            tree[idea] = self._build_reasoning_tree(sub_ideas, depth + 1)

        return tree

    def _expand_idea(self, idea: str) -> list:
        """Expand a single idea into sub-components."""
        prompt = f"""
Break down this approach into {self.branching_factor} detailed steps:

Approach: {idea}

Detailed steps:"""

        # Would call LLM here
        return [f"Step {i+1} of {idea}" for i in range(self.branching_factor)]
```

### Agent Orchestration Pattern

```python
class AgentOrchestrator:
    def __init__(self):
        self.agents = {
            'planner': PlanningAgent(),
            'researcher': ResearchAgent(),
            'writer': WritingAgent(),
            'reviewer': ReviewAgent()
        }
        self.workflow_templates = self._load_workflow_templates()

    def execute_workflow(self, task: str, workflow_type: str) -> dict:
        """Execute a predefined multi-agent workflow."""

        workflow = self.workflow_templates[workflow_type]

        results = {}
        current_context = {'task': task, 'history': []}

        for stage in workflow:
            agent = self.agents[stage['agent']]
            stage_result = agent.execute(
                task=stage['task'],
                context=current_context
            )

            results[stage['name']] = stage_result
            current_context['history'].append({
                'stage': stage['name'],
                'result': stage_result
            })

        return {
            'final_result': results[workflow[-1]['name']],
            'stage_results': results,
            'workflow_type': workflow_type
        }

    def _load_workflow_templates(self) -> dict:
        """Load predefined workflow templates."""
        return {
            'content_creation': [
                {'name': 'planning', 'agent': 'planner', 'task': 'Create content outline'},
                {'name': 'research', 'agent': 'researcher', 'task': 'Gather supporting information'},
                {'name': 'writing', 'agent': 'writer', 'task': 'Write first draft'},
                {'name': 'review', 'agent': 'reviewer', 'task': 'Review and improve content'}
            ],
            'problem_solving': [
                {'name': 'analysis', 'agent': 'planner', 'task': 'Analyze problem components'},
                {'name': 'research', 'agent': 'researcher', 'task': 'Research similar problems'},
                {'name': 'solution', 'agent': 'writer', 'task': 'Develop solution approach'},
                {'name': 'validation', 'agent': 'reviewer', 'task': 'Validate solution correctness'}
            ]
        }
```

## Step Coordination Strategies

Manage dependencies and information flow between chain steps.

### Sequential Processing

```python
def create_sequential_chain_prompts(task: str, steps: list) -> list:
    """Create a series of prompts for sequential processing."""

    prompts = []

    for i, step in enumerate(steps):
        context = ""
        if i > 0:
            context = f"Previous step result: {{step_{i-1}_result}}"

        prompt = f"""
Complete this step in the sequence:

Overall Task: {task}

Step {i+1}: {step['description']}

{context}

Step {i+1} Result:"""

        prompts.append(prompt)

    return prompts
```

### Parallel Processing with Aggregation

```python
class ParallelChain:
    def __init__(self, num_workers: int = 3):
        self.num_workers = num_workers

    def execute_parallel_steps(self, task: str, perspectives: list) -> dict:
        """Execute multiple perspectives in parallel, then aggregate."""

        # Create parallel prompts
        parallel_prompts = []
        for perspective in perspectives:
            prompt = f"""
Analyze this task from the {perspective} perspective:

Task: {task}

{perspective.title()} Analysis:"""
            parallel_prompts.append(prompt)

        # Execute in parallel (would use async LLM calls)
        parallel_results = [f"Result from {p}" for p in perspectives]

        # Aggregation step
        aggregation_prompt = f"""
Synthesize these parallel analyses into a comprehensive solution:

Task: {task}

Individual Analyses:
{chr(10).join(f"- {result}" for result in parallel_results)}

Synthesized Solution:"""

        # Final aggregation (would call LLM)
        final_result = "Aggregated final result"

        return {
            'parallel_results': parallel_results,
            'aggregated_result': final_result,
            'perspectives_used': perspectives
        }
```

### Conditional Branching

```python
class ConditionalChain:
    def __init__(self, decision_points: dict):
        self.decision_points = decision_points

    def execute_conditional_workflow(self, task: str) -> dict:
        """Execute workflow with conditional branching."""

        current_step = 'start'
        path_taken = ['start']
        results = {}

        while current_step != 'end':
            step_config = self.decision_points[current_step]

            # Execute current step
            step_result = self._execute_step(step_config, task, results)

            # Make decision for next step
            if 'condition' in step_config:
                decision = self._evaluate_condition(step_result, step_config['condition'])
                next_step = step_config['branches'][decision]
            else:
                next_step = step_config.get('next', 'end')

            results[current_step] = step_result
            path_taken.append(next_step)
            current_step = next_step

        return {
            'final_result': results.get('end', results[list(results.keys())[-1]]),
            'execution_path': path_taken,
            'step_results': results
        }

    def _evaluate_condition(self, result: str, condition: str) -> str:
        """Evaluate branching condition (simplified example)."""
        if 'complex' in result.lower():
            return 'complex_path'
        elif 'simple' in result.lower():
            return 'simple_path'
        else:
            return 'default_path'
```

## Error Handling and Recovery

Implement robust error handling in prompt chains.

### Step Failure Recovery

```python
class ResilientChain:
    def __init__(self, max_retries: int = 3):
        self.max_retries = max_retries

    def execute_with_recovery(self, steps: list, initial_input: str) -> dict:
        """Execute chain with automatic recovery from step failures."""

        current_input = initial_input
        execution_log = []
        recovery_attempts = 0

        for step_idx, step in enumerate(steps):
            success = False
            step_result = None

            for attempt in range(self.max_retries):
                try:
                    step_result = self._execute_step_with_validation(step, current_input)
                    if self._validate_step_result(step_result, step.get('validation_criteria')):
                        success = True
                        break
                    else:
                        execution_log.append(f"Step {step_idx} attempt {attempt+1}: Validation failed")
                except Exception as e:
                    execution_log.append(f"Step {step_idx} attempt {attempt+1}: Error - {str(e)}")

            if not success:
                # Try recovery strategy
                recovery_result = self._attempt_recovery(step, current_input, execution_log)
                if recovery_result:
                    step_result = recovery_result
                    execution_log.append(f"Step {step_idx}: Recovered successfully")
                else:
                    execution_log.append(f"Step {step_idx}: Failed permanently")
                    break

            current_input = step_result
            execution_log.append(f"Step {step_idx}: Completed successfully")

        return {
            'success': success,
            'final_result': current_input,
            'execution_log': execution_log,
            'recovery_attempts': recovery_attempts
        }

    def _attempt_recovery(self, failed_step: dict, input_data: str, log: list) -> str:
        """Attempt to recover from step failure."""
        recovery_prompt = f"""
This step failed: {failed_step['description']}

Previous attempts log: {log[-3:]}  # Last 3 log entries

Input data: {input_data}

Provide an alternative approach to complete this step:"""

        # Would call LLM for recovery
        return "Recovered result using alternative approach"
```

### Chain-Level Error Propagation

```python
class ErrorAwareChain:
    def __init__(self):
        self.error_handlers = {
            'timeout': self._handle_timeout,
            'content_filter': self._handle_content_filter,
            'rate_limit': self._handle_rate_limit,
            'validation_error': self._handle_validation_error
        }

    def execute_with_error_handling(self, chain_definition: dict) -> dict:
        """Execute chain with comprehensive error handling."""

        try:
            result = self._execute_chain_steps(chain_definition)
            return {'status': 'success', 'result': result}

        except TimeoutError as e:
            return self.error_handlers['timeout'](e, chain_definition)

        except ContentFilterError as e:
            return self.error_handlers['content_filter'](e, chain_definition)

        except RateLimitError as e:
            return self.error_handlers['rate_limit'](e, chain_definition)

        except ValidationError as e:
            return self.error_handlers['validation_error'](e, chain_definition)

    def _handle_timeout(self, error: TimeoutError, chain: dict) -> dict:
        """Handle timeout errors with fallback strategies."""
        return {
            'status': 'partial_success',
            'result': 'Completed steps before timeout',
            'error': str(error),
            'recovery_suggestion': 'Reduce step complexity or increase timeout'
        }

    def _handle_content_filter(self, error: ContentFilterError, chain: dict) -> dict:
        """Handle content filter violations."""
        return {
            'status': 'blocked',
            'result': None,
            'error': 'Content filter violation in chain execution',
            'recovery_suggestion': 'Review chain steps for potentially sensitive content'
        }
```

## Performance Optimization

### Caching and Memoization

```python
class CachedChain:
    def __init__(self):
        self.cache = {}
        self.cache_hits = 0
        self.cache_misses = 0

    def execute_with_caching(self, chain_id: str, steps: list, input_data: str) -> dict:
        """Execute chain with intelligent caching."""

        cache_key = self._generate_cache_key(chain_id, input_data)

        if cache_key in self.cache:
            self.cache_hits += 1
            return self.cache[cache_key]

        self.cache_misses += 1

        # Execute chain
        result = self._execute_chain_steps(steps, input_data)

        # Cache result if deterministic
        if self._is_deterministic_chain(steps):
            self.cache[cache_key] = result

        return result

    def _generate_cache_key(self, chain_id: str, input_data: str) -> str:
        """Generate cache key based on chain and input characteristics."""
        import hashlib
        content = f"{chain_id}:{input_data}"
        return hashlib.md5(content.encode()).hexdigest()

    def _is_deterministic_chain(self, steps: list) -> bool:
        """Check if chain produces deterministic results."""
        # Simplified check - in practice, analyze each step
        return all(not step.get('random', False) for step in steps)
```

## Best Practices

1. Design chains with clear inputs/outputs for each step
2. Include validation criteria for step results
3. Implement proper error handling and recovery strategies
4. Use caching for expensive or repetitive operations
5. Monitor chain performance and step success rates
6. Provide clear documentation for chain workflows
7. Test chains with various inputs including edge cases
8. Consider both sequential and parallel execution patterns
9. Implement timeouts and resource limits
10. Log detailed execution traces for debugging

## Common Mistakes

- Creating overly complex chains without testing intermediate steps
- Not handling step failures gracefully
- Ignoring dependencies between chain steps
- Failing to validate step inputs and outputs
- Not considering the cumulative cost of multiple LLM calls
- Using chains when simpler prompts would suffice
- Not monitoring chain performance over time
- Hardcoding step sequences instead of making them configurable

## Related Resources

- LangChain documentation for chain implementation patterns
- DSPy framework for programmable prompt pipelines
- AutoGen multi-agent conversation frameworks
- See references/few-shot-learning.md for dynamic example selection in chains
- See references/prompt-optimization.md for A/B testing chain variations
- See references/evaluation-frameworks.md for automated chain evaluation</content>
<parameter name="filePath">/home/jase/src/dotfiles/generic/.config/opencode/skill/ai-prompt-engineering/references/prompt-chaining.md