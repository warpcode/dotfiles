# WCAG 2.1 Level AA Accessibility & Compound Component Patterns

Comprehensive guide for auditing, implementing, and validating WCAG 2.1 Level AA compliance and accessible frontend compound UI components.

---

## 1. WCAG 2.1 Level AA Audit Checklist

The Web Content Accessibility Guidelines (WCAG) 2.1 AA standard is built on the four **POUR** principles:

### Perceivable
- [ ] **Color Contrast**:
  - Regular text (< 18pt / 24px regular, < 14pt / 18.5px bold): Minimum contrast ratio of **4.5:1** against background.
  - Large text (≥ 18pt / 24px or ≥ 14pt / 18.5px bold): Minimum contrast ratio of **3.0:1**.
  - UI components and graphical objects (borders, active button states, form outlines): Minimum contrast ratio of **3.0:1**.
  - Color is never used as the sole conveyor of information (e.g. required form fields include text asterisk/label).
- [ ] **Text Alternatives (1.1.1)**:
  - Meaningful images have descriptive `alt` text.
  - Decorative images have empty `alt=""` or `aria-hidden="true"`.
  - Icon-only buttons have explicit accessible names via `aria-label` or `.sr-only` text.
- [ ] **Adaptable Layout (1.3.1 & 1.4.10)**:
  - Valid semantic HTML structure (`<header>`, `<nav>`, `<main>`, `<article>`, `<aside>`, `<footer>`).
  - No horizontal scrolling required at 320px width (Reflow / responsive design).
  - Page scales cleanly up to 200% zoom without loss of content or functionality.

### Operable
- [ ] **Keyboard Navigation (2.1.1 & 2.1.2)**:
  - All interactive elements (buttons, links, inputs, dialogs, dropdowns) are reachable and operable using `Tab`, `Shift+Tab`, `Enter`, `Space`, and `Arrow` keys.
  - **Zero Keyboard Traps**: Focus never gets permanently locked inside a component without an intuitive exit mechanism (e.g. `Esc` key).
  - Skip navigation link provided at the top of the DOM (`<a href="#main-content" class="skip-link">Skip to main content</a>`).
- [ ] **Focus Visibility & Order (2.4.3 & 2.4.7)**:
  - Unbroken, logical DOM tab order matching visual flow.
  - High-visibility focus indicators enabled for keyboard users (`:focus-visible { outline: 2px solid #2563eb; outline-offset: 2px; }`).
- [ ] **Motion & Flashing (2.2.2 & 2.3.1)**:
  - Animations respect `prefers-reduced-motion: reduce`.
  - Content does not flash more than 3 times per second to prevent seizure risks.

### Understandable
- [ ] **Language & Predictability (3.1.1 & 3.2.1)**:
  - Valid `<html lang="en">` attribute declared on root document.
  - Focusing on an input element does not trigger unexpected context changes or auto-submission.
- [ ] **Form Labels & Error Handling (3.3.1 - 3.3.4)**:
  - Every form input is bound to an explicit `<label for="id">` or uses `aria-labelledby`.
  - Error states are announced to assistive technologies via `role="alert"` or `aria-live="assertive"`.
  - Errored inputs link to their error message via `aria-describedby="field-error-id"` and set `aria-invalid="true"`.

### Robust
- [ ] **Assistive Technology Compatibility (4.1.2 & 4.1.3)**:
  - Custom UI controls adhere to ARIA 1.2 authoring practices (correct `role`, `aria-expanded`, `aria-selected`, `aria-checked`).
  - Dynamic status notifications use `aria-live="polite"`.

---

## 2. Accessible Modal Dialog with Focus Trap

A compliant modal dialog must manage focus entry, trap keyboard navigation within the container, and return focus to the trigger element upon dismissal.

```typescript
export class AccessibleModal {
  private previousActiveElement: HTMLElement | null = null;
  private focusableElements: HTMLElement[] = [];

  constructor(
    private modalElement: HTMLElement,
    private closeButton: HTMLElement
  ) {
    this.handleKeyDown = this.handleKeyDown.bind(this);
  }

  public open(): void {
    this.previousActiveElement = document.activeElement as HTMLElement;
    this.modalElement.setAttribute('aria-hidden', 'false');
    this.modalElement.classList.remove('hidden');

    this.updateFocusableElements();
    this.focusableElements[0]?.focus();

    document.addEventListener('keydown', this.handleKeyDown);
  }

  public close(): void {
    this.modalElement.setAttribute('aria-hidden', 'true');
    this.modalElement.classList.add('hidden');
    document.removeEventListener('keydown', this.handleKeyDown);

    // Restore focus to the trigger element
    this.previousActiveElement?.focus();
  }

  private updateFocusableElements(): void {
    const selector = 'a[href], button:not([disabled]), textarea:not([disabled]), input:not([disabled]), select:not([disabled]), [tabindex]:not([tabindex="-1"])';
    this.focusableElements = Array.from(this.modalElement.querySelectorAll<HTMLElement>(selector));
  }

  private handleKeyDown(event: KeyboardEvent): void {
    if (event.key === 'Escape') {
      this.close();
      return;
    }

    if (event.key === 'Tab') {
      if (this.focusableElements.length === 0) return;

      const first = this.focusableElements[0];
      const last = this.focusableElements[this.focusableElements.length - 1];

      if (event.shiftKey && document.activeElement === first) {
        event.preventDefault();
        last.focus();
      } else if (!event.shiftKey && document.activeElement === last) {
        event.preventDefault();
        first.focus();
      }
    }
  }
}
```

