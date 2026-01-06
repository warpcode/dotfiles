# Multimodal Prompting Guide

Combine text, images, and other modalities in prompts to enable cross-modal reasoning and richer AI interactions.

## Image-Text Integration

Structure prompts that effectively combine visual and textual information for comprehensive understanding.

### Visual Question Answering

```python
def create_vqa_prompt(image_description: str, question: str) -> str:
    """Create a prompt for visual question answering tasks."""

    prompt = f"""
Analyze this image and answer the question using both visual and contextual information.

Image Description: {image_description}

Question: {question}

Provide a detailed answer that:
1. Describes relevant visual elements
2. Uses contextual reasoning
3. Gives a clear, direct answer
4. Explains your reasoning process

Answer:"""

    return prompt
```

### Image Captioning with Context

```python
def create_captioning_prompt(image_features: dict, context: str = None) -> str:
    """Create a prompt for detailed image captioning."""

    base_prompt = f"""
Generate a comprehensive caption for this image based on the following features:
- Objects: {', '.join(image_features.get('objects', []))}
- Colors: {', '.join(image_features.get('colors', []))}
- Composition: {image_features.get('composition', 'unknown')}
- Mood: {image_features.get('mood', 'neutral')}

Caption:"""

    if context:
        enhanced_prompt = f"""
Additional Context: {context}

{base_prompt}"""

        return enhanced_prompt

    return base_prompt
```

### Comparative Visual Analysis

```python
def create_comparison_prompt(image1_features: dict, image2_features: dict, comparison_task: str) -> str:
    """Create a prompt for comparing two images."""

    prompt = f"""
Compare these two images based on the given criteria.

Image 1 Features:
- Objects: {', '.join(image1_features.get('objects', []))}
- Style: {image1_features.get('style', 'unknown')}
- Colors: {', '.join(image1_features.get('colors', []))}

Image 2 Features:
- Objects: {', '.join(image2_features.get('objects', []))}
- Style: {image2_features.get('style', 'unknown')}
- Colors: {', '.join(image2_features.get('colors', []))}

Task: {comparison_task}

Analysis:"""

    return prompt
```

## Cross-Modal Reasoning

Develop prompts that leverage multiple modalities for enhanced reasoning capabilities.

### Audio-Text Integration

```python
def create_audio_text_prompt(transcript: str, audio_features: dict, task: str) -> str:
    """Create prompts that combine audio transcripts with acoustic features."""

    prompt = f"""
Analyze this audio content using both transcript and acoustic information.

Transcript: "{transcript}"

Acoustic Features:
- Speaker emotion: {audio_features.get('emotion', 'neutral')}
- Speech rate: {audio_features.get('speech_rate', 'normal')} words per minute
- Background noise: {audio_features.get('background_noise', 'minimal')}
- Voice quality: {audio_features.get('voice_quality', 'clear')}

Task: {task}

Analysis:"""

    return prompt
```

### Multi-Modal Chain-of-Thought

```python
class MultimodalReasoner:
    def __init__(self):
        self.modalities = ['text', 'image', 'audio']

    def create_reasoning_prompt(self, modalities_data: dict, question: str) -> str:
        """Create a chain-of-thought prompt across multiple modalities."""

        reasoning_steps = []

        # Step 1: Analyze each modality separately
        for modality, data in modalities_data.items():
            if modality == 'text':
                reasoning_steps.append(f"1. Text Analysis: Extract key information from '{data}'")
            elif modality == 'image':
                reasoning_steps.append(f"2. Visual Analysis: Identify objects, colors, and composition in the image")
            elif modality == 'audio':
                reasoning_steps.append(f"3. Audio Analysis: Note tone, emotion, and acoustic features")

        # Step 2: Cross-modal integration
        reasoning_steps.append("4. Integration: Combine insights from all modalities")

        # Step 3: Reasoning towards answer
        reasoning_steps.append("5. Reasoning: Use integrated information to answer the question")

        prompt = f"""
Use chain-of-thought reasoning across multiple modalities to answer this question.

Available Modalities: {', '.join(modalities_data.keys())}

Reasoning Process:
{chr(10).join(reasoning_steps)}

Question: {question}

Final Answer:"""

        return prompt
```

## Structured Multi-Modal Templates

Create reusable templates for common multi-modal tasks.

### Document Analysis Template

```python
DOCUMENT_ANALYSIS_TEMPLATE = """
Analyze this document using both textual and visual information.

Text Content: {text_content}

Visual Elements:
- Layout: {layout_description}
- Charts/Graphs: {chart_description}
- Images: {image_descriptions}
- Formatting: {formatting_notes}

Analysis Task: {task}

Provide a comprehensive analysis that integrates both textual and visual information:"""

def analyze_document(text_content: str, visual_elements: dict, task: str) -> str:
    """Generate document analysis prompt."""
    return DOCUMENT_ANALYSIS_TEMPLATE.format(
        text_content=text_content,
        layout_description=visual_elements.get('layout', 'standard document layout'),
        chart_description=visual_elements.get('charts', 'no charts present'),
        image_descriptions=visual_elements.get('images', 'no images present'),
        formatting_notes=visual_elements.get('formatting', 'standard formatting'),
        task=task
    )
```

