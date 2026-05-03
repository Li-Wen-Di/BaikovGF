# BaikovGF 项目说明

本仓库存放与论文配套的 Baikov 生成函数约化流程的可发布 Wolfram Language 实现。论文链接：[arXiv:2504.02573](https://arxiv.org/abs/2504.02573)。

## 仓库结构

- [BaikovGF/](BaikovGF/)
  主 Wolfram Language 程序包及程序包说明文档。
- [examples/](examples/)
  示例 notebook，每个积分族一个文件。
- [external/](external/)
  外部 Python/FLINT 后端及跨平台初始化脚本。
- [tests/](tests/)
  可复用解析回归脚本、FIRE 参考表和测试结果。
- [arXiv 论文链接](https://arxiv.org/abs/2504.02573)
  公开论文入口。

## 可移植性状态

当前仓库对于程序包使用和解析测试是可以移植到其他设备的。

### 可直接移植的部分

- 程序包代码不依赖本机绝对路径。
- 示例 notebook 通过 `NotebookDirectory[]` 的相对路径加载程序包和参考数据。
- 主回归脚本通过项目根目录相对路径读取参考数据。
- 外部后端文件位于仓库内部，程序包会从项目根目录定位它。

### 需要的软件

若只使用主程序包：

- Wolfram Language / Mathematica

若要使用完整最终化简路径：

- Python 3
- `python-flint`

若要重新生成 FIRE 参考结果：

- FIRE
- 部分流程还会用到 LiteRed
- 当前自动化 FIRE 脚本按 Windows + WSL 工作流组织

### 仍然依赖本地环境的部分

下面这些部分是可选的，但需要本地环境配置：

- [external/](external/)：依赖 Python 与 `python-flint`
- [tests/check_example_notebooks.ps1](tests/check_example_notebooks.ps1)：基于 PowerShell 的 notebook 检查脚本
- [tests/fire_reference_cases/scripts/run_fire_cases_in_wsl.ps1](tests/fire_reference_cases/scripts/run_fire_cases_in_wsl.ps1)：基于 Windows/WSL 的 FIRE 运行脚本

## 快速开始

克隆仓库后，在 Wolfram Language 中从仓库根目录加载程序包：

```wl
projectRoot = "/path/to/this/repository";
Get[FileNameJoin[{projectRoot, "BaikovGF", "BaikovGF.wl"}]];
```

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

## 外部后端

配置与说明见：

- [external/README.en.md](external/README.en.md)
- [external/README.zh.md](external/README.zh.md)

后端自检：

```wl
CheckBaikovExternalBackend[]
```

## 示例

[examples/](examples/) 目录中每个积分族对应一个 notebook。每个 notebook 会：

- 构造积分族对象
- 统计 build / extract / simplify 的时间
- 将最终解析结果与对应的 FIRE 参考系数比较

## 测试

主解析回归脚本：

- [tests/run_fire_incremental_analytic.wls](tests/run_fire_incremental_analytic.wls)

在项目根目录运行：

```powershell
wolframscript -script .\tests\run_fire_incremental_analytic.wls
```

详细测试说明见：

- [tests/README.en.md](tests/README.en.md)
- [tests/README.zh.md](tests/README.zh.md)

## 程序包说明

- [BaikovGF/README.en.md](BaikovGF/README.en.md)
- [BaikovGF/README.zh.md](BaikovGF/README.zh.md)

## GitHub 发布说明

仓库现在已经包含 `.gitignore`，用于忽略本地运行产物，例如：

- `.cache/`
- `.venv-flint/`
- Python 缓存文件
- 本地测试日志

这已经足够支持正常的跨设备使用和 GitHub 发布。
