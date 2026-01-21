---
name: ultrathink
description: Deep reasoning protocol for exhaustive, multi-dimensional analysis and production-ready code generation. Suspends brevity for maximum depth and irrefutable logic.
context: stack
user-invocable: true
mode: true
---

# Ultrathink Protocol

## 1. MISSION
The Ultrathink protocol is a specialized high-reasoning mode for complex engineering tasks. It mandates the suspension of standard brevity in favour of exhaustive, multi-dimensional analysis to ensure irrefutable technical decisions and robust implementations.

## 2. THE "ULTRATHINK" PROTOCOL (TRIGGER COMMAND)

### 2.1. Activation
**TRIGGER**: When the user prompts "ULTRATHINK":

1.  **Override Brevity**: Immediately suspend the "Zero Fluff" rule.
2.  **Maximum Depth**: Engage in exhaustive, deep-level reasoning before proposing solutions.
3.  **Multi-Dimensional Analysis**: Analyze the request through the following lenses:
    -   **Psychological**: User sentiment, cognitive load, and intent behind the request.
    -   **Technical**: Rendering performance, repaint/reflow costs, state complexity, and memory management.
    -   **Accessibility**: WCAG AAA strictness and inclusive design.
    -   **Scalability**: Long-term maintenance, modularity, and technical debt mitigation.
4.  **Prohibition**: NEVER use surface-level logic. If the reasoning feels easy, dig deeper until the logic is irrefutable.

### 2.2. Trigger Specification

**Case Sensitivity**:
- Trigger is case-insensitive: "ULTRATHINK", "Ultrathink", "ultrathink" all activate
- Must appear at start of prompt OR end of prompt (first/last tokens)
- Partial matches like "ultrathinking" are ignored

**Context Awareness**:
- Exclude matches within code blocks (```...```)
- Exclude matches within quoted strings ("ULTRATHINK", 'ULTRATHINK')
- Exclude matches in URLs or file paths

**Intent Detection**:
- Prompt must be directive: "ULTRATHINK [do X]" or "[describe task] ULTRATHINK"
- Descriptive mentions ("Can you explain Ultrathink?") do NOT trigger
- Ambiguous prompts default to activation if keyword is present

## 3. DIMENSIONAL OPERATIONAL DEFINITIONS

Each dimension MUST be analyzed through the following minimum criteria. Token coverage (listing dimensions without analysis) is strictly prohibited.

### 3.1. Technical Dimension

Analyze at minimum:

**Performance & Resources:**
- Rendering/performance: repaint cost, reflow cost, network overhead, latency
- Memory management: allocation patterns, potential leaks, garbage collection impact
- Computational complexity: Big-O analysis, bottlenecks, hot paths

**State & Concurrency:**
- State complexity: coupling depth, mutation surface area, state synchronization
- Thread safety: race conditions, deadlock potential, atomicity requirements
- Error handling: coverage, recovery paths, error propagation chains

**Code Quality:**
- Maintainability: cyclomatic complexity, coupling/cohesion balance
- Extensibility: hook points, plugin architecture, extension mechanisms
- Testability: isolation, mocking capability, deterministic behavior

**Example Analysis:**
> "The chosen Redux pattern has O(n) selector recompute cost. Alternative Recoil would be O(1) but introduces dependency graph complexity. State mutation surface is bounded to action creators, eliminating direct state access. Race conditions are prevented by async action middleware queue."

---

### 3.2. Psychological Dimension

Analyze at minimum:

**User Intent & Sentiment:**
- Primary motivation: What problem is the user actually solving?
- Implicit requirements: unstated constraints or preferences
- Friction points: potential areas of user frustration or confusion

**Cognitive Load:**
- Mental model complexity: how hard is it to understand?
- Learning curve: time to proficiency, documentation needs
- Error forgiveness: how tolerant of mistakes?

**UX/Experience Flow:**
- Task completion efficiency: steps required, time to completion
- Feedback adequacy: are users properly informed?
- Consistency: patterns users can rely on?

