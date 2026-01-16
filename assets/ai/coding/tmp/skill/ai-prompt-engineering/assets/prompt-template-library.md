# Prompt Template Library

## Classification Templates

### Sentiment Analysis
```
Classify the sentiment of the following text as Positive, Negative, or Neutral.

Text: {text}

Sentiment:
```

### Intent Detection
```
Determine the user's intent from the following message.

Possible intents: {intent_list}

Message: {message}

Intent:
```

### Topic Classification
```
Classify the following article into one of these categories: {categories}

Article:
{article}

Category:
```

## Extraction Templates

### Named Entity Recognition
```
Extract all named entities from the text and categorize them.

Text: {text}

Entities (JSON format):
{
  "persons": [],
  "organizations": [],
  "locations": [],
  "dates": []
}
```

### Structured Data Extraction
```
Extract structured information from the job posting.

Job Posting:
{posting}

Extracted Information (JSON):
{
  "title": "",
  "company": "",
  "location": "",
  "salary_range": "",
  "requirements": [],
  "responsibilities": []
}
```

## Generation Templates

### Email Generation
```
Write a professional {email_type} email.

To: {recipient}
Context: {context}
Key points to include:
{key_points}

Email:
Subject:
Body:
```

### Code Generation
```
Generate {language} code for the following task:

Task: {task_description}

Requirements:
{requirements}

Include:
- Error handling
- Input validation
- Inline comments

Code:
```

### Creative Writing
```
Write a {length}-word {style} story about {topic}.

Include these elements:
- {element_1}
- {element_2}
- {element_3}

Story:
```

## Transformation Templates

### Summarization
```
Summarize the following text in {num_sentences} sentences.

Text:
{text}

Summary:
```

### Translation with Context
```
Translate the following {source_lang} text to {target_lang}.

Context: {context}
Tone: {tone}

Text: {text}

Translation:
```

### Format Conversion
```
Convert the following {source_format} to {target_format}.

Input:
{input_data}

Output ({target_format}):
```

## Analysis Templates

### Code Review
```
Review the following code for:
1. Bugs and errors
2. Performance issues
3. Security vulnerabilities
4. Best practice violations

Code:
{code}

Review:
```

### SWOT Analysis
```
Conduct a SWOT analysis for: {subject}

Context: {context}

Analysis:
Strengths:
-

Weaknesses:
-

Opportunities:
-

Threats:
-
```

## Question Answering Templates

### RAG Template
```
Answer the question based on the provided context. If the context doesn't contain enough information, say so.

Context:
{context}

Question: {question}

Answer:
```

### Multi-Turn Q&A
```
Previous conversation:
{conversation_history}

New question: {question}

Answer (continue naturally from conversation):
```

## Specialized Templates

### SQL Query Generation
```
Generate a SQL query for the following request.

Database schema:
{schema}

Request: {request}

SQL Query:
```

### Regex Pattern Creation
```
Create a regex pattern to match: {requirement}

Test cases that should match:
{positive_examples}

Test cases that should NOT match:
{negative_examples}

Regex pattern:
```

### API Documentation
```
Generate API documentation for this function:

Code:
{function_code}

Documentation (follow {doc_format} format):
```

## Industry-Specific Templates

### Healthcare

#### Medical Report Analysis
```
Analyze this medical report for key findings and recommendations.

Patient Information:
- Age: {age}
- Gender: {gender}
- Presenting Symptoms: {symptoms}
- Medical History: {history}

Report Content:
{report_text}

Analysis Structure:
1. **Summary of Findings**: Key medical observations
2. **Diagnosis Assessment**: Likely conditions based on symptoms
3. **Treatment Recommendations**: Suggested interventions
4. **Follow-up Requirements**: Recommended next steps
5. **Risk Assessment**: Potential complications or concerns

Analysis:
```

#### Patient Communication
```
Generate a patient-friendly explanation for this medical condition.

Medical Condition: {condition}
Complexity Level: {simple|intermediate|detailed}
Patient Context: {patient_background}

Explanation should include:
- What the condition is (in simple terms)
- Common symptoms
- Treatment approaches
- Expected outcomes
- When to seek immediate care

Patient-Friendly Explanation:
```

#### Clinical Decision Support
```
Provide clinical decision support for this patient case.

Patient Presentation:
{symptoms_and_findings}

Vital Signs:
{vital_signs}

Relevant History:
{medical_history}

Differential Diagnosis (top 5):
{rank_by_likelihood}

Recommended Workup:
{diagnostic_tests}

Treatment Considerations:
{initial_management}

Rationale:
```

### Finance

