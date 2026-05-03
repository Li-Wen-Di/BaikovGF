BeginPackage["BaikovGF`"];

(*

SP::usage = "SP[p, q] 表示标量积。";
CreateFeynmanIntegral::usage =
  "CreateFeynmanIntegral[\"LoopMomenta\" -> {...}, \"ExternalMomenta\" -> {...}, \"Propagators\" -> {...}, \"AuxiliaryPropagators\" -> {...}, \"KinematicRules\" -> {...}, \"DimensionSymbol\" -> d] 构造费曼积分结构体。";
BuildBaikovGeneratingFunction::usage =
  "BuildBaikovGeneratingFunction[feynmanIntegral, targetPowers] 判断类型并构造生成函数对象。";
ExtractBaikovCoefficient::usage =
  "ExtractBaikovCoefficient[gfObject, sourcePowers] 从生成函数对象提取未最终化简的约化系数。";
SimplifyBaikovCoefficient::usage =
  "SimplifyBaikovCoefficient[rawObject] 对未化简系数做类型化简与外部有理式化简。";

*)

SP::usage = "SP[p, q] represents a scalar product.";
CreateFeynmanIntegral::usage =
  "CreateFeynmanIntegral[...] builds a Feynman-integral association.";
BuildBaikovGeneratingFunction::usage =
  "BuildBaikovGeneratingFunction[feynmanIntegral, targetPowers] builds a generating-function object.";
ExtractBaikovCoefficient::usage =
  "ExtractBaikovCoefficient[gfObject, sourcePowers] extracts the unsimplified reduction coefficient.";
ExtractBaikovCoefficientBatch::usage =
  "ExtractBaikovCoefficientBatch[gfObject, sourcePowersList] extracts a list of unsimplified reduction coefficients.";
SimplifyBaikovCoefficient::usage =
  "SimplifyBaikovCoefficient[rawObject] simplifies the extracted coefficient.";
SimplifyBaikovCoefficientBatch::usage =
  "SimplifyBaikovCoefficientBatch[rawObjectList] simplifies a list of extracted coefficients.";
BaikovGF`CheckBaikovExternalBackend::usage =
  "CheckBaikovExternalBackend[] checks whether the external Python/FLINT backend is available to the package.";

Begin["`Private`"];

$baikovPackageFile = $InputFileName;

SetAttributes[BaikovGF`SP, Orderless];

ClearAll[
  baikovFailure,
  containsApproximateNumberQ,
  listDuplicates,
  scalarFreeQ,
  expandSP,
  normalizeKinematicRuleLHS,
  simplifyWithLevel,
  independentScalarProducts,
  solveISPs,
  buildGramMatrix,
  zeroExprQ,
  rootDifferenceSquared,
  quadraticRootsOrdered,
  buildInternalFamilyData,
  residueData,
  buildTopGF,
  buildTypeIGF,
  buildTypeIIGF,
  buildTypeIIIGF,
  normalizeRootsForTypeIII,
  validResidueDataQ,
  orderActiveSpecsForExtraction,
  sequentialDerivativeCoefficient,
  buildCanonicalTypeIIExtractionState,
  simplifyCanonicalTypeIIState,
  canonicalTypeIIStateApplyRules,
  differentiateCanonicalTypeIIStateBlock,
  extractTypeIICoefficientClosedForm,
  typeIIIFormalHyperCoefficient,
  monomialFromExponents,
  truncatePolynomialByOrders,
  multivariateSeriesPolynomial,
  exactHalfIntegerQ,
  splitIntegerHalfPart,
  splitEvenSquarePart,
  splitPositiveRationalSquarePart,
  extractPerfectSquareFactor,
  radicalAtomicSymbols,
  squareChartPolynomialToSquares,
  squareChartEvenProjectionRationalize,
  squareChartRadicalSimplify,
  mergeAllSquareRoots,
  simplifySingleSquareRoot,
  simplifySquareRootArguments,
  normalizeHalfIntegerTerm,
  normalizeHalfIntegerTerms,
  normalizeNestedSquareRootsInArgument,
  postSimplifySqrtTail,
  normalizeSqrtPowersForFLINT,
  replaceDimensionInExponentsWithTwo,
  hiddenHalfPowerQ,
  heldKey,
  addExponentCount,
  mergeExponentCounts,
  emptyPowerSplit,
  mergePowerSplits,
  collectPowerSplit,
  countsToProduct,
  cancelSharedCounts,
  rebuildPreparedTerm,
  prepareTermsForFLINTAttempt,
  prepareWithPowerExpandFallback,
  prepareRationalForExternalSimplifier,
  defaultFLINTPythonExecutable,
  defaultFLINTBackendScript,
  checkBackendResultAssociationQ,
  collectFLINTVariables,
  encodeFLINTAST,
  decodeFLINTAST,
  runFLINTBackend,
  externalRationalSimplify,
  preprocessTypeIIExpression,
  preprocessTypeIIIExpression,
  elementaryNormalize,
  simplifyElementaryCoefficient,
  simplifyByType,
  packageRootDirectory,
  packageVersionToken,
  persistentCacheDirectory,
  persistentCacheFile,
  loadPersistentCacheEntry,
  savePersistentCacheEntry,
  familyObjectCacheKey,
  gfObjectCacheKey,
  cacheLookupOrCompute,
  pureRationalNoHalfQ,
  cheapRationalEarlyReturn,
  sparseSeriesKey,
  sparseSeriesLookup,
  sparseSeriesNormalize,
  sparseSeriesFromExpr,
  sparseSeriesAdd,
  sparseSeriesScale,
  sparseSeriesConvolve,
  sparseSeriesDerivative,
  zeroMultiIndex,
  extractTypeIIICoefficientSparse
];

(* 缓存重复使用的中间对象，避免同一积分族/目标反复构造。 *)
$internalFamilyDataCache = <||>;
$residueDataCache = <||>;
$topGFCache = <||>;
$gfObjectCache = <||>;
$typeIIStateCache = <||>;
$rawCoefficientCache = <||>;
$simplifiedCoefficientCache = <||>;
$enablePersistentBaikovCache = True;
$packageVersionToken = None;

SetAttributes[cacheLookupOrCompute, HoldAll];

cacheLookupOrCompute[cache_Symbol, key_, expr_] := Module[{cacheKey, cacheKind, cached, persisted, value},
  cacheKey = HoldComplete[key];
  cacheKind = SymbolName[Unevaluated[cache]];
  cached = Lookup[cache, cacheKey, Missing["NotCached"]];
  If[cached =!= Missing["NotCached"], Return[cached]];
  persisted = loadPersistentCacheEntry[cacheKind, key];
  If[Head[persisted] =!= Missing,
    AssociateTo[cache, cacheKey -> persisted];
    Return[persisted]
  ];
  value = expr;
  If[!FailureQ[value],
    AssociateTo[cache, cacheKey -> value];
    savePersistentCacheEntry[cacheKind, key, value];
  ];
  value
];

baikovFailure[tag_String, template_String, details_: <||>] :=
  Failure[tag, Join[<|"MessageTemplate" -> template|>, details]];

containsApproximateNumberQ[expr_] := !FreeQ[Unevaluated[expr], _Real];

listDuplicates[list_List] := Keys @ Select[Counts[list], # > 1 &];

scalarFreeQ[expr_, momenta_List] := FreeQ[expr, Alternatives @@ momenta];

expandSP[expr_, momenta_List] := FixedPoint[
  Expand[
    # /. {
      BaikovGF`SP[a_ + b_, c_] :> BaikovGF`SP[a, c] + BaikovGF`SP[b, c],
      BaikovGF`SP[a_, b_ + c_] :> BaikovGF`SP[a, b] + BaikovGF`SP[a, c],
      BaikovGF`SP[-a_, b_] :> -BaikovGF`SP[a, b],
      BaikovGF`SP[a_, -b_] :> -BaikovGF`SP[a, b],
      BaikovGF`SP[c_.*a_, b_] /; scalarFreeQ[c, momenta] :> c*BaikovGF`SP[a, b],
      BaikovGF`SP[a_, c_.*b_] /; scalarFreeQ[c, momenta] :> c*BaikovGF`SP[a, b]
    }
  ] &,
  expr
];

undeclaredMomentumCandidates[expr_, allowedMomenta_List] := Module[{vectorArgs},
  vectorArgs = Cases[HoldComplete[expr], BaikovGF`SP[a_, b_] :> HoldComplete[a, b], Infinity];
  DeleteDuplicates @ Cases[
    vectorArgs,
    s_Symbol /; Context[s] =!= "System`" && !MemberQ[allowedMomenta, s],
    Infinity
  ]
];

propagatorLinearInSPQ[expr_, allowedMomenta_List] := Module[
  {expanded, spTerms, tempVars, tempExpr, exponents},
  expanded = expandSP[expr, allowedMomenta];
  spTerms = DeleteDuplicates @ Cases[expanded, _SP, Infinity];
  tempVars = Array[Unique["u$"] &, Length[spTerms]];
  tempExpr = expanded /. Thread[spTerms -> tempVars];
  If[!PolynomialQ[tempExpr, tempVars], Return[False]];
  exponents = Exponent[tempExpr, tempVars, List];
  If[exponents === {}, True, Max[Total /@ exponents] <= 1]
];

normalizeKinematicRuleLHS[rule_] := rule /. {
  HoldPattern[(lhs_ -> rhs_)] :> (expandSP[lhs, {}] -> rhs),
  HoldPattern[(lhs_ :> rhs_)] :> (expandSP[lhs, {}] :> rhs)
};

simplifyWithLevel[expr_, assumptions_: True, level_: "Simplify"] := Switch[level,
  "None", expr,
  "FullSimplify", FullSimplify[expr, assumptions],
  _, Simplify[expr, assumptions]
];

independentScalarProducts[loopMomenta_List, externalMomenta_List] := Join[
  Flatten @ Table[
    BaikovGF`SP[loopMomenta[[i]], loopMomenta[[j]]],
    {i, Length[loopMomenta]},
    {j, i, Length[loopMomenta]}
  ],
  Flatten @ Table[
    BaikovGF`SP[loopMomenta[[i]], externalMomenta[[j]]],
    {i, Length[loopMomenta]},
    {j, Length[externalMomenta]}
  ]
];

solveISPs[equations_List, isps_List] := Module[{solution},
  solution = Quiet @ Solve[equations, isps];
  If[solution === {} || !ListQ[solution], $Failed, First[solution]]
];

