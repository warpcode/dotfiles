# XSS Protection for Frontend Applications

**Purpose**: Guide for preventing Cross-Site Scripting (XSS) vulnerabilities in frontend applications

## XSS VULNERABILITY TYPES

### Stored XSS
- **Definition**: Malicious script permanently stored on server
- **Attack Vector**: User input stored in database and displayed to other users
- **Example**: Forum post containing `<script>alert('XSS')</script>`
- **Prevention**: Sanitize input on storage, escape output

### Reflected XSS
- **Definition**: Malicious script reflected in response
- **Attack Vector**: URL parameters, query strings, form data
- **Example**: `?search=<script>alert('XSS')</script>`
- **Prevention**: Encode URL parameters, escape output

### DOM-Based XSS
- **Definition**: Vulnerability exists in client-side code
- **Attack Vector**: Client-side manipulation of DOM
- **Example**: `document.location.hash = '#<img src=x onerror=alert('XSS')>'`
- **Prevention**: Validate inputs, avoid `innerHTML`, use safe DOM methods

### Self-XSS
- **Definition**: XSS from user's own input
- **Attack Vector**: Not directly exploitable, but indicates poor security
- **Example**: User sees their own malicious input rendered
- **Prevention**: Still sanitize and escape (defense in depth)

## XSS PREVENTION IN FRAMEWORKS

### React

#### Dangerous Methods
```jsx
// BAD: dangerouslySetInnerHTML
<div dangerouslySetInnerHTML={userContent} />

// BAD: dangerouslySetURL
<a href={userUrl} onClick={handleClick}>Link</a>
```

#### Safe Methods
```jsx
// GOOD: JSX auto-escapes
<div>{userContent}</div>

// GOOD: Safe prop setting
<div dangerouslySetInnerHTML={{ __html: DOMPurify.sanitize(userContent) }} />
```

#### Event Handlers
```jsx
// BAD: User-controlled event handlers
<div onClick={userFunction} />

// GOOD: Sanitize function names or use predefined functions
<div onClick={handleClick} />
```

#### Links
```jsx
// BAD: User-controlled URL
<a href={userUrl} onClick={handleClick}>Link</a>

// GOOD: Validate and encode URLs
<a href={encodeURI(userUrl)} onClick={handleClick}>Link</a>
```

### Vue.js

#### v-html Directive
```vue
<!-- BAD: v-html without sanitization -->
<div v-html="userContent"></div>

<!-- GOOD: v-html with DOMPurify -->
<div v-html="sanitizedContent"></div>

<script>
import DOMPurify from 'dompurify';

export default {
  data() {
    return {
      userContent: '<script>alert("XSS")</script>'
    };
  },
  computed: {
    sanitizedContent() {
      return DOMPurify.sanitize(this.userContent);
    }
  }
}
</script>
```

#### Binding Input
```vue
<!-- BAD: User-controlled input without validation -->
<input v-model="userInput" type="text" />

<!-- GOOD: Validate and sanitize input -->
<input v-model="userInput" type="text" @input="validateInput" />

<script>
export default {
  data() {
    return {
      userInput: '',
      allowedTags: ['b', 'i', 'u']
    };
  },
  methods: {
    validateInput() {
      this.userInput = DOMPurify.sanitize(this.userInput, {
        ALLOWED_TAGS: this.allowedTags
      });
    }
  }
}
</script>
```

### Angular

#### DomSanitizer
```typescript
import { DomSanitizer } from '@angular/platform-browser';

@Component({
  selector: 'app-user-content',
  template: `
    <div [innerHTML]="sanitizedContent"></div>
  `
})
export class UserContentComponent {
  constructor(private sanitizer: DomSanitizer) {}

  userContent = '<script>alert("XSS")</script>';

  get sanitizedContent(): SafeHtml {
    // Good: Sanitize HTML
    return this.sanitizer.bypassSecurityTrustHtml(
      this.sanitizer.sanitize(SecurityContext.HTML, this.userContent)
    );
  }
}
```

#### URL Sanitization
```typescript
@Component({
  selector: 'app-external-link',
  template: `<a [href]="safeUrl">{{ linkText }}</a>`
})
export class ExternalLinkComponent {
  @Input() userUrl!: string;
  @Input() linkText!: string;

  constructor(private sanitizer: DomSanitizer) {}

  get safeUrl(): SafeUrl {
    return this.sanitizer.sanitize(SecurityContext.URL, this.userUrl);
  }
}
```

