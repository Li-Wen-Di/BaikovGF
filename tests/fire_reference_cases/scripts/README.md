# FIRE 脚本说明

这个目录只放与 `tests/fire_reference_cases` 有直接关系的脚本。

目标是两件事：

1. 生成每个论文例子的 FIRE 输入文件。
2. 将 FIRE 的输出解析成项目内部统一的参考系数文件，供包对答案使用。

## 文件列表

### 1. `fire_reference_specs.wl`

作用：

- 定义所有论文图的规格清单。
- 每个图的条目都包含：
  - `Slug`
  - 图名
  - 传播子
  - 圈动量
  - 外动量
  - 运动学替换
  - 源幂次列表
  - 其他必要元信息

这是整套 FIRE 参考库的“总清单”。

如果要新增一个图，先修改这个文件。

### 2. `generate_fire_reference_inputs.wls`

作用：

- 根据 `fire_reference_specs.wl` 中的定义，自动生成每个图对应的 FIRE 输入文件。

会生成的内容包括：

- `PrepareStart.m`
- `<slug>.config`
- `<slug>int.m`
- 每个图目录下的说明文件

典型用途：

- 第一次建立 `tests/fire_reference_cases`
- 新增图后重新生成输入
- 修改某个图的源幂次组合后重新生成输入

运行方式：

```powershell
wolframscript -file tests/fire_reference_cases/scripts/generate_fire_reference_inputs.wls
```

只生成指定图：

```powershell
wolframscript -file tests/fire_reference_cases/scripts/generate_fire_reference_inputs.wls bubble_massive vacuum_2loop
```

### 3. `parse_fire_reference_tables.wls`

作用：

- 读取每个图目录中的 FIRE `.tables` 文件。
- 解析出每个源积分到所有主积分的约化系数。
- 生成统一的参考系数 `.wl` 文件，供包测试和 example 对答案使用。

生成的核心结果包括：

- `<slug>_index.wl`
- `coefficients/*.wl`
- 总的解析汇总文件

运行方式：

```powershell
wolframscript -file tests/fire_reference_cases/scripts/parse_fire_reference_tables.wls
```

只解析指定图：

```powershell
wolframscript -file tests/fire_reference_cases/scripts/parse_fire_reference_tables.wls bubble_massive vacuum_2loop
```

### 4. `parse_fire_variant_tables.wls`

作用：

- 处理标准符号 `.tables` 之外的变体结果。
- 目前主要用于 prime / modular / 数值变体的 FIRE 输出整理。

适用场景：

- 某些重图的符号 FIRE 过慢
- 只能得到有限域或 prime 模参考结果
- 需要将这些结果也整理成可供测试使用的参考文件

### 5. `run_fire_cases_in_wsl.ps1`

作用：

- 在 WSL 中批量运行 FIRE case。
- 自动进入对应目录，调用 FIRE，收集输出。

适用场景：

- 需要批量重跑多个图
- 需要在同一环境下更新 `tests/fire_reference_cases`

这个脚本不负责解析 `.tables`，它只负责“跑 FIRE”。

## 推荐工作流

如果是第一次建立或更新 FIRE 参考库，建议按下面顺序：

### 步骤 1：修改图规格

编辑：

- `fire_reference_specs.wl`

### 步骤 2：生成输入文件

运行：

```powershell
wolframscript -file tests/fire_reference_cases/scripts/generate_fire_reference_inputs.wls
```

### 步骤 3：运行 FIRE

如果手动运行，就到每个图目录执行对应 FIRE 命令。

如果批量运行，可以使用：

```powershell
powershell -ExecutionPolicy Bypass -File tests/fire_reference_cases/scripts/run_fire_cases_in_wsl.ps1
```

### 步骤 4：解析 FIRE 输出

运行：

```powershell
wolframscript -file tests/fire_reference_cases/scripts/parse_fire_reference_tables.wls
```

如果是变体输出，再使用：

```powershell
wolframscript -file tests/fire_reference_cases/scripts/parse_fire_variant_tables.wls
```

## 目录关系

这个 `scripts` 目录与各个图的目录是并列关系：

- `tests/fire_reference_cases/scripts/`
- `tests/fire_reference_cases/tadpole/`
- `tests/fire_reference_cases/bubble_massive/`
- `tests/fire_reference_cases/vacuum_3loop/`
- ...

规则是：

- 通用脚本只放在 `scripts/`
- 某个图自己的 FIRE 输入、输出、日志、系数文件只放在该图目录中

## 新增一个图时需要做什么

1. 在 `fire_reference_specs.wl` 中新增一个条目。
2. 运行 `generate_fire_reference_inputs.wls`。
3. 跑 FIRE。
4. 运行 `parse_fire_reference_tables.wls`。
5. 确认该图目录下的 `coefficients/*.wl` 已生成。

## 注意事项

- 这个目录只负责 FIRE 参考库，不负责包测试逻辑。
- 包测试脚本应当放在根目录的 `tests/` 下。
- example notebook 应当放在根目录的 `examples/` 下。
- 如果重新跑了 FIRE，应该重新执行解析脚本，避免参考系数过期。

