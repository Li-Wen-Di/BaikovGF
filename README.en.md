# BaikovGF Project

This repository contains a publishable Wolfram Language implementation of the Baikov generating-function reduction workflow used in the associated paper: [arXiv:2504.02573](https://arxiv.org/abs/2504.02573).

## Repository Layout

- [BaikovGF/](BaikovGF/)
  Main Wolfram Language package and package-level documentation.
- [examples/](examples/)
  Demonstration notebooks, one notebook per family.
- [external/](external/)
  External Python/FLINT backend and cross-platform setup scripts.
- [tests/](tests/)
  Reusable analytic regression scripts, FIRE reference tables, and test results.
- [Paper on arXiv](https://arxiv.org/abs/2504.02573)
  Public paper link.

## Portability Status

The repository is portable to other devices for package use and analytic testing.

### Portable parts

- The package code does not depend on machine-local absolute paths.
- Example notebooks load package files and reference data relative to `NotebookDirectory[]`.
- The main regression script reads reference data relative to the project root.
- The external backend is located inside the repository and discovered from the package root.

### Required software

Core package use:

- Wolfram Language / Mathematica

Full final simplification path:

- Python 3
- `python-flint`

Optional FIRE reference regeneration:

- FIRE
- some workflows also use LiteRed
- the provided FIRE automation is currently organized around a Windows + WSL workflow

### Environment-dependent parts

These parts are optional and require local setup:

- [external/](external/): Python + `python-flint`
- [tests/check_example_notebooks.ps1](tests/check_example_notebooks.ps1): PowerShell-based notebook checker
- [tests/fire_reference_cases/scripts/run_fire_cases_in_wsl.ps1](tests/fire_reference_cases/scripts/run_fire_cases_in_wsl.ps1): Windows/WSL-based FIRE runner

## Quick Start

Clone the repository, then in Wolfram Language load the package from the cloned root:

```wl
projectRoot = "/path/to/this/repository";
Get[FileNameJoin[{projectRoot, "BaikovGF", "BaikovGF.wl"}]];
```

## Minimal Workflow

```wl
projectRoot = "/path/to/this/repository";
Get[FileNameJoin[{projectRoot, "BaikovGF", "BaikovGF.wl"}]];

family = CreateFeynmanIntegral[
  "LoopMomenta" -> {...},
  "ExternalMomenta" -> {...},
  "Propagators" -> {...},
  "AuxiliaryPropagators" -> {...},
  "KinematicRules" -> {...},
  "DimensionSymbol" -> d
];

gf = BuildBaikovGeneratingFunction[family, targetPowers];
raw = ExtractBaikovCoefficient[gf, sourcePowers];
res = SimplifyBaikovCoefficient[raw];

res["Coefficient"]
```

## External Backend

Setup and backend details:

- [external/README.en.md](external/README.en.md)
- [external/README.zh.md](external/README.zh.md)

Backend self-check:

```wl
CheckBaikovExternalBackend[]
```

## Examples

The [examples/](examples/) directory contains one notebook per family. Each notebook:

- builds a family object
- times build / extract / simplify
- compares the final analytic result against the corresponding FIRE reference coefficient

## Tests

Main analytic regression script:

- [tests/run_fire_incremental_analytic.wls](tests/run_fire_incremental_analytic.wls)

Run from the project root:

```powershell
wolframscript -script .\tests\run_fire_incremental_analytic.wls
```

Further test documentation:

- [tests/README.en.md](tests/README.en.md)
- [tests/README.zh.md](tests/README.zh.md)

## Package Documentation

- [BaikovGF/README.en.md](BaikovGF/README.en.md)
- [BaikovGF/README.zh.md](BaikovGF/README.zh.md)

## GitHub Publishing Notes

The repository now includes a `.gitignore` for local artifacts such as:

- `.cache/`
- `.venv-flint/`
- Python cache files
- local test logs

That is sufficient for normal cross-device use and GitHub publishing.