## SAFE DOM METHODS

### textContent vs innerHTML
```javascript
// BAD: innerHTML allows XSS
element.innerHTML = userInput;

// GOOD: textContent is safe
element.textContent = userInput;

// GOOD: Use textNode
element.appendChild(document.createTextNode(userInput));
```

### setAttribute vs innerHTML
```javascript
// BAD: Setting innerHTML with user input
element.innerHTML = `<img src="${userUrl}">`;

// GOOD: Setting attribute safely
element.setAttribute('src', userUrl);
```

### createElement vs innerHTML
```javascript
// BAD: Creating HTML with user input
element.innerHTML = `<a href="${userUrl}">${userText}</a>`;

// GOOD: Creating element with safe API
const link = document.createElement('a');
link.href = userUrl;
link.textContent = userText;
element.appendChild(link);
```

### document.write vs Safe DOM Manipulation
```javascript
// BAD: document.write with user input
document.write(`<p>${userInput}</p>`);

// GOOD: Safe DOM manipulation
const paragraph = document.createElement('p');
paragraph.textContent = userInput;
document.body.appendChild(paragraph);
```

## CONTENT SECURITY POLICY (CSP)

### CSP Headers
```http
Content-Security-Policy: default-src 'self'; script-src 'self' 'unsafe-inline' 'unsafe-eval' https://cdn.example.com; style-src 'self' 'unsafe-inline'; img-src 'self' data:; font-src 'self' https://fonts.gstatic.com;
```

### CSP in React
```javascript
// Use react-helmet for CSP
import { Helmet } from 'react-helmet';

function App() {
  return (
    <div>
      <Helmet>
        <meta http-equiv="Content-Security-Policy" content="default-src 'self'; script-src 'self' 'unsafe-inline';" />
      </Helmet>
      {/* App content */}
    </div>
  );
}
```

### CSP in Vue.js
```javascript
// Use vue-head for CSP
import { Head } from '@vue/head';

export default {
  data() {
    return {
      cspPolicy: "default-src 'self'; script-src 'self' 'unsafe-inline';"
    };
  },
  head() {
    return {
      meta: [
        {
          'http-equiv': 'Content-Security-Policy',
          content: this.cspPolicy
        }
      ]
    };
  }
}
```

### CSP in Angular
```typescript
import { Meta } from '@angular/platform-browser';

@Component({
  selector: 'app-root',
  template: `<router-outlet></router-outlet>`
})
export class AppComponent {
  constructor(private meta: Meta) {
    this.meta.addTag({
      'http-equiv': 'Content-Security-Policy',
      'content': "default-src 'self'; script-src 'self';"
    });
  }
}
```

## INPUT VALIDATION

### Allowlist Validation
```javascript
// Allowlist approach (recommended)
function validateHTML(input, allowedTags, allowedAttributes) {
  // Strip all HTML except allowed tags
  return DOMPurify.sanitize(input, {
    ALLOWED_TAGS: allowedTags,
    ALLOWED_ATTR: allowedAttributes,
    ALLOW_DATA_ATTR: false
  });
}

// Usage
const userInput = '<script>alert("XSS")</script><p>Safe content</p>';
const sanitized = validateHTML(userInput, ['p', 'b', 'i', 'u'], ['em', 'strong']);
// Result: <p>Safe content</p>
```

### URL Validation
```javascript
// Validate URLs before using
function isValidUrl(url) {
  try {
    const urlObj = new URL(url);
    // Only allow http and https
    return ['http:', 'https:'].includes(urlObj.protocol);
  } catch {
    return false;  // Invalid URL
  }
}

// Usage
if (isValidUrl(userUrl)) {
  element.href = userUrl;
} else {
  console.warn('Invalid URL');
}
```

### Input Sanitization
```javascript
// General purpose sanitization
function sanitizeInput(input) {
  // Escape HTML entities
  return input
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#39;');
}

// Usage
const safeInput = sanitizeInput(userInput);
element.textContent = safeInput;
```

## CONTENT SANITIZATION LIBRARIES

### DOMPurify
```bash
# Installation
npm install dompurify
# OR
yarn add dompurify
# OR
pnpm add dompurify
```

