# BaikovGF 程序包说明

## 1. 程序包文件

`BaikovGF/` 目录当前包含两个程序文件：

- `BaikovGF.wl`
  主程序包文件。对外导出标量积记号、四步主流程接口、批量接口以及外部后端自检接口。
- `BaikovGFCheck.wl`
  输入检查文件。该文件不单独对外使用，由 `BaikovGF.wl` 在内部自动加载，只负责输入合法性检查与目标模式判断。

正常使用时只需要加载：

```wl
projectRoot = "/path/to/this/repository";
Get[FileNameJoin[{projectRoot, "BaikovGF", "BaikovGF.wl"}]];
```

加载 `BaikovGF.wl` 后，`BaikovGFCheck.wl` 会自动进入 `Private`` 上下文，不需要单独 `Get`。

## 2. 对外接口

程序包当前对外提供以下符号。

### 2.1 基本记号

- `SP[p, q]`
  程序包使用的标量积记号。输入传播子和动力学规则时，所有动量点乘都应写成 `SP[*, *]` 的形式。

### 2.2 主流程接口

- `CreateFeynmanIntegral[...]`
  构造费曼积分对象。
- `BuildBaikovGeneratingFunction[family, targetPowers]`
  根据目标主积分幂次判断类型，并构造生成函数对象。
- `ExtractBaikovCoefficient[gfObject, sourcePowers]`
  从生成函数对象中提取未最终化简的约化系数。
- `SimplifyBaikovCoefficient[rawObject]`
  对提取出的系数做类型预处理、根式整理和最终有理式化简，返回解析结果。

### 2.3 批量接口

- `ExtractBaikovCoefficientBatch[gfObject, sourcePowersList]`
  对多个源幂次向量批量调用 `ExtractBaikovCoefficient`。
- `SimplifyBaikovCoefficientBatch[rawObjectList]`
  对多个原始系数对象批量调用 `SimplifyBaikovCoefficient`。

### 2.4 外部后端检查接口

- `CheckBaikovExternalBackend[]`
  检查程序包当前是否能够调用外部 Python/FLINT 有理式化简后端。

## 3. 程序包的整体工作流

程序包的公开流程固定为四步：

1. `CreateFeynmanIntegral`  
   接受用户输入的圈动量、外动量、传播子、辅助传播子、动力学替换规则和维数符号，构造一个 `FeynmanIntegral` 对象。
2. `BuildBaikovGeneratingFunction`  
   对目标幂次进行模式判断，确定该目标属于 `Top`、`TypeI`、`TypeII` 或 `TypeIII`，并构造相应生成函数。
3. `ExtractBaikovCoefficient`  
   根据源幂次对生成函数求导或做级数系数提取，得到未最终化简的解析表达式。
4. `SimplifyBaikovCoefficient`  
   按类型进入统一化简主链，最终返回约化系数。

四步之间传递的都不是裸表达式，而是带有结构化字段的 `Association` 对象。这样做的目的有两个：

- 在每一步保留足够的中间信息，便于后续步骤继续使用，而不必反复重算。
- 将输入、派生量、内部缓存键和类型判定结果分开存储，降低不同阶段之间的耦合。

## 4. 对象结构

### 4.1 `FeynmanIntegral` 对象

`CreateFeynmanIntegral[...]` 返回：

```wl
<|
  "ObjectType" -> "FeynmanIntegral",
  "Input" -> <| ... |>,
  "Derived" -> <| ... |>,
  "Internal" -> <| ... |>
