# BaikovGF

`BaikovGF` is a Wolfram Language package for analytic IBP reduction of Feynman integrals based on the Baikov generating-function method. The corresponding paper is [arXiv:2504.02573, *Generating Function of Loop Reduction by Baikov Representation*](https://arxiv.org/abs/2504.02573).

## Repository Layout

- [BaikovGF/](BaikovGF/)
  Main Wolfram Language package and package-level documentation.
- [examples/](examples/)
  Example notebooks, one notebook for each family.
- [external/](external/)
  Python/FLINT backend and setup scripts.
- [tests/](tests/)
  Reusable analytic regression scripts, FIRE reference tables, and test results.

## Requirements

This project requires:

- Wolfram Language / Mathematica
- Python 3
- `python-flint`

The Python/FLINT backend is used in the final rational-simplification stage of the package.

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

After loading the package and before running reductions, you can use the following function in Mathematica to verify that FLINT has been configured correctly:

```wl
CheckBaikovExternalBackend[]
```

### 2. Load the package

```wl
projectRoot = "/path/to/this/repository";
Get[FileNameJoin[{projectRoot, "BaikovGF", "BaikovGF.wl"}]];
```

## Minimal Usage Example

The following example uses the massive bubble family and shows the basic workflow from family construction to the final reduction coefficient.

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

## Examples

The [examples/](examples/) directory contains one notebook for each integral family. These notebooks demonstrate:

- construction of the family object
- construction of the generating function for a target master integral
- extraction and simplification of the reduction coefficient
- analytic comparison against the corresponding FIRE reference coefficient

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
