#!/usr/bin/env python3
"""Validate UTF-8 text files and local Markdown links."""

from __future__ import annotations

import re
import sys
from pathlib import Path
from urllib.parse import unquote

ROOT = Path(__file__).resolve().parents[1]

TEXT_EXTENSIONS = {
    ".md",
    ".json",
    ".yml",
    ".yaml",
    ".ps1",
    ".sh",
    ".cmd",
    ".py",
    ".txt",
}

IGNORED_DIRS = {
    ".git",
    ".super-dev-kit",
    "node_modules",
    "reports",
    "__pycache__",
}

LINK_PATTERN = re.compile(r"!?\[[^\]]*\]\(([^)]+)\)")


def iter_text_files():
    for path in ROOT.rglob("*"):
        if not path.is_file():
            continue
        if any(part in IGNORED_DIRS for part in path.parts):
            continue
        if path.suffix.lower() in TEXT_EXTENSIONS:
            yield path


def validate_utf8(path: Path) -> str | None:
    try:
        path.read_text(encoding="utf-8")
        return None
    except UnicodeDecodeError as exc:
        return f"{path.relative_to(ROOT)}: UTF-8 inválido ({exc})"


def normalize_link(raw: str) -> str:
    target = raw.strip()

    if target.startswith("<") and target.endswith(">"):
        target = target[1:-1]

    # Markdown may include an optional title after the URL.
    if ' "' in target:
        target = target.split(' "', 1)[0]
    elif " '" in target:
        target = target.split(" '", 1)[0]

    return unquote(target)


def validate_markdown_links(path: Path) -> list[str]:
    errors: list[str] = []
    text = path.read_text(encoding="utf-8")

    for match in LINK_PATTERN.finditer(text):
        target = normalize_link(match.group(1))

        if not target:
            continue

        lowered = target.lower()
        if (
            target.startswith("#")
            or lowered.startswith("http://")
            or lowered.startswith("https://")
            or lowered.startswith("mailto:")
            or lowered.startswith("tel:")
            or lowered.startswith("data:")
        ):
            continue

        target_without_fragment = target.split("#", 1)[0]
        target_without_query = target_without_fragment.split("?", 1)[0]

        if not target_without_query:
            continue

        if target_without_query.startswith("/"):
            resolved = ROOT / target_without_query.lstrip("/")
        else:
            resolved = (path.parent / target_without_query).resolve()

        try:
            resolved.relative_to(ROOT.resolve())
        except ValueError:
            errors.append(
                f"{path.relative_to(ROOT)}: link sai do repositório: {target}"
            )
            continue

        if not resolved.exists():
            errors.append(
                f"{path.relative_to(ROOT)}: link local inexistente: {target}"
            )

    return errors


def main() -> int:
    errors: list[str] = []
    checked = 0

    for path in iter_text_files():
        checked += 1
        utf8_error = validate_utf8(path)

        if utf8_error:
            errors.append(utf8_error)
            continue

        if path.suffix.lower() == ".md":
            errors.extend(validate_markdown_links(path))

    if errors:
        print("Falhas de documentação:")
        for error in errors:
            print(f"  - {error}")
        print(f"\nArquivos verificados: {checked}")
        return 1

    print(f"[OK] UTF-8 e links locais válidos em {checked} arquivos.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
