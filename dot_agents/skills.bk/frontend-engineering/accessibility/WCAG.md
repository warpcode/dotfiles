# WCAG (Web Content Accessibility Guidelines)

**Purpose**: Guide for implementing WCAG 2.1 Level AA accessibility compliance

## WCAG PRINCIPLES

### POUR Principles
- **Perceivable**: Information and UI components must be presentable to users in ways they can perceive
- **Operable**: UI components and navigation must be operable
- **Understandable**: Information and the operation of the UI must be understandable
- **Robust**: Content must be robust enough to be interpreted by assistive technologies

## PERCEIVABLE

### Text Alternatives (1.1)
- **Requirement**: Non-text content has text alternative
- **Examples**:
```html
<!-- Images -->
<img src="chart.png" alt="Bar chart showing 2024 sales: Q1: $1M, Q2: $1.5M, Q3: $2M, Q4: $2.5M">

<!-- Icons -->
<button aria-label="Search">
  <svg>...</svg>
</button>

<!-- Decorative images -->
<img src="decoration.jpg" alt="">
```

### Time-Based Media (1.2)
- **Requirements**:
  - 1.2.1: Audio-only and video-only (pre-recorded)
  - 1.2.2: Captions (pre-recorded)
  - 1.2.3: Audio Description or Media Alternative (pre-recorded)
  - 1.2.4: Captions (live)
  - 1.2.5: Audio Description (pre-recorded)

### Adaptable (1.3)
- **Requirement**: Create content that can be presented in different ways
- **Examples**:
```html
<!-- Semantic HTML -->
<h1>Main Heading</h1>
<nav>...</nav>
<main>
  <article>...</article>
</main>

<!-- Flexible layout -->
<div style="width: 100%; max-width: 1200px; margin: 0 auto;">
  <p>Flexible content width</p>
</div>
```

### Distinguishable (1.4)
- **Requirement**: Make it easier for users to see and hear content
- **Examples**:
```html
<!-- Color contrast (4.5:1 for normal text, 3:1 for large text) -->
<style>
.text { color: #333; background: #fff; }  /* Contrast ratio: 12.6:1 ✓ */
.large-text { font-size: 24px; color: #333; background: #fff; }  /* 3:1 for 24px+ */
</style>

<!-- Visual focus indicators -->
:focus {
  outline: 3px solid #007bff;
  outline-offset: 2px;
}

<!-- Resize text -->
body {
  font-size: 100%;
}

@media (prefers-reduced-motion: no-preference) {
  body {
    font-size: 200%;  /* Can be resized */
  }
}
```

## OPERABLE

### Keyboard Accessible (2.1)
- **Requirements**:
  - 2.1.1: Keyboard
  - 2.1.2: No Keyboard Trap
  - 2.1.3: Keyboard (No Exception)
  - 2.1.4: Character Key Shortcuts

- **Examples**:
```html
<!-- All interactive elements keyboard accessible -->
<button onclick="doAction()">Action</button>  <!-- Works with Enter/Space -->
<a href="/page">Link</a>  <!-- Works with Enter -->

<!-- Custom components must be keyboard accessible -->
<div role="button" tabindex="0" onclick="doAction()">
  Action
</div>

<!-- Focus order -->
<button>Button 1</button>
<button>Button 2</button>
<button>Button 3</button>

<!-- Skip navigation links -->
<a href="#main-content" class="skip-link">Skip to main content</a>
...
<main id="main-content">...</main>

<style>
.skip-link {
  position: absolute;
  top: -40px;
  left: 0;
  background: #000;
  color: #fff;
  padding: 8px;
  z-index: 100;
}

.skip-link:focus {
  top: 0;
}
</style>
```

### Enough Time (2.2)
- **Requirements**:
  - 2.2.1: Timing Adjustable
  - 2.2.2: Pause, Stop, Hide
  - 2.2.3: No Seizures
  - 2.2.4: Interruptions

- **Examples**:
```html
<!-- Auto-play with pause control -->
<video controls>
  <source src="video.mp4" type="video/mp4">
</video>

<!-- Reduced motion -->
@media (prefers-reduced-motion: reduce) {
  * {
    animation-duration: 0.01ms !important;
    animation-iteration-count: 1 !important;
    transition-duration: 0.01ms !important;
  }
}

<!-- Paused auto-playing content -->
<div id="carousel" aria-live="polite">
  <!-- Carousel items -->
</div>

<button onclick="toggleCarousel()">
  Pause
</button>
```

### Seizures and Physical Reactions (2.3)
- **Requirement**: Do not design content in a way that is known to cause seizures
- **Examples**:
```css
/* Flashing content */
@keyframes flash {
  0%, 100% { opacity: 1; }
  50% { opacity: 0; }
}

/* Bad: More than 3 flashes per second */
.bad-flash {
  animation: flash 0.3s infinite;  /* 3.33 flashes/sec ✗ */
}

/* Good: Maximum 3 flashes per second */
.good-flash {
  animation: flash 0.33s infinite;  /* 3 flashes/sec ✓ */
}

/* Avoid flashing large areas */
.large-flash {
  animation: flash 0.5s infinite;  /* 2 flashes/sec, but covers 25% of screen ✗ */
}

.small-flash {
  width: 10px;
  height: 10px;
  animation: flash 0.33s infinite;  /* 2 flashes/sec, small area ✓ */
}
```