|>
```

其主要字段如下。

#### `Input`

保留用户输入或规范化后的输入：

- `"LoopMomenta"`
- `"ExternalMomenta"`
- `"Propagators"`
- `"AuxiliaryPropagators"`
- `"KinematicRules"`
- `"DimensionSymbol"`

其中传播子和辅助传播子在进入对象前会先按程序包的 `SP` 代数展开并标准化。

#### `Derived`

存放后续计算会直接用到的解析派生量：

- `"PropagatorToBaikovRules"`  
  completed family 中每个传播子到其 Baikov 变量的对应规则。
- `"ScalarProductToBaikovRules"`  
  由 completed family 反求所有圈动量相关独立标量积得到的替换规则。
- `"BaikovPolynomial"`  
  由 Gram 行列式经 `ScalarProductToBaikovRules` 和 `KinematicRules` 替换后得到的 Baikov 多项式。

#### `Internal`

存放程序控制逻辑和缓存依赖的信息：

- `"AllPropagators"`  
  completed family 的传播子总表，顺序固定为  
  `Join[Propagators, AuxiliaryPropagators]`。
- `"BaikovVariables"`  
  与 `AllPropagators` 一一对应的内部 Baikov 变量。
- `"ExplicitPropagatorCount"`
- `"AuxiliaryPropagatorCount"`
- `"TotalPropagatorCount"`
- `"ScalarProductCount"`  
  独立圈动量相关标量积个数，记作 `Nsp`。
- `"LoopCount"`
- `"ExternalCount"`
- `"TopSectorVanishingQ"`  
  用于判断顶扇区在 `z = 0` 处是否消失，影响根求解策略。
- `"R"`  
  程序内部统一使用的指数参数  
  `R = (d - L - E - 1)/2`，其中 `L` 是圈数，`E` 是外动量个数。

### 4.2 `BaikovGeneratingFunction` 对象

`BuildBaikovGeneratingFunction[family, targetPowers]` 返回：

```wl
<|
  "ObjectType" -> "BaikovGeneratingFunction",
  "Family" -> family,
  "TargetPowers" -> targetPowers,
  "Type" -> ...,
  "GeneratingFunctions" -> <|
    "Current" -> ...,
    "Top" -> ...
  |>,
  "Internal" -> <| ... |>
|>
```

其核心字段为：

- `"Type"`  
  当前目标所属类型：`"Top"`、`"TypeI"`、`"TypeII"`、`"TypeIII"`。
- `"GeneratingFunctions"["Current"]`  
  当前目标真正用于后续提取的生成函数。
- `"GeneratingFunctions"["Top"]`  
  顶拓扑生成函数。  
  只有 `TypeII` 需要它作为边界项，其余类型该字段可能只是缓存后的附带信息。
- `"Internal"["Kind"]`  
  目标模式判断结果，值为 `"Top"`、`"TypeI"` 或 `"SubTop"`。
- `"Internal"["DroppedIndex"]`  
  次大拓扑中被去掉的传播子位置。
- `"Internal"["FamilyData"]`  
  当前类型下用于生成函数构造和系数提取的内部数据。
- `"Internal"["ResidueData"]`  
  对应 dropped propagator 的留数数据，包括多项式中该变量的根和二次项系数。

### 4.3 `BaikovRawCoefficient` 对象

`ExtractBaikovCoefficient[gfObject, sourcePowers]` 返回：

```wl
<|
  "ObjectType" -> "BaikovRawCoefficient",
  "Family" -> ...,
  "Type" -> ...,
  "TargetPowers" -> ...,
  "SourcePowers" -> ...,
  "RawCoefficient" -> ...,
  "Internal" -> ...
|>
```

其中 `"RawCoefficient"` 是已经完成求导或系数提取，但尚未经过最终统一化简链处理的解析表达式。

### 4.4 `BaikovCoefficient` 对象

`SimplifyBaikovCoefficient[rawObject]` 返回：

```wl
<|
  "ObjectType" -> "BaikovCoefficient",
  "Family" -> ...,
  "Type" -> ...,
  "TargetPowers" -> ...,
  "SourcePowers" -> ...,
  "Coefficient" -> ...