buildGramMatrix[loopMomenta_List, externalMomenta_List] := Module[{all},
  all = Join[loopMomenta, externalMomenta];
  Table[BaikovGF`SP[all[[i]], all[[j]]], {i, Length[all]}, {j, Length[all]}]
];

zeroExprQ[expr_, assumptions_: True] := TrueQ[Simplify[expr == 0, assumptions]];

rootDifferenceSquared[zPlus_, zMinus_, assumptions_: True] :=
  simplifyWithLevel[(zPlus - zMinus)^2, assumptions, "Simplify"];

packageRootDirectory[] := ParentDirectory[DirectoryName[$baikovPackageFile]];

packageVersionToken[] := Module[{token},
  If[StringQ[$packageVersionToken], Return[$packageVersionToken]];
  token = Quiet @ Check[FileHash[$baikovPackageFile, "SHA256"], $Failed];
  If[token === $Failed,
    token = IntegerString[Hash[{FileDate[$baikovPackageFile], FileByteCount[$baikovPackageFile]}], 36],
    token = ToString[token, InputForm]
  ];
  $packageVersionToken = token;
  token
];

persistentCacheDirectory[] := Module[{dir},
  dir = FileNameJoin[{packageRootDirectory[], ".cache", packageVersionToken[]}];
  If[!DirectoryQ[dir], Quiet @ CreateDirectory[dir, CreateIntermediateDirectories -> True]];
  dir
];

persistentCacheFile[kind_String, key_] := FileNameJoin[{
  persistentCacheDirectory[],
  kind <> "-" <> IntegerString[Hash[HoldComplete[kind, key]], 36] <> ".wl"
}];

loadPersistentCacheEntry[kind_String, key_] := Module[{file, value},
  If[!TrueQ[$enablePersistentBaikovCache], Return[Missing["PersistentCacheDisabled"]]];
  file = persistentCacheFile[kind, key];
  If[!FileExistsQ[file], Return[Missing["PersistentCacheMiss"]]];
  value = Quiet @ Check[Get[file], $Failed];
  If[value === $Failed, Missing["PersistentCacheUnreadable"], value]
];

savePersistentCacheEntry[kind_String, key_, value_] := Module[{file},
  If[!TrueQ[$enablePersistentBaikovCache], Return[value]];
  file = persistentCacheFile[kind, key];
  Quiet @ Check[Put[value, file], Null];
  value
];

familyObjectCacheKey[family_Association] := Module[
  {internal, input, loopMomenta, externalMomenta, propagators, auxiliaryPropagators, kinematicRules, dimensionSymbol},
  internal = Lookup[family, "Internal", <||>];
  If[AssociationQ[internal] && KeyExistsQ[internal, "CacheKey"],
    Return[internal["CacheKey"]]
  ];
  input = Lookup[family, "Input", Missing["MissingInput"]];
  If[!AssociationQ[input], Return[Hash @ HoldComplete[family]]];
  loopMomenta = Lookup[input, "LoopMomenta", Missing["LoopMomenta"]];
  externalMomenta = Lookup[input, "ExternalMomenta", Missing["ExternalMomenta"]];
  propagators = Lookup[input, "Propagators", Missing["Propagators"]];
  auxiliaryPropagators = Lookup[input, "AuxiliaryPropagators", Missing["AuxiliaryPropagators"]];
  kinematicRules = Lookup[input, "KinematicRules", Missing["KinematicRules"]];
  dimensionSymbol = Lookup[input, "DimensionSymbol", Missing["DimensionSymbol"]];
  Hash @ Apply[
    HoldComplete,
    {
      loopMomenta,
      externalMomenta,
      propagators,
      auxiliaryPropagators,
      kinematicRules,
      dimensionSymbol
    }
  ]
];

gfObjectCacheKey[gfObject_Association] := Lookup[
  gfObject["Internal"],
  "CacheKey",
  {familyObjectCacheKey[gfObject["Family"]], gfObject["TargetPowers"]}
];

Get[FileNameJoin[{DirectoryName[$InputFileName], "BaikovGFCheck.wl"}]];

BaikovGF`CreateFeynmanIntegral[rawRules___Rule] := Module[
  {
    input = Association[{rawRules}],
    validated,
    allPropagators,
    loopMomenta,
    externalMomenta,
    kinematicRules,
    dimensionSymbol,
    zVars,
    equations,
    isps,
    solution,
    gram,
    polynomial,
    internal,
    familyCacheKey
  },
  validated = validateCreateFeynmanIntegralInput[input];
  If[FailureQ[validated], Return[validated]];

  loopMomenta = validated["LoopMomenta"];
  externalMomenta = validated["ExternalMomenta"];
  kinematicRules = validated["KinematicRules"];
  dimensionSymbol = validated["DimensionSymbol"];
  allPropagators = Join[validated["Propagators"], validated["AuxiliaryPropagators"]];

  zVars = Array[Unique["z$"] &, Length[allPropagators]];
  equations = Thread[zVars == allPropagators];
  isps = independentScalarProducts[loopMomenta, externalMomenta];
  solution = solveISPs[equations, isps];
  If[solution === $Failed,
    Return @ baikovFailure[
      "NonInvertibleCompletedFamily",
      "The completed family does not uniquely determine all scalar products involving loop momenta.",
      <||>
    ]
  ];

  gram = buildGramMatrix[loopMomenta, externalMomenta];
  polynomial = simplifyWithLevel[Det[gram] /. solution /. kinematicRules, True, "Simplify"];
  familyCacheKey = Hash @ Apply[
    HoldComplete,
    {
      loopMomenta,
      externalMomenta,
      validated["Propagators"],
      validated["AuxiliaryPropagators"],
      kinematicRules,
      dimensionSymbol
    }
  ];

  internal = <|
    "CacheKey" -> familyCacheKey,
    "AllPropagators" -> allPropagators,
    "BaikovVariables" -> zVars,
    "ExplicitPropagatorCount" -> Length[validated["Propagators"]],
    "AuxiliaryPropagatorCount" -> Length[validated["AuxiliaryPropagators"]],
    "TotalPropagatorCount" -> Length[allPropagators],
    "ScalarProductCount" -> Length[isps],
    "LoopCount" -> Length[loopMomenta],
    "ExternalCount" -> Length[externalMomenta],
    "TopSectorVanishingQ" -> zeroExprQ[polynomial /. Thread[zVars -> 0], True],
    "R" -> (dimensionSymbol - Length[loopMomenta] - Length[externalMomenta] - 1)/2
  |>;

  <|
    "ObjectType" -> "FeynmanIntegral",
    "Input" -> <|
      "LoopMomenta" -> loopMomenta,
      "ExternalMomenta" -> externalMomenta,
      "Propagators" -> validated["Propagators"],
      "AuxiliaryPropagators" -> validated["AuxiliaryPropagators"],
      "KinematicRules" -> kinematicRules,
      "DimensionSymbol" -> dimensionSymbol
    |>,
    "Derived" -> <|
      "PropagatorToBaikovRules" -> Thread[allPropagators -> zVars],
      "ScalarProductToBaikovRules" -> solution,
      "BaikovPolynomial" -> polynomial
    |>,
    "Internal" -> internal
  |>
];

buildInternalFamilyData[family_Association, mode_String] := cacheLookupOrCompute[
  $internalFamilyDataCache,
  {familyObjectCacheKey[family], mode},
  Module[
    {
      input = family["Input"],
      derived = family["Derived"],
      internal = family["Internal"],
      zVars,
      activeTVars,
      tAssignments
    },
    zVars = derived["PropagatorToBaikovRules"][[All, 2]];
    activeTVars = Switch[mode,
      "TypeI",
        Array[Unique["t$"] &, internal["ExplicitPropagatorCount"]],
      _,
        Array[Unique["t$"] &, internal["TotalPropagatorCount"]]
    ];
    tAssignments = Switch[mode,
      "TypeI",
        Join[
          Thread[zVars[[;; internal["ExplicitPropagatorCount"]]] -> activeTVars],
          Thread[zVars[[internal["ExplicitPropagatorCount"] + 1 ;;]] -> zVars[[internal["ExplicitPropagatorCount"] + 1 ;;]]]
        ],
      _,
        Thread[zVars -> activeTVars]
    ];
    <|
      "CacheKey" -> {familyObjectCacheKey[family], mode},
      "Mode" -> mode,
      "Polynomial" -> derived["BaikovPolynomial"],
      "CompletedVariables" -> zVars,
      "ActiveTVariables" -> activeTVars,
      "CompletedTAssignments" -> tAssignments,
      "DimensionSymbol" -> input["DimensionSymbol"],
      "LoopMomenta" -> input["LoopMomenta"],
      "ExternalMomenta" -> input["ExternalMomenta"],
      "KinematicRules" -> input["KinematicRules"],
      "Assumptions" -> True,
      "R" -> internal["R"],
      "TopSectorVanishingQ" -> internal["TopSectorVanishingQ"]
    |>
  ]
];

quadraticRootsOrdered[a_, b_, c_, assumptions_: True] := Module[{disc},
  disc = simplifyWithLevel[b^2 - 4 a c, assumptions, "Simplify"];
  {
    simplifyWithLevel[(-b - Sqrt[disc])/(2 a), assumptions, "Simplify"],
    simplifyWithLevel[(-b + Sqrt[disc])/(2 a), assumptions, "Simplify"]
  }
];

residueData[familyData_Association, index_Integer] := cacheLookupOrCompute[
  $residueDataCache,
  {familyData["CacheKey"], index},
  Module[
    {
      polyExpr = familyData["Polynomial"],
      zVars = familyData["CompletedVariables"],
      tAssignments = familyData["CompletedTAssignments"],
      tVars = familyData["ActiveTVariables"],
      assumptions = familyData["Assumptions"],
      zi,
      ti,
      polyWithT,
      coeffWithT,
      coeffWithoutT,
      linearCoeffWithT,
      constantCoeffWithT,
      rootsWithT,
      rootsWithoutT,
      zeroFlags,
      solvedRoots
    },
    zi = zVars[[index]];
    polyWithT = polyExpr /. tAssignments;
    If[index <= Length[tVars],
      ti = tVars[[index]];
      polyWithT = polyWithT /. ti -> ti + zi
    ];
    coeffWithT = simplifyWithLevel[Coefficient[polyWithT, zi, 2], assumptions, "Simplify"];
    If[TrueQ[familyData["TopSectorVanishingQ"]],
      rootsWithT = Simplify[zi /. Solve[polyWithT == 0, zi], assumptions],
      solvedRoots = Quiet @ Check[
        TimeConstrained[
          simplifyWithLevel[zi /. Solve[polyWithT == 0, zi], assumptions, "FullSimplify"],
          10,
          $Failed
        ],
        $Failed
      ];
      If[ListQ[solvedRoots] && Length[solvedRoots] == 2,
        rootsWithT = solvedRoots,
        linearCoeffWithT = simplifyWithLevel[Coefficient[polyWithT, zi, 1], assumptions, "Simplify"];
        constantCoeffWithT = simplifyWithLevel[polyWithT /. zi -> 0, assumptions, "Simplify"];
        rootsWithT = quadraticRootsOrdered[coeffWithT, linearCoeffWithT, constantCoeffWithT, assumptions]
      ]
    ];
    rootsWithoutT = simplifyWithLevel[rootsWithT /. Thread[tVars -> 0], assumptions, "Simplify"];
    zeroFlags = zeroExprQ[#, assumptions] & /@ rootsWithoutT;
    If[zeroFlags === {False, True},
      rootsWithT = Reverse[rootsWithT];
      rootsWithoutT = Reverse[rootsWithoutT]
    ];
    coeffWithoutT = simplifyWithLevel[coeffWithT /. Thread[tVars -> 0], assumptions, "Simplify"];
    <|
      "Index" -> index,
      "Variable" -> zi,
      "PolynomialWithT" -> polyWithT,
      "RootsWithT" -> rootsWithT,
      "RootsWithoutT" -> rootsWithoutT,
      "CoefficientWithT" -> coeffWithT,
      "CoefficientWithoutT" -> coeffWithoutT
    |>
  ]
];

buildTopGF[familyData_Association] := cacheLookupOrCompute[
  $topGFCache,
  familyData["CacheKey"],
  Module[
    {
      polyExpr = familyData["Polynomial"],
      tAssignments = familyData["CompletedTAssignments"],
      zVars = familyData["CompletedVariables"],
      assumptions = familyData["Assumptions"],
      r = familyData["R"]
    },
    simplifyWithLevel[
      ((polyExpr /. tAssignments)/(polyExpr /. Thread[zVars -> 0]))^r,
      assumptions,
      "Simplify"
    ]
  ]
];

buildTypeIGF[familyData_Association, data_Association] := Module[
  {
    assumptions = familyData["Assumptions"],
    r = familyData["R"],
    coeffRatio,
    diffRatio
  },
  coeffRatio = simplifyWithLevel[data["CoefficientWithT"]/data["CoefficientWithoutT"], assumptions, "Simplify"];
  diffRatio = simplifyWithLevel[
    (data["RootsWithT"][[1]] - data["RootsWithT"][[2]])/
    (data["RootsWithoutT"][[1]] - data["RootsWithoutT"][[2]]),
    assumptions,
    "Simplify"
  ];
  coeffRatio^r * diffRatio^(2 r + 1)
];

buildTypeIIGF[familyData_Association, data_Association, topGF_] := Module[
  {
    assumptions = familyData["Assumptions"],
    r = familyData["R"],
    zPlusT, zMinusT, zPlus0, zMinus0,
    coeffRatio,
    diffRatio,
    zRatioT,
    zRatio0,
    prefactorT,
    prefactor0
  },
  {zPlus0, zMinus0} = data["RootsWithoutT"];
  {zPlusT, zMinusT} = data["RootsWithT"];
  coeffRatio = simplifyWithLevel[data["CoefficientWithT"]/data["CoefficientWithoutT"], assumptions, "Simplify"];
  diffRatio = simplifyWithLevel[
    rootDifferenceSquared[zPlusT, zMinusT, assumptions]/
    rootDifferenceSquared[zPlus0, zMinus0, assumptions],
    assumptions,
    "Simplify"
  ];
  zRatioT = simplifyWithLevel[zPlusT/zMinusT, assumptions, "Simplify"];
  zRatio0 = simplifyWithLevel[zPlus0/zMinus0, assumptions, "Simplify"];
  prefactorT = coeffRatio^r * diffRatio^(r + 1/2) * (1/zMinusT) * zRatioT^(-r - 1);
  prefactor0 = topGF * (1/zMinus0) * zRatio0^(-r - 1);
  prefactorT*Hypergeometric2F1[r + 1, 2 r + 1, 2 r + 2, 1 - zMinusT/zPlusT]
    - prefactor0*Hypergeometric2F1[r + 1, 2 r + 1, 2 r + 2, 1 - zMinus0/zPlus0]
];

buildTypeIIIGF[familyData_Association, data_Association] := Module[
  {
    assumptions = familyData["Assumptions"],
    r = familyData["R"],
    zPlusT, zMinusT, zPlus0, zMinus0,
    coeffRatio,
    diffRatio,
    prefactor
  },
  {zPlus0, zMinus0} = data["RootsWithoutT"];
  {zPlusT, zMinusT} = data["RootsWithT"];
  coeffRatio = simplifyWithLevel[data["CoefficientWithT"]/data["CoefficientWithoutT"], assumptions, "Simplify"];
  diffRatio = simplifyWithLevel[
    rootDifferenceSquared[zPlusT, zMinusT, assumptions]/
    rootDifferenceSquared[zPlus0, zMinus0, assumptions],
    assumptions,
    "Simplify"
  ];
  prefactor = coeffRatio^r * diffRatio^(r + 1/2) * (1/zMinusT);
  prefactor*Hypergeometric2F1[1, r + 1, 2 r + 2, 1 - zPlusT/zMinusT]
];

normalizeRootsForTypeIII[data_Association] := Module[{plusZeroQ},
  plusZeroQ = zeroExprQ[data["RootsWithoutT"][[1]], True];
  If[plusZeroQ,
    data,
    Join[
      data,
      <|
        "RootsWithoutT" -> Reverse[data["RootsWithoutT"]],
        "RootsWithT" -> Reverse[data["RootsWithT"]]
      |>
    ]
  ]
];

validResidueDataQ[data_Association] := Module[{coeff},
  coeff = data["CoefficientWithoutT"];
  !zeroExprQ[coeff, True] &&
    FreeQ[data["RootsWithoutT"], Indeterminate | ComplexInfinity | DirectedInfinity | Infinity]
];

BaikovGF`BuildBaikovGeneratingFunction[family_Association, targetPowers_List] := Module[
  {targetCheck},
  If[Lookup[family, "ObjectType", Missing["MissingObjectType"]] =!= "FeynmanIntegral",
    Return @ baikovFailure[
      "InvalidFeynmanIntegralObject",
      "The first argument must be a FeynmanIntegral object produced by CreateFeynmanIntegral.",
      <||>
    ]
  ];

  targetCheck = validateTargetPowersForGF[family, targetPowers];
  If[FailureQ[targetCheck], Return[targetCheck]];

  cacheLookupOrCompute[
    $gfObjectCache,
    {familyObjectCacheKey[family], targetPowers},
    Module[
      {
        kind = targetCheck["Kind"],
        droppedIndex = targetCheck["DroppedIndex"],
        type,
        currentGF,
        topGF = Missing["NotNeeded"],
        familyData,
        residue = Missing["NotApplicable"],
        zeroRootQ
      },
      Switch[kind,
        "Top",
          familyData = buildInternalFamilyData[family, "Top"];
          type = "Top";
          currentGF = buildTopGF[familyData],
        "TypeI",
          familyData = buildInternalFamilyData[family, "TypeI"];
          residue = residueData[familyData, family["Internal"]["TotalPropagatorCount"]];
          If[!validResidueDataQ[residue],
            Return @ baikovFailure[
              "InvalidResidueData",
              "The residue data for the auxiliary propagator could not be constructed.",
              <|"TargetPowers" -> targetPowers|>
            ]
          ];
          type = "TypeI";
          currentGF = buildTypeIGF[familyData, residue],
        "SubTop",
          familyData = buildInternalFamilyData[family, "Complete"];
          residue = residueData[familyData, droppedIndex];
          If[!validResidueDataQ[residue],
            Return @ baikovFailure[
              "InvalidResidueData",
              "The residue data for the dropped propagator could not be constructed.",
              <|"TargetPowers" -> targetPowers, "DroppedIndex" -> droppedIndex|>
            ]
          ];
          zeroRootQ = AnyTrue[residue["RootsWithoutT"], zeroExprQ[#, True] &];
          If[TrueQ[zeroRootQ],
            type = "TypeIII";
            residue = normalizeRootsForTypeIII[residue];
            currentGF = buildTypeIIIGF[familyData, residue],
            type = "TypeII";
            topGF = buildTopGF[familyData];
            currentGF = buildTypeIIGF[familyData, residue, topGF]
          ],
        _,
          Return @ baikovFailure[
            "UnsupportedTargetPattern",
            "The requested target powers are outside the currently supported generating-function scope.",
            <|"TargetPowers" -> targetPowers|>
          ]
      ];

      <|
        "ObjectType" -> "BaikovGeneratingFunction",
        "Family" -> family,
        "TargetPowers" -> targetPowers,
        "Type" -> type,
        "GeneratingFunctions" -> <|
          "Current" -> currentGF,
          "Top" -> topGF
        |>,
        "Internal" -> <|
          "CacheKey" -> {familyObjectCacheKey[family], targetPowers},
          "Kind" -> kind,
          "DroppedIndex" -> droppedIndex,
          "FamilyData" -> familyData,
          "ResidueData" -> residue
        |>
      |>
    ]
  ]
];

orderActiveSpecsForExtraction[expr_, activeSpecs_List] := SortBy[
  activeSpecs,
  {
    -Last[#] &,
    (LeafCount[expr /. First[#] -> 0]) &
  }
];

sequentialDerivativeCoefficient[expr_, vars_List, powers_List] := Module[
  {
    orders = powers - 1,
    activeSpecs,
    inactiveRules,
    workingExpr
  },
  activeSpecs = Select[Transpose[{vars, orders}], Last[#] > 0 &];
  inactiveRules = Thread[Complement[vars, activeSpecs[[All, 1]] /. {} -> {}] -> 0];
  workingExpr = expr /. inactiveRules;
  If[activeSpecs === {}, Return[expr /. Thread[vars -> 0]]];
  activeSpecs = orderActiveSpecsForExtraction[workingExpr, activeSpecs];
  Fold[
    Function[{acc, spec},
      (D[acc, {spec[[1]], spec[[2]]}]/Factorial[spec[[2]]]) /. spec[[1]] -> 0
    ],
    workingExpr,
    activeSpecs
  ]
];

buildCanonicalTypeIIExtractionState[gfObject_Association] := cacheLookupOrCompute[
  $typeIIStateCache,
  gfObjectCacheKey[gfObject],
  Module[
    {
      familyData = gfObject["Internal"]["FamilyData"],
      residue = gfObject["Internal"]["ResidueData"],
      assumptions = True,
      rSym,
      zPlusT,
      zMinusT,
      coeffRatio,
      diffRatio,
      zArg,
      prefactor
    },
    rSym = Unique["rTypeII$"];
    {zPlusT, zMinusT} = residue["RootsWithT"];
    coeffRatio = simplifyWithLevel[
      residue["CoefficientWithT"]/residue["CoefficientWithoutT"],
      assumptions,
      "Simplify"
    ];
    diffRatio = simplifyWithLevel[
      rootDifferenceSquared[zPlusT, zMinusT, assumptions]/
        rootDifferenceSquared[residue["RootsWithoutT"][[1]], residue["RootsWithoutT"][[2]], assumptions],
      assumptions,
      "Simplify"
    ];
    zArg = simplifyWithLevel[1 - zMinusT/zPlusT, assumptions, "Simplify"];
    prefactor = simplifyWithLevel[
      coeffRatio^rSym * diffRatio^(rSym + 1/2) * (1/zMinusT) * (zPlusT/zMinusT)^(-rSym - 1),
      assumptions,
      "Simplify"
    ];
    <|
      "RationalPart" -> 0,
      "HyperCoefficient" -> prefactor,
      "HyperArgument" -> zArg,
      "RSymbol" -> rSym,
      "RestoreRules" -> {rSym -> familyData["R"]}
    |>
  ]
];

simplifyCanonicalTypeIIState[state_Association] := Join[
  state,
  <|
    "RationalPart" -> Together[state["RationalPart"]],
    "HyperCoefficient" -> Together[state["HyperCoefficient"]],
    "HyperArgument" -> state["HyperArgument"]
  |>
];

canonicalTypeIIStateApplyRules[state_Association, rules_List] := simplifyCanonicalTypeIIState @ Join[
  state,
  <|
    "RationalPart" -> (state["RationalPart"] /. rules),
    "HyperCoefficient" -> (state["HyperCoefficient"] /. rules),
    "HyperArgument" -> (state["HyperArgument"] /. rules)
  |>
];

differentiateCanonicalTypeIIStateBlock[state_Association, {var_Symbol, n_Integer}] := Module[
  {
    r,
    z,
    rationalPart,
    baseHyperCoefficient,
    hyperPolynomial,
    logDerivative,
    driveR,
    factor,
    step
  },
  If[n <= 0, Return[state]];
  r = state["RSymbol"];
  z = state["HyperArgument"];
  rationalPart = state["RationalPart"];
  baseHyperCoefficient = state["HyperCoefficient"];
  hyperPolynomial = 1;
  logDerivative = Together[D[baseHyperCoefficient, var]/baseHyperCoefficient];
  driveR = Together[
    (2 r + 1) * D[z, var] * z^(2 r) * (1 - z)^(-r - 1)
  ];
  For[step = 1, step <= n, step++,
    rationalPart = Together[
      D[rationalPart, var] + baseHyperCoefficient * hyperPolynomial * driveR
    ];
    hyperPolynomial = Together[D[hyperPolynomial, var] + hyperPolynomial * logDerivative];
  ];
  factor = Factorial[n];
  Join[
    state,
    <|
      "RationalPart" -> Together[(rationalPart/factor) /. var -> 0],
      "HyperCoefficient" -> Together[(baseHyperCoefficient * hyperPolynomial/factor) /. var -> 0],
      "HyperArgument" -> (z /. var -> 0)
    |>
  ]
];

extractTypeIICoefficientClosedForm[gfObject_Association, sourcePowers_List] := Module[
  {
    familyData = gfObject["Internal"]["FamilyData"],
    currentGF = gfObject["GeneratingFunctions"]["Current"],
    orders = sourcePowers - 1,
    activeSpecs,
    inactiveRules,
    state
  },
  activeSpecs = Select[Transpose[{familyData["ActiveTVariables"], orders}], Last[#] > 0 &];
  If[activeSpecs === {},
    Return[(currentGF /. Thread[familyData["ActiveTVariables"] -> 0]) // FunctionExpand]
  ];
  activeSpecs = orderActiveSpecsForExtraction[currentGF, activeSpecs];
  inactiveRules = Thread[Complement[familyData["ActiveTVariables"], activeSpecs[[All, 1]]] -> 0];
  state = buildCanonicalTypeIIExtractionState[gfObject];
  state = canonicalTypeIIStateApplyRules[state, inactiveRules];
  state = Join[
    state,
    <|
      "HyperCoefficient" -> Together[
        state["HyperCoefficient"] * state["HyperArgument"]^(-(2 state["RSymbol"] + 1))
      ]
    |>
  ];
  state = Fold[differentiateCanonicalTypeIIStateBlock, state, activeSpecs];
  Cancel[Together[state["RationalPart"] /. state["RestoreRules"]]]
];

typeIIIFormalHyperCoefficient[r_, n_Integer] :=
  (-1)^n*
  Pochhammer[r + 1, n]*
  Pochhammer[2 r + 1, n + 1]/
  (Pochhammer[2 r + 2, n]*Pochhammer[r - n, n + 1]);

monomialFromExponents[vars_List, exponents_List] :=
  Times @@ MapThread[#1^#2 &, {vars, exponents}];

truncatePolynomialByOrders[expr_, vars_List, maxOrders_List] := Module[
  {rules},
  rules = CoefficientRules[Expand[expr], vars];
  Total @ Map[
    If[And @@ Thread[#[[1]] <= maxOrders],
      #[[2]]*monomialFromExponents[vars, #[[1]]],
      0
    ] &,
    rules
  ]
];

multivariateSeriesPolynomial[expr_, specs_List] :=
  Normal @ Apply[Series, Prepend[(List[#[[1]], 0, #[[2]]] &) /@ specs, expr]];

zeroMultiIndex[n_Integer] := ConstantArray[0, n];

sparseSeriesKey[idx_List] := HoldComplete[idx];

sparseSeriesLookup[assoc_Association, idx_List] := Lookup[assoc, sparseSeriesKey[idx], 0];

sparseSeriesNormalize[assoc_Association] := Association @ KeyValueMap[
  If[TrueQ[#2 === 0], Nothing, #1 -> #2] &,
  assoc
];

sparseSeriesFromExpr[expr_, specs_List] := Module[
  {vars, maxOrders, poly, rules},
  If[specs === {}, Return[<|sparseSeriesKey[{}] -> expr|>]];
  vars = specs[[All, 1]];
  maxOrders = specs[[All, 2]];
  poly = truncatePolynomialByOrders[
    multivariateSeriesPolynomial[expr, specs],
    vars,
    maxOrders
  ];
  rules = CoefficientRules[Expand[poly], vars];
  sparseSeriesNormalize @ Association[
    Map[sparseSeriesKey[#[[1]]] -> #[[2]] &, rules]
  ]
];

sparseSeriesAdd[left_Association, right_Association] := sparseSeriesNormalize @ Merge[{left, right}, Total];

sparseSeriesScale[scalar_, assoc_Association] := sparseSeriesNormalize @ Association @ KeyValueMap[
  #1 -> scalar*#2 &,
  assoc
];

sparseSeriesConvolve[left_Association, right_Association, maxOrders_List] := Module[
  {result = <||>, idxLeft, idxRight, idxNew, key},
  KeyValueMap[
    Function[{leftKey, leftCoeff},
      idxLeft = ReleaseHold[leftKey];
      KeyValueMap[
        Function[{rightKey, rightCoeff},
          idxRight = ReleaseHold[rightKey];
          idxNew = idxLeft + idxRight;
          If[And @@ Thread[idxNew <= maxOrders],
            key = sparseSeriesKey[idxNew];
            result[key] = Lookup[result, key, 0] + leftCoeff*rightCoeff;
          ]
        ],
        right
      ]
    ],
    left
  ];
  sparseSeriesNormalize[result]
];

sparseSeriesDerivative[assoc_Association, pos_Integer] := Module[
  {result = <||>, idx, key, order, newIdx},
  KeyValueMap[
    Function[{heldIdx, coeff},
      idx = ReleaseHold[heldIdx];
      order = idx[[pos]];
      If[order > 0,
        newIdx = ReplacePart[idx, pos -> order - 1];
        key = sparseSeriesKey[newIdx];
        result[key] = Lookup[result, key, 0] + order*coeff;
      ]
    ],
    assoc
  ];
  sparseSeriesNormalize[result]
];

extractTypeIIICoefficientSparse[gfObject_Association, sourcePowers_List] := Module[
  {
    familyData = gfObject["Internal"]["FamilyData"],
    residue = gfObject["Internal"]["ResidueData"],
    orders = sourcePowers - 1,
    activeSpecs,
    activeVars,
    activeOrders,
    inactiveRules,
    assumptions = True,
    r,
    zPlusT,
    zMinusT,
    u,
    prefactor,
    prefSeries,
    uSeries,
    hyperSeries,
    uPower,
    maxOrder,
    n,
    zeroIdx
  },
  r = familyData["R"];
  activeSpecs = Select[Transpose[{familyData["ActiveTVariables"], orders}], Last[#] > 0 &];
  If[activeSpecs === {},
    Return[(gfObject["GeneratingFunctions"]["Current"] /. Thread[familyData["ActiveTVariables"] -> 0]) // FunctionExpand]
  ];
  activeVars = activeSpecs[[All, 1]];
  activeOrders = activeSpecs[[All, 2]];
  zeroIdx = zeroMultiIndex[Length[activeVars]];
  inactiveRules = Thread[Complement[familyData["ActiveTVariables"], activeVars] -> 0];
  {zPlusT, zMinusT} = residue["RootsWithT"];
  u = simplifyWithLevel[(zPlusT/zMinusT) /. inactiveRules, assumptions, "Simplify"];
  prefactor = simplifyWithLevel[
    ((residue["CoefficientWithT"]/residue["CoefficientWithoutT"])^r *
      (rootDifferenceSquared[zPlusT, zMinusT, assumptions]/
        rootDifferenceSquared[residue["RootsWithoutT"][[1]], residue["RootsWithoutT"][[2]], assumptions])^(r + 1/2) *
      (1/zMinusT)) /. inactiveRules,
    assumptions,
    "Simplify"
  ];
  prefSeries = sparseSeriesFromExpr[prefactor, activeSpecs];
  uSeries = sparseSeriesFromExpr[u, activeSpecs];
  hyperSeries = <|sparseSeriesKey[zeroIdx] -> typeIIIFormalHyperCoefficient[r, 0]|>;
  uPower = <|sparseSeriesKey[zeroIdx] -> 1|>;
  maxOrder = Total[activeOrders];
  For[n = 1, n <= maxOrder, n++,
    uPower = sparseSeriesConvolve[uPower, uSeries, activeOrders];
    If[uPower === <||>, Break[]];
    hyperSeries = sparseSeriesAdd[
      hyperSeries,
      sparseSeriesScale[typeIIIFormalHyperCoefficient[r, n], uPower]
    ];
  ];
  FunctionExpand[
    sparseSeriesLookup[
      sparseSeriesConvolve[prefSeries, hyperSeries, activeOrders],
      activeOrders
    ]
  ]
];

BaikovGF`ExtractBaikovCoefficient[gfObject_Association, sourcePowers_List] := Module[
  {sourceCheck},
  If[Lookup[gfObject, "ObjectType", Missing["MissingObjectType"]] =!= "BaikovGeneratingFunction",
    Return @ baikovFailure[
      "InvalidGeneratingFunctionObject",
      "The first argument must be a BaikovGeneratingFunction object produced by BuildBaikovGeneratingFunction.",
      <||>
    ]
  ];

  sourceCheck = validateSourcePowersForExtraction[gfObject, sourcePowers];
  If[FailureQ[sourceCheck], Return[sourceCheck]];

  cacheLookupOrCompute[
    $rawCoefficientCache,
    {gfObjectCacheKey[gfObject], sourcePowers},
    Module[
      {
        type = gfObject["Type"],
        family = gfObject["Family"],
        familyData = gfObject["Internal"]["FamilyData"],
        currentGF = gfObject["GeneratingFunctions"]["Current"],
        raw
      },
      raw = Switch[type,
        "Top",
          sequentialDerivativeCoefficient[currentGF, familyData["ActiveTVariables"], sourcePowers],
        "TypeI",
          sequentialDerivativeCoefficient[
            currentGF,
            familyData["ActiveTVariables"],
            Take[sourcePowers, Length[familyData["ActiveTVariables"]]]
          ],
        "TypeII",
          extractTypeIICoefficientClosedForm[gfObject, sourcePowers],
        "TypeIII",
          extractTypeIIICoefficientSparse[gfObject, sourcePowers],
        _,
          Return @ baikovFailure[
            "UnsupportedGFType",
            "The generating-function type is not supported for coefficient extraction.",
            <|"Type" -> type|>
          ]
      ];

      <|
        "ObjectType" -> "BaikovRawCoefficient",
        "Family" -> family,
        "Type" -> type,
        "TargetPowers" -> gfObject["TargetPowers"],
        "SourcePowers" -> sourcePowers,
        "RawCoefficient" -> raw,
        "Internal" -> gfObject["Internal"]
      |>
    ]
  ]
];

sameExponentQ[exp1_, exp2_, assumptions_: True] :=
  exp1 === exp2 || TrueQ[Simplify[exp1 == exp2, assumptions]];

reciprocalBaseQ[base1_, base2_, assumptions_: True] := Module[{product},
  product = simplifyWithLevel[Together[base1*base2], assumptions, "Simplify"];
  TrueQ[Simplify[product == 1, assumptions]]
];

collapseReciprocalPowerPairsInTimes[term_Times, assumptions_: True] := Module[
  {factors = List @@ term, used, result = {}, i, j, found},
  used = ConstantArray[False, Length[factors]];
  For[i = 1, i <= Length[factors], i++,
    If[used[[i]], Continue[]];
    found = False;
    If[MatchQ[factors[[i]], Power[_, _]],
      For[j = i + 1, j <= Length[factors], j++,
        If[
          !used[[j]] &&
          MatchQ[factors[[j]], Power[_, _]] &&
          sameExponentQ[factors[[i, 2]], factors[[j, 2]], assumptions] &&
          reciprocalBaseQ[factors[[i, 1]], factors[[j, 1]], assumptions],
          used[[i]] = True;
          used[[j]] = True;
          found = True;
          Break[];
        ]
      ]
    ];
    If[!found,
      used[[i]] = True;
      AppendTo[result, factors[[i]]];
    ];
  ];
  If[result === {}, 1, Times @@ result]
];

collapseReciprocalPowerPairsInTimes[expr_, assumptions_: True] := expr;

cancelReciprocalPowerPairs[expr_, assumptions_: True] := FixedPoint[
  ReplaceAll[#, t_Times :> collapseReciprocalPowerPairsInTimes[t, assumptions]] &,
  expr
];

dropDimensionDependentPowers[expr_, dimSym_, assumptions_: True] := Module[{result},
  result = cancelReciprocalPowerPairs[expr, assumptions];
  result = result /. HoldPattern[Power[base_, exp_]] /; !FreeQ[exp, dimSym] :>
    Power[simplifyWithLevel[base, assumptions, "Simplify"], Simplify[exp /. dimSym -> 2, assumptions]];
  cancelReciprocalPowerPairs[result, assumptions]
];

simplifySquareRoots[expr_] := Module[{tmp},
  tmp = expr /. {
    HoldPattern[Power[x_, Rational[1, 2]]] :> Sqrt[x],
    HoldPattern[Power[x_, Rational[-1, 2]]] :> 1/Sqrt[x]
  };
  tmp //. {
    HoldPattern[Sqrt[x_]^2] :> x,
    Sqrt[x_]*Sqrt[y_] :> Sqrt[x*y],
    Sqrt[x_]/Sqrt[y_] :> Sqrt[x/y]
  }
];

normalizeHalfIntegerPowersForSimplify[expr_] := expr /. HoldPattern[Power[x_, exp_Rational]] /; Denominator[exp] == 2 :>
  Module[{integerPart, remainder},
    {integerPart, remainder} = splitIntegerHalfPart[exp];
    Which[
      remainder === 0, x^integerPart,
      remainder === Rational[1, 2], x^integerPart*Sqrt[x],
      remainder === Rational[-1, 2], x^integerPart/Sqrt[x],
      True, x^exp
    ]
  ];

splitEvenSquarePart[exp_Integer] := Module[{outsideExp, remainder},
  outsideExp = If[exp >= 0, Floor[exp/2], Ceiling[exp/2]];
  remainder = exp - 2 outsideExp;
  {outsideExp, remainder}
];

splitPositiveRationalSquarePart[q_Rational] /; Positive[q] := Module[
  {num = Numerator[q], den = Denominator[q], numFac, denFac, outNum, outDen, inNum, inDen},
  numFac = FactorInteger[num];
  denFac = FactorInteger[den];
  outNum = Times @@ (#[[1]]^Floor[#[[2]]/2] & /@ numFac);
  outDen = Times @@ (#[[1]]^Floor[#[[2]]/2] & /@ denFac);
  inNum = Times @@ (#[[1]]^Mod[#[[2]], 2] & /@ numFac);
  inDen = Times @@ (#[[1]]^Mod[#[[2]], 2] & /@ denFac);
  {outNum/outDen, inNum/inDen}
];

splitPositiveRationalSquarePart[q_] := {1, q};

extractPerfectSquareFactor[expr_] := Module[
  {factors, outside = 1, inside = 1, base, exp, split},
  factors = Which[
    expr === 1, {},
    Head[expr] === Times, List @@ expr,
    True, {expr}
  ];
  Scan[
    Function[factor,
      Which[
        MatchQ[factor, Power[_, exp_Integer]],
          base = factor[[1]];
          exp = factor[[2]];
          split = splitEvenSquarePart[exp];
          outside *= base^split[[1]];
          If[split[[2]] =!= 0, inside *= base^split[[2]]],
        RationalQ[factor] && Positive[factor],
          split = splitPositiveRationalSquarePart[factor];
          outside *= split[[1]];
          inside *= split[[2]],
        True,
          inside *= factor
      ]
    ],
    factors
  ];
  {outside, inside}
];

radicalAtomicSymbols[expr_, dimSym_] := Module[{work, radArgs},
  work = HoldComplete[expr];
  radArgs = Cases[
    work,
    HoldPattern[Power[arg_, exp_Rational]] /; Denominator[exp] == 2 && OddQ[Numerator[exp]] :> arg,
    Infinity
  ];
  DeleteDuplicates @ Cases[
    radArgs,
    s_Symbol /; Context[s] =!= "System`" && s =!= dimSym,
    Infinity
  ]
];

(* 把平方图变量中的偶次多项式重新写回原始根号原子符号。 *)
squareChartPolynomialToSquares[poly_, chartVars_List, syms_List] := Module[{rules},
  rules = CoefficientRules[Expand[poly], chartVars];
  If[!AllTrue[rules[[All, 1]], AllTrue[#, EvenQ] &], Return[$Failed]];
  Total[
    Map[
      #[[2]]*Times @@ MapThread[#1^(#2/2) &, {syms, #[[1]]}] &,
      rules
    ]
  ]
];

(* 用 u -> -u 的偶投影去掉纯有理结果里残留的半整数幂；若仍含奇次项则返回 $Failed。 *)
squareChartEvenProjectionRationalize[expr_, dimSym_, time_: 20] := TimeConstrained[
  Module[{syms, chartVars, subRules, work, num, den, num2, den2},
    syms = radicalAtomicSymbols[expr, dimSym];
    If[syms === {}, Return[expr]];
    chartVars = Array[Unique["u$"] &, Length[syms]];
    subRules = Thread[syms -> chartVars^2];
    work = normalizeSqrtPowersForFLINT[expr /. subRules];
    work = PowerExpand[work];
    work = Cancel[Together[work]];
    Do[
      work = Cancel[Together[(work + (work /. chartVars[[i]] -> -chartVars[[i]]))/2]],
      {i, Length[chartVars]}
    ];
    work = Expand[work];
    work = Cancel[Together[work]];
    num = squareChartPolynomialToSquares[Numerator[work], chartVars, syms];
    den = squareChartPolynomialToSquares[Denominator[work], chartVars, syms];
    If[num === $Failed || den === $Failed, Return[$Failed]];
    Cancel[Together[num/den]]
  ],
  time,
  $Failed
];

squareChartRadicalSimplify[expr_, dimSym_, time_: 30] := Module[
  {syms, chartVars, subRules, backRules, ass, work, simplified, back},
  syms = radicalAtomicSymbols[expr, dimSym];
  If[syms === {}, Return[expr]];
  chartVars = Table[Unique["rad$"], {Length[syms]}];
  subRules = Thread[syms -> chartVars^2];
  backRules = Thread[chartVars -> (Sqrt /@ syms)];
  ass = And @@ Thread[chartVars > 0];
  work = expr /. subRules;
  work = PowerExpand[work];
  simplified = TimeConstrained[
    simplifyWithLevel[work, ass, "FullSimplify"],
    time,
    $Aborted
  ];
  If[simplified === $Aborted, Return[expr]];
  back = Cancel[Together[simplified /. backRules]];
  back
];

mergeAllSquareRoots[expr_] := FixedPoint[
  ReplaceAll[
    normalizeHalfIntegerPowersForSimplify[normalizeNestedSquareRootsInArgument[#]],
    {
      HoldPattern[Sqrt[x_]^2] :> x,
      HoldPattern[1/Sqrt[x_]] :> Sqrt[Together[1/x]],
      HoldPattern[Sqrt[x_]*Sqrt[y_]] :> Sqrt[Together[x*y]],
      HoldPattern[Sqrt[x_]/Sqrt[y_]] :> Sqrt[Together[x/y]]
    }
  ] &,
  expr,
  6
];

normalizeNestedSquareRootsInArgument[arg_] := FixedPoint[
  normalizeHalfIntegerPowersForSimplify[
    # /. {
      HoldPattern[Power[x_Times, Rational[1, 2]]] :> Times @@ (Power[#, Rational[1, 2]] & /@ (List @@ x)),
      HoldPattern[Power[x_Times, Rational[-1, 2]]] :> Times @@ (Power[#, Rational[-1, 2]] & /@ (List @@ x)),
      HoldPattern[Power[Power[x_, n_Integer], Rational[1, 2]]] :> Power[x, Rational[n, 2]],
      HoldPattern[Power[Power[x_, n_Integer], Rational[-1, 2]]] :> Power[x, Rational[-n, 2]]
    }
  ] &,
  arg,
  6
];

simplifySingleSquareRoot[arg_] := Module[
  {work, num, den, outsideNum, insideNum, outsideDen, insideDen, outside, inside},
  work = normalizeNestedSquareRootsInArgument[arg];
  work = PowerExpand[work];
  work = normalizeHalfIntegerPowersForSimplify[work];
  work = simplifySquareRoots[work];
  work = Cancel[Together[work]];
  If[work === 1, Return[1]];
  num = Numerator[work];
  den = Denominator[work];
  {outsideNum, insideNum} = extractPerfectSquareFactor[num];
  {outsideDen, insideDen} = extractPerfectSquareFactor[den];
  outside = Cancel[Together[outsideNum/outsideDen]];
  inside = Cancel[Together[insideNum/insideDen]];
  Which[
    inside === 1, outside,
    outside === 1, Sqrt[inside],
    True, outside*Sqrt[inside]
  ]
];

simplifySquareRootArguments[expr_] := FixedPoint[
  ReplaceAll[#, HoldPattern[Sqrt[arg_]] :> simplifySingleSquareRoot[arg]] &,
  expr,
  4
];

normalizeHalfIntegerTerm[term_] := Module[
  {
    split,
    integerCounts,
    numCounts,
    denCounts,
    integerPart,
    sqrtNumerator,
    sqrtDenominator,
    radicand
  },
  split = collectPowerSplit[normalizeSqrtPowersForFLINT[term]];
  If[split["Unsupported"] =!= {}, Return[term]];
  integerCounts = split["IntegerCounts"];
  {numCounts, denCounts} = cancelSharedCounts[split["HalfNumeratorCounts"], split["HalfDenominatorCounts"]];
  integerPart = countsToProduct[integerCounts];
  sqrtNumerator = countsToProduct[numCounts];
  sqrtDenominator = countsToProduct[denCounts];
  radicand = simplifyWithLevel[Together[sqrtNumerator/sqrtDenominator], True, "Simplify"];
  Cancel[Together[
    integerPart * If[radicand === 1, 1, simplifySingleSquareRoot[radicand]]
  ]]
];

normalizeHalfIntegerTerms[expr_] := Module[{terms},
  terms = If[Head[expr] === Plus, List @@ expr, {expr}];
  Total[normalizeHalfIntegerTerm /@ terms]
];

postSimplifySqrtTail[expr_, dimSym_] := Module[{work, projected},
  work = normalizeNestedSquareRootsInArgument[expr];
  work = normalizeHalfIntegerPowersForSimplify[work];
  work = normalizeHalfIntegerTerms[work];
  If[FreeQ[work, Sqrt] && !hiddenHalfPowerQ[work], Return[work]];
  work = FixedPoint[
    simplifySquareRootArguments[mergeAllSquareRoots[#]] &,
    work,
    6
  ];
  work = mergeAllSquareRoots[work];
  work = normalizeHalfIntegerPowersForSimplify[work];
  If[FreeQ[work, Sqrt] && !hiddenHalfPowerQ[work], Return[Cancel[Together[work]]]];
  projected = squareChartEvenProjectionRationalize[work, dimSym, 20];
  If[projected =!= $Failed,
    projected = normalizeHalfIntegerPowersForSimplify[projected];
    If[FreeQ[projected, Sqrt] && !hiddenHalfPowerQ[projected], Return[Cancel[Together[projected]]]]
  ];
  If[LeafCount[work] > 800, Return[Cancel[Together[work]]]];
  work = squareChartRadicalSimplify[work, dimSym, 30];
  If[FreeQ[work, Sqrt] && !hiddenHalfPowerQ[work], Return[Cancel[Together[work]]]];
  projected = squareChartEvenProjectionRationalize[work, dimSym, 20];
  If[projected =!= $Failed,
    projected = normalizeHalfIntegerPowersForSimplify[projected];
    If[FreeQ[projected, Sqrt] && !hiddenHalfPowerQ[projected], Return[Cancel[Together[projected]]]]
  ];
  work = normalizeHalfIntegerPowersForSimplify[work];
  work = FixedPoint[
    simplifySquareRootArguments[mergeAllSquareRoots[#]] &,
    work,
    4
  ];
  Cancel[Together[work]]
];

exactHalfIntegerQ[exp_] := Quiet @ TrueQ[IntegerQ[2 exp]];

splitIntegerHalfPart[exp_] := Module[{integerPart, remainder},
  integerPart = If[TrueQ[exp >= 0], Floor[exp], Ceiling[exp]];
  remainder = Simplify[exp - integerPart];
  {integerPart, remainder}
];

normalizeSqrtPowersForFLINT[expr_] := expr /. {
  HoldPattern[Sqrt[x_]] :> x^Rational[1, 2],
  HoldPattern[1/Sqrt[x_]] :> x^Rational[-1, 2]
};

replaceDimensionInExponentsWithTwo[expr_, dimSym_] := expr //. HoldPattern[Power[base_, exponent_]] /; !FreeQ[exponent, dimSym] :>
  Power[base, Simplify[exponent /. dimSym -> 2]];

hiddenHalfPowerQ[expr_] := !FreeQ[
  HoldComplete[expr],
  HoldPattern[Power[_, exponent_]] /; !IntegerQ[exponent],
  Infinity
];

pureRationalNoHalfQ[expr_] := FreeQ[expr, Sqrt] && !hiddenHalfPowerQ[expr];

cheapRationalEarlyReturn[expr_] := Module[{work},
  work = Cancel[Together[expr]];
  If[!pureRationalNoHalfQ[work], Return[$Failed]];
  If[LeafCount[work] <= 400,
    Return[simplifyWithLevel[work, True, "Simplify"]]
  ];
  If[LeafCount[work] <= 2000,
    Return[work]
  ];
  $Failed
];

heldKey[expr_] := HoldComplete[expr];

addExponentCount[counts_Association, base_, amount_Integer] := Module[{key = heldKey[base], updated},
  updated = Lookup[counts, key, 0] + amount;
  If[updated == 0,
    KeyDrop[counts, key],
    Join[counts, <|key -> updated|>]
  ]
];

mergeExponentCounts[left_Association, right_Association] := Module[{merged = Association[left]},
  KeyValueMap[
    (merged = addExponentCount[merged, ReleaseHold[#1], #2]) &,
    right
  ];
  merged
];

emptyPowerSplit[] := <|
  "IntegerCounts" -> <||>,
  "HalfNumeratorCounts" -> <||>,
  "HalfDenominatorCounts" -> <||>,
  "Unsupported" -> {}
|>;

mergePowerSplits[left_Association, right_Association] := <|
  "IntegerCounts" -> mergeExponentCounts[left["IntegerCounts"], right["IntegerCounts"]],
  "HalfNumeratorCounts" -> mergeExponentCounts[left["HalfNumeratorCounts"], right["HalfNumeratorCounts"]],
  "HalfDenominatorCounts" -> mergeExponentCounts[left["HalfDenominatorCounts"], right["HalfDenominatorCounts"]],
  "Unsupported" -> Join[left["Unsupported"], right["Unsupported"]]
|>;

collectPowerSplit[expr_, scale_: 1] := Module[
  {result = emptyPowerSplit[], parts, integerPart, remainder, atomicWarnings = {}},
  If[!exactHalfIntegerQ[scale],
    result["Unsupported"] = {<|"Reason" -> "UnsupportedExponentPattern", "Expression" -> expr, "Exponent" -> scale|>};
    Return[result]
  ];
  Which[
    Head[expr] === Times,
      parts = List @@ expr;
      Return[Fold[mergePowerSplits, emptyPowerSplit[], collectPowerSplit[#, scale] & /@ parts]],
    Head[expr] === Power,
      Return[collectPowerSplit[expr[[1]], Simplify[scale*expr[[2]]]]],
    True,
      {integerPart, remainder} = splitIntegerHalfPart[scale];
      If[integerPart =!= 0,
        If[hiddenHalfPowerQ[expr],
          AppendTo[atomicWarnings, <|"Reason" -> "HiddenHalfPowerInsideAtomicFactor", "Expression" -> expr|>],
          result["IntegerCounts"] = addExponentCount[result["IntegerCounts"], expr, integerPart]
        ]
      ];
      Which[
        remainder === 0, Null,
        remainder === Rational[1, 2],
          result["HalfNumeratorCounts"] = addExponentCount[result["HalfNumeratorCounts"], expr, 1],
        remainder === Rational[-1, 2],
          result["HalfDenominatorCounts"] = addExponentCount[result["HalfDenominatorCounts"], expr, 1],
        True,
          AppendTo[atomicWarnings, <|"Reason" -> "UnsupportedHalfRemainder", "Expression" -> expr, "Remainder" -> remainder|>]
      ];
      result["Unsupported"] = atomicWarnings;
      result
  ]
];

countsToProduct[counts_Association] := Module[{factors},
  factors = KeyValueMap[
    If[#2 === 1, ReleaseHold[#1], ReleaseHold[#1]^#2] &,
    counts
  ];
  If[factors === {}, 1, Times @@ factors]
];

cancelSharedCounts[numCounts_Association, denCounts_Association] := Module[
  {num = Association[numCounts], den = Association[denCounts], sharedKeys, cancelCount},
  sharedKeys = Intersection[Keys[num], Keys[den]];
  Do[
    cancelCount = Min[num[key], den[key]];
    If[cancelCount > 0,
      num = addExponentCount[num, ReleaseHold[key], -cancelCount];
      den = addExponentCount[den, ReleaseHold[key], -cancelCount]
    ],
    {key, sharedKeys}
  ];
  {num, den}
];

rebuildPreparedTerm[term_] := Module[
  {split, integerCounts, numCounts, denCounts, integerPart, sqrtNumerator, sqrtDenominator, radicand},
  split = collectPowerSplit[term];
  If[split["Unsupported"] =!= {},
    Return @ <|"Status" -> "failure", "Failures" -> split["Unsupported"], "RawTerm" -> term|>
  ];
  integerCounts = split["IntegerCounts"];
  {numCounts, denCounts} = cancelSharedCounts[split["HalfNumeratorCounts"], split["HalfDenominatorCounts"]];
  integerPart = countsToProduct[integerCounts];
  sqrtNumerator = countsToProduct[numCounts];
  sqrtDenominator = countsToProduct[denCounts];
  radicand = If[sqrtNumerator === 1 && sqrtDenominator === 1, 1, sqrtNumerator/sqrtDenominator];
  radicand = simplifyWithLevel[Together[radicand], True, "Simplify"];
  If[radicand === 1,
    <|
      "Status" -> "ok",
      "RawTerm" -> term,
      "IntegerPart" -> integerPart,
      "SqrtNumerator" -> sqrtNumerator,
      "SqrtDenominator" -> sqrtDenominator,
      "Radicand" -> 1
    |>,
    <|
      "Status" -> "failure",
      "Failures" -> {
        <|
          "Reason" -> "NonUnitRadicand",
          "RawTerm" -> term,
          "IntegerPart" -> integerPart,
          "SqrtNumerator" -> sqrtNumerator,
          "SqrtDenominator" -> sqrtDenominator,
          "Radicand" -> radicand
        |>
      },
      "RawTerm" -> term,
      "IntegerPart" -> integerPart,
      "SqrtNumerator" -> sqrtNumerator,
      "SqrtDenominator" -> sqrtDenominator,
      "Radicand" -> radicand
    |>
  ]
];

prepareTermsForFLINTAttempt[expr_, expandTermsQ_] := Module[
  {preparedExpr, terms, termResults, failures},
  preparedExpr = If[TrueQ[expandTermsQ], Expand[expr], expr];
  terms = If[Head[preparedExpr] === Plus, List @@ preparedExpr, {preparedExpr}];
  termResults = rebuildPreparedTerm /@ terms;
  failures = Flatten[Lookup[Select[termResults, #["Status"] === "failure" &], "Failures", {}], 1];
  If[failures === {},
    <|
      "Status" -> "ok",
      "Expanded" -> TrueQ[expandTermsQ],
      "PreparedExpression" -> Total[Lookup[termResults, "IntegerPart", 0]],
      "TermCount" -> Length[terms],
      "Terms" -> termResults,
      "Failures" -> {}
    |>,
    <|
      "Status" -> "failure",
      "Expanded" -> TrueQ[expandTermsQ],
      "PreparedExpression" -> Missing["NotAvailable"],
      "TermCount" -> Length[terms],
      "Terms" -> termResults,
      "Failures" -> failures
    |>
  ]
];

prepareWithPowerExpandFallback[expr_, timeConstraint_: 60] := Module[
  {fallbackExpr, normalizedFallback, attempt},
  fallbackExpr = Quiet @ Check[
    TimeConstrained[Together[PowerExpand[expr]], timeConstraint, $Aborted],
    $Failed
  ];
  If[fallbackExpr === $Aborted || fallbackExpr === $Failed,
    Return @ baikovFailure[
      "PowerExpandFallbackFailed",
      "The PowerExpand fallback failed while preparing the rational expression.",
      <|"Expression" -> expr|>
    ]
  ];
  normalizedFallback = normalizeSqrtPowersForFLINT[fallbackExpr];
  attempt = prepareTermsForFLINTAttempt[normalizedFallback, True];
  If[attempt["Status"] === "ok", attempt,
    baikovFailure[
      "FLINTPreparationFailed",
      "The expression still contains unresolved square-root structure after PowerExpand fallback.",
      <|"PreparationResult" -> attempt|>
    ]
  ]
];

prepareRationalForExternalSimplifier[expr_, dimSym_] := Module[
  {dimensionReduced, normalized, attempt, fallback},
  dimensionReduced = replaceDimensionInExponentsWithTwo[expr, dimSym];
  dimensionReduced = elementaryNormalize[dimensionReduced, False];
  normalized = normalizeSqrtPowersForFLINT[dimensionReduced];
  attempt = prepareTermsForFLINTAttempt[normalized, False];
  If[attempt["Status"] === "failure",
    attempt = prepareTermsForFLINTAttempt[normalized, True]
  ];
  If[attempt["Status"] === "ok", Return[attempt["PreparedExpression"]]];
  fallback = prepareWithPowerExpandFallback[dimensionReduced];
  If[FailureQ[fallback], fallback, fallback["PreparedExpression"]]
];

defaultFLINTPythonExecutable[] := Module[{root, candidates, found, fallback},
  root = packageRootDirectory[];
  candidates = {
    FileNameJoin[{root, ".venv-flint", "Scripts", "python.exe"}],
    FileNameJoin[{root, ".venv-flint", "bin", "python"}]
  };
  found = SelectFirst[candidates, FileExistsQ, Missing["NotFound"]];
  If[found =!= Missing["NotFound"], Return[found]];
  fallback = SelectFirst[{"python", "python3"}, StringQ[Quiet @ FindExecutable[#]] &, Missing["NotFound"]];
  If[fallback === Missing["NotFound"], "python", fallback]
];

defaultFLINTBackendScript[] := FileNameJoin[{packageRootDirectory[], "external", "flint_backend", "flint_simplify.py"}];

checkBackendResultAssociationQ[result_] :=
  AssociationQ[result] && Lookup[result, "status", "error"] === "ok";

collectFLINTVariables[expr_] := SortBy[
  DeleteDuplicates @ Cases[
    HoldComplete[expr],
    s_Symbol /; Context[s] =!= "System`",
    Infinity
  ],
  SymbolName
];

encodeFLINTAST[expr_, vars_List] := Module[{allowedNames = AssociationThread[vars -> (SymbolName /@ vars)]},
  Which[
    IntegerQ[expr],
      <|"head" -> "Integer", "value" -> ToString[expr, InputForm]|>,
    Head[expr] === Rational,
      <|"head" -> "Rational", "p" -> ToString[Numerator[expr], InputForm], "q" -> ToString[Denominator[expr], InputForm]|>,
    MatchQ[expr, _Symbol?(KeyExistsQ[allowedNames, #] &)],
      <|"head" -> "Symbol", "name" -> allowedNames[expr]|>,
    Head[expr] === Plus,
      <|"head" -> "Plus", "args" -> (encodeFLINTAST[#, vars] & /@ (List @@ expr))|>,
    Head[expr] === Times,
      <|"head" -> "Times", "args" -> (encodeFLINTAST[#, vars] & /@ (List @@ expr))|>,
    Head[expr] === Power && IntegerQ[expr[[2]]],
      <|"head" -> "Power", "base" -> encodeFLINTAST[expr[[1]], vars], "exp" -> ToString[expr[[2]], InputForm]|>,
    True,
      baikovFailure[
        "UnsupportedFLINTAST",
        "The expression contains unsupported constructs for the FLINT encoder.",
        <|"Expression" -> expr|>
      ]
  ]
];

decodeFLINTAST[ast_Association, nameMap_Association] := Module[{head = Lookup[ast, "head", Missing["MissingHead"]]},
  Which[
    head === "Integer",
      ToExpression[Lookup[ast, "value", "0"], InputForm],
    head === "Rational",
      Rational[
        ToExpression[Lookup[ast, "p", "0"], InputForm],
        ToExpression[Lookup[ast, "q", "1"], InputForm]
      ],
    head === "Symbol",
      Lookup[nameMap, Lookup[ast, "name", ""], Symbol[Lookup[ast, "name", "Global`x"]]],
    head === "Plus",
      Total[decodeFLINTAST[#, nameMap] & /@ Lookup[ast, "args", {}]],
    head === "Times",
      Times @@ (decodeFLINTAST[#, nameMap] & /@ Lookup[ast, "args", {}]),
    head === "Power",
      decodeFLINTAST[Lookup[ast, "base"], nameMap]^ToExpression[Lookup[ast, "exp", "1"], InputForm],
    True,
      baikovFailure[
        "UnsupportedFLINTDecodeAST",
        "The FLINT backend returned an unsupported AST head.",
        <|"AST" -> ast|>
      ]
  ]
];

runFLINTBackend[payload_Association, pythonExecutable_String, backendScript_String, workers_Integer] := Module[
  {inputFile, outputFile, process, stdout, stderr, parsed},
  inputFile = FileNameJoin[{$TemporaryDirectory, "flint-input-" <> CreateUUID[] <> ".json"}];
  outputFile = FileNameJoin[{$TemporaryDirectory, "flint-output-" <> CreateUUID[] <> ".json"}];
  Export[inputFile, payload, "RawJSON"];
  process = RunProcess[
    {
      pythonExecutable,
      backendScript,
      "--workers",
      ToString[workers],
      "--input-file",
      inputFile,
      "--output-file",
      outputFile
    },
    All
  ];
  stdout = Lookup[process, "StandardOutput", ""];
  stderr = Lookup[process, "StandardError", ""];
  parsed = If[FileExistsQ[outputFile], Quiet @ Check[Import[outputFile, "RawJSON"], $Failed], $Failed];
  Quiet @ DeleteFile /@ Select[{inputFile, outputFile}, FileExistsQ];
  If[process["ExitCode"] =!= 0 || parsed === $Failed || !AssociationQ[parsed],
    Return @ baikovFailure[
      "FLINTBackendProcessFailed",
      "The FLINT backend process failed.",
      <|"ExitCode" -> process["ExitCode"], "StandardOutput" -> stdout, "StandardError" -> stderr|>
    ]
  ];
  If[Lookup[parsed, "status", "error"] =!= "ok",
    Return @ baikovFailure[
      "FLINTBackendReportedError",
      "The FLINT backend reported an error.",
      <|"BackendResponse" -> parsed, "StandardError" -> stderr|>
    ]
  ];
  parsed
];

externalRationalSimplify[expr_] := Module[
  {vars, encoded, payload, response, result, nameMap, pythonExecutable, backendScript, workers},
  vars = collectFLINTVariables[expr];
  encoded = encodeFLINTAST[expr, vars];
  If[FailureQ[encoded], Return[encoded]];
  nameMap = AssociationThread[SymbolName /@ vars -> vars];
  pythonExecutable = defaultFLINTPythonExecutable[];
  backendScript = defaultFLINTBackendScript[];
  workers = Max[1, $ProcessorCount];
  payload = <|
    "variables" -> (SymbolName /@ vars),
    "workers" -> workers,
    "expressions" -> {<|"id" -> "expr$1", "ast" -> encoded|>}
  |>;
  response = runFLINTBackend[payload, pythonExecutable, backendScript, workers];
  If[FailureQ[response], Return[response]];
  result = First @ Lookup[response, "results", {}];
  If[!AssociationQ[result] || Lookup[result, "status", "error"] =!= "ok",
    Return @ baikovFailure[
      "FLINTExpressionFailed",
      "The FLINT backend failed on the prepared rational expression.",
      <|"BackendResult" -> result|>
    ]
  ];
  decodeFLINTAST[Lookup[result, "numerator"], nameMap] / decodeFLINTAST[Lookup[result, "denominator"], nameMap]
];

BaikovGF`CheckBaikovExternalBackend[] := Module[
  {
    pythonExecutable, backendScript, importProcess, testSymbol, encoded,
    payload, response, backendResult, nameMap, decoded, expected
  },
  pythonExecutable = defaultFLINTPythonExecutable[];
  backendScript = defaultFLINTBackendScript[];

  If[!FileExistsQ[backendScript],
    Return @ <|
      "ObjectType" -> "BaikovExternalBackendCheck",
      "Available" -> False,
      "PythonExecutable" -> pythonExecutable,
      "BackendScript" -> backendScript,
      "Reason" -> "BackendScriptMissing",
      "Message" -> "The FLINT backend script was not found."
    |>
  ];

  importProcess = Quiet @ Check[
    RunProcess[
      {
        pythonExecutable,
        "-c",
        "import sys, flint; print(sys.executable); print(flint.__file__)"
      },
      All
    ],
    $Failed
  ];

  If[importProcess === $Failed,
    Return @ <|
      "ObjectType" -> "BaikovExternalBackendCheck",
      "Available" -> False,
      "PythonExecutable" -> pythonExecutable,
      "BackendScript" -> backendScript,
      "Reason" -> "PythonLaunchFailed",
      "Message" -> "The selected Python executable could not be launched."
    |>
  ];

  If[Lookup[importProcess, "ExitCode", 1] =!= 0,
    Return @ <|
      "ObjectType" -> "BaikovExternalBackendCheck",
      "Available" -> False,
      "PythonExecutable" -> pythonExecutable,
      "BackendScript" -> backendScript,
      "Reason" -> "PythonImportFailed",
      "Message" -> "Python could not import the flint module.",
      "PythonStdout" -> Lookup[importProcess, "StandardOutput", ""],
      "PythonStderr" -> Lookup[importProcess, "StandardError", ""]
    |>
  ];

  testSymbol = Unique["flintCheck$"];
  encoded = encodeFLINTAST[(testSymbol^2 - 1)/(testSymbol - 1), {testSymbol}];
  If[FailureQ[encoded],
    Return @ <|
      "ObjectType" -> "BaikovExternalBackendCheck",
      "Available" -> False,
      "PythonExecutable" -> pythonExecutable,
      "BackendScript" -> backendScript,
      "Reason" -> "BackendEncodingFailed",
      "Message" -> "The package failed while encoding the FLINT backend test expression.",
      "Details" -> encoded
    |>
  ];

  payload = <|
    "variables" -> {SymbolName[testSymbol]},
    "workers" -> 1,
    "expressions" -> {<|"id" -> "expr$check", "ast" -> encoded|>}
  |>;
  response = runFLINTBackend[payload, pythonExecutable, backendScript, 1];
  If[FailureQ[response],
    Return @ <|
      "ObjectType" -> "BaikovExternalBackendCheck",
      "Available" -> False,
      "PythonExecutable" -> pythonExecutable,
      "BackendScript" -> backendScript,
      "Reason" -> "BackendExecutionFailed",
      "Message" -> "The FLINT backend test call failed.",
      "Details" -> response,
      "PythonStdout" -> Lookup[importProcess, "StandardOutput", ""],
      "PythonStderr" -> Lookup[importProcess, "StandardError", ""]
    |>
  ];

  backendResult = First @ Lookup[response, "results", {}];
  If[!checkBackendResultAssociationQ[backendResult],
    Return @ <|
      "ObjectType" -> "BaikovExternalBackendCheck",
      "Available" -> False,
      "PythonExecutable" -> pythonExecutable,
      "BackendScript" -> backendScript,
      "Reason" -> "BackendReturnedError",
      "Message" -> "The FLINT backend returned a non-ok result for the test expression.",
      "BackendResponse" -> response,
      "PythonStdout" -> Lookup[importProcess, "StandardOutput", ""],
      "PythonStderr" -> Lookup[importProcess, "StandardError", ""]
    |>
  ];

  nameMap = Association[SymbolName[testSymbol] -> testSymbol];
  decoded =
    decodeFLINTAST[Lookup[backendResult, "numerator"], nameMap] /
    decodeFLINTAST[Lookup[backendResult, "denominator"], nameMap];
  If[FailureQ[decoded],
    Return @ <|
      "ObjectType" -> "BaikovExternalBackendCheck",
      "Available" -> False,
      "PythonExecutable" -> pythonExecutable,
      "BackendScript" -> backendScript,
      "Reason" -> "BackendDecodeFailed",
      "Message" -> "The FLINT backend test result could not be decoded.",
      "BackendResponse" -> response,
      "PythonStdout" -> Lookup[importProcess, "StandardOutput", ""],
      "PythonStderr" -> Lookup[importProcess, "StandardError", ""]
    |>
  ];

  expected = testSymbol + 1;
  If[!TrueQ[Simplify[decoded == expected]],
    Return @ <|
      "ObjectType" -> "BaikovExternalBackendCheck",
      "Available" -> False,
      "PythonExecutable" -> pythonExecutable,
      "BackendScript" -> backendScript,
      "Reason" -> "BackendRoundTripMismatch",
      "Message" -> "The FLINT backend test expression did not simplify to the expected result.",
      "DecodedResult" -> decoded,
      "ExpectedResult" -> expected,
      "PythonStdout" -> Lookup[importProcess, "StandardOutput", ""],
      "PythonStderr" -> Lookup[importProcess, "StandardError", ""]
    |>
  ];

  <|
    "ObjectType" -> "BaikovExternalBackendCheck",
    "Available" -> True,
    "PythonExecutable" -> pythonExecutable,
    "BackendScript" -> backendScript,
    "Reason" -> "OK",
    "Message" -> "The external Python/FLINT backend is available.",
    "PythonStdout" -> Lookup[importProcess, "StandardOutput", ""],
    "PythonStderr" -> Lookup[importProcess, "StandardError", ""],
    "DecodedResult" -> decoded,
    "ExpectedResult" -> expected
  |>
];

preprocessTypeIIExpression[expr_, dimSym_] := dropDimensionDependentPowers[expr, dimSym, True];

preprocessTypeIIIExpression[expr_] := FunctionExpand[expr];

elementaryNormalize[expr_, expandQ_: False] := Module[{work},
  work = normalizeNestedSquareRootsInArgument[expr];
  work = FunctionExpand[work];
  If[TrueQ[expandQ], work = Expand[work]];
  work = normalizeHalfIntegerPowersForSimplify[work];
  simplifySquareRoots[work]
];

simplifyElementaryCoefficient[expr_, dimSym_] := Module[
  {prepared, simplified, fallback, normalizedExpr, quick, tail},
  normalizedExpr = elementaryNormalize[expr, False];
  normalizedExpr = normalizeHalfIntegerTerms[normalizedExpr];
  quick = cheapRationalEarlyReturn[normalizedExpr];
  If[quick =!= $Failed, Return[quick]];
  normalizedExpr = Cancel[Together[normalizedExpr]];
  tail = postSimplifySqrtTail[normalizedExpr, dimSym];
  If[pureRationalNoHalfQ[tail], Return[tail]];
  prepared = prepareRationalForExternalSimplifier[normalizedExpr, dimSym];
  If[FailureQ[prepared],
    Return[tail]
  ];
  prepared = Cancel[Together[prepared]];
  quick = cheapRationalEarlyReturn[prepared];
  If[quick =!= $Failed, Return[quick]];
  simplified = externalRationalSimplify[prepared];
  fallback = If[FailureQ[simplified], prepared, simplified];
  fallback = simplifyWithLevel[Cancel[Together[fallback]], True, "Simplify"];
  fallback = normalizeHalfIntegerTerms[fallback];
  quick = cheapRationalEarlyReturn[fallback];
  If[quick =!= $Failed, Return[quick]];
  postSimplifySqrtTail[fallback, dimSym]
];

simplifyByType[rawObject_Association] := Module[
  {type, raw, family, dimSym, work},
  type = rawObject["Type"];
  raw = rawObject["RawCoefficient"];
  family = rawObject["Family"];
  dimSym = family["Input"]["DimensionSymbol"];
  work = Switch[type,
    "Top" | "TypeI",
      raw,
    "TypeII",
      preprocessTypeIIExpression[raw, dimSym],
    "TypeIII",
      preprocessTypeIIIExpression[raw],
    _,
      raw
  ];
  simplifyElementaryCoefficient[work, dimSym]
];

BaikovGF`SimplifyBaikovCoefficient[rawObject_Association] := Module[
  {coefficient, cacheKey},
  If[Lookup[rawObject, "ObjectType", Missing["MissingObjectType"]] =!= "BaikovRawCoefficient",
    Return @ baikovFailure[
      "InvalidRawCoefficientObject",
      "The argument must be a BaikovRawCoefficient object produced by ExtractBaikovCoefficient.",
      <||>
    ]
  ];
  cacheKey = {
    familyObjectCacheKey[rawObject["Family"]],
    rawObject["Type"],
    rawObject["TargetPowers"],
    rawObject["SourcePowers"]
  };
  coefficient = cacheLookupOrCompute[
    $simplifiedCoefficientCache,
    cacheKey,
    simplifyByType[rawObject]
  ];
  <|
    "ObjectType" -> "BaikovCoefficient",
    "Family" -> rawObject["Family"],
    "Type" -> rawObject["Type"],
    "TargetPowers" -> rawObject["TargetPowers"],
    "SourcePowers" -> rawObject["SourcePowers"],
    "Coefficient" -> coefficient
  |>
];

BaikovGF`ExtractBaikovCoefficientBatch[gfObject_Association, sourcePowersList_List] :=
  BaikovGF`ExtractBaikovCoefficient[gfObject, #] & /@ sourcePowersList;

BaikovGF`SimplifyBaikovCoefficientBatch[rawObjectList_List] :=
  BaikovGF`SimplifyBaikovCoefficient /@ rawObjectList;

End[];
EndPackage[];
