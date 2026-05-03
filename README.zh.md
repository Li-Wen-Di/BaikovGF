# BaikovGF

`BaikovGF` 是一个基于 Baikov 表示生成函数方法进行费曼积分解析 IBP 约化的 Wolfram Language 程序包。

本仓库包含：

- 主程序包
- 示例 notebook
- 程序包使用的 Python/FLINT 有理式化简后端
- 带有 FIRE 参考结果的解析回归测试

## 依赖

程序包需要：

- Wolfram Language / Mathematica
- Python 3
- `python-flint`

其中，Python/FLINT 后端属于程序包运行环境的一部分。

## 快速上手

### 1. 安装 `external/` 中的 FLINT 后端

根据你的平台，在仓库根目录运行对应脚本。

Windows：

```powershell
powershell -ExecutionPolicy Bypass -File .\external\setup_flint_env.ps1
```

Linux：

```bash
bash ./external/setup_flint_env_linux.sh
```

macOS：

```bash
bash ./external/setup_flint_env_macos.sh
```

详细说明见：

- [external/README.en.md](external/README.en.md)
- [external/README.zh.md](external/README.zh.md)

在正式运行程序包前，可用以下函数检查 FLINT 是否已正确配置：

```wl
CheckBaikovExternalBackend[]
```

### 2. 加载程序包

```wl
projectRoot = "/path/to/this/repository";
Get[FileNameJoin[{projectRoot, "BaikovGF", "BaikovGF.wl"}]];
```

## 最小使用示例

下面以 massive bubble 积分族为例。

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

## 仓库结构

- [BaikovGF/](BaikovGF/)
  主 Wolfram Language 程序包及程序包说明文档。
- [examples/](examples/)
  示例 notebook，每个积分族一个文件。
- [external/](external/)
  Python/FLINT 后端及初始化脚本。
- [tests/](tests/)
  可复用解析回归脚本、FIRE 参考表和测试结果。

## 示例

[examples/](examples/) 目录中每个积分族对应一个 notebook，主要展示：

- 如何构造积分族对象
- build / extract / simplify 的计时
- 与对应 FIRE 参考系数的比较

## 测试

主解析回归脚本：

- [tests/run_fire_incremental_analytic.wls](tests/run_fire_incremental_analytic.wls)

在仓库根目录运行：

```powershell
wolframscript -script .\tests\run_fire_incremental_analytic.wls
```

详细测试说明：

- [tests/README.en.md](tests/README.en.md)
- [tests/README.zh.md](tests/README.zh.md)

## 文档

程序包级说明文档：

- [BaikovGF/README.en.md](BaikovGF/README.en.md)
- [BaikovGF/README.zh.md](BaikovGF/README.zh.md)