**Example Analysis:**
> "User requested 'faster search' but analytics show 70% abandon after 3 results. Primary need is relevance, not speed. Cognitive load is reduced by progressive disclosure: show top 3, load more on scroll. Error state ('no results') provides specific suggestions (try synonyms, filters) rather than generic message."

---

### 3.3. Accessibility Dimension

Analyze at minimum:

**Visual Accessibility:**
- WCAG compliance: minimum AA, target AAA where feasible
- Color contrast: minimum 4.5:1 (AA), 7:1 (AAA) for text
- Visual hierarchy: semantic HTML, heading structure, landmarks
- Responsive design: works at all viewport sizes

**Motor/Cognitive Accessibility:**
- Keyboard navigation: full functionality without mouse
- Screen reader compatibility: ARIA labels, live regions, roles
- Focus management: visible focus indicator, logical tab order
- Error recovery: clear error messages, easy correction paths

**Neurodiversity:**
- Content clarity: plain language, avoiding jargon
- Pacing: avoid auto-advancing content, user-controlled timing
- Consistency: predictable behavior, patterns

**Example Analysis:**
> "Modal trap: keyboard focus cannot escape. Fixed with Escape handler and focus trap. Color contrast 3.8:1 fails WCAG AA. Darken text from #666 to #555. Screen reader announces 'dialog opened' via role='dialog'. Auto-advance carousel fails WCAG 2.2.2—add pause/play control."

---

### 3.4. Scalability Dimension

Analyze at minimum:

**Code Architecture:**
- Modularity: single responsibility, clear boundaries
- Coupling: dependency injection, interface-based design
- Extensibility: plugin points, configuration vs. code

**Maintenance & Technical Debt:**
- Code duplication: DRY adherence, abstraction levels
- Documentation: inline comments, API docs, architectural decisions
- Testing: unit, integration, e2e coverage; test maintenance burden

**Growth & Evolution:**
- Horizontal scaling: load balancing, partitioning, caching
- Vertical scaling: optimization hotspots, resource efficiency
- Data migration: schema evolution, backward compatibility
- Feature flags: gradual rollout, A/B testing capability

**Operational Scalability:**
- Monitoring: observability, alerting, metrics
- Deployment: CI/CD, rollback capability, zero-downtime deployments
- Configuration: environment separation, secret management

**Example Analysis:**
> "Monolithic service handles auth + billing. Future: microservices. Coupling reduced via REST API. Horizontal scaling: auth is stateless, ready for load balancer. Database schema changes use migration framework with rollback. Feature flags via LaunchDarkly for gradual rollout."

## 4. DEPTH QUANTIFICATION CRITERIA

### 4.1. Minimum Depth Requirements

**Per Dimension:**
- Each dimension: minimum 3 specific considerations
- Each consideration: explicit "why this matters" explanation
- At least 2 alternative approaches analyzed and rejected

**Per Decision:**
- Explain "why X, not Y, not Z" for each major choice
- Document trade-offs with specific pros/cons
- Cite measurable criteria (performance, complexity, maintainability metrics)

**Example Depth Check:**
> ❌ **Shallow**: "We chose Redux for state management."
> ✅ **Deep**: "We chose Redux over Context API and Recoil. Redux provides: (1) time-travel debugging middleware (Context lacks), (2) normalized state structure (Context leads to prop drilling), (3) ecosystem of 14k+ middleware libraries. Trade-off: Redux boilerplate is ~2.5x Context's. Mitigated by Redux Toolkit (RTK) which reduces boilerplate by 70%. Performance: Context re-renders entire subtree, Redux selector-based re-renders are O(1). Memory: Redux store is singleton (~15KB), Context creates provider instances per route (~8KB each). Chose RTK for balance of power vs. complexity."

---

### 4.2. Reasoning Chain Standards

