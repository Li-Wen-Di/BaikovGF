# Test Folder

This folder contains the reusable final regression test for the publishable package.

## Files

- `run_fire_incremental_analytic.wls`
  - Main reusable regression runner.
  - Reads the FIRE reference data under `tests/fire_reference_cases/`.
  - Runs the package analytically case by case.
  - Compares the final analytic package coefficient against the FIRE coefficient.
  - Continuously updates the result files.
- `results/fire_incremental_analytic/results.wl`
  - Machine-readable accumulated result table.
- `results/fire_incremental_analytic/summary.en.md`
  - English human-readable summary.
- `results/fire_incremental_analytic/summary.zh.md`
  - Chinese human-readable summary.

## What the script measures

`PackageTime` includes only:

1. `BuildBaikovGeneratingFunction`
2. `ExtractBaikovCoefficient`
3. `SimplifyBaikovCoefficient`

The analytic comparison to the FIRE reference is not counted into `PackageTime`.

## Supported statuses

- `analytic-ok`
- `gf-timeout`
- `gf-failure`
- `extract-timeout`
- `extract-failure`
- `simplify-timeout`
- `simplify-failure`
- `compare-timeout`
- `mismatch`
- `family-failure`
- `case-error`

## Usage

Run from the project root:

```powershell
wolframscript -script .\tests\run_fire_incremental_analytic.wls
```

Pilot run:

```powershell
wolframscript -script .\tests\run_fire_incremental_analytic.wls --pilot
```

Force rerun:

```powershell
wolframscript -script .\tests\run_fire_incremental_analytic.wls --force
```

Rerun only non-analytic cases:

```powershell
wolframscript -script .\tests\run_fire_incremental_analytic.wls --rerun-non-analytic
```

Restrict to selected families:

```powershell
wolframscript -script .\tests\run_fire_incremental_analytic.wls bubble_massive vacuum_2loop
```

Change per-case wall-clock budget:

```powershell
wolframscript -script .\tests\run_fire_incremental_analytic.wls --case-budget-seconds 3600
```

Limit the number of newly executed cases:

```powershell
wolframscript -script .\tests\run_fire_incremental_analytic.wls --max-cases 10
```

## Reference data location

The script expects the FIRE reference folder at:

- `tests/fire_reference_cases/`

under the project root.