#### Risk Assessment
```
Conduct a comprehensive risk assessment for this investment opportunity.

Investment Details:
- Type: {investment_type}
- Amount: {amount}
- Time Horizon: {horizon}
- Risk Tolerance: {tolerance}

Market Context:
{market_conditions}

Risk Categories to Assess:
1. **Market Risk**: Volatility, correlation with market indices
2. **Credit Risk**: Counterparty default potential
3. **Liquidity Risk**: Ability to exit position quickly
4. **Operational Risk**: Platform/technical failures
5. **Regulatory Risk**: Compliance and legal changes

Risk Assessment:
```

#### Financial Report Analysis
```
Analyze this financial statement for key insights and trends.

Company: {company_name}
Reporting Period: {period}
Statement Type: {income_statement|balance_sheet|cash_flow}

Financial Data:
{statement_content}

Analysis Framework:
1. **Revenue Trends**: Growth patterns, seasonality
2. **Profitability Metrics**: Margins, efficiency ratios
3. **Liquidity Position**: Working capital, cash reserves
4. **Solvency**: Debt levels, coverage ratios
5. **Cash Flow Health**: Operating cash generation
6. **Key Ratios**: Industry comparisons and benchmarks

Executive Summary:
```

#### Compliance Review
```
Review this financial transaction for regulatory compliance.

Transaction Details:
- Type: {transaction_type}
- Parties: {parties_involved}
- Amount: {amount}
- Purpose: {purpose}

Regulatory Framework:
{applicable_regulations}

Compliance Checklist:
- [ ] AML/KYC requirements met
- [ ] Transaction reporting thresholds
- [ ] Sanctions screening completed
- [ ] Source of funds verified
- [ ] Enhanced due diligence if required

Compliance Assessment:
```

### Legal

#### Contract Analysis
```
Analyze this contract for key terms, obligations, and potential issues.

Contract Type: {contract_type}
Parties: {party_names}
Effective Date: {effective_date}

Contract Content:
{contract_text}

Analysis Structure:
1. **Key Obligations**: Primary duties of each party
2. **Financial Terms**: Payment schedules, penalties, termination fees
3. **Timeline Requirements**: Deadlines and milestones
4. **Risk Allocation**: Liability, indemnification, insurance
5. **Termination Conditions**: Exit clauses and notice periods
6. **Dispute Resolution**: Governing law, arbitration clauses

Critical Issues Identified:
```

#### Legal Research
```
Conduct legal research on this issue and provide analysis.

Legal Question: {question}
Jurisdiction: {jurisdiction}
Practice Area: {practice_area}

Research Scope:
- Relevant statutes and regulations
- Precedent cases (cite case law)
- Secondary sources and treatises
- Current developments and trends

Analysis Framework:
1. **Legal Framework**: Applicable laws and regulations
2. **Case Law Analysis**: Relevant judicial decisions
3. **Arguments For/Against**: Key legal positions
4. **Practical Considerations**: Implementation challenges
5. **Recommendations**: Suggested approach or strategy

Legal Analysis:
```

#### Regulatory Compliance
```
Assess compliance with this regulation for the described activity.

Regulation: {regulation_name}
Activity: {activity_description}
Industry: {industry_sector}

Regulatory Requirements:
{key_requirements}

Compliance Assessment:
- [ ] Licensing requirements met
- [ ] Record keeping obligations satisfied
- [ ] Reporting requirements fulfilled
- [ ] Training and certification completed
- [ ] Audit and monitoring procedures in place

Gaps Identified:
Remediation Plan:
```

## Multi-Turn Conversation Templates

### Customer Support Escalation
```
Previous Conversation Context:
{conversation_history}

Current Customer Issue:
{current_issue}

Escalation Level: {level_1|level_2|level_3}

Response Guidelines:
- Acknowledge previous interaction attempts
- Show empathy for customer frustration
- Provide clear next steps
- Set appropriate expectations
- Offer additional support channels if needed

Escalation Response:
```

### Technical Troubleshooting
```
Issue Description: {initial_problem}
Steps Already Tried: {previous_attempts}
System Information: {system_details}

Diagnostic Framework:
Step 1: Reproduce the issue
Current Status: {reproduction_results}

Step 2: Isolate the problem
Suspected Cause: {hypothesis}

Step 3: Implement solution
Proposed Fix: {solution}

Step 4: Verify resolution
Testing Results: {verification}

Step 5: Prevent recurrence
Preventive Measures: {preventive_actions}

Next Recommended Action:
```

### Educational Tutoring
```
Student Level: {beginner|intermediate|advanced}
Subject: {subject_area}
Current Topic: {topic}

Previous Session Summary:
{previous_work}

Learning Objective: {objective}

Tutorial Structure:
1. **Review Previous Material**: Quick recap
2. **Present New Concept**: Clear explanation with examples
3. **Guided Practice**: Step-by-step problem solving
4. **Independent Practice**: Student attempts problems
5. **Assessment**: Check understanding
6. **Homework/Extension**: Additional practice

Current Session Plan:
```

