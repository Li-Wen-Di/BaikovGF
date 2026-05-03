# BaikovGF Package

This folder contains the publishable Wolfram Language package for the Baikov generating-function reduction workflow.

## Files

- `BaikovGF.wl`
  - Main package.
  - Builds the Feynman-integral object.
  - Classifies the target as `Top`, `TypeI`, `TypeII`, or `TypeIII`.
  - Builds the generating function.
  - Extracts the raw reduction coefficient.
  - Simplifies the coefficient to the final analytic result.
- `BaikovGFCheck.wl`
  - Input-validation helpers loaded internally by `BaikovGF.wl`.
  - Checks momenta, propagators, kinematic rules, target powers, and source powers.

Normal use only needs:

```wl
projectRoot = "/path/to/this/repository";
Get[FileNameJoin[{projectRoot, "BaikovGF", "BaikovGF.wl"}]];
```

## Public API

- `SP[p, q]`
  - Scalar-product notation used by the package.
- `CreateFeynmanIntegral[...]`
  - Builds a `FeynmanIntegral` object.
- `BuildBaikovGeneratingFunction[family, targetPowers]`
  - Builds a `BaikovGeneratingFunction` object and classifies the target type.
- `ExtractBaikovCoefficient[gfObject, sourcePowers]`
  - Returns a `BaikovRawCoefficient` object.
- `SimplifyBaikovCoefficient[rawObject]`
  - Returns a `BaikovCoefficient` object.
- `ExtractBaikovCoefficientBatch[...]`
  - Batch wrapper over `ExtractBaikovCoefficient`.
- `SimplifyBaikovCoefficientBatch[...]`
  - Batch wrapper over `SimplifyBaikovCoefficient`.
- `CheckBaikovExternalBackend[]`
  - Checks whether the external Python/FLINT simplifier backend is available.

## Supported integral families

The current package supports analytic reduction only for completed families where:

- the number of explicit propagators is `Nsp`, or
- the number of explicit propagators is `Nsp - 1` and exactly one auxiliary propagator is supplied.

Here `Nsp` is the number of independent scalar products determined by loop and external momenta.

## Type classification

`BuildBaikovGeneratingFunction` classifies the target as follows.

- `Top`
  - Complete family, target powers are all `1`.
- `TypeI`
  - Incomplete family completed by one auxiliary propagator, with target powers equal to explicit `1` and auxiliary `0`.
- `TypeII`
  - Complete family sub-topology with exactly one dropped propagator, and the residue roots at `t = 0` are both nonzero.
- `TypeIII`
  - Complete family sub-topology with exactly one dropped propagator, and one residue root at `t = 0` is zero.

## Current extraction routes

There are three actual extraction kernels in the current publishable package.

- `Top` and `TypeI`
  - Use direct sequential differentiation through `sequentialDerivativeCoefficient`.
- `TypeII`
  - Uses the specialized canonical-state recursion implemented by `extractTypeIICoefficientClosedForm`.
  - Internally it rewrites the hypergeometric coefficient as `C = C0 * P` and propagates only the polynomial part `P`.
- `TypeIII`
  - Uses sparse multivariate series extraction through `extractTypeIIICoefficientSparse`.

So although there are four physical types, there are only three extraction pipelines in the code.

## Simplification route

All types eventually pass through the same final simplification pipeline, after a type-specific preprocessing step.

- `Top` and `TypeI`
  - No extra preprocessing.
- `TypeII`
  - Applies dimension-dependent power reduction first.
- `TypeIII`
  - Applies `FunctionExpand` first.

Then the common simplifier:

1. normalizes half-integer powers and square roots,
2. tries cheap rational early return,
3. applies `Cancel[Together[...]]`,
4. tries the square-root tail cancellation before FLINT,
5. only if needed, prepares a rational expression for the external FLINT backend,
6. simplifies with FLINT,
7. performs final normalization and square-root-tail cleanup.

## Minimal workflow

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

## Reference data and testing

The FIRE reference tables are expected under the project root:

- `tests/fire_reference_cases/`

The reusable analytic regression script lives in:

- `tests/run_fire_incremental_analytic.wls`

Its outputs are written to:

- `tests/results/fire_incremental_analytic/results.wl`
- `tests/results/fire_incremental_analytic/summary.en.md`
- `tests/results/fire_incremental_analytic/summary.zh.md`