### Product Review Template

```python
PRODUCT_REVIEW_TEMPLATE = """
Review this product using both description and image information.

Product Description: {description}

Visual Features:
- Primary color: {primary_color}
- Shape/Form: {shape}
- Texture: {texture}
- Brand elements: {branding}
- Packaging: {packaging}

Review Criteria: {criteria}

Provide a balanced review that considers both textual description and visual presentation:"""

def create_product_review_prompt(product_data: dict, criteria: list) -> str:
    """Generate product review prompt."""
    return PRODUCT_REVIEW_TEMPLATE.format(
        description=product_data.get('description', ''),
        primary_color=product_data.get('primary_color', 'unknown'),
        shape=product_data.get('shape', 'unknown'),
        texture=product_data.get('texture', 'unknown'),
        branding=product_data.get('branding', 'not specified'),
        packaging=product_data.get('packaging', 'standard'),
        criteria=', '.join(criteria)
    )
```

## Modality-Specific Prompting Strategies

### Image-Only Reasoning

```python
def create_image_only_prompt(image_features: dict, reasoning_task: str) -> str:
    """Create prompts that focus on visual reasoning without text bias."""

    prompt = f"""
Focus exclusively on visual information to complete this task. Do not rely on text or assume textual context.

Visual Information Available:
- Dominant objects: {', '.join(image_features.get('objects', []))}
- Color palette: {', '.join(image_features.get('colors', []))}
- Spatial relationships: {image_features.get('spatial', 'objects arranged in composition')}
- Lighting: {image_features.get('lighting', 'natural lighting')}
- Perspective: {image_features.get('perspective', 'standard view')}

Task: {reasoning_task}

Visual Analysis:"""

    return prompt
```

### Text-Enhanced Visual Reasoning

```python
def create_text_enhanced_visual_prompt(image_features: dict, text_context: str, task: str) -> str:
    """Use text to guide and enhance visual analysis."""

    prompt = f"""
Use the provided text context to guide your visual analysis of this image.

Text Context: "{text_context}"

Visual Features:
- Key elements: {', '.join(image_features.get('objects', []))}
- Visual style: {image_features.get('style', 'realistic')}
- Emotional tone: {image_features.get('tone', 'neutral')}

Task: {task}

Integrated Analysis (text + visual):"""

    return prompt
```

## Handling Modality Conflicts

Address situations where different modalities provide conflicting information.

### Conflict Resolution Strategies

```python
class ModalityConflictResolver:
    def __init__(self):
        self.conflict_strategies = {
            'prioritize_visual': "When text and image conflict, trust the visual information",
            'prioritize_text': "When modalities conflict, defer to the textual description",
            'synthesize': "Create a new understanding that reconciles both modalities",
            'flag_conflict': "Explicitly note the conflict and provide both interpretations"
        }

    def create_conflict_resolution_prompt(self, modality1: dict, modality2: dict,
                                       conflict_description: str, strategy: str) -> str:
        """Create a prompt that addresses modality conflicts."""

        strategy_instruction = self.conflict_strategies.get(strategy, self.conflict_strategies['synthesize'])

        prompt = f"""
Two modalities provide conflicting information. Apply this resolution strategy: {strategy_instruction}

Modality 1 (Text): {modality1.get('content', '')}
Modality 2 (Visual): {modality2.get('content', '')}

Conflict: {conflict_description}

Resolution:"""

        return prompt
```

## Performance Optimization

### Modality Weighting

```python
def create_weighted_multimodal_prompt(modalities: dict, weights: dict, task: str) -> str:
    """Create prompts with different weights for each modality."""

    weighted_sections = []
    for modality, data in modalities.items():
        weight = weights.get(modality, 1.0)
        weighted_sections.append(f"{modality.upper()} (Weight: {weight}): {data}")

    prompt = f"""
Complete this task using multiple modalities with different importance weights.

{' '.join(weighted_sections)}

Task: {task}

Weighted Analysis:"""

    return prompt
```

## Best Practices

1. Clearly separate different modalities in your prompts
2. Use modality-specific language when describing each type of input
3. Explicitly state how modalities should be combined or weighted
4. Test prompts with missing modalities to ensure robustness
5. Provide clear examples of cross-modal reasoning in few-shot examples
6. Use structured formats to organize multi-modal information
7. Consider the order of modality presentation (text first often works best)
8. Validate that each modality contributes meaningfully to the task

## Common Mistakes

- Treating all modalities equally when they have different relevance
- Not clearly separating modality descriptions in prompts
- Assuming models can automatically integrate modalities without guidance
- Using text-biased language when describing visual content
- Ignoring the computational cost of processing multiple modalities
- Failing to handle missing or corrupted modality data
- Not testing prompts with single modalities to isolate issues

## Related Resources

- CLIP model documentation for image-text understanding
- OpenAI GPT-4V capabilities for visual reasoning
- Multi-modal evaluation benchmarks (e.g., VQAv2, COCO Captioning)
- See references/prompt-chaining.md for multi-step multi-modal workflows
- See references/few-shot-learning.md for multi-modal example selection</content>
<parameter name="filePath">/home/jase/src/dotfiles/generic/.config/opencode/skill/ai-prompt-engineering/references/multimodal-prompting.md