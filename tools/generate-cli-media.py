#!/usr/bin/env python3
"""Generate README media from real Super Dev Kit CLI executions.

The screenshots and GIF are rendered from commands executed by this script.
Sensitive machine-specific data is sanitized before rendering.
"""

from __future__ import annotations

import json
import os
import re
import socket
import subprocess
import textwrap
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[1]
MEDIA_DIR = ROOT / "docs" / "media" / "generated"
README = ROOT / "README.md"

WIDTH = 1600
HEIGHT = 900
MAX_BODY_LINES = 31
WRAP_COLUMNS = 108

ANSI_RE = re.compile(r"\x1B(?:[@-Z\\-_]|\[[0-?]*[ -/]*[@-~])")
IPV4_RE = re.compile(r"\b(?:\d{1,3}\.){3}\d{1,3}\b")
EMAIL_RE = re.compile(r"\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}\b")
ABS_HOME_RE = re.compile(r"/home/[^/\s]+")
WIN_HOME_RE = re.compile(r"[A-Za-z]:\\Users\\[^\\\s]+")


@dataclass(frozen=True)
class CaptureSpec:
    title: str
    command: tuple[str, ...]
    filename: str


SPECS = (
    CaptureSpec("CLI Help", ("bash", "devkit.sh", "help"), "cli-help.png"),
    CaptureSpec(
        "Full Stack Setup — Dry Run",
        ("bash", "devkit.sh", "setup", "fullstack", "--dry-run"),
        "setup-fullstack-dry-run.png",
    ),
    CaptureSpec("Dev Doctor", ("bash", "devkit.sh", "doctor"), "dev-doctor.png"),
    CaptureSpec(
        "Project Generator — Dry Run",
        (
            "bash",
            "devkit.sh",
            "project",
            "react-vite",
            "demo",
            "--output",
            "/tmp/super-dev-kit-media",
            "--dry-run",
        ),
        "project-react-vite-dry-run.png",
    ),
)


def font(size: int, bold: bool = False, mono: bool = False):
    candidates = []
    if mono:
        candidates.extend(
            [
                "/usr/share/fonts/truetype/dejavu/DejaVuSansMono.ttf",
                "/usr/share/fonts/truetype/liberation2/LiberationMono-Regular.ttf",
            ]
        )
    elif bold:
        candidates.extend(
            [
                "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf",
                "/usr/share/fonts/truetype/liberation2/LiberationSans-Bold.ttf",
            ]
        )
    else:
        candidates.extend(
            [
                "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf",
                "/usr/share/fonts/truetype/liberation2/LiberationSans-Regular.ttf",
            ]
        )

    for candidate in candidates:
        path = Path(candidate)
        if path.exists():
            return ImageFont.truetype(str(path), size)

    return ImageFont.load_default()


FONT_TITLE = font(32, bold=True)
FONT_COMMAND = font(22, mono=True)
FONT_BODY = font(22, mono=True)
FONT_FOOTER = font(18)


def command_text(command: tuple[str, ...]) -> str:
    def quote(part: str) -> str:
        if re.search(r"\s", part):
            return f'"{part}"'
        return part

    return " ".join(quote(part) for part in command)


def run_capture(spec: CaptureSpec) -> tuple[int, str]:
    env = os.environ.copy()
    env.update(
        {
            "TERM": "dumb",
            "NO_COLOR": "1",
            "COLUMNS": "120",
            "LINES": "40",
        }
    )

    try:
        result = subprocess.run(
            spec.command,
            cwd=ROOT,
            env=env,
            text=True,
            capture_output=True,
            timeout=90,
            check=False,
        )
        output = (result.stdout or "") + (result.stderr or "")
        return result.returncode, output
    except subprocess.TimeoutExpired as exc:
        partial = (exc.stdout or "") + (exc.stderr or "")
        return 124, f"{partial}\n[command timed out after 90 seconds]\n"


