# `external` Directory Guide

## Purpose

The `external/` directory contains the external rational-simplification backend used by the `BaikovGF` package.

The main backend file at present is:

- [flint_simplify.py](flint_backend/flint_simplify.py)

This backend is mainly called in the final simplification stage of `SimplifyBaikovCoefficient[...]`.

If this directory is missing:

- `CreateFeynmanIntegral[...]` can still run.
- `BuildBaikovGeneratingFunction[...]` can still run.
- `ExtractBaikovCoefficient[...]` can still run.
- The final rational simplification in `SimplifyBaikovCoefficient[...]` that depends on the external backend will not be available.

## Directory Contents

- [README.en.md](README.en.md): this file.
- [README.zh.md](README.zh.md): Chinese documentation.
- [setup_flint_env.ps1](setup_flint_env.ps1): Windows setup script.
- [setup_flint_env_linux.sh](setup_flint_env_linux.sh): Linux setup script.
- [setup_flint_env_macos.sh](setup_flint_env_macos.sh): macOS setup script.
- [flint_simplify.py](flint_backend/flint_simplify.py): Python/FLINT backend implementation.

## How the Package Finds Python

The package first looks for a project-local virtual environment under the repository root:

- Windows: `.venv-flint\\Scripts\\python.exe`
- macOS/Linux: `.venv-flint/bin/python`

If that environment does not exist, the package falls back to the system `python`.

In normal use, no extra path configuration is needed as long as one of the following conditions is satisfied:

1. `.venv-flint` exists in the project root and has `python-flint` installed.
2. The system `python` can directly `import flint`.

## Setup Scripts for the Three Platforms

### Windows

Script:

- [setup_flint_env.ps1](setup_flint_env.ps1)

Recommended usage:

```powershell
powershell -ExecutionPolicy Bypass -File .\external\setup_flint_env.ps1
```

Specify a Python launcher:

```powershell
powershell -ExecutionPolicy Bypass -File .\external\setup_flint_env.ps1 -Python py
```

Specify a Python executable:

```powershell
powershell -ExecutionPolicy Bypass -File .\external\setup_flint_env.ps1 -Python "C:\Path\To\python.exe"
```

### Linux

Script:

- [setup_flint_env_linux.sh](setup_flint_env_linux.sh)

Recommended usage:

```bash
bash ./external/setup_flint_env_linux.sh
```

Specify a Python executable:

```bash
bash ./external/setup_flint_env_linux.sh python3.11
```

### macOS

Script:

- [setup_flint_env_macos.sh](setup_flint_env_macos.sh)

Recommended usage:

```bash
bash ./external/setup_flint_env_macos.sh
```

Specify a Python executable:

```bash
bash ./external/setup_flint_env_macos.sh python3.11
```

## What These Scripts Do

The three scripts do the same job on different platforms:

1. Create a `.venv-flint` virtual environment in the project root.
2. Upgrade `pip`, `setuptools`, and `wheel`.
3. Install or upgrade `python-flint`.
4. Run a minimal `flint` import test.

## Minimal User Action

If the user already has:

- Mathematica / Wolfram Language
- Python

then the only additional step is usually:

- run the setup script for the current platform

## How to Verify That the Backend Works

After a successful setup, the script prints:

- the Python executable being used
- the installation path of the `flint` module

You can also run the following in Wolfram Language:

```wl
CheckBaikovExternalBackend[]
```

It checks:

- which Python interpreter the package has selected
- whether [flint_simplify.py](flint_backend/flint_simplify.py) exists
- whether Python can `import flint`
- whether the backend can complete a minimal round-trip simplification test

## Common Cases

### Only system Python is available and `python-flint` is not installed

This is the most common case. Just run the setup script for your platform.

### Multiple Python installations exist

All three scripts allow the Python executable to be specified manually:

- Windows: `-Python ...`
- macOS/Linux: the first positional argument

### Manual installation instead of using the scripts

That is also possible, as long as one of the following conditions is satisfied:

1. `.venv-flint` exists in the project root and has `python-flint` installed.
2. The system `python` can directly `import flint`.

For reproducibility and stability, using the provided scripts is still recommended.
