#!/usr/bin/env python3
"""Validate the public JSON contracts used by Super Dev Kit.

This script intentionally validates representative files against the versioned
JSON Schemas. It does not modify user configuration, manifests, or lock files.

Install the validator dependency with:
    python -m pip install "jsonschema>=4.18,<5"
"""

from __future__ import annotations

import json
import sys
from pathlib import Path

try:
    from jsonschema import Draft202012Validator
except ImportError:
    print(
        "[ERRO] Dependência ausente: jsonschema. "
        'Instale com: python -m pip install "jsonschema>=4.18,<5"',
        file=sys.stderr,
    )
    raise SystemExit(69)

ROOT = Path(__file__).resolve().parents[1]

CASES = (
    (
        ROOT / "schemas" / "config-v1.schema.json",
        ROOT / "config" / "devkit.config.example.json",
        True,
    ),
    (
        ROOT / "schemas" / "manifest-v2.schema.json",
        ROOT / "tests" / "fixtures" / "manifest-v2.minimal.json",
        True,
    ),
    (
        ROOT / "schemas" / "environment-lock-v1.schema.json",
        ROOT / "tests" / "fixtures" / "environment-lock.minimal.json",
        True,
    ),
    (
        ROOT / "schemas" / "cli-envelope-v1.schema.json",
        ROOT / "tests" / "fixtures" / "cli-envelope-v1.minimal.json",
        True,
    ),
    (
        ROOT / "schemas" / "environment-lock-v1.schema.json",
        ROOT / "tests" / "fixtures" / "environment-lock.invalid-schema-version.json",
        False,
    ),
)


def load_json(path: Path):
    with path.open(encoding="utf-8") as handle:
        return json.load(handle)


def describe_errors(validator: Draft202012Validator, instance) -> list[str]:
    errors = sorted(validator.iter_errors(instance), key=lambda item: list(item.absolute_path))
    messages = []
    for error in errors:
        location = ".".join(str(part) for part in error.absolute_path) or "<root>"
        messages.append(f"{location}: {error.message}")
    return messages


def main() -> int:
    failures: list[str] = []

    schema_cache: dict[Path, dict] = {}

    for schema_path, instance_path, should_pass in CASES:
        schema = schema_cache.get(schema_path)
        if schema is None:
            schema = load_json(schema_path)
            Draft202012Validator.check_schema(schema)
            schema_cache[schema_path] = schema

        validator = Draft202012Validator(schema)
        instance = load_json(instance_path)
        errors = describe_errors(validator, instance)
        passed = not errors

        if passed == should_pass:
            expectation = "válido" if should_pass else "inválido rejeitado"
            print(f"[OK] {instance_path.relative_to(ROOT)}: {expectation}")
            continue

        if should_pass:
            failures.append(
                f"{instance_path.relative_to(ROOT)} deveria ser válido:\n  "
                + "\n  ".join(errors)
            )
        else:
            failures.append(
                f"{instance_path.relative_to(ROOT)} deveria ser rejeitado, "
                "mas passou no schema."
            )

    if failures:
        print("\n[ERRO] Falha na validação dos contratos:", file=sys.stderr)
        for failure in failures:
            print(f"- {failure}", file=sys.stderr)
        return 1

    print("\n[OK] Schemas públicos e fixtures estão consistentes.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