def sanitize(text: str) -> str:
    clean = ANSI_RE.sub("", text).replace("\r\n", "\n").replace("\r", "\n")

    replacements = {
        str(ROOT): "<repo>",
        str(Path.home()): "<home>",
        "/tmp/super-dev-kit-media": "<tmp>/super-dev-kit-media",
    }

    hostname = socket.gethostname()
    if hostname:
        replacements[hostname] = "<host>"

    for key in ("USER", "LOGNAME", "USERNAME"):
        value = os.environ.get(key)
        if value and len(value) >= 2:
            replacements[value] = "<user>"

    for source, target in sorted(replacements.items(), key=lambda item: len(item[0]), reverse=True):
        clean = clean.replace(source, target)

    clean = WIN_HOME_RE.sub("<home>", clean)
    clean = ABS_HOME_RE.sub("<home>", clean)
    clean = EMAIL_RE.sub("<email>", clean)
    clean = IPV4_RE.sub("<ip>", clean)

    normalized = []
    blank_count = 0
    for line in clean.splitlines():
        line = line.rstrip()
        if not line:
            blank_count += 1
            if blank_count > 1:
                continue
        else:
            blank_count = 0
        normalized.append(line)

    return "\n".join(normalized).strip() or "(no output)"


def wrap_output(text: str) -> list[str]:
    lines: list[str] = []

    for raw in text.splitlines():
        if len(raw) <= WRAP_COLUMNS:
            lines.append(raw)
            continue

        indent = len(raw) - len(raw.lstrip())
        prefix = " " * min(indent, 8)
        chunks = textwrap.wrap(
            raw.strip(),
            width=max(24, WRAP_COLUMNS - len(prefix)),
            replace_whitespace=False,
            drop_whitespace=False,
        )
        lines.extend(prefix + chunk for chunk in chunks)

    if len(lines) > MAX_BODY_LINES:
        keep = (MAX_BODY_LINES - 1) // 2
        lines = (
            lines[:keep]
            + ["... output shortened for README capture ..."]
            + lines[-keep:]
        )

    return lines


def draw_terminal(spec: CaptureSpec, exit_code: int, output: str) -> Image.Image:
    image = Image.new("RGB", (WIDTH, HEIGHT), "#07111f")
    draw = ImageDraw.Draw(image)

    draw.rounded_rectangle((34, 30, WIDTH - 34, HEIGHT - 30), radius=28, fill="#0b1627", outline="#1f3654", width=2)
    draw.rounded_rectangle((34, 30, WIDTH - 34, 130), radius=28, fill="#111d30")

    for x, color in ((72, "#ff5f57"), (104, "#febc2e"), (136, "#28c840")):
        draw.ellipse((x - 10, 70 - 10, x + 10, 70 + 10), fill=color)

    draw.text((184, 51), spec.title, fill="#f4f7fb", font=FONT_TITLE)

    command = "$ " + command_text(spec.command)
    draw.text((72, 154), command, fill="#5eead4", font=FONT_COMMAND)

    y = 205
    line_height = 25
    for line in wrap_output(output):
        color = "#d7e2f0"
        stripped = line.lstrip()
        if stripped.startswith("[OK]") or "OK" in stripped[:8]:
            color = "#86efac"
        elif "AVISO" in line or "WARNING" in line.upper():
            color = "#fde68a"
        elif "ERRO" in line or "ERROR" in line.upper() or "FAIL" in line.upper():
            color = "#fca5a5"
        elif stripped.startswith("$") or stripped.startswith(">"):
            color = "#7dd3fc"

        draw.text((72, y), line, fill=color, font=FONT_BODY)
        y += line_height

    footer = f"Real CLI execution • sanitized for public docs • exit code {exit_code}"
    draw.text((72, HEIGHT - 72), footer, fill="#8094ad", font=FONT_FOOTER)

    return image