### Navigable (2.4)
- **Requirements**:
  - 2.4.1: Bypass Blocks
  - 2.4.2: Page Titled
  - 2.4.3: Focus Order
  - 2.4.4: Link Purpose (In Context)
  - 2.4.5: Multiple Ways
  - 2.4.6: Headings and Labels
  - 2.4.7: Focus Visible

- **Examples**:
```html
<!-- Page title -->
<head>
  <title>Page Title - Site Name</title>
</head>

<!-- Headings hierarchy -->
<h1>Main heading</h1>
  <h2>Section heading</h2>
    <h3>Subsection heading</h3>

<!-- Form labels -->
<label for="name">Name:</label>
<input type="text" id="name" name="name">

<!-- Link purpose -->
<a href="/about">About Us</a>
<a href="mailto:contact@example.com">Contact</a>

<!-- Focus visible -->
button:focus-visible {
  outline: 3px solid #007bff;
  outline-offset: 2px;
}

/* Skip nav for keyboard users */
.sr-only {
  position: absolute;
  width: 1px;
  height: 1px;
  padding: 0;
  margin: -1px;
  overflow: hidden;
  clip: rect(0, 0, 0, 0);
  border: 0;
}
```

## UNDERSTANDABLE

### Readable (3.1)
- **Requirements**:
  - 3.1.1: Language of Page
  - 3.1.2: Language of Parts

- **Examples**:
```html
<html lang="en">
  ...
  <article>
    <p lang="fr">Ceci est du français.</p>
  </article>
</html>
```

### Predictable (3.2)
- **Requirements**:
  - 3.2.1: On Focus
  - 3.2.2: On Input
  - 3.2.3: Consistent Navigation
  - 3.2.4: Error Identification
  - 3.2.5: Labels

- **Examples**:
```html
<!-- Focus doesn't cause context change -->
<input type="text" onchange="alert('Changed!')">
<!-- Bad: Alert on focus -->
<input type="text" onfocus="alert('Focused!')">

<!-- Error messages -->
<div class="error" role="alert">
  Email is required
</div>

<!-- Form labels -->
<label for="email">Email:</label>
<input type="email" id="email" required>
<span class="error-message" id="email-error"></span>

<!-- Consistent navigation -->
<nav>
  <a href="/">Home</a>
  <a href="/about">About</a>
  <a href="/contact">Contact</a>
</nav>
```

### Input Assistance (3.3)
- **Requirements**:
  - 3.3.1: Error Identification
  - 3.3.2: Labels or Instructions
  - 3.3.3: Error Suggestion
  - 3.3.4: Error Prevention (Legal, Financial, Data)
  - 3.3.5: Help
  - 3.3.6: Error Prevention (All)
  - 3.3.7: Re-authentication
  - 3.3.8: Accessible Authentication (Minimum)

- **Examples**:
```html
<!-- Labels -->
<label for="password">Password:</label>
<input type="password" id="password" required minlength="8">

<!-- Error messages -->
<p id="password-error" class="error" role="alert"></p>

<script>
function validatePassword() {
  const password = document.getElementById('password').value;
  const error = document.getElementById('password-error');
  
  if (password.length < 8) {
    error.textContent = 'Password must be at least 8 characters';
    error.style.display = 'block';
  } else {
    error.style.display = 'none';
  }
}
</script>

<!-- Form validation -->
<form onsubmit="return validateForm()">
  <label for="email">Email:</label>
  <input type="email" id="email" required>
  <p id="email-error" class="error" role="alert"></p>
  
  <input type="submit" value="Submit">
</form>
```

## ROBUST

### Compatible (4.1)
- **Requirements**:
  - 4.1.1: Parsing
  - 4.1.2: Name, Role, Value
  - 4.1.3: Status Messages

- **Examples**:
```html
<!-- Semantic HTML for assistive technologies -->
<nav aria-label="Main navigation">
  <ul>
    <li><a href="/home">Home</a></li>
    <li><a href="/about">About</a></li>
  </ul>
</nav>

<button aria-pressed="false" onclick="toggle()">
  Toggle button
</button>

<div role="alert" aria-live="polite">
  Success message
</div>

<!-- Form with proper labels -->
<form>
  <label for="search">Search:</label>
  <input type="search" id="search" name="search">
  <button type="submit">Search</button>
</form>

<!-- ARIA roles for custom components -->
<div role="tablist" aria-label="Example tabs">
  <button role="tab" aria-selected="true" aria-controls="panel1" id="tab1">Tab 1</button>
  <button role="tab" aria-selected="false" aria-controls="panel2" id="tab2">Tab 2</button>
</div>

<div role="tabpanel" id="panel1" aria-labelledby="tab1">
  Panel 1 content
</div>
<div role="tabpanel" id="panel2" aria-labelledby="tab2" aria-hidden="true">
  Panel 2 content
</div>
```

