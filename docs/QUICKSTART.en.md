# Quick Start — Super Dev Kit

> English version. [Leia em Português](QUICKSTART.md).

This is the recommended flow for preparing a new machine with Super Dev Kit.

In v1.0, the recommended way to use the project is through the unified \`devkit\` CLI. The legacy menus and scripts remain available.

## 1. Install Git

### Windows

~~~powershell
winget install --id Git.Git -e
~~~

Close and reopen your terminal.

### Ubuntu / Linux

~~~bash
sudo apt update
sudo apt install -y git
~~~

## 2. Clone the repository

~~~text
git clone https://github.com/Ricar66/dev-environment-bootstrap.git
cd dev-environment-bootstrap
~~~

## 3. Test the CLI

### Windows — CMD

~~~cmd
devkit.cmd version
devkit.cmd help
~~~

### Windows — PowerShell

~~~powershell
.\devkit.ps1 version
.\devkit.ps1 help
~~~

### Linux

~~~bash
bash devkit.sh version
bash devkit.sh help
~~~

## 4. Run a dry-run

Before installing anything, preview the plan.

### Windows

~~~cmd
devkit.cmd setup fullstack --dry-run
~~~

or:

~~~powershell
.\devkit.ps1 setup fullstack --dry-run
~~~

### Linux

~~~bash
bash devkit.sh setup fullstack --dry-run
~~~

Available profiles:

- essential;
- frontend;
- backend;
- fullstack;
- datasql;
- devops.

Details: [PROFILES.md](PROFILES.md).

## 5. Install the profile

### Windows

Open CMD or PowerShell as Administrator when the selected profile requires elevated privileges.

CMD:

~~~cmd
devkit.cmd setup fullstack
~~~

PowerShell:

~~~powershell
.\devkit.ps1 setup fullstack
~~~

### Linux

~~~bash
bash devkit.sh setup fullstack
~~~

The CLI requests sudo when the Linux bootstrap needs elevated privileges.

## 6. Validate with Dev Doctor

### Windows

~~~cmd
devkit.cmd doctor
~~~

or:

~~~powershell
.\devkit.ps1 doctor
~~~

### Linux

~~~bash
bash devkit.sh doctor
~~~

To validate Docker:

~~~text
docker run --rm hello-world
~~~

## 7. Install the global command — optional

After validating the clone, you can stop typing the full launcher.

### Windows

~~~cmd
devkit.cmd cli install
~~~

or:

~~~powershell
.\devkit.ps1 cli install
~~~

Open a new terminal and test:

~~~text
devkit version
~~~

### Linux

~~~bash
bash devkit.sh cli install
~~~

Then:

~~~bash
devkit version
~~~

If ~/.local/bin is not already in PATH, the installer shows how to configure it.

## 8. Use stacks for specific environments

Stacks continue to use the modular catalog.

Example:

~~~text
devkit stack react --dry-run
devkit stack react
~~~

Another example:

~~~text
devkit stack fullstack-react-node --dry-run
~~~

See [STACKS.md](STACKS.md).

## 9. Generate projects

List templates:

~~~text
devkit project list
~~~

React + Vite:

~~~text
devkit project react-vite meu-app --dry-run
devkit project react-vite meu-app --with-devcontainer
~~~

Python API:

~~~text
devkit project python-api minha-api
~~~

See [PROJECT-TEMPLATES.md](PROJECT-TEMPLATES.md).

## 10. Corporate certificates are optional

Most machines do not need an additional certificate.

If Docker and HTTPS work normally, skip this step.

Only when you see an error such as:

~~~text
x509: certificate signed by unknown authority
~~~

see [CERTIFICADOS-CORPORATIVOS.md](CERTIFICADOS-CORPORATIVOS.md).

On Linux, when required:

~~~text
devkit setup fullstack --auto-ca
~~~

The flow still requires validation before trusting a CA.

## 11. Inspect local state

~~~text
devkit state
~~~

For automation:

~~~text
devkit state --json
~~~

The manifest is stored at:

~~~text
.super-dev-kit/manifest.json
~~~

## 12. Export or reproduce an environment

Export:

~~~text
devkit export
~~~

On the other machine, start with a dry-run:

~~~text
devkit import --dry-run
~~~

Then import:

~~~text
devkit import
~~~

Compare the result:

~~~text
devkit compare
~~~

See [REPRODUCIBILITY.md](REPRODUCIBILITY.md).

## 13. Backup, inventory and updates

VS Code backup:

~~~text
devkit backup vscode
~~~

Safe Git configuration backup:

~~~text
devkit backup git
~~~

Inventory:

~~~text
devkit inventory
~~~

Update:

~~~text
devkit update
~~~

The updater continues to refuse updates when the clone contains unsaved local changes.

## 14. JSON output

The v1 CLI provides structured output for automation:

~~~text
devkit version --json
devkit commands --json
devkit doctor --json
devkit stack react --dry-run --json
~~~

See [CLI.md](CLI.md) for the contract, exit codes and examples.

## Legacy menus remain available

If you prefer the interactive experience:

### CMD

~~~cmd
setup.cmd
~~~

### PowerShell

~~~powershell
.\setup.ps1
~~~

### Linux

~~~bash
bash setup.sh
~~~

Legacy flows remain available in v1.

## Full user manual

For a complete day-to-day guide, see [USER-MANUAL.md](USER-MANUAL.md).

## Next steps

Explore the main guides:

- [Unified CLI](CLI.md)
- [Profiles](PROFILES.md)
- [Stacks](STACKS.md)
- [Project Templates](PROJECT-TEMPLATES.md)
- [Reproducible environments](REPRODUCIBILITY.md)
- [Advanced automation](AUTOMATION.md)
