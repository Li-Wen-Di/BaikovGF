# BaikovGF

`BaikovGF` is a Wolfram Language package for analytic IBP reduction of Feynman integrals based on the Baikov generating-function method.

This repository contains:

- the main package
- example notebooks
- the Python/FLINT backend used by the package for rational simplification
- analytic regression tests together with FIRE reference data

## Requirements

The package requires:

- Wolfram Language / Mathematica
- Python 3
- `python-flint`

The Python/FLINT backend is part of the required runtime environment of the package.

## Getting Started

### 1. Install the FLINT backend from `external/`

Run the setup script for your platform from the repository root.

Windows:

```powershell
powershell -ExecutionPolicy Bypass -File .\external\setup_flint_env.ps1
```

Linux:

```bash
bash ./external/setup_flint_env_linux.sh
```

macOS:

```bash
bash ./external/setup_flint_env_macos.sh
```

Detailed setup notes:

- [external/README.en.md](external/README.en.md)
- [external/README.zh.md](external/README.zh.md)

Before running the package, you can verify that FLINT has been configured correctly:

```wl
CheckBaikovExternalBackend[]
```

### 2. Load the package

```wl
projectRoot = "/path/to/this/repository";
Get[FileNameJoin[{projectRoot, "BaikovGF", "BaikovGF.wl"}]];
```

## Minimal Usage Example

The following example uses the massive bubble family.

```wl
projectRoot = "/path/to/this/repository";
Get[FileNameJoin[{projectRoot, "BaikovGF", "BaikovGF.wl"}]];

family = CreateFeynmanIntegral[
  "LoopMomenta" -> {k1},
  "ExternalMomenta" -> {p1},
  "Propagators" -> {
    -m1sq + SP[k1, k1],
    -m2sq + SP[k1 + p1, k1 + p1]
  },
  "AuxiliaryPropagators" -> {},
  "KinematicRules" -> {SP[p1, p1] -> s},
  "DimensionSymbol" -> d
];

targetPowers = {1, 0};
sourcePowers = {2, 2};

gf = BuildBaikovGeneratingFunction[family, targetPowers];
raw = ExtractBaikovCoefficient[gf, sourcePowers];
res = SimplifyBaikovCoefficient[raw];

res["Coefficient"]
```

## Repository Layout

- [BaikovGF/](BaikovGF/)
  Main Wolfram Language package and package-level documentation.
- [examples/](examples/)
  Example notebooks, one notebook for each family.
- [external/](external/)
  Python/FLINT backend and setup scripts.
- [tests/](tests/)
  Reusable analytic regression scripts, FIRE reference tables, and test results.

## Examples

The [examples/](examples/) directory contains one notebook for each family. These notebooks demonstrate:

- family construction
- timings for build / extract / simplify
- comparison against the corresponding FIRE reference coefficient

## Tests

The main analytic regression script is:

- [tests/run_fire_incremental_analytic.wls](tests/run_fire_incremental_analytic.wls)

Run it from the repository root:

```powershell
wolframscript -script .\tests\run_fire_incremental_analytic.wls
```

Further test documentation:

- [tests/README.en.md](tests/README.en.md)
- [tests/README.zh.md](tests/README.zh.md)

## Documentation

Package-level documentation:

- [BaikovGF/README.en.md](BaikovGF/README.en.md)
- [BaikovGF/README.zh.md](BaikovGF/README.zh.md)
