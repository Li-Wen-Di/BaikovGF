# BaikovGF

`BaikovGF` 是一个基于 Baikov 表示生成函数方法进行费曼积分解析 IBP 约化的 Wolfram Language 程序包。对应论文见 [arXiv:2504.02573, *Generating Function of Loop Reduction by Baikov Representation*](https://arxiv.org/abs/2504.02573)。

## 仓库结构

- [BaikovGF/](BaikovGF/)
  主 Wolfram Language 程序包及程序包级说明文档。
- [examples/](examples/)
  示例 notebook，每个积分族一个文件。
- [external/](external/)
  Python/FLINT 后端及初始化脚本。
- [tests/](tests/)
  可复用解析回归脚本、FIRE 参考表和测试结果。

## 依赖

运行本项目需要：

- Wolfram Language / Mathematica
- Python 3
- `python-flint`

其中，Python/FLINT 后端负责程序包最终阶段的有理分式化简。

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

加载程序包后、正式执行约化前，可先在 Mathematica 中运行以下函数检查 FLINT 是否已正确配置：

```wl
CheckBaikovExternalBackend[]
```

### 2. 加载程序包

```wl
projectRoot = "/path/to/this/repository";
Get[FileNameJoin[{projectRoot, "BaikovGF", "BaikovGF.wl"}]];
```

## 最小使用示例

下面以 massive bubble 积分族为例，演示从积分族构造到约化系数输出的基本流程。

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

## 示例

[examples/](examples/) 目录中每个 notebook 对应论文中的一个积分族，主要展示：

- 构造积分族对象
- 构造目标主积分的生成函数
- 从生成函数提取约化系数并完成化简
- 与对应 FIRE 参考系数进行解析核对

## 测试

主解析回归脚本为：

- [tests/run_fire_incremental_analytic.wls](tests/run_fire_incremental_analytic.wls)

在仓库根目录运行：

```powershell
wolframscript -script .\tests\run_fire_incremental_analytic.wls
```

进一步说明见：

- [tests/README.en.md](tests/README.en.md)
- [tests/README.zh.md](tests/README.zh.md)

## 文档

程序包级说明文档：

- [BaikovGF/README.en.md](BaikovGF/README.en.md)
- [BaikovGF/README.zh.md](BaikovGF/README.zh.md)