## COMMON WCAG VIOLATIONS

### Missing Alt Text
```html
<!-- Bad: No alt text -->
<img src="chart.png">

<!-- Good: Descriptive alt text -->
<img src="chart.png" alt="Bar chart showing monthly sales for 2024">
```

### Missing Labels
```html
<!-- Bad: No label -->
<input type="text">

<!-- Good: Properly labeled -->
<label for="name">Name:</label>
<input type="text" id="name">
```

### Color Only Indicators
```html
<!-- Bad: Color only -->
<p>Required fields are in red</p>
<input type="text" style="border-color: red;">
<input type="text" style="border-color: green;">

<!-- Good: Color + icon/indicator -->
<p>Required fields have an asterisk *</p>
<label for="name">Name *:</label>
<input type="text" id="name" required>
```

### Keyboard Traps
```html
<!-- Bad: Modal without escape -->
<div id="modal" onclick="openModal()">
  <button onclick="closeModal()">Close</button>
</div>

<!-- Good: Modal with keyboard trap management -->
<div id="modal" role="dialog" aria-modal="true" aria-labelledby="modal-title">
  <h2 id="modal-title">Modal</h2>
  <button onclick="closeModal()">Close (Esc)</button>
</div>

<script>
let previousFocus;

function openModal() {
  previousFocus = document.activeElement;
  const modal = document.getElementById('modal');
  modal.style.display = 'block';
  const closeButton = modal.querySelector('button');
  closeButton.focus();
  
  modal.addEventListener('keydown', trapFocus);
}

function closeModal() {
  const modal = document.getElementById('modal');
  modal.style.display = 'none';
  modal.removeEventListener('keydown', trapFocus);
  previousFocus.focus();
}

function trapFocus(e) {
  const modal = document.getElementById('modal');
  const focusableElements = modal.querySelectorAll('button, [href], input, select, textarea, [tabindex]:not([tabindex="-1"])');
  const firstElement = focusableElements[0];
  const lastElement = focusableElements[focusableElements.length - 1];

  if (e.key === 'Tab') {
    if (e.shiftKey) {
      if (document.activeElement === firstElement) {
        e.preventDefault();
        lastElement.focus();
      }
    } else {
      if (document.activeElement === lastElement) {
        e.preventDefault();
        firstElement.focus();
      }
    }
  } else if (e.key === 'Escape') {
    closeModal();
  }
}
</script>
```

## TESTING FOR ACCESSIBILITY

### Screen Reader Testing
- Use NVDA (Windows), VoiceOver (macOS), JAWS (Windows)
- Navigate using keyboard only
- Verify all interactive elements are accessible
- Verify all images have alt text
- Verify all forms are properly labeled

### Keyboard Navigation Testing
- Tab through entire page
- Verify logical focus order
- Verify all functionality works with keyboard
- Verify focus indicators are visible

### Color Contrast Testing
- Use WebAIM Contrast Checker or axe DevTools
- Verify text contrast ratio meets WCAG AA (4.5:1 for normal text, 3:1 for large text)
- Verify interactive elements have contrast ratio of 3:1

## FRAMEWORK-SPECIFIC EXAMPLES

### React
```jsx
// Accessible component
function Button({ onClick, children }) {
  return (
    <button
      onClick={onClick}
      type="button"
      className="button"
    >
      {children}
    </button>
  );
}

// Accessible form
function Form() {
  const [error, setError] = useState(null);

  return (
    <form>
      <div>
        <label htmlFor="email">Email:</label>
        <input
          id="email"
          type="email"
          required
          aria-invalid={!!error}
          aria-describedby={error ? 'email-error' : undefined}
          onChange={(e) => setError(null)}
        />
        {error && (
          <p id="email-error" className="error" role="alert">
            {error}
          </p>
        )}
      </div>
    </form>
  );
}
```

### Vue.js
```vue
<template>
  <button
    @click="handleClick"
    type="button"
    class="button"
    :aria-pressed="isActive"
  >
    Button Text
  </button>
</template>

<script>
export default {
  data() {
    return {
      isActive: false
    };
  },
  methods: {
    handleClick() {
      this.isActive = !this.isActive;
    }
  }
}
</script>
```

## TOOLS

### Accessibility Testing Tools
- **axe DevTools**: Chrome/Firefox extension
- **WAVE**: Web Accessibility Evaluation Tool
- **Lighthouse**: Built into Chrome DevTools
- **WAVE Chrome Extension**: Browser extension
- **Tenon.io**: Online accessibility testing
- **WebAIM Contrast Checker**: Color contrast testing

### Screen Readers
- **NVDA**: Windows (free, open source)
- **JAWS**: Windows (commercial)
- **VoiceOver**: macOS (built-in)
- **Orca**: Linux (open source)
- **TalkBack**: Android (built-in)
- **VoiceOver**: iOS (built-in)
