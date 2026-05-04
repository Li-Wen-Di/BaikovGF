# BaikovGF Package Guide

## 1. Package Files

The `BaikovGF/` directory currently contains two program files:

- `BaikovGF.wl`
  The main package file. It exports the scalar-product notation, the four-step main workflow API, the batch wrappers, and the external-backend self-check entry point.
- `BaikovGFCheck.wl`
  The input-validation file. It is not meant to be loaded directly by users. It is loaded internally by `BaikovGF.wl` and is responsible only for input validation and target-pattern classification.

In normal use, only the main package file needs to be loaded:

```wl
projectRoot = "/path/to/this/repository";
Get[FileNameJoin[{projectRoot, "BaikovGF", "BaikovGF.wl"}]];
```

Once `BaikovGF.wl` is loaded, `BaikovGFCheck.wl` is brought into the private context automatically and does not need a separate `Get`.

## 2. Public API

The package currently exports the following symbols.

### 2.1 Basic notation

- `SP[p, q]`
  Scalar-product notation used by the package. All momentum dot products in propagators and kinematic rules should be written as `SP[*, *]`.

### 2.2 Main workflow API

- `CreateFeynmanIntegral[...]`
  Builds a Feynman-integral object.
- `BuildBaikovGeneratingFunction[family, targetPowers]`
  Classifies the target master-integral powers and builds the corresponding generating-function object.
- `ExtractBaikovCoefficient[gfObject, sourcePowers]`
  Extracts the reduction coefficient before the final global simplification stage.
- `SimplifyBaikovCoefficient[rawObject]`
  Applies type-specific preprocessing, radical cleanup, and final rational simplification, and returns the analytic result.

### 2.3 Batch API

- `ExtractBaikovCoefficientBatch[gfObject, sourcePowersList]`
  Calls `ExtractBaikovCoefficient` on a list of source-power vectors.
- `SimplifyBaikovCoefficientBatch[rawObjectList]`
  Calls `SimplifyBaikovCoefficient` on a list of raw-coefficient objects.

### 2.4 External-backend check

- `CheckBaikovExternalBackend[]`
  Checks whether the package can call the external Python/FLINT rational-simplification backend.

## 3. Overall Workflow of the Package

The public workflow of the package is fixed to four steps:

1. `CreateFeynmanIntegral`  
   Accepts user input for loop momenta, external momenta, propagators, auxiliary propagators, kinematic replacement rules, and the dimension symbol, and builds a `FeynmanIntegral` object.
2. `BuildBaikovGeneratingFunction`  
   Inspects the target-power pattern, determines whether the target belongs to `Top`, `TypeI`, `TypeII`, or `TypeIII`, and builds the corresponding generating function.
3. `ExtractBaikovCoefficient`  
   Differentiates the generating function or performs series-coefficient extraction according to the source powers, producing an analytic expression that has not yet gone through the final simplification pipeline.
4. `SimplifyBaikovCoefficient`  
   Sends the extracted expression through the type-specific preprocessing and the common simplification pipeline, and returns the final reduction coefficient.

The package does not pass raw expressions directly from one stage to the next. Instead, each stage returns a structured `Association`. This has two purposes:

- to preserve enough intermediate information for later stages without recomputation;
- to separate input data, derived data, cache keys, and classification results cleanly.

## 4. Object Structure

### 4.1 `FeynmanIntegral` object

`CreateFeynmanIntegral[...]` returns:

```wl
<|
  "ObjectType" -> "FeynmanIntegral",
  "Input" -> <| ... |>,
  "Derived" -> <| ... |>,
  "Internal" -> <| ... |>
|>
```

The main fields are the following.

#### `Input`

This section stores the user input, after normalization where appropriate:

- `"LoopMomenta"`
- `"ExternalMomenta"`
- `"Propagators"`
- `"AuxiliaryPropagators"`
- `"KinematicRules"`
- `"DimensionSymbol"`

