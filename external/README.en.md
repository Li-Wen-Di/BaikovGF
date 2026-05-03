# external Directory Guide

## Purpose

The `external/` directory contains the external rational-simplification backend used by the `BaikovGF` package.

The main backend file is:

- [flint_simplify.py](flint_backend/flint_simplify.py)

This backend is called by the final simplification stage of the package, mainly through `SimplifyBaikovCoefficient[...]`.

Without this directory:

- `CreateFeynmanIntegral[...]` can still run.
- `BuildBaikovGeneratingFunction[...]` can still run.
- `ExtractBaikovCoefficient[...]` can still run.
- The final external rational simplification used by `SimplifyBaikovCoefficient[...]` will not be available.

## Directory Contents

- [README.md](README.md): language index.
- [README.en.md](README.en.md): this file.
- [README.zh.md](README.zh.md): Chinese version.
- [setup_flint_env.ps1](setup_flint_env.ps1): Windows setup script.
- [setup_flint_env_linux.sh](setup_flint_env_linux.sh): Linux setup script.
- [setup_flint_env_macos.sh](setup_flint_env_macos.sh): macOS setup script.
- [flint_simplify.py](flint_backend/flint_simplify.py): Python/FLINT backend implementation.

## How the Package Finds Python

The package prefers a project-local virtual environment:

- Windows: `.venv-flint\\Scripts\\python.exe`
- macOS/Linux: `.venv-flint/bin/python`

If that environment does not exist, the package falls back to the system `python`.

This means that in normal use you do not need to configure an extra path manually, as long as one of the following is true:

1. `.venv-flint` exists in the project root and contains `python-flint`.
2. Your system `python` can import `flint`.

## Setup Scripts

### Windows

Script:

- [setup_flint_env.ps1](setup_flint_env.ps1)

Recommended command:

```powershell
powershell -ExecutionPolicy Bypass -File .\external\setup_flint_env.ps1
```

Use a specific Python launcher:

```powershell
powershell -ExecutionPolicy Bypass -File .\external\setup_flint_env.ps1 -Python py
```

Or a specific Python executable:

```powershell
powershell -ExecutionPolicy Bypass -File .\external\setup_flint_env.ps1 -Python "C:\Path\To\python.exe"
```

### Linux

Script:

- [setup_flint_env_linux.sh](setup_flint_env_linux.sh)

Recommended command:

```bash
bash ./external/setup_flint_env_linux.sh
```

Use a specific Python:

```bash
bash ./external/setup_flint_env_linux.sh python3.11
```

### macOS

Script:

- [setup_flint_env_macos.sh](setup_flint_env_macos.sh)

Recommended command:

```bash
bash ./external/setup_flint_env_macos.sh
```

Use a specific Python:

```bash
bash ./external/setup_flint_env_macos.sh python3.11
```

## What the Setup Scripts Do

All three setup scripts do the same job for different platforms:

1. Create a project-local virtual environment named `.venv-flint`.
2. Upgrade `pip`, `setuptools`, and `wheel`.
3. Install or upgrade `python-flint`.
4. Run a minimal import test for `flint`.

## Minimal User Requirement

If the user already has:

- Mathematica / Wolfram Language
- Python

then the usual extra step is only:

- run the setup script for the current platform

## How to Verify the Backend

After setup, the script prints the Python executable and the installed `flint` path.

You can also verify the backend from Wolfram Language:

```wl
CheckBaikovExternalBackend[]
```

This checks:

- which Python executable the package will use
- whether [flint_simplify.py](flint_backend/flint_simplify.py) exists
- whether Python can import `flint`
- whether the backend can complete a minimal round-trip simplification test

## Common Cases

### Only system Python exists

That is fine. The setup scripts are designed for exactly this case.

### Multiple Python installations exist

All three scripts let you choose which Python to use:

- Windows: `-Python ...`
- macOS/Linux: first positional argument

### Manual setup instead of scripts

That also works, as long as one of the following is true:

1. `.venv-flint` exists in the project root and contains `python-flint`.
2. System `python` can import `flint`.

The provided scripts are still the recommended path because they are the most reproducible.

## Relation to tests and compare

This directory is not the test directory and not the speed-comparison directory.

It only provides the external simplification backend.

However, if `tests/` or `compare/` run package paths that call `SimplifyBaikovCoefficient[...]`, they indirectly depend on the backend configured here.
