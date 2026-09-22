# I built a cross-platform Dev Environment Bootstrap — here is what I learned

Setting up a development machine sounds simple until you need to repeat it.

Git, Node.js, Python, Docker, SSH, VS Code extensions, database clients, certificates, package managers and environment validation quickly turn onboarding into a checklist that is easy to forget.

That problem became the **Super Dev Kit**.

## The goal

The project is an open-source toolkit for preparing and validating development environments on Windows and Ubuntu/Linux.

The current CLI looks like this:

~~~text
devkit setup fullstack
devkit doctor
devkit stack react
devkit project react-vite my-app
devkit export
devkit compare
~~~

## Why not one huge script?

The project evolved toward a thin CLI over specialized components.

The CLI does not reimplement installation logic. It delegates to platform-specific scripts, while stacks, modules, templates and runtime policies are described declaratively.

That makes it easier to keep CMD, PowerShell and Bash aligned.

## Dry-run first

Environment automation can be dangerous when it modifies package managers, Docker, certificates or system features.

So destructive or state-changing flows are designed around preview and explicit execution.

~~~text
devkit setup fullstack --dry-run
devkit stack react --dry-run
devkit project react-vite my-app --dry-run
~~~

## State matters

The kit records a local manifest so cleanup can distinguish between software that already existed and software installed by the toolkit.

That same state supports drift detection and reproducible environment exports.

## Corporate HTTPS inspection

One of the more practical problems was Docker failing with x509 errors on networks that inspect HTTPS traffic.

The solution was not to disable TLS.

Instead, the project documents a safe flow for exporting and importing the authorized root CA only when necessary.

## Reproducibility

A machine can export its environment intent to a lock file.

Another machine can preview the import, apply it and compare the result.

~~~text
devkit export
devkit import --dry-run
devkit import
devkit compare
~~~

## Version 0.9

The v0.9 milestone focuses on public readiness rather than large new features:

- better README and Quick Start;
- architecture docs;
- FAQ and troubleshooting;
- support matrix;
- contribution guides;
- link and UTF-8 validation;
- public issue templates;
- Windows/Linux smoke tests.

The repository is available at:

https://github.com/Ricar66/dev-environment-bootstrap

Feedback and contributions are welcome.