Before entering the object, propagators and auxiliary propagators are expanded and normalized in the package’s `SP` algebra.

#### `Derived`

This section stores analytic derived quantities used directly in later stages:

- `"PropagatorToBaikovRules"`  
  Rules mapping each propagator in the completed family to its Baikov variable.
- `"ScalarProductToBaikovRules"`  
  Rules obtained by solving all independent loop-momentum-related scalar products in terms of Baikov variables from the completed family.
- `"BaikovPolynomial"`  
  The Baikov polynomial obtained from the Gram determinant after applying `ScalarProductToBaikovRules` and `KinematicRules`.

#### `Internal`

This section stores control information and cache-dependent data:

- `"AllPropagators"`  
  The ordered propagator list of the completed family, always
  `Join[Propagators, AuxiliaryPropagators]`.
- `"BaikovVariables"`  
  Internal Baikov variables in one-to-one correspondence with `"AllPropagators"`.
- `"ExplicitPropagatorCount"`
- `"AuxiliaryPropagatorCount"`
- `"TotalPropagatorCount"`
- `"ScalarProductCount"`  
  The number of independent scalar products involving loop momenta, denoted `Nsp`.
- `"LoopCount"`
- `"ExternalCount"`
- `"TopSectorVanishingQ"`  
  Indicates whether the top sector vanishes at `z = 0`; this affects the root-solving strategy.
- `"R"`  
  The exponent parameter used internally by the package,
  `R = (d - L - E - 1)/2`, where `L` is the loop count and `E` is the number of external momenta.

### 4.2 `BaikovGeneratingFunction` object

`BuildBaikovGeneratingFunction[family, targetPowers]` returns:

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

Its core fields are:

- `"Type"`  
  The target type: `"Top"`, `"TypeI"`, `"TypeII"`, or `"TypeIII"`.
- `"GeneratingFunctions"["Current"]`  
  The generating function actually used in coefficient extraction for the current target.
- `"GeneratingFunctions"["Top"]`  
  The top-topology generating function. Only `TypeII` needs it as a boundary term; for other types it may simply be retained as cached auxiliary data.
- `"Internal"["Kind"]`  
  The target-pattern classification result, with value `"Top"`, `"TypeI"`, or `"SubTop"`.
- `"Internal"["DroppedIndex"]`  
  The position of the dropped propagator for a sub-topology target.
- `"Internal"["FamilyData"]`  
  Internal data used for generating-function construction and coefficient extraction in the current type.
- `"Internal"["ResidueData"]`  
  Residue data for the dropped propagator, including the relevant roots and quadratic coefficient.

### 4.3 `BaikovRawCoefficient` object

`ExtractBaikovCoefficient[gfObject, sourcePowers]` returns:

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

The field `"RawCoefficient"` is the analytic expression after differentiation or coefficient extraction, but before the final global simplification pipeline.

### 4.4 `BaikovCoefficient` object

`SimplifyBaikovCoefficient[rawObject]` returns:

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

The field `"Coefficient"` is the final reduction coefficient produced by the package.

## 5. Responsibility of Input Validation

All input validation is centralized in `BaikovGFCheck.wl`. The main package file does not maintain a second parallel validation layer.

### 5.1 Validation in `CreateFeynmanIntegral`

`validateCreateFeynmanIntegralInput` checks:

- `LoopMomenta` and `ExternalMomenta` must be lists of symbols.
- The two momentum lists must have no duplicates internally and no overlap with each other.
- `Propagators` and `AuxiliaryPropagators` must both be lists.
- `KinematicRules` must be a list of rules.
- `DimensionSymbol` must be a symbol.
- Approximate machine numbers are not accepted in analytic mode.
- The current version supports at most one auxiliary propagator.
- Every propagator must be a linear combination of scalar products built from declared momenta.
- `KinematicRules` must cover all scalar products among the declared external momenta.
- The number of explicit propagators must satisfy  
  `nExp == Nsp` or `nExp == Nsp - 1`.
