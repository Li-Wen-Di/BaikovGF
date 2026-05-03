﻿# 测试目录说明

该目录存放可复用的发布版最终回归测试。

## 文件

- `run_fire_incremental_analytic.wls`
  - 主测试脚本。
  - 读取 `tests/fire_reference_cases/` 下的 FIRE 参考结果。
  - 对程序包逐例做解析计算。
  - 将程序包最终解析系数与 FIRE 系数做解析比较。
  - 持续更新结果文件。
- `results/fire_incremental_analytic/results.wl`
  - 机器可读的累积结果表。
- `results/fire_incremental_analytic/summary.en.md`
  - 英文人工可读汇总。
- `results/fire_incremental_analytic/summary.zh.md`
  - 中文人工可读汇总。

## 脚本统计的时间

`PackageTime` 只统计：

1. `BuildBaikovGeneratingFunction`
2. `ExtractBaikovCoefficient`
3. `SimplifyBaikovCoefficient`

与 FIRE 参考答案做解析比较的时间不计入 `PackageTime`。

## 可能状态

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

## 用法

在项目根目录运行：

```powershell
wolframscript -script .\tests\run_fire_incremental_analytic.wls
```

运行 pilot 样例：

```powershell
wolframscript -script .\tests\run_fire_incremental_analytic.wls --pilot
```

强制重跑：

```powershell
wolframscript -script .\tests\run_fire_incremental_analytic.wls --force
```

只重跑当前未解析通过的例子：

```powershell
wolframscript -script .\tests\run_fire_incremental_analytic.wls --rerun-non-analytic
```

只跑指定图族：

```powershell
wolframscript -script .\tests\run_fire_incremental_analytic.wls bubble_massive vacuum_2loop
```

修改单例 wall-clock 预算：

```powershell
wolframscript -script .\tests\run_fire_incremental_analytic.wls --case-budget-seconds 3600
```

限制本次新增执行的 case 数：

```powershell
wolframscript -script .\tests\run_fire_incremental_analytic.wls --max-cases 10
```

## FIRE 参考目录

脚本默认要求 FIRE 参考目录位于项目根目录下：

- `tests/fire_reference_cases/`

当前项目结构中，该目录已经位于 `tests/` 下。