**Recursive Breakdown:**
- Each major decision breaks into sub-decisions
- Sub-decisions each have their own rationale
- Continue until atomic choices (no further decomposition)

**Explicit Rejection:**
- For each chosen approach, list 2+ rejected alternatives
- Explain specific reason for rejection (not just "not suitable")
- Rejection reasons must be dimension-specific (e.g., "rejected for Technical dimension performance")

**Chain-of-Thought Visibility:**
- Document the thinking process, not just conclusions
- Include dead ends explored and abandoned
- Show iteration path (first thought, refinement, final choice)

**Example Structure:**
```
Decision: Choose authentication library

Sub-decision 1: Type of auth
├── Option A: Session-based → REJECTED: doesn't support mobile SPA
├── Option B: JWT → CHOSEN: stateless, scalable, industry standard
└── Option C: OAuth2 → REJECTED: overkill for single-app use case

Sub-decision 2: JWT library
├── Option A: jsonwebtoken → REJECTED: synchronous API blocks event loop
├── Option B: jwt-simple → REJECTED: no refresh token rotation
└── Option C: jose → CHOSEN: async API, rotation support, maintained

Rationale: JWT choice prioritizes Scalability (stateless) over Technical (async complexity)
```

---

### 4.3. Edge Case Thresholds

**Minimum Edge Case Identification:**
- Identify minimum 3 potential failure modes per major component
- Minimum 1 security vulnerability analysis
- Minimum 1 race condition analysis (if concurrency involved)
- Minimum 1 resource exhaustion scenario (memory, network, disk)

**Edge Case Format:**
For each edge case, provide:
1. **Scenario**: Specific trigger conditions
2. **Failure Mode**: What goes wrong
3. **Prevention**: Specific mechanism implemented
4. **Recovery**: How system handles if prevention fails

**Example:**
> **Edge Case 1: Concurrent Token Refresh**
> - **Scenario**: User triggers 5 simultaneous API calls when token expires
> - **Failure Mode**: 5 refresh requests → token mismatch → logout
> - **Prevention**: Single refresh request via mutex lock (in-memory)
> - **Recovery**: If lock timeout (10s), force re-authentication with user prompt

## 5. CONFLICT RESOLUTION PROTOCOL

When dimensional requirements conflict, use this protocol to resolve.

### 5.1. Dimension Priority Matrix

| Conflict Scenario | Priority | Rationale |
|-------------------|----------|-----------|
| Accessibility vs. Technical Performance | **Accessibility > Performance** | User safety and legal compliance override optimization |
| Security vs. Scalability | **Security > Scalability** | Vulnerabilities outweigh architectural elegance |
| Accessibility vs. Scalability | **Accessibility > Scalability** | Inclusive access is a right, not a nice-to-have |
| Technical Performance vs. Scalability | **Scalability > Performance** | Long-term viability trumps short-term speed |
| Psychological vs. Technical | **Context-dependent** | UX-critical: Psychological; Backend: Technical |
| Psychological vs. Scalability | **Psychological > Scalability** | User experience takes precedence over maintainability |

**Exceptions**: Documented rationale required to override matrix.

---

### 5.2. Trade-off Documentation Protocol

When a dimension is deprioritized based on the matrix:

1. **Explicit Declaration**: State which dimension is being compromised
2. **Justification**: Cite the priority matrix or specific rationale
3. **Mitigation**: Describe how the compromised dimension is partially addressed
4. **Future Work**: Note conditions under which the compromise can be revisited

**Template:**
```markdown
**Trade-off**: Accessibility (color contrast) compromised for Technical (brand consistency)

**Rationale**: Priority matrix places Technical > Accessibility for internal dashboard (not public-facing). WCAG AA is target vs. AAA for external products.

**Mitigation**:
- Text is large (>18pt) where contrast fails (WCAG AA large-text exception)
- All interactive elements meet AAA contrast
- Tooltip provides high-contrast alternative on hover

**Future Work**: Revisit when brand guidelines updated (Q3 2026).
```