- The total size of the completed family must be exactly `Nsp`.
- If the explicit family is already complete, auxiliary propagators are not allowed.
- If the explicit family is short by one propagator, the current version requires exactly one auxiliary propagator.

So the current package supports only two completed-family input patterns:

1. already complete: the number of explicit propagators equals `Nsp`;
2. short by one propagator: the number of explicit propagators equals `Nsp - 1`, and exactly one auxiliary propagator is provided.

### 5.2 Validation of target powers

`validateTargetPowersForGF` checks:

- `targetPowers` must be a list of non-negative integers;
- its length must equal the total number of propagators in the completed family.

Then it classifies the pattern as:

- `Top`  
  all target powers are `1`;
- `TypeI`  
  all explicit propagator powers are `1` and the auxiliary propagator power is `0`;
- `SubTop`  
  for a complete family, exactly one entry is `0` and all others are `1`.

Any target pattern outside these cases is currently unsupported.

### 5.3 Validation of source powers

`validateSourcePowersForExtraction` checks:

- `sourcePowers` must be a list of non-negative integers;
- its length must equal the total number of propagators in the completed family.

Additional conditions depend on the type:

- `TypeI`  
  all explicit propagator powers must be positive, and the auxiliary propagator power must be `0`;
- `Top` / `TypeII` / `TypeIII`  
  all source powers must be positive integers.

## 6. Implementation of `CreateFeynmanIntegral`

The implementation of `CreateFeynmanIntegral` can be divided into six steps.

### 6.1 Input normalization

The function first calls `validateCreateFeynmanIntegralInput`, expands propagators in the `SP` algebra, normalizes the left-hand sides of the kinematic rules, and compresses everything into a standard form.

### 6.2 Construction of the completed family

Internally the package uses

```wl
allPropagators = Join[propagators, auxiliaryPropagators]
```

as the fixed order of the completed family. The following all depend on this order:

- the order of Baikov variables;
- the order of `t` variables;
- the positions in target-power and source-power vectors.

### 6.3 Solving for independent scalar products

The package lists all independent scalar products involving loop momenta, writes `z_i == D_i` as a system of equations, and solves for each independent scalar product in terms of the Baikov variables.  
If the completed family does not uniquely determine these scalar products, the package immediately returns the failure object `NonInvertibleCompletedFamily`.

### 6.4 Construction of the Gram determinant

The package builds the Gram matrix of `Join[loopMomenta, externalMomenta]`, takes its determinant, replaces independent scalar products using the solution found in the previous step, and then applies `KinematicRules` to obtain the Baikov polynomial.

### 6.5 Construction of internal control data

This includes:

- the size of the completed family;
- the numbers of explicit and auxiliary propagators;
- `Nsp`;
- whether the top sector vanishes at `z = 0`;
- the exponent parameter `R`.

### 6.6 Returning the structured object

All later stages operate directly on this `Association`. The package does not re-analyze propagators from scratch in later steps.

## 7. Implementation of `BuildBaikovGeneratingFunction`

This is the key step of the package. It both classifies the target and builds all internal data required for later coefficient extraction.

### 7.1 The four target types currently supported

#### `Top`

- the completed family is complete;
- all target powers are `1`.

#### `TypeI`

- the explicit family is incomplete and becomes complete after adding one auxiliary propagator;
- all target powers on explicit propagators are `1`;
- the auxiliary propagator power is `0`.

#### `TypeII`

- the completed family is complete;
- the target is a sub-topology with exactly one dropped propagator;
- both relevant residue roots are nonzero at `t = 0`.

#### `TypeIII`

- the completed family is complete;
- the target is a sub-topology;
- one of the relevant residue roots is zero at `t = 0`.

### 7.2 The role of `FamilyData`

