#!/bin/bash
export PATH="${HOME}/.local/bin:${PATH}"
if command -v mise >/dev/null; then
  echo "Installing tools via mise..."
  mise install
fi