def intro_frame() -> Image.Image:
    image = Image.new("RGB", (1280, 720), "#07111f")
    draw = ImageDraw.Draw(image)

    title = "SUPER DEV KIT"
    subtitle = "v1.0.0 • real CLI demo"
    note = "setup • doctor • project templates"

    title_font = font(64, bold=True)
    subtitle_font = font(34, bold=True)
    note_font = font(25)

    title_box = draw.textbbox((0, 0), title, font=title_font)
    subtitle_box = draw.textbbox((0, 0), subtitle, font=subtitle_font)
    note_box = draw.textbbox((0, 0), note, font=note_font)

    draw.text(((1280 - (title_box[2] - title_box[0])) / 2, 245), title, fill="#eaf2ff", font=title_font)
    draw.text(((1280 - (subtitle_box[2] - subtitle_box[0])) / 2, 335), subtitle, fill="#67e8f9", font=subtitle_font)
    draw.text(((1280 - (note_box[2] - note_box[0])) / 2, 405), note, fill="#a9b8cc", font=note_font)

    return image


def save_demo(images: list[Image.Image]) -> None:
    frames = [intro_frame()]
    for image in images:
        frames.append(image.resize((1280, 720), Image.Resampling.LANCZOS))

    palette_frames = [frame.convert("P", palette=Image.Palette.ADAPTIVE, colors=128) for frame in frames]
    durations = [1800] + [2800] * (len(palette_frames) - 1)

    palette_frames[0].save(
        MEDIA_DIR / "cli-demo.gif",
        save_all=True,
        append_images=palette_frames[1:],
        duration=durations,
        loop=0,
        optimize=True,
        disposal=2,
    )


def update_readme() -> None:
    start = "<!-- CLI_MEDIA_START -->"
    end = "<!-- CLI_MEDIA_END -->"

    section = """<!-- CLI_MEDIA_START -->
## 🎬 CLI em execução

As capturas abaixo são geradas a partir de **execuções reais da CLI em CI**. Caminhos, usuários, hostnames, IPs e e-mails são sanitizados antes da publicação.

| CLI Help | Full Stack dry-run |
| --- | --- |
| ![Super Dev Kit CLI help](docs/media/generated/cli-help.png) | ![Super Dev Kit full stack dry-run](docs/media/generated/setup-fullstack-dry-run.png) |

| Dev Doctor | Project generator |
| --- | --- |
| ![Super Dev Kit Dev Doctor](docs/media/generated/dev-doctor.png) | ![Super Dev Kit project generator dry-run](docs/media/generated/project-react-vite-dry-run.png) |

### Demo curta

![Super Dev Kit real CLI demo](docs/media/generated/cli-demo.gif)

Detalhes da captura: [manifesto de mídia](docs/media/generated/capture-manifest.json).

<!-- CLI_MEDIA_END -->"""

    text = README.read_text(encoding="utf-8")

    if start in text and end in text:
        before = text.split(start, 1)[0].rstrip()
        after = text.split(end, 1)[1].lstrip()
        updated = before + "\n\n" + section + "\n\n" + after
    else:
        marker = "## 🧩 Perfis disponíveis"
        if marker not in text:
            raise RuntimeError("README insertion marker not found")
        updated = text.replace(marker, section + "\n\n" + marker, 1)

    README.write_text(updated, encoding="utf-8")


def main() -> int:
    MEDIA_DIR.mkdir(parents=True, exist_ok=True)

    manifest = {
        "schema_version": 1,
        "source": "real_cli_execution",
        "sanitized": True,
        "generated_at": datetime.now(timezone.utc).isoformat().replace("+00:00", "Z"),
        "git_sha": os.environ.get("GITHUB_SHA", "local"),
        "captures": [],
    }

    rendered: list[Image.Image] = []

    for spec in SPECS:
        exit_code, raw_output = run_capture(spec)
        safe_output = sanitize(raw_output)
        image = draw_terminal(spec, exit_code, safe_output)
        image.save(MEDIA_DIR / spec.filename, "PNG", optimize=True)
        rendered.append(image)

        manifest["captures"].append(
            {
                "title": spec.title,
                "command": list(spec.command),
                "filename": spec.filename,
                "exit_code": exit_code,
            }
        )

    save_demo(rendered)

    (MEDIA_DIR / "capture-manifest.json").write_text(
        json.dumps(manifest, indent=2, ensure_ascii=False) + "\n",
        encoding="utf-8",
    )

    update_readme()

    print(f"[OK] Generated {len(SPECS)} screenshots and CLI demo in {MEDIA_DIR}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
