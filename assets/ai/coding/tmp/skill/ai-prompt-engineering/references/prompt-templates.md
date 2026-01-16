# Prompt Template Systems

## Template Architecture

### Basic Template Structure
```python
class PromptTemplate:
    def __init__(self, template_string, variables=None):
        self.template = template_string
        self.variables = variables or []

    def render(self, **kwargs):
        missing = set(self.variables) - set(kwargs.keys())
        if missing:
            raise ValueError(f"Missing required variables: {missing}")

        return self.template.format(**kwargs)

# Usage
template = PromptTemplate(
    template_string="Translate {text} from {source_lang} to {target_lang}",
    variables=['text', 'source_lang', 'target_lang']
)

prompt = template.render(
    text="Hello world",
    source_lang="English",
    target_lang="Spanish"
)
```

### Conditional Templates
```python
class ConditionalTemplate(PromptTemplate):
    def render(self, **kwargs):
        # Process conditional blocks
        result = self.template

        # Handle if-blocks: {{#if variable}}content{{/if}}
        import re
        if_pattern = r'\{\{#if (\w+)\}\}(.*?)\{\{/if\}\}'

        def replace_if(match):
            var_name = match.group(1)
            content = match.group(2)
            return content if kwargs.get(var_name) else ''

        result = re.sub(if_pattern, replace_if, result, flags=re.DOTALL)

        # Handle for-loops: {{#each items}}{{this}}{{/each}}
        each_pattern = r'\{\{#each (\w+)\}\}(.*?)\{\{/each\}\}'

        def replace_each(match):
            var_name = match.group(1)
            content = match.group(2)
            items = kwargs.get(var_name, [])
            return '\\n'.join(content.replace('{{this}}', str(item)) for item in items)

        result = re.sub(each_pattern, replace_each, result, flags=re.DOTALL)

        # Finally, render remaining variables
        return result.format(**kwargs)

# Usage
template = ConditionalTemplate("""
Analyze the following text:
{text}

{{#if include_sentiment}}
Provide sentiment analysis.
{{/if}}

{{#if include_entities}}
Extract named entities.
{{/if}}

{{#if examples}}
Reference examples:
{{#each examples}}
- {{this}}
{{/each}}
{{/if}}
""")
```

### Modular Template Composition
```python
class ModularTemplate:
    def __init__(self):
        self.components = {}

    def register_component(self, name, template):
        self.components[name] = template

    def render(self, structure, **kwargs):
        parts = []
        for component_name in structure:
            if component_name in self.components:
                component = self.components[component_name]
                parts.append(component.format(**kwargs))

        return '\\n\\n'.join(parts)

# Usage
builder = ModularTemplate()

builder.register_component('system', "You are a {role}.")
builder.register_component('context', "Context: {context}")
builder.register_component('instruction', "Task: {task}")
builder.register_component('examples', "Examples:\\n{examples}")
builder.register_component('input', "Input: {input}")
builder.register_component('format', "Output format: {format}")

# Compose different templates for different scenarios
basic_prompt = builder.render(
    ['system', 'instruction', 'input'],
    role='helpful assistant',
    instruction='Summarize the text',
    input='...'
)

advanced_prompt = builder.render(
    ['system', 'context', 'examples', 'instruction', 'input', 'format'],
    role='expert analyst',
    context='Financial analysis',
    examples='...',
    instruction='Analyze sentiment',
    input='...',
    format='JSON'
)
```

## Common Template Patterns

### Classification Template
```python
CLASSIFICATION_TEMPLATE = """
Classify the following {content_type} into one of these categories: {categories}

{{#if description}}
Category descriptions:
{description}
{{/if}}

{{#if examples}}
Examples:
{examples}
{{/if}}

{content_type}: {input}

Category:"""
```

### Extraction Template
```python
EXTRACTION_TEMPLATE = """
Extract structured information from the {content_type}.

Required fields:
{field_definitions}

{{#if examples}}
Example extraction:
{examples}
{{/if}}

{content_type}: {input}

Extracted information (JSON):"""
```

### Generation Template
```python
GENERATION_TEMPLATE = """
Generate {output_type} based on the following {input_type}.

Requirements:
{requirements}

{{#if style}}
Style: {style}
{{/if}}

{{#if constraints}}
Constraints:
{constraints}
{{/if}}

{{#if examples}}
Examples:
{examples}
{{/if}}

{input_type}: {input}

{output_type}:"""
```