### Project Management Updates
```
Project: {project_name}
Current Phase: {phase}
Overall Progress: {percentage_complete}%

Team Status Update:
{team_updates}

Recent Accomplishments:
{accomplishments}

Current Challenges:
{challenges}

Next Milestone: {milestone}
Deadline: {deadline}

Required Actions:
{action_items}

Risk Assessment:
{risks}

Status Summary:
```

## Error Recovery Templates

### API Failure Recovery
```
API Call Failed:
Endpoint: {endpoint}
Error Code: {error_code}
Error Message: {error_message}
Request Payload: {payload}

Recovery Strategy:
1. **Error Classification**: {transient|permanent|rate_limit|auth}
2. **Immediate Action**: {retry|fallback|notify_user}
3. **Retry Logic**: {exponential_backoff|fixed_interval|immediate}
4. **Fallback Options**: {cached_data|simplified_response|alternative_service}
5. **User Communication**: {error_message|progress_indicator|retry_notification}

Recovery Implementation:
```

### Data Processing Error
```
Data Processing Failed:
Stage: {processing_stage}
Input Data: {input_sample}
Error Type: {validation|transformation|output}
Error Details: {specific_error}

Recovery Protocol:
1. **Error Isolation**: Identify exact failure point
2. **Data Validation**: Check input data integrity
3. **Fallback Processing**: Alternative processing method
4. **Partial Results**: Return what can be processed
5. **Error Logging**: Comprehensive error documentation
6. **User Notification**: Clear communication of issue

Recovery Plan:
```

### Model Inference Failure
```
Model Inference Error:
Model: {model_name}
Input: {input_sample}
Error: {error_details}
Confidence Threshold: {threshold}

Recovery Strategies:
1. **Input Validation**: Check input format and bounds
2. **Fallback Model**: Use simpler/backup model
3. **Default Response**: Provide safe default answer
4. **Confidence Checking**: Reject low-confidence predictions
5. **Error Propagation**: Handle upstream system errors
6. **Circuit Breaker**: Temporarily disable failing component

Recovery Response:
```

### Network Connectivity Issues
```
Network Error Detected:
Service: {service_name}
Endpoint: {endpoint}
Error Type: {timeout|connection_refused|dns_failure}
Duration: {error_duration}

Recovery Actions:
1. **Connection Testing**: Verify network connectivity
2. **DNS Resolution**: Check domain name resolution
3. **Service Health**: Confirm service availability
4. **Load Balancing**: Switch to backup endpoints
5. **Caching Strategy**: Serve cached responses
6. **Graceful Degradation**: Reduce functionality temporarily
7. **User Communication**: Inform about service issues

Recovery Status:
```

## Cultural Adaptation Patterns

### Language and Tone Adaptation
```
Adapt this content for {target_culture} audience.

Original Content: {original_text}
Source Culture: {source_culture}
Target Culture: {target_culture}

Cultural Considerations:
- **Communication Style**: {direct|indirect|high_context|low_context}
- **Formality Level**: {formal|informal|hierarchical|egalitarian}
- **Humor and Idioms**: {literal|figurative|culture_specific}
- **Time Orientation**: {monochronic|polychronic}
- **Power Distance**: {high|low}

Adapted Content:
```

### Localization Templates
```
Localize this content for {country}/{region}.

Original Content: {original_content}
Target Locale: {locale_code}

Localization Requirements:
1. **Language**: Translate to {target_language}
2. **Currency**: Convert to {local_currency}
3. **Date/Time**: Format as {local_date_format}
4. **Measurements**: Convert to {local_units}
5. **Cultural References**: Adapt for local context
6. **Legal Compliance**: Ensure local law compliance
7. **Local Preferences**: Account for regional preferences

Localized Version:
```

### Inclusive Communication
```
Adapt this communication to be culturally inclusive.

Original Message: {original_message}
Target Audience: {audience_description}
Cultural Diversity: {diversity_notes}

Inclusion Considerations:
- **Pronoun Usage**: {gender_neutral|inclusive_pronouns}
- **Cultural References**: {universal|broad_appeal}
- **Accessibility**: {screen_reader_friendly|multimodal}
- **Language Complexity**: {simple|accessible|technical}
- **Visual Elements**: {culturally_universal|locally_relevant}

Inclusive Version:
```

### Cross-Cultural Negotiation
```
Adapt this negotiation approach for {target_culture}.

Negotiation Context: {context}
Original Approach: {original_strategy}
Target Culture: {culture}

Cultural Negotiation Factors:
- **Relationship Building**: {task_focused|relationship_focused}
- **Decision Making**: {individual|consensus|hierarchical}
- **Time Orientation**: {flexible|strict_deadlines}
- **Communication Style**: {explicit|implicit}
- **Conflict Resolution**: {direct|harmonious}

Adapted Strategy:
```

## Use these templates by filling in the {variables}
