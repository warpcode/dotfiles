# Product Guidelines

## Tone and Style
- **Helpful and Instructional:** Documentation and AI-generated responses should focus on clarity. Provide clear, step-by-step instructions and explain the rationale behind specific configurations or automation steps.

## Visual Identity and Aesthetics
- **Rich and Informative:** The terminal environment should leverage Nerd Fonts, Powerline symbols, and color-coded status lines (e.g., via Oh My Zsh themes) to provide a high-density, visually appealing information display.

## User Interaction and Feedback
- **Informative Verbosity:** The system should provide explicit feedback. This includes progress bars or spinners for long-running tasks, clear success messages upon completion, and detailed, actionable error reports when things go wrong.

## Code Organization and Naming
- **Functional Modularization:** Use a prefix-based naming convention (e.g., _installer_, _ai_) for functions and internal variables to prevent namespace pollution and ensure modularity.
- **Strict Directory Hierarchy:** Maintain a clear and enforced directory structure (e.g., src/zsh/apps/, src/zsh/config/, src/zsh/functions/) to ensure the configuration is predictable and easy to navigate.
