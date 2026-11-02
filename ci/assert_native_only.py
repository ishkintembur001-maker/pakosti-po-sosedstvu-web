#!/usr/bin/env python3
"""Prevent accidental redistribution of this native Godot game as a website."""
from pathlib import Path
import re
import sys

repo = Path(__file__).resolve().parents[1]
errors = []

for path in repo.glob("index.*"):
    if path.is_file():
        errors.append(f"Web export file: {path.relative_to(repo)}")

for relative in (
    ".nojekyll", "CNAME", "404.html", "manifest.webmanifest",
    "service-worker.js", "web/index.html", "docs/index.html",
    "dist/index.html", "build/web/index.html", "public/index.html",
):
    if (repo / relative).is_file():
        errors.append(f"Web distribution file: {relative}")

for preset in repo.rglob("export_presets.cfg"):
    if re.search(r'^\s*platform\s*=\s*["\'](?:Web|HTML5)["\']',
                 preset.read_text(encoding="utf-8"), re.I | re.M):
        errors.append(f"Godot Web export preset: {preset.relative_to(repo)}")

workflows = repo / ".github" / "workflows"
for workflow in workflows.glob("*"):
    if workflow.suffix not in (".yml", ".yaml"):
        continue
    text = workflow.read_text(encoding="utf-8").lower()
    for marker in (
        "actions/deploy-pages", "actions/upload-pages-artifact",
        "actions/configure-pages", "peaceiris/actions-gh-pages",
        "pages-build-deployment", "--export-debug web",
        "--export-release web", "github-pages-deploy-action",
    ):
        if marker in text:
            errors.append(f"Web publication in {workflow.relative_to(repo)}: {marker}")

if errors:
    for error in errors:
        print("NATIVE_ONLY_GUARD_FAILED: " + error, file=sys.stderr)
    sys.exit(1)
print("NATIVE_ONLY_GUARD_OK")