### Transformation Template
```python
TRANSFORMATION_TEMPLATE = """
Transform the input {source_format} to {target_format}.

Transformation rules:
{rules}

{{#if examples}}
Example transformations:
{examples}
{{/if}}

Input {source_format}:
{input}

Output {target_format}:"""
```

## Advanced Features

### Template Inheritance
```python
class TemplateRegistry:
    def __init__(self):
        self.templates = {}

    def register(self, name, template, parent=None):
        if parent and parent in self.templates:
            # Inherit from parent
            base = self.templates[parent]
            template = self.merge_templates(base, template)

        self.templates[name] = template

    def merge_templates(self, parent, child):
        # Child overwrites parent sections
        return {**parent, **child}

# Usage
registry = TemplateRegistry()

registry.register('base_analysis', {
    'system': 'You are an expert analyst.',
    'format': 'Provide analysis in structured format.'
})

registry.register('sentiment_analysis', {
    'instruction': 'Analyze sentiment',
    'format': 'Provide sentiment score from -1 to 1.'
}, parent='base_analysis')
```

### Variable Validation
```python
class ValidatedTemplate:
    def __init__(self, template, schema):
        self.template = template
        self.schema = schema

    def validate_vars(self, **kwargs):
        for var_name, var_schema in self.schema.items():
            if var_name in kwargs:
                value = kwargs[var_name]

                # Type validation
                if 'type' in var_schema:
                    expected_type = var_schema['type']
                    if not isinstance(value, expected_type):
                        raise TypeError(f"{var_name} must be {expected_type}")

                # Range validation
                if 'min' in var_schema and value < var_schema['min']:
                    raise ValueError(f"{var_name} must be >= {var_schema['min']}")

                if 'max' in var_schema and value > var_schema['max']:
                    raise ValueError(f"{var_name} must be <= {var_schema['max']}")

                # Enum validation
                if 'choices' in var_schema and value not in var_schema['choices']:
                    raise ValueError(f"{var_name} must be one of {var_schema['choices']}")

    def render(self, **kwargs):
        self.validate_vars(**kwargs)
        return self.template.format(**kwargs)

# Usage
template = ValidatedTemplate(
    template="Summarize in {length} words with {tone} tone",
    schema={
        'length': {'type': int, 'min': 10, 'max': 500},
        'tone': {'type': str, 'choices': ['formal', 'casual', 'technical']}
    }
)
```

### Template Caching
```python
class CachedTemplate:
    def __init__(self, template):
        self.template = template
        self.cache = {}

    def render(self, use_cache=True, **kwargs):
        if use_cache:
            cache_key = self.get_cache_key(kwargs)
            if cache_key in self.cache:
                return self.cache[cache_key]

        result = self.template.format(**kwargs)

        if use_cache:
            self.cache[cache_key] = result

        return result

    def get_cache_key(self, kwargs):
        return hash(frozenset(kwargs.items()))

    def clear_cache(self):
        self.cache = {}
```

## Multi-Turn Templates

### Conversation Template
```python
class ConversationTemplate:
    def __init__(self, system_prompt):
        self.system_prompt = system_prompt
        self.history = []

    def add_user_message(self, message):
        self.history.append({'role': 'user', 'content': message})

    def add_assistant_message(self, message):
        self.history.append({'role': 'assistant', 'content': message})

    def render_for_api(self):
        messages = [{'role': 'system', 'content': self.system_prompt}]
        messages.extend(self.history)
        return messages

    def render_as_text(self):
        result = f"System: {self.system_prompt}\\n\\n"
        for msg in self.history:
            role = msg['role'].capitalize()
            result += f"{role}: {msg['content']}\\n\\n"
        return result
```

### State-Based Templates
```python
class StatefulTemplate:
    def __init__(self):
        self.state = {}
        self.templates = {}

    def set_state(self, **kwargs):
        self.state.update(kwargs)

    def register_state_template(self, state_name, template):
        self.templates[state_name] = template

    def render(self):
        current_state = self.state.get('current_state', 'default')
        template = self.templates.get(current_state)

        if not template:
            raise ValueError(f"No template for state: {current_state}")

        return template.format(**self.state)

# Usage for multi-step workflows
workflow = StatefulTemplate()

workflow.register_state_template('init', """
Welcome! Let's {task}.
What is your {first_input}?
""")

workflow.register_state_template('processing', """
Thanks! Processing {first_input}.
Now, what is your {second_input}?
""")

workflow.register_state_template('complete', """
Great! Based on:
- {first_input}
- {second_input}

Here's the result: {result}
""")
```