After the type is determined, the package first constructs an internal working dataset called `FamilyData`. Its core content includes:

- the order of Baikov variables of the completed family;
- the `t` variables that are active in the current type;
- the replacement rules `z -> t`;
- the polynomial, momentum lists, dimension symbol, and exponent parameter `R` used by the current type.

Specifically:

- `Top`, `TypeII`, and `TypeIII`  
  assign a `t` variable to every propagator;
- `TypeI`  
  assigns `t` variables only to explicit propagators, while the Baikov variable of the auxiliary propagator remains unchanged.

### 7.3 The role of `ResidueData`

For sub-topologies and for `TypeI`, the package also builds `ResidueData`.  
This performs the following steps:

1. select the Baikov variable `z_i` corresponding to the dropped propagator;
2. rewrite the polynomial as a quadratic in `z_i`;
3. extract the quadratic coefficient;
4. solve for the two roots;
5. store the roots both with active `t` variables and at `t = 0`.

These data then determine:

- the root-difference ratio in `TypeI`;
- the hypergeometric argument and prefactor in `TypeII`;
- the zero-root classification and generating-function form in `TypeIII`.

### 7.4 Explicit form of the four generating functions

#### `Top`

The package directly constructs

```wl
((P(t)) / P(0))^R
```

where `P(t)` is the Baikov polynomial after replacing variables by the current `t` variables.

#### `TypeI`

The package constructs

```wl
(C(t)/C(0))^R * ((z_+(t)-z_-(t)) / (z_+(0)-z_-(0)))^(2R+1)
```

from the ratio of quadratic coefficients and the difference of the two roots. This is the pure elementary generating function obtained after taking the residue in the auxiliary propagator.

#### `TypeII`

The package constructs an expression involving a single `Hypergeometric2F1`, and subtracts a boundary term determined by the `Top` generating function. In the code, the parameters are normalized into a fixed form so that the later differentiation stage has to handle only one hypergeometric type.

#### `TypeIII`

The package constructs another single-`Hypergeometric2F1` form corresponding to the zero-root case.  
Before extraction begins, `normalizeRootsForTypeIII` is applied to ensure that the zero root is always placed in a consistent position.

## 8. Implementation of `ExtractBaikovCoefficient`

Although there are four physical target types, the current publishable version contains only three actual extraction pipelines.

### 8.1 `Top` and `TypeI`: sequential differentiation

These two types share `sequentialDerivativeCoefficient`.

For source powers `a_i`, the package first writes the differentiation orders as

```wl
orders = sourcePowers - 1
```

Only variables with `a_i - 1 > 0` are actually differentiated; all other variables are first set to zero.  
The active variables are then ordered so that the package prefers:

- variables with larger differentiation order;
- variables that make the expression simpler when set to zero.

The repeated operation is

```wl
D[expr, {t_i, a_i - 1}] / (a_i - 1)! /. t_i -> 0
```

This route is a direct mixed-partial-derivative extraction without an intermediate series layer.

### 8.2 `TypeII`: closed-form recursion on a canonical hypergeometric state

`TypeII` does not differentiate the entire hypergeometric expression naively. Instead, it first rewrites the current generating function into a canonical state:

```wl
A(t) + B(t) * 2F1(...)
```

Then the hypergeometric coefficient is rewritten further as

```wl
C(t) = C0(t) * P(t)
```

The actual recursion propagates only:

- the rational part `A`;
- the polynomial part `P`;
- the hypergeometric argument `z`.

On a variable block `{t_i, n}`, the package does not rebuild the full hypergeometric function. Instead, `differentiateCanonicalTypeIIStateBlock` updates:

- `RationalPart`;
- `HyperCoefficient`;
- `HyperArgument`.

The purpose is to compress the problem of repeatedly generating different hypergeometric functions under high-order differentiation into a recursion involving a single hypergeometric type and a rational driving term.

At the end, the package returns only the pure rational part of the canonical state and restores `R -> family["Internal"]["R"]`.

