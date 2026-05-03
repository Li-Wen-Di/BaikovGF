﻿# BaikovGF 程序包

该目录包含用于 Baikov 生成函数约化流程的可发布 Wolfram Language 程序包。

## 文件

- `BaikovGF.wl`
  - 主程序包文件。
  - 负责构造费曼积分对象。
  - 判断目标属于 `Top`、`TypeI`、`TypeII` 或 `TypeIII`。
  - 构造生成函数。
  - 提取原始约化系数。
  - 将系数化简为最终解析结果。
- `BaikovGFCheck.wl`
  - 由 `BaikovGF.wl` 内部自动加载的输入检查文件。
  - 负责检查动量、传播子、动力学规则、目标幂次和源幂次是否合法。

正常使用只需要加载：

```wl
projectRoot = "/path/to/this/repository";
Get[FileNameJoin[{projectRoot, "BaikovGF", "BaikovGF.wl"}]];
```

## 对外接口

- `SP[p, q]`
  - 程序包使用的标量积记号。
- `CreateFeynmanIntegral[...]`
  - 构造 `FeynmanIntegral` 对象。
- `BuildBaikovGeneratingFunction[family, targetPowers]`
  - 构造 `BaikovGeneratingFunction` 对象，并判断目标类型。
- `ExtractBaikovCoefficient[gfObject, sourcePowers]`
  - 返回 `BaikovRawCoefficient` 对象。
- `SimplifyBaikovCoefficient[rawObject]`
  - 返回 `BaikovCoefficient` 对象。
- `ExtractBaikovCoefficientBatch[...]`
  - `ExtractBaikovCoefficient` 的批量封装。
- `SimplifyBaikovCoefficientBatch[...]`
  - `SimplifyBaikovCoefficient` 的批量封装。
- `CheckBaikovExternalBackend[]`
  - 检查外部 Python/FLINT 化简后端是否可用。

## 当前支持的积分族

当前程序包只支持解析约化到以下 completed family 情形：

- 显式传播子个数等于 `Nsp`，或
- 显式传播子个数等于 `Nsp - 1`，并且额外提供恰好一个辅助传播子。

其中 `Nsp` 是由圈动量和外动量决定的独立标量积个数。

## 类型判断

`BuildBaikovGeneratingFunction` 目前按下列规则判断类型：

- `Top`
  - 完整传播子族，目标幂次全为 `1`。
- `TypeI`
  - 不完整传播子族补一个辅助传播子后形成 completed family，目标幂次为显式传播子全 `1`、辅助传播子为 `0`。
- `TypeII`
  - 完整传播子族的次大拓扑，恰好去掉一个传播子，且 `t = 0` 时两个留数根都非零。
- `TypeIII`
  - 完整传播子族的次大拓扑，恰好去掉一个传播子，且 `t = 0` 时有一个留数根为零。

## 当前求导 / 提取线路

当前可发布版本中，实际只有三套提取内核：

- `Top` 和 `TypeI`
  - 共用顺序求导内核 `sequentialDerivativeCoefficient`。
- `TypeII`
  - 使用 `extractTypeIICoefficientClosedForm` 中的专门递推。
  - 内部会把超几何系数改写为 `C = C0 * P`，只传播多项式部分 `P`。
- `TypeIII`
  - 使用 `extractTypeIIICoefficientSparse` 的稀疏多元级数提取。

因此物理上虽然有四类，但代码里真正的提取主线路只有三条。

## 当前化简线路

所有类型最终都会汇合到同一条公共化简链，只是在进入公共化简前有类型预处理：

- `Top` 和 `TypeI`
  - 不做额外预处理。
- `TypeII`
  - 先做含维数指数幂次的预处理。
- `TypeIII`
  - 先做 `FunctionExpand`。

之后统一进入公共化简器，顺序为：

1. 规范半整数幂和根号；
2. 尝试快速纯有理返回；
3. 执行 `Cancel[Together[...]]`；
4. 在进入 FLINT 前先做根号尾部消除；
5. 只有在仍然不是纯有理式时，才交给外部 FLINT；
6. FLINT 返回后做最终有理式整理；
7. 再做一次根号尾部整理，得到最终解析系数。

## 最小使用流程

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

## FIRE 参考结果与测试

FIRE 参考表默认位于项目根目录：

- `tests/fire_reference_cases/`

可复用解析回归脚本位于：

- `tests/run_fire_incremental_analytic.wls`

脚本输出位于：

- `tests/results/fire_incremental_analytic/results.wl`
- `tests/results/fire_incremental_analytic/summary.en.md`
- `tests/results/fire_incremental_analytic/summary.zh.md`