## Best Practices

1. **Keep It DRY**: Use templates to avoid repetition
2. **Validate Early**: Check variables before rendering
3. **Version Templates**: Track changes like code
4. **Test Variations**: Ensure templates work with diverse inputs
5. **Document Variables**: Clearly specify required/optional variables
6. **Use Type Hints**: Make variable types explicit
7. **Provide Defaults**: Set sensible default values where appropriate
8. **Cache Wisely**: Cache static templates, not dynamic ones

## Template Libraries

### Question Answering
```python
QA_TEMPLATES = {
    'factual': """Answer the question based on the context.

Context: {context}
Question: {question}
Answer:""",

    'multi_hop': """Answer the question by reasoning across multiple facts.

Facts: {facts}
Question: {question}

Reasoning:""",

    'conversational': """Continue the conversation naturally.

Previous conversation:
{history}

User: {question}
Assistant:"""
}
```

### Content Generation
```python
GENERATION_TEMPLATES = {
    'blog_post': """Write a blog post about {topic}.

Requirements:
- Length: {word_count} words
- Tone: {tone}
- Include: {key_points}

Blog post:""",

    'product_description': """Write a product description for {product}.

Features: {features}
Benefits: {benefits}
Target audience: {audience}

Description:""",

    'email': """Write a {type} email.

To: {recipient}
Context: {context}
Key points: {key_points}

Email:"""
}
```

## Advanced Template Applications

Use these specialized guides for advanced template scenarios:

- **"How do I optimize my template performance systematically?"** → Load `references/prompt-optimization.md` for template A/B testing, token optimization, and iterative refinement
- **"I need automated testing and benchmarking for my templates"** → Load `references/evaluation-frameworks.md` for comprehensive template evaluation and performance metrics
- **"How do I create multi-turn conversation templates?"** → Load `references/prompt-chaining.md` for complex multi-step template workflows
- **"I want to include examples in my templates dynamically"** → Load `references/few-shot-learning.md` for dynamic example selection and template integration

## Universal Pattern Integration in Templates

### Incorporating Structural Guidelines

When designing prompts, integrate universal patterns for better reliability and maintainability:

#### Frontmatter Standardization Template
```python
UNIVERSAL_FRONTMATTER_TEMPLATE = """
---
name: {component_name}
description: {purpose_statement}. Use when {trigger_conditions}.
---

# {Component Title}

{opening_statement}
"""

# Example usage for creating prompts
frontmatter_prompt = UNIVERSAL_FRONTMATTER_TEMPLATE.format(
    component_name="data-analysis-agent",
    purpose_statement="Expert data analyst with comprehensive knowledge of statistical methods, visualization techniques, and machine learning algorithms",
    trigger_conditions="analyzing datasets, creating visualizations, or performing statistical tests",
    Component_Title="Data Analysis Agent",
    opening_statement="You are a data analysis expert specializing in statistical methods and machine learning."
)
```

#### Progressive Disclosure Template
```python
PROGRESSIVE_DISCLOSURE_TEMPLATE = """
{overview_section}

## When to Use This {component_type}

{trigger_conditions}

## Core Capabilities

{capabilities_list}

## Quick Start

{basic_example}

For advanced implementations, see the reference guides below.

## Available Resources

{triggers_and_references}

## Best Practices

{best_practices}

## Common Pitfalls

{pitfalls}

## Quality Assurance Checklist

{validation_checklist}
"""

# Example usage
progressive_prompt = PROGRESSIVE_DISCLOSURE_TEMPLATE.format(
    overview_section="Master advanced techniques for reliable component design.",
    component_type="Component",
    trigger_conditions="- Creating complex workflows\n- Ensuring quality and reliability\n- Optimizing performance",
    capabilities_list="- **Pattern A**: Description\n- **Pattern B**: Description",
    basic_example="```python\n# Basic usage\nresult = Component.basic_method()\n```",
    triggers_and_references="- **\"I need advanced features\"** → Load `references/advanced.md`\n- **\"Help with optimization\"** → Load `references/optimization.md`",
    best_practices="1. Start simple, add complexity as needed\n2. Test thoroughly\n3. Document rationale",
    pitfalls="- Over-engineering simple cases\n- Skipping validation\n- Ignoring performance",
    validation_checklist="- [ ] Tested on diverse inputs\n- [ ] Performance metrics tracked\n- [ ] Documentation complete"
)
```

#### Quality Assurance Integration Template
```python
QUALITY_ASSURANCE_TEMPLATE = """
## Quality Assurance Checklist

Before deploying in production:

{validation_items}

## Success Criteria

{measurable_criteria}
"""

