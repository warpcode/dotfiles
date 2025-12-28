# Main Task Structure

## Required Sections

### 1. Title
- Short, action-oriented
- Clearly states change or problem
- Example: "Implement cron script for daily data export" (NOT just "Data export")

### 2. Overview / Story
- Brief context explaining why work is needed
- Feature work: User story format ("As a <user>, I want <goal> so that <benefit>")
- Technical work: Drop user-story wording if it gets in the way

### 3. Detailed Request / Description
- What should be built or fixed
- Include scope and constraints
- Requirements and dependencies

### 4. Acceptance Criteria
- Clear, testable conditions defining "done"
- Format: Gherkin (Given/When/Then) OR Checklist (measurable, testable as true/false)
- Aligned with business goals

### 5. Technical Brief
- Executive Summary: High-level overview
- Impacted Areas: Database, Backend, Frontend, Infrastructure
- Risks: Data integrity, performance impact, security concerns

### 6. Resources / Attachments
- Links to relevant docs, designs, discussions
- Centralised at epic level to avoid duplication

## Ticket Types

### User Story (Features)
- Format: "As a <user>, I want <goal> so that <benefit>"
- Use for new features, enhancements
- Include business value

### Technical Ticket
- Same skeleton as User Story
- Drop user-story wording when it gets in the way
- Focus on technical implementation

### Bug Report
- Identifier and summary
- Steps to reproduce (numbered, minimum steps)
- Expected vs actual result
- Environment: App version, browser/OS, device, environment (prod/stage), config flags
- Severity and priority (separate fields)
- Attachments: Logs, screenshots, recordings

## Detection Criteria

### User Story
- Keywords: feature, add, implement, create, build
- Focus on user benefit
- New functionality

### Technical Ticket
- Keywords: refactor, optimize, migrate, update, fix (non-bug)
- Focus on technical improvement
- No direct user story context

### Bug Report
- Keywords: bug, issue, error, broken, not working, incorrect
- Focus on fixing existing functionality
- Includes reproduction steps