```javascript
import DOMPurify from 'dompurify';

// Basic usage
const dirty = '<img src=x onerror=alert(1)>';
const clean = DOMPurify.sanitize(dirty);

// Configured usage
const clean = DOMPurify.sanitize(dirty, {
  ALLOWED_TAGS: ['b', 'i', 'u', 'em', 'strong'],
  ALLOWED_ATTR: ['href', 'title', 'class'],
  KEEP_CONTENT: false
});

// With hooks
DOMPurify.addHook('uponSanitizeAttribute', function (currentNode, hookEvent, data) {
  // Prevent javascript: protocols
  if (data.attrName === 'href' && data.attrValue.startsWith('javascript:')) {
    data.attrValue = '#';
  }
});
```

### sanitize-html
```bash
# Installation
npm install sanitize-html
```

```javascript
import sanitizeHtml from 'sanitize-html';

const dirty = '<script>alert("XSS")</script><p>Safe content</p>';
const clean = sanitizeHtml(dirty, {
  allowedTags: ['p', 'b', 'i', 'u', 'strong', 'em'],
  allowedAttributes: {
    'p': ['class', 'id'],
    'b': ['class', 'id']
  }
});
```

### XSS-filters
```bash
# Installation
npm install xss-filters
```

```javascript
import xss from 'xss-filters';

const dirty = '<script>alert("XSS")</script>';
const clean = xss(dirty, {
  whiteList: {
    b: [],
    i: [],
    em: [],
    strong: []
  }
});
```

## COMMON XSS VECTORS

### Image Tag
```javascript
// Vector: onerror attribute
const userInput = '<img src=x onerror=alert("XSS")>';

// BAD: Using dangerouslySetInnerHTML
<div dangerouslySetInnerHTML={{ __html: userInput }} />

// GOOD: Using DOMPurify
<div dangerouslySetInnerHTML={{ __html: DOMPurify.sanitize(userInput) }} />
```

### Event Handlers
```javascript
// Vector: onerror, onclick, onload
const userInput = '<div onclick="alert(\'XSS\')">Click me</div>';

// BAD: Using dangerouslySetInnerHTML
<div dangerouslySetInnerHTML={{ __html: userInput }} />

// GOOD: Using DOMPurify or avoid
<div onClick={handleClick}>Click me</div>
```

### Script Tag
```javascript
// Vector: Direct script tag
const userInput = '<script>alert("XSS")<\/script>';

// BAD: Using dangerouslySetInnerHTML
<div dangerouslySetInnerHTML={{ __html: userInput }} />

// GOOD: Using textContent (escapes script tags)
<div>{userInput}</div>
```

### Style Tag
```javascript
// Vector: expression(), url()
const userInput = '<style>body { background: url("javascript:alert('XSS')") }</style>';

// BAD: Using dangerouslySetInnerHTML
<div dangerouslySetInnerHTML={{ __html: userInput }} />

// GOOD: Sanitize or use inline styles
<div style={userStyle}>Content</div>
```

### Template Literals
```javascript
// Vector: User input in template literals
const userInput = '${alert("XSS")}';

// BAD: Evaluating user input
eval(`const x = ${userInput};`);

// GOOD: Escape before use in template
const safeInput = encodeURI(userInput);
console.log(`Safe: ${safeInput}`);
```

## BEST PRACTICES

### Framework-Specific
```javascript
// React: Avoid dangerouslySetInnerHTML
// Use JSX auto-escaping instead
<div>{userContent}</div>

// Vue.js: Avoid v-html unless necessary
// Prefer text interpolation
<div>{{ userContent }}</div>

// Angular: Use DomSanitizer
// Always sanitize user input before using innerHTML
const safe = sanitizer.sanitize(SecurityContext.HTML, userInput);
```

### General Practices
- **Never trust user input**: Always validate and sanitize
- **Context-encoding**: Encode for the context (HTML, JavaScript, URL, CSS)
- **Content Security Policy**: Implement CSP to limit attack surface
- **Input validation**: Validate on server-side (not just client-side)
- **Output encoding**: Always encode user-controlled data in output
- **Avoid eval()**: Never use eval() with user input
- **Avoid innerHTML**: Use textContent or safe DOM methods
- **Keep libraries updated**: Use latest versions of sanitization libraries

### Defense in Depth
- **Input validation**: Validate and sanitize on input
- **Output encoding**: Escape output for context
- **CSP headers**: Limit allowed scripts and styles
- **Subresource Integrity (SRI)**: Verify script integrity
- **HTTP headers**: Use secure headers (X-Content-Type-Options, etc.)
```