|>
```

其中 `"Coefficient"` 就是程序包最终输出的约化系数。

## 5. 输入检查的职责

程序包的输入检查全部集中在 `BaikovGFCheck.wl` 中完成，主文件不重复实现另一套检查逻辑。

### 5.1 `CreateFeynmanIntegral` 阶段的检查

`validateCreateFeynmanIntegralInput` 主要检查：

- `LoopMomenta` 和 `ExternalMomenta` 必须是符号列表。
- 两组动量内部不能重复，且两组之间不能重叠。
- `Propagators` 和 `AuxiliaryPropagators` 必须是列表。
- `KinematicRules` 必须是规则列表。
- `DimensionSymbol` 必须是符号。
- 解析模式下不接受近似浮点数输入。
- 当前版本最多支持一个辅助传播子。
- 每个传播子必须是由已声明动量构成的标量积的线性组合。
- `KinematicRules` 必须覆盖所有外动量之间的标量积。
- 显式传播子数必须满足  
  `nExp == Nsp` 或 `nExp == Nsp - 1`。
- completed family 的传播子总数必须恰好等于 `Nsp`。
- 如果显式传播子已经是完整族，则不允许再给辅助传播子。
- 如果显式传播子少一个，则当前版本要求且只允许补一个辅助传播子。

也就是说，当前程序包只支持两种 completed family 输入形态：

1. 已经完整：显式传播子数等于 `Nsp`。
2. 差一个传播子：显式传播子数等于 `Nsp - 1`，并显式提供一个辅助传播子。

### 5.2 目标幂次检查

`validateTargetPowersForGF` 检查：

- `targetPowers` 必须是非负整数列表。
- 长度必须等于 completed family 的传播子总数。

之后按模式分类：

- `Top`  
  目标幂次全为 `1`。
- `TypeI`  
  显式传播子幂次全为 `1`，辅助传播子幂次为 `0`。
- `SubTop`  
  完整传播子族中恰有一个位置为 `0`，其余位置为 `1`。

超出上述三类的目标模式，当前版本直接返回不支持。

### 5.3 源幂次检查

`validateSourcePowersForExtraction` 检查：

- `sourcePowers` 必须是非负整数列表。
- 长度必须等于 completed family 的传播子总数。

额外条件按类型区分：

- `TypeI`  
  显式传播子幂次必须全部正，辅助传播子幂次必须是 `0`。
- `Top` / `TypeII` / `TypeIII`  
  所有源幂次都必须为正整数。

## 6. `CreateFeynmanIntegral` 的实现细节

`CreateFeynmanIntegral` 的实现可以分成六步。

### 6.1 规范化输入

先调用 `validateCreateFeynmanIntegralInput`，把传播子中的 `SP` 展开、把动力学规则左端规范化，并把输入压缩成标准形式。

### 6.2 构造 completed family

内部使用

```wl
allPropagators = Join[propagators, auxiliaryPropagators]
```

作为 completed family 的固定顺序。后续：

- Baikov 变量顺序
- `t` 变量顺序
- 目标幂次和源幂次位置

都以这条顺序为准。

### 6.3 反求独立标量积

程序先列出与圈动量相关的全部独立标量积，再把 `z_i == D_i` 写成方程组，求出每个独立标量积关于 Baikov 变量的表达式。  
如果 completed family 不能唯一确定这些标量积，程序立即返回失败对象 `NonInvertibleCompletedFamily`。

### 6.4 构造 Gram 行列式

程序对 `Join[loopMomenta, externalMomenta]` 构造 Gram 矩阵并取行列式，再将独立标量积用上一步的解替换，并施加 `KinematicRules`，得到 Baikov 多项式。

### 6.5 计算内部控制量

包括：

- completed family 大小
- 显式传播子与辅助传播子个数
- `Nsp`
- 顶扇区是否在 `z = 0` 处消失
- 指数参数 `R`

### 6.6 返回结构体对象

所有后续步骤都直接使用这一步产生的 `Association`，而不再重新分析传播子。

## 7. `BuildBaikovGeneratingFunction` 的实现细节

这是程序包中最关键的一步。它既做类型判断，也构造后续提取所需的所有内部数据。

### 7.1 当前支持的四种类型

#### `Top`

- completed family 完整；
- 目标幂次全为 `1`。

#### `TypeI`

- 显式传播子不完整，补一个辅助传播子后得到 completed family；
- 目标幂次在显式传播子位置全为 `1`；
- 辅助传播子幂次为 `0`。

#### `TypeII`

- completed family 完整；
- 目标为次大拓扑，即恰去掉一个传播子；
- 对应留数根在 `t = 0` 时两个都非零。

#### `TypeIII`

- completed family 完整；
- 目标为次大拓扑；
- 对应留数根在 `t = 0` 时有一个为零。

### 7.2 `FamilyData` 的作用

在确定类型后，程序先为当前类型构造一份内部工作数据 `FamilyData`。其核心内容包括：

- completed family 的 Baikov 变量顺序；
- 当前类型下真正参与展开的 `t` 变量；
- `z -> t` 的替换规则；
- 当前类型使用的多项式、动量列表、维数符号、指数参数 `R`。

其中：

- `Top`、`TypeII`、`TypeIII`  
  所有传播子都分配 `t` 变量。
- `TypeI`  
  只有显式传播子分配 `t` 变量，辅助传播子的 Baikov 变量保持不动。

### 7.3 `ResidueData` 的作用

对次大拓扑或 `TypeI`，程序还会构造 `ResidueData`。  
它做的事情是：

1. 选出当前 dropped propagator 对应的 Baikov 变量 `z_i`；
2. 把多项式写成关于 `z_i` 的二次式；
3. 提取二次项系数；
4. 求该二次式的两个根；
5. 同时记录带 `t` 和 `t = 0` 时的根。

这些数据随后决定：

- `TypeI` 的根差比；
- `TypeII` 的超几何参数和 prefactor；
- `TypeIII` 的零根判断及其生成函数形式。

### 7.4 四种生成函数的具体形式

#### `Top`

程序直接构造

```wl
((P(t)) / P(0))^R
```

其中 `P(t)` 是将 Baikov 多项式用 `t` 变量替换后的表达式。

#### `TypeI`

程序根据二次项系数比和两个根的差构造

```wl
(C(t)/C(0))^R * ((z_+(t)-z_-(t)) / (z_+(0)-z_-(0)))^(2R+1)
```

它本质上是对辅助传播子取留数后得到的纯初等函数生成函数。

#### `TypeII`

程序构造一个带有单一 `Hypergeometric2F1` 的表达式，并减去由 `Top` 生成函数给出的边界项。代码中将参数规范成固定形式，使得后续求导阶段只需要处理一种超几何函数。

#### `TypeIII`

程序构造另一种单一 `Hypergeometric2F1` 形式，但它对应的是零根情形。  
在进入实际提取前，程序还会调用 `normalizeRootsForTypeIII` 保证零根始终被放在统一的位置上。

## 8. `ExtractBaikovCoefficient` 的实现细节

虽然物理上有四种目标类型，但当前可发布版本中实际只有三条提取主线路。

### 8.1 `Top` 与 `TypeI`：顺序求导

两类共用 `sequentialDerivativeCoefficient`。

对源幂次 `a_i`，程序先把求导阶数写成：

```wl
orders = sourcePowers - 1
```

只对 `a_i - 1 > 0` 的变量真正求导；其余变量直接先置零。  
然后程序会对活动变量排序，优先处理：

- 求导阶数更高的变量；
- 把该变量置零后表达式更简单的变量。

最终执行的是重复的

```wl
D[expr, {t_i, a_i - 1}] / (a_i - 1)! /. t_i -> 0
```

这条路径是完全直接的偏导提取，没有级数中间层。

### 8.2 `TypeII`：超几何规范形上的闭式递推

`TypeII` 不直接对整个超几何表达式暴力求导，而是先把当前生成函数改写成规范状态：

```wl
A(t) + B(t) * 2F1(...)
```

随后进一步把超几何系数改写成

```wl
C(t) = C0(t) * P(t)
```

实际递推时只传播：

- 有理部分 `A`
- 多项式部分 `P`
- 超几何自变量 `z`

在一个变量块 `{t_i, n}` 上，程序并不重建完整超几何函数，而是用 `differentiateCanonicalTypeIIStateBlock` 更新：

- `RationalPart`
- `HyperCoefficient`
- `HyperArgument`

这样做的目的，是把“高阶求导中不断出现不同超几何函数”的问题压缩成“单一超几何类型 + 有理驱动项”的递推。

最后，程序只返回规范状态中的纯有理部分，并恢复 `R -> family["Internal"]["R"]`。

### 8.3 `TypeIII`：稀疏多元级数系数提取

`TypeIII` 走的是完全不同的一条路线：不再直接对整个表达式求导，而是把对象拆成稀疏多元级数。

具体做法是：

1. 选出活动变量和对应最高阶数；
2. 把 prefactor 展开成稀疏多元级数；
3. 把超几何自变量 `u = z_+(t) / z_-(t)` 也展开成稀疏多元级数；
4. 用显式公式 `typeIIIFormalHyperCoefficient[r, n]` 生成超几何级数的各阶系数；
5. 做稀疏卷积；
6. 直接读取目标多重指标的系数。

这条线路的关键点在于：程序只保留实际需要的幂次，不生成超出目标阶数的大型中间对象。

### 8.4 `BaikovRawCoefficient` 的输出

不论走哪条提取主线，输出统一打包成 `BaikovRawCoefficient` 对象。  
这一步结束时，提取逻辑就已经完成；后续只剩化简。

## 9. `SimplifyBaikovCoefficient` 的实现细节

最终化简并不是简单的一次 `Simplify`。当前程序包使用的是“类型预处理 + 公共化简主链”的方式。

### 9.1 类型预处理

在进入统一化简器前，不同类型先做不同预处理：

- `Top` / `TypeI`
  不做额外预处理。
- `TypeII`
  先执行 `preprocessTypeIIExpression`，核心是消去包含维数参数的互逆幂对，并把指数中的维数依赖规范化到更便于后续处理的形式。
- `TypeIII`
  先执行 `preprocessTypeIIIExpression`，当前实现主要是 `FunctionExpand`。

### 9.2 公共化简主链

所有类型最后都会进入 `simplifyElementaryCoefficient`。其顺序是：

1. `elementaryNormalize`  
   规范嵌套根式、执行 `FunctionExpand`、整理半整数幂，并合并根号结构。
2. `normalizeHalfIntegerTerms`  
   把半整数幂统一到内部标准形式。
3. `cheapRationalEarlyReturn`  
   如果已经显然是纯有理式，则直接返回，不再进入后续重化简。
4. `Cancel[Together[...]]`
5. `postSimplifySqrtTail`  
   先尝试把尾部残留的根式结构消掉。如果此时已经是纯有理式，则在进入外部后端前提前返回。
6. `prepareRationalForExternalSimplifier`  
   将表达式整理成可编码给外部后端的有理式结构。
7. `externalRationalSimplify`  
   调用 Python/FLINT。
8. 外部返回后再做一次 `Cancel[Together[...]]` 与内部规范化。
9. 最后再执行一次 `postSimplifySqrtTail`，得到程序包最终输出。

### 9.3 外部后端在程序包中的位置

外部后端不是贯穿所有步骤使用，而只在最终有理式化简阶段被调用。  
也就是说：

- 输入检查不依赖外部后端；
- 生成函数构造不依赖外部后端；
- 系数提取不依赖外部后端；
- 只有最终的有理式化简依赖外部后端。

因此，`CheckBaikovExternalBackend[]` 的职责也很明确：  
它不是检查整个程序包能否加载，而是检查最终化简阶段所需的 Python/FLINT 路径、脚本和最小往返测试是否可用。

## 10. 程序包当前支持范围

当前版本只支持以下目标：

- 完整传播子族的顶拓扑目标；
- 完整传播子族的次大拓扑目标，即只去掉一个传播子的目标；
- 显式传播子差一个、补一个辅助传播子后的 `TypeI` 顶目标。

当前版本不支持：

- 任意更深层子拓扑的统一自动生成函数；
- 多于一个辅助传播子的 completed family；
- 不满足 completed family 唯一反求独立标量积条件的输入；
- 不属于上述三种目标模式的目标幂次。

## 11. 最小使用流程

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

如果只想检查外部后端是否就绪，可在加载程序包后运行：

```wl
CheckBaikovExternalBackend[]
```
