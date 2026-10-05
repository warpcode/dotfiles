#!/usr/bin/env python3
"""Assemble standalone Jules prompts: agent block + shared protocol, one .txt per agent.

Jules scheduled tasks cannot include or share prompts, so every prompt must carry the
protocol inline. Usage:
    python scripts/build_prompts.py OUT_DIR [agent ...]   # no agents = all of them
"""
import sys
from pathlib import Path

root = Path(__file__).resolve().parent.parent
protocol = (root / "references" / "protocol.md").read_text().strip()
agents_dir = root / "references" / "agents"

out = Path(sys.argv[1])
wanted = sys.argv[2:] or sorted(p.stem for p in agents_dir.glob("*.md"))
out.mkdir(parents=True, exist_ok=True)
for name in wanted:
    src = agents_dir / f"{name}.md"
    if not src.exists():
        sys.exit(f"unknown agent: {name}")
    text = src.read_text().strip() + "\n\n" + protocol + "\n"
    (out / f"{name}.txt").write_text(text)
    print(f"{name}.txt  {len(text)} bytes")
