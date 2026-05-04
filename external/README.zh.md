# `external` 目录说明

## 作用

`external/` 目录存放 `BaikovGF` 程序包使用的外部有理式化简后端。

当前主要后端文件是：

- [flint_simplify.py](flint_backend/flint_simplify.py)

这个后端主要在 `SimplifyBaikovCoefficient[...]` 的最后化简阶段被调用。

如果缺少这个目录：

- `CreateFeynmanIntegral[...]` 仍然可以运行。
- `BuildBaikovGeneratingFunction[...]` 仍然可以运行。
- `ExtractBaikovCoefficient[...]` 仍然可以运行。
- `SimplifyBaikovCoefficient[...]` 中依赖外部后端的最终有理式化简将不可用。

## 目录内容

- [README.en.md](README.en.md)：英文说明。
- [README.zh.md](README.zh.md)：本文件。
- [setup_flint_env.ps1](setup_flint_env.ps1)：Windows 初始化脚本。
- [setup_flint_env_linux.sh](setup_flint_env_linux.sh)：Linux 初始化脚本。
- [setup_flint_env_macos.sh](setup_flint_env_macos.sh)：macOS 初始化脚本。
- [flint_simplify.py](flint_backend/flint_simplify.py)：Python/FLINT 后端实现。

## 程序包如何查找 Python

程序包优先使用项目根目录下的本地虚拟环境：

- Windows：`.venv-flint\\Scripts\\python.exe`
- macOS/Linux：`.venv-flint/bin/python`

如果该环境不存在，再回退到系统 `python`。

因此正常情况下，不需要额外配置路径，只要满足下面两种情况之一即可：

1. 项目根目录下存在 `.venv-flint`，且其中安装了 `python-flint`。
2. 系统 `python` 可以直接 `import flint`。

## 三个平台的初始化脚本

### Windows

脚本：

- [setup_flint_env.ps1](setup_flint_env.ps1)

推荐用法：

```powershell
powershell -ExecutionPolicy Bypass -File .\external\setup_flint_env.ps1
```

指定 Python 启动器：

```powershell
powershell -ExecutionPolicy Bypass -File .\external\setup_flint_env.ps1 -Python py
```

指定 Python 可执行文件：

```powershell
powershell -ExecutionPolicy Bypass -File .\external\setup_flint_env.ps1 -Python "C:\Path\To\python.exe"
```

### Linux

脚本：

- [setup_flint_env_linux.sh](setup_flint_env_linux.sh)

推荐用法：

```bash
bash ./external/setup_flint_env_linux.sh
```

指定 Python：

```bash
bash ./external/setup_flint_env_linux.sh python3.11
```

### macOS

脚本：

- [setup_flint_env_macos.sh](setup_flint_env_macos.sh)

推荐用法：

```bash
bash ./external/setup_flint_env_macos.sh
```

指定 Python：

```bash
bash ./external/setup_flint_env_macos.sh python3.11
```

## 这些脚本会做什么

三个脚本在不同平台上做的是同一件事：

1. 在项目根目录创建 `.venv-flint` 虚拟环境。
2. 升级 `pip`、`setuptools`、`wheel`。
3. 安装或升级 `python-flint`。
4. 运行一次最小 `flint` 导入测试。

## 用户最少需要做什么

如果用户已经安装了：

- Mathematica / Wolfram Language
- Python

通常只需要再做一步：

- 运行当前平台对应的初始化脚本

## 如何确认后端可用

脚本执行成功后，会打印：

- 当前使用的 Python 路径
- `flint` 模块的安装路径

此外，也可以在 Wolfram Language 中运行：

```wl
CheckBaikovExternalBackend[]
```

它会检查：

- 程序包当前选中的 Python 解释器
- [flint_simplify.py](flint_backend/flint_simplify.py) 是否存在
- Python 是否可以 `import flint`
- 后端是否能完成一次最小往返化简测试

## 常见情况

### 只有系统 Python，没有 `python-flint`

这是最常见情况，直接运行对应平台的初始化脚本即可。

### 系统中有多个 Python

三个脚本都支持手动指定 Python：

- Windows：`-Python ...`
- macOS/Linux：第一个位置参数

### 不用脚本，手动安装

也可以，只要最终满足下面两种情况之一：

1. 项目根目录下存在 `.venv-flint`，且其中安装了 `python-flint`。
2. 系统 `python` 可以直接 `import flint`。

但从可复现性和稳定性来看，仍然建议直接使用这里提供的脚本。