```html
<!-- Modal HTML Structure -->
<div
  id="confirm-dialog"
  role="dialog"
  aria-modal="true"
  aria-labelledby="dialog-title"
  aria-describedby="dialog-desc"
  aria-hidden="true"
  class="hidden modal-backdrop"
>
  <div class="modal-surface">
    <h2 id="dialog-title">Delete Account</h2>
    <p id="dialog-desc">Are you sure you want to delete your account? This action cannot be undone.</p>
    <div class="actions">
      <button type="button" id="cancel-btn">Cancel</button>
      <button type="button" id="confirm-btn" class="btn-danger">Delete</button>
    </div>
  </div>
</div>
```

---

## 3. UI Compound Component Patterns

Compound components share implicit state and manage keyboard interactions across coordinated sub-components.

### Accessible Tabs Compound Component (React)

Adheres to the WAI-ARIA Tabs design pattern with `role="tablist"`, `role="tab"`, `role="tabpanel"`, and horizontal arrow key navigation.

```tsx
import React, { createContext, useContext, useState, useRef, KeyboardEvent, ReactNode } from 'react';

interface TabsContextValue {
  activeTab: string;
  setActiveTab: (id: string) => void;
}

const TabsContext = createContext<TabsContextValue | null>(null);

export function Tabs({ defaultTab, children }: { defaultTab: string; children: ReactNode }) {
  const [activeTab, setActiveTab] = useState(defaultTab);

  return (
    <TabsContext.Provider value={{ activeTab, setActiveTab }}>
      <div className="tabs-container">{children}</div>
    </TabsContext.Provider>
  );
}

export function TabList({ children, ariaLabel }: { children: ReactNode[]; ariaLabel: string }) {
  const { activeTab, setActiveTab } = useContext(TabsContext)!;
  const listRef = useRef<HTMLDivElement>(null);

  const handleKeyDown = (e: KeyboardEvent<HTMLDivElement>) => {
    const tabs = Array.from(listRef.current?.querySelectorAll<HTMLButtonElement>('[role="tab"]') ?? []);
    const currentIndex = tabs.findIndex((t) => t.id === `tab-${activeTab}`);
    if (currentIndex === -1) return;

    let nextIndex = currentIndex;
    if (e.key === 'ArrowRight') {
      nextIndex = (currentIndex + 1) % tabs.length;
    } else if (e.key === 'ArrowLeft') {
      nextIndex = (currentIndex - 1 + tabs.length) % tabs.length;
    } else if (e.key === 'Home') {
      nextIndex = 0;
    } else if (e.key === 'End') {
      nextIndex = tabs.length - 1;
    } else {
      return;
    }

    e.preventDefault();
    const nextTab = tabs[nextIndex];
    nextTab.focus();
    const tabValue = nextTab.getAttribute('data-tab-value');
    if (tabValue) setActiveTab(tabValue);
  };

  return (
    <div role="tablist" aria-label={ariaLabel} ref={listRef} onKeyDown={handleKeyDown} className="tab-list">
      {children}
    </div>
  );
}

export function Tab({ value, children }: { value: string; children: ReactNode }) {
  const { activeTab, setActiveTab } = useContext(TabsContext)!;
  const isSelected = activeTab === value;

  return (
    <button
      role="tab"
      id={`tab-${value}`}
      data-tab-value={value}
      aria-selected={isSelected}
      aria-controls={`panel-${value}`}
      tabIndex={isSelected ? 0 : -1}
      onClick={() => setActiveTab(value)}
      className={`tab-item ${isSelected ? 'active' : ''}`}
    >
      {children}
    </button>
  );
}

export function TabPanel({ value, children }: { value: string; children: ReactNode }) {
  const { activeTab } = useContext(TabsContext)!;
  if (activeTab !== value) return null;

  return (
    <div
      role="tabpanel"
      id={`panel-${value}`}
      aria-labelledby={`tab-${value}`}
      tabIndex={0}
      className="tab-panel"
    >
      {children}
    </div>
  );
}
```

---

## 4. Screen Reader & Automated Testing Strategy

### Automated Audit Tooling
- **axe-core / Jest Axe**: Integrate automated accessibility checks into unit & component tests.
  ```typescript
  import { axe, toHaveNoViolations } from 'jest-axe';
  expect.extend(toHaveNoViolations);

  test('modal dialog has no accessibility violations', async () => {
    const { container } = render(<DeleteModal isOpen={true} />);
    const results = await axe(container);
    expect(results).toHaveNoViolations();
  });
  ```
- **Lighthouse CI**: Enforce accessibility scores ≥ 95 in build pipelines.

### Manual Assistive Technology Testing
| Screen Reader | Platform | Browser | Key Commands |
|---|---|---|---|
| **VoiceOver** | macOS | Safari / Chrome | `Cmd + F5` (Toggle), `Ctrl + Opt + Left/Right` (Navigate), `Ctrl + Opt + U` (Rotor) |
| **NVDA** | Windows | Chrome / Firefox | `NVDA + Q` (Exit), `Down Arrow` (Read next), `Insert + F7` (Elements list) |
| **TalkBack** | Android | Chrome | Swipe right (Next element), Double tap (Activate) |
