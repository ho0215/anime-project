#!/usr/bin/env python3
"""Upsert KEY=value into .env-style files without bash-sourcing."""
from __future__ import annotations

import argparse
from pathlib import Path


def upsert(path: Path, key: str, value: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    lines: list[str] = []
    if path.exists():
        lines = path.read_text(encoding="utf-8", errors="replace").splitlines()

    # Quote values so systemd EnvironmentFile and django-environ both accept them.
    safe = value.replace("'", "'\"'\"'")
    new_line = f"{key}='{safe}'"
    found = False
    out: list[str] = []
    for line in lines:
        stripped = line.strip()
        if not stripped or stripped.startswith("#") or "=" not in stripped:
            out.append(line)
            continue
        k = stripped.split("=", 1)[0].strip()
        if k == key:
            out.append(new_line)
            found = True
        else:
            out.append(line)
    if not found:
        out.append(new_line)
    path.write_text("\n".join(out) + "\n", encoding="utf-8")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--key", required=True)
    parser.add_argument("--value", required=True)
    parser.add_argument("files", nargs="+", type=Path)
    args = parser.parse_args()
    for f in args.files:
        upsert(f, args.key, args.value)
        print(f"updated {f} ({args.key})")


if __name__ == "__main__":
    main()