### 8.3 `TypeIII`: sparse multivariate series coefficient extraction

`TypeIII` follows a completely different route: instead of differentiating the whole expression, it decomposes the object into sparse multivariate series.

The steps are:

1. select the active variables and their maximal orders;
2. expand the prefactor into a sparse multivariate series;
3. expand the hypergeometric variable `u = z_+(t) / z_-(t)` into a sparse multivariate series as well;
4. generate hypergeometric-series coefficients using the explicit formula `typeIIIFormalHyperCoefficient[r, n]`;
5. perform sparse convolution;
6. read off the coefficient of the target multi-index directly.

The key point of this route is that the package keeps only the powers that are actually needed and does not construct large intermediate objects beyond the target orders.

### 8.4 Output of `BaikovRawCoefficient`

Regardless of which extraction route is used, the output is always wrapped as a `BaikovRawCoefficient` object.  
At this point the extraction logic is complete; only simplification remains.

## 9. Implementation of `SimplifyBaikovCoefficient`

The final simplification is not a single `Simplify` call. The current package uses a combination of type-specific preprocessing and a common simplification pipeline.

### 9.1 Type-specific preprocessing

Before entering the common simplifier, different target types undergo different preprocessing:

- `Top` / `TypeI`
  no extra preprocessing;
- `TypeII`
  `preprocessTypeIIExpression` is applied first; its main role is to remove reciprocal power pairs involving the dimension parameter and to normalize dimension-dependent exponents into a form better suited for later processing;
- `TypeIII`
  `preprocessTypeIIIExpression` is applied first; in the current implementation this is mainly `FunctionExpand`.

### 9.2 Common simplification pipeline

All types eventually pass through `simplifyElementaryCoefficient`. The order is:

1. `elementaryNormalize`  
   normalize nested radicals, apply `FunctionExpand`, rewrite half-integer powers, and merge square-root structure;
2. `normalizeHalfIntegerTerms`  
   rewrite half-integer powers into the internal standard form;
3. `cheapRationalEarlyReturn`  
   if the expression is already clearly rational, return immediately without entering the heavier stages;
4. `Cancel[Together[...]]`;
5. `postSimplifySqrtTail`  
   try to eliminate residual square-root structure at the tail; if the result is already rational at this point, return before calling the external backend;
6. `prepareRationalForExternalSimplifier`  
   convert the expression into a rational form that can be encoded for the external backend;
7. `externalRationalSimplify`  
   call Python/FLINT;
8. after the external result returns, apply `Cancel[Together[...]]` and internal normalization again;
9. finally apply `postSimplifySqrtTail` once more to obtain the package’s final output.

### 9.3 The role of the external backend in the package

The external backend is not used throughout the whole workflow. It is called only in the final rational-simplification stage. In other words:

- input validation does not depend on the external backend;
- generating-function construction does not depend on it;
- coefficient extraction does not depend on it;
- only the final rational simplification depends on it.

Accordingly, the role of `CheckBaikovExternalBackend[]` is precise:  
it does not check whether the package can be loaded, but whether the Python/FLINT path, backend script, and minimal round-trip test required by the final simplification stage are all available.

## 10. Current Supported Scope

The current version supports only the following targets:

- top-topology targets of complete propagator families;
- sub-topology targets of complete propagator families with exactly one dropped propagator;
- `TypeI` top targets formed by an explicit family short by one propagator and completed by exactly one auxiliary propagator.

The current version does not support:

- a unified automatic generating-function construction for arbitrarily deeper sub-topologies;
- completed families with more than one auxiliary propagator;
- input for which the completed family does not uniquely determine all independent scalar products;
- target-power patterns outside the three supported classes listed above.

## 11. Minimal Usage Workflow

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

If only the external backend readiness needs to be checked, run after loading the package:

```wl
CheckBaikovExternalBackend[]
```