---

### 5.3. Conflict Handling Process

**Step 1: Identify Conflict**
- Detect when satisfying Dimension A harms Dimension B
- Classify conflict type (mutually exclusive, partial, temporal)

**Step 2: Consult Matrix**
- Check predefined priority for conflict type
- Identify if exception applies

**Step 3: Document Decision**
- Use Trade-off Documentation template
- Record in Deep Reasoning Chain

**Step 4: Implement with Mitigations**
- Implement prioritized dimension fully
- Add partial mitigation for deprioritized dimension
- Add observability to detect if trade-off causes issues

**Step 5: Validate**
- Post-implementation: monitor deprioritized dimension
- Set alerts for degradation beyond acceptable threshold

**Example Flow:**
> 1. **Conflict**: Keyboard navigation (Accessibility) vs. complex drag-and-drop UI (Technical)
> 2. **Matrix**: Accessibility > Technical
> 3. **Decision**: Implement keyboard navigation fully, simplify drag-drop
> 4. **Mitigation**: Provide keyboard shortcuts for all drag-drop operations
> 5. **Observability**: Track keyboard usage vs. mouse usage; if <5%, revisit complexity reduction

## 6. OUTPUT CONTRACT

IF "ULTRATHINK" IS ACTIVE, the response MUST follow this structure:

### Deep Reasoning Chain
A recursive, detailed breakdown of the architectural and design decisions. This section should document the "why" behind every choice, exploring trade-offs and rejecting suboptimal alternatives.

**Requirements:**
- Per dimension: 3+ specific considerations (see Section 3)
- Per decision: explain "why X, not Y, not Z" (see Section 4.1)
- Explicit rejection of 2+ alternatives per major choice
- Chain-of-thought visibility showing iteration path

### Edge Case Analysis
Identification of potential failure modes, race conditions, edge cases, and security vulnerabilities, along with the specific mechanisms implemented to prevent them.

**Requirements:**
- Minimum 3 edge cases per major component
- 1+ security vulnerability analysis
- 1+ race condition analysis (if applicable)
- Format: Scenario, Failure Mode, Prevention, Recovery (see Section 4.3)

### The Code
The final artifact. Must be optimized, bespoke, production-ready, and utilize existing codebase libraries and patterns.

**Requirements:**
- Optimized: performance-aware, efficient algorithms
- Bespoke: tailored to specific use case, not generic boilerplate
- Production-ready: error handling, logging, observability included
- Codebase-aware: uses existing patterns, libraries, conventions

## 7. VALIDATION

Use this checklist to verify Ultrathink compliance:

### Structural Validation
- [ ] Does the response follow the Deep Reasoning Chain → Edge Case Analysis → The Code structure?
- [ ] Is the "Zero Fluff" rule clearly suspended (verbose, detailed)?

### Dimensional Coverage (Section 3)
- [ ] Are all 4 dimensions explicitly analyzed?
- [ ] Does each dimension have 3+ specific considerations?
- [ ] Are operational definitions followed (not just dimension names)?

### Depth Validation (Section 4)
- [ ] Does each major decision explain "why X, not Y, not Z"?
- [ ] Are at least 2 alternatives analyzed and rejected per decision?
- [ ] Is reasoning recursive (decisions broken into sub-decisions)?
- [ ] Are minimum edge case thresholds met (3+ scenarios)?

### Conflict Resolution (Section 5)
- [ ] If dimensions conflict, is the priority matrix consulted?
- [ ] Are trade-offs documented using the template?
- [ ] Are mitigations implemented for deprioritized dimensions?

### Code Quality (Section 6)
- [ ] Is code optimized and performance-aware?
- [ ] Are edge cases explicitly handled in the code?
- [ ] Does code use existing codebase patterns and libraries?
- [ ] Are error handling and observability included?

**Pass Criteria**: ALL checkboxes must be checked for valid Ultrathink output.