# Example checklist items
qa_checklist = QUALITY_ASSURANCE_TEMPLATE.format(
    validation_items="- [ ] Test on diverse, representative inputs\n- [ ] Validate outputs meet quality standards\n- [ ] Measure performance metrics\n- [ ] Include error handling\n- [ ] Document expected behavior",
    measurable_criteria="- Accuracy > 95%\n- Response time < 2 seconds\n- Error rate < 1%\n- User satisfaction > 4.5/5"
)
```

#### Writing Style Enforcement Template
```python
WRITING_STYLE_TEMPLATE = """
## Writing Guidelines

When creating content, follow these universal standards:

### Tense and Voice
- **Present tense**: "This function processes data" (not "will process")
- **Active voice**: "Create the file" (not "The file should be created")
- **Imperative mood**: Direct commands for instructions

### Sentence Structure
- Average length: 15-25 words
- Mix simple (Subject-Verb-Object) and compound sentences
- Avoid hedging language ("could", "might", "perhaps")

### Technical Depth
- **Introductory**: Basic concepts, simple examples
- **Intermediate**: Standard practices, common patterns
- **Advanced**: Complex logic, edge cases, optimization

### Code Density Guidelines
- **Low (<20%)**: Specification documents, high-level overviews
- **Medium (20-60%)**: Implementation guides, API documentation
- **High (60%+)**: Tutorials, reference examples

Example of proper writing style:

✅ GOOD:
```
Create the configuration file with these settings.
Test the implementation thoroughly.
Use active voice and present tense.
```

❌ AVOID:
```
You might want to consider creating a configuration file.
The implementation should be tested at some point.
It would be helpful to use proper writing style.
```
"""

### Cross-Referencing Template
```python
CROSS_REFERENCING_TEMPLATE = """
## Cross-References

### Required Background Knowledge
- **FOUNDATIONAL**: Understand `references/foundational-concept.md` before proceeding
- **PREREQUISITE**: Complete `guides/prerequisite-guide.md` first

### Related Components
- **ALTERNATIVE**: See `alternatives/other-approach.md` for different methodology
- **EXTENSION**: Load `extensions/advanced-features.md` for additional capabilities
- **INTEGRATION**: Reference `integrations/third-party.md` for external connections

### Progressive Depth
- **OVERVIEW**: Start with `overview/introduction.md`
- **DETAILS**: Dive deeper in `details/comprehensive-guide.md`
- **EXPERT**: Access `expert/specialized-topics.md` for advanced scenarios
"""

# Usage in prompt generation
cross_ref_prompt = CROSS_REFERENCING_TEMPLATE.format()
```

### Directory Structure Template
```python
DIRECTORY_STRUCTURE_TEMPLATE = """
## Directory Structure Guidelines

Organize components using this progressive complexity approach:

### Level 1: Minimal (Self-Contained)
```
component-name/
├── component.md    # Single file, <300 lines
└── LICENSE.txt     # If applicable
```

### Level 2: Standard (With Documentation)
```
component-name/
├── component.md           # Main file, overview + quick start
├── references/            # Deep-dive technical documentation
│   ├── api-reference.md
│   ├── workflows.md
│   └── best-practices.md
└── LICENSE.txt
```

### Level 3: Extended (With Automation)
```
component-name/
├── component.md           # Main file
├── references/            # Documentation
├── scripts/               # Executable helpers
│   ├── utility.py
│   └── automation.sh
└── LICENSE.txt
```

### Level 4: Complete (With Resources)
```
component-name/
├── component.md           # Main file
├── references/            # Documentation
├── scripts/               # Automation
├── assets/                # Templates/resources
│   ├── templates/
│   └── examples/
└── LICENSE.txt
```

**Decision Logic:**
- Add `references/` when documentation exceeds 300 lines
- Add `scripts/` when executable code benefits users
- Add `assets/` when reusable templates/styles are needed
"""

## Performance Considerations

- Pre-compile templates for repeated use
- Cache rendered templates when variables are static
- Minimize string concatenation in loops
- Use efficient string formatting (f-strings, .format())
- Profile template rendering for bottlenecks
