(* ::Package:: *)

scriptPath = ExpandFileName[$InputFileName];
testsDir = DirectoryName[scriptPath];
projectRoot = DirectoryName[testsDir];
packagePath = FileNameJoin[{projectRoot, "BaikovGF", "BaikovGF.wl"}];
examplesDir = FileNameJoin[{projectRoot, "examples"}];
fireRoot = FileNameJoin[{testsDir, "fire_reference_cases"}];

If[!FileExistsQ[packagePath],
  Print["Package file not found: " <> packagePath];
  Exit[1];
];

Get[packagePath];

SetAttributes[inputCell, HoldAll];
inputCell[expr_] := Cell[BoxData @ ToBoxes[Unevaluated[expr]], "Input"];
outputCell[expr_] := Cell[BoxData @ ToBoxes[expr], "Output"];

heldInputCell[code_String] := Module[{held},
  held = ToExpression[code, InputForm, HoldComplete];
  Replace[held, HoldComplete[expr_] :> inputCell[expr]]
];

placeholderSymbols[n_Integer] := Array[Symbol["a" <> ToString[#]] &, n];

reorderByAux[v_List, auxSlots_List] :=
  If[auxSlots === {}, v, Join[Delete[v, List /@ auxSlots], v[[auxSlots]]]];

toOriginalFromPackageCode[varName_String, totalCount_Integer, auxSlots_List] := Module[
  {explicitSlots},
  explicitSlots = Complement[Range[totalCount], auxSlots];
  StringRiffle[
    {
      "toOriginalPowerOrder[v_List] := Module[{res = ConstantArray[0, " <> ToString[totalCount] <> "]},",
      "  res[[" <> ToString[InputForm[explicitSlots]] <> "]] = Take[v, " <> ToString[Length[explicitSlots]] <> "];",
      "  res[[" <> ToString[InputForm[auxSlots]] <> "]] = Take[v, -" <> ToString[Length[auxSlots]] <> "];",
      "  res",
      "];",
      "",
      varName <> " = toOriginalPowerOrder[" <> varName <> "Package];"
    },
    "\n"
  ]
];

sourceCoefficientFileName[slug_String, sourceOrig_List] :=
  slug <> "__src_" <> StringRiffle[ToString /@ sourceOrig, "_"] <> ".wl";

coefficientPrefixFromFile[path_String] := Module[{text, matches},
  text = Import[path, "Text"];
  matches = StringCases[
    text,
    StartOfString ~~ prefix : (LetterCharacter ~~ (WordCharacter | "$") ..) ~~ "$src$" :> prefix,
    1
  ];
  If[matches === {}, Missing["PrefixNotFound"], First[matches]]
];

fireVariableName[prefix_String, sourceOrig_List, targetOrig_List] :=
  prefix <> "$src$" <> StringRiffle[ToString /@ sourceOrig, "$"] <> "$to$" <> StringRiffle[ToString /@ targetOrig, "$"];

buildFamilyFromSpec[spec_Association] := Module[{allProps, auxSlots, explicit, auxiliary},
  allProps = spec["Propagators"];
  auxSlots = Lookup[spec, "AuxiliarySlots", {}];
  explicit = If[auxSlots === {}, allProps, Delete[allProps, List /@ auxSlots]];
  auxiliary = If[auxSlots === {}, {}, allProps[[auxSlots]]];
  CreateFeynmanIntegral[
    "LoopMomenta" -> spec["LoopMomenta"],
    "ExternalMomenta" -> spec["ExternalMomenta"],
    "Propagators" -> explicit,
    "AuxiliaryPropagators" -> auxiliary,
    "KinematicRules" -> spec["KinematicRules"],
    "DimensionSymbol" -> d
  ]
];

exprCodeString[expr_] := ToString[InputForm[expr /. BaikovGF`SP -> SP]];

extractDisplayTNames[expr_] := SortBy[
  DeleteDuplicates @ Cases[
    HoldComplete[expr],
    s_Symbol /; StringMatchQ[SymbolName[s], "t$" ~~ DigitCharacter ..],
    Infinity
  ],
  ToExpression[StringDrop[SymbolName[#], 2]] &
];

mappingPropagatorsForType[family_Association, type_String] := Module[
  {explicit, auxiliary},
  explicit = family["Input"]["Propagators"];
  auxiliary = family["Input"]["AuxiliaryPropagators"];
  If[type === "TypeI", explicit, Join[explicit, auxiliary]]
];

mappingCellTextForGF[family_Association, type_String, expr_] := Module[
  {tNames, props, lines, pairCount},
  tNames = SymbolName /@ extractDisplayTNames[expr];
  props = mappingPropagatorsForType[family, type];
  pairCount = Min[Length[tNames], Length[props]];
  lines = Join[
    {"t-variable mapping for the generating function above:"},
    Table[
      tNames[[i]] <> " <-> D" <> ToString[i] <> " = " <> exprCodeString[props[[i]]],
      {i, pairCount}
    ]
  ];
  If[type === "TypeI" && family["Input"]["AuxiliaryPropagators"] =!= {},
    lines = Join[lines, {"", "Only the explicit propagators carry t-variables in this TypeI generating function."}]
  ];
  If[Length[tNames] =!= Length[props],
    lines = Join[lines, {"", "Warning: the number of displayed t-variables does not match the expected propagator count."}]
  ];
  StringRiffle[lines, "\n"]
];

loadPackageCode[] := StringRiffle[
  {
    "Get[FileNameJoin[{DirectoryName@NotebookDirectory[], \"BaikovGF\", \"BaikovGF.wl\"}]];",
    "",
    "Needs[\"BaikovGF`\"];"
  },
  "\n"
];

familyCommentString[spec_Association, explicit_List, auxiliary_List] := Module[
  {auxText},
  auxText = If[
    auxiliary === {},
    "no auxiliary propagators",
    "auxiliary propagators " <> exprCodeString[auxiliary]
  ];
  "(* Build the Feynman-integral family object with loop momenta " <>
    exprCodeString[spec["LoopMomenta"]] <>
    ", external momenta " <>
    exprCodeString[spec["ExternalMomenta"]] <>
    ", explicit propagators " <>
    exprCodeString[explicit] <>
    ", " <> auxText <>
    ", kinematic rules " <>
    exprCodeString[spec["KinematicRules"]] <>
    ", and dimension symbol d. *)"
];

buildSetupCode[slug_String, spec_Association, sourceOrig_List, targetsOrig_List] := Module[
  {
    auxSlots = Lookup[spec, "AuxiliarySlots", {}],
    allProps = spec["Propagators"],
    explicit,
    auxiliary,
    sourcePkg,
    sourcePlaceholders,
    targetPkgList,
    targetLines,
    setupLines
  },
  explicit = If[auxSlots === {}, allProps, Delete[allProps, List /@ auxSlots]];
  auxiliary = If[auxSlots === {}, {}, allProps[[auxSlots]]];
  sourcePkg = reorderByAux[sourceOrig, auxSlots];
  sourcePlaceholders = placeholderSymbols[Length[sourcePkg]];
  targetPkgList = reorderByAux[#, auxSlots] & /@ targetsOrig;

  targetLines = Flatten @ Table[
    {
      "(* Set the powers for target" <> ToString[i] <> ". *)",
      "target" <> ToString[i] <> " = " <> ToString[InputForm[targetPkgList[[i]]]] <> ";",
      ""
    },
    {i, Length[targetPkgList]}
  ];

  setupLines = Join[
    {
      "(* Fix the numeric source powers used in this example. *)",
      "sourcePowerRule = " <> ToString[InputForm[Thread[sourcePlaceholders -> sourcePkg]]] <> ";",
      "",
      "(* Build helper forms of the source powers from sourcePowerRule. *)",
      "sourcePowerVectorPackage = " <> ToString[InputForm[sourcePlaceholders]] <> " /. sourcePowerRule;"
    },
    If[
      auxSlots === {},
      {
        "sourcePowerVector = sourcePowerVectorPackage;"
      },
      {
        "(* Convert the source powers from package order back to the original FIRE order. *)",
        toOriginalFromPackageCode["sourcePowerVector", Length[allProps], auxSlots]
      }
    ],
    {
      "sourcePowerFileTag = StringRiffle[ToString /@ sourcePowerVector, \"_\"];",
      "sourcePowerVarTag = StringRiffle[ToString /@ sourcePowerVector, \"$\"];",
      ""
    },
    targetLines,
    {
      familyCommentString[spec, explicit, auxiliary],
      "family = CreateFeynmanIntegral[",
      "  \"LoopMomenta\" -> " <> exprCodeString[spec["LoopMomenta"]] <> ",",
      "  \"ExternalMomenta\" -> " <> exprCodeString[spec["ExternalMomenta"]] <> ",",
      "  \"Propagators\" -> " <> exprCodeString[explicit] <> ",",
      "  \"AuxiliaryPropagators\" -> " <> exprCodeString[auxiliary] <> ",",
      "  \"KinematicRules\" -> " <> exprCodeString[spec["KinematicRules"]] <> ",",
      "  \"DimensionSymbol\" -> d",
      "];",
      "",
      "(* Point to the FIRE coefficient file for this source powers. *)",
      "fireSourceFile = FileNameJoin[{DirectoryName@NotebookDirectory[], \"tests\", \"fire_reference_cases\", \"" <> slug <> "\", \"coefficients\", \"" <> slug <> "__src_\" <> sourcePowerFileTag <> \".wl\"}];"
    }
  ];

  StringRiffle[setupLines, "\n"]
];

targetSectionLabel[typesSeen_Association, type_String, targetPkg_List] := Module[{count, newSeen},
  count = Lookup[typesSeen, type, 0] + 1;
  newSeen = Association[typesSeen, type -> count];
  {
    newSeen,
    Switch[type,
      "Top",
        "Top Target " <> ToString[InputForm[targetPkg]],
      _ /; count == 1,
        "Representative " <> type <> " Target " <> ToString[InputForm[targetPkg]],
      _,
        "Representative " <> type <> " Target " <> ToString[count] <> " " <> ToString[InputForm[targetPkg]]
    ]
  }
];

runCase[family_Association, slug_String, sourceOrig_List, targetOrig_List, auxSlots_List, coeffPrefix_String] := Module[
  {
    sourcePkg,
    targetPkg,
    gf,
    raw,
    res,
    coeffFile,
    fireCoeff,
    compare,
    type,
    currentGF,
    tBuild,
    tExtract,
    tSimplify,
    tCompare
  },
  sourcePkg = reorderByAux[sourceOrig, auxSlots];
  targetPkg = reorderByAux[targetOrig, auxSlots];
  coeffFile = FileNameJoin[{fireRoot, slug, "coefficients", sourceCoefficientFileName[slug, sourceOrig]}];

  tBuild = AbsoluteTiming[gf = BuildBaikovGeneratingFunction[family, targetPkg];][[1]];
  type = Lookup[gf, "Type", ""];
  currentGF = gf["GeneratingFunctions"]["Current"];
  tExtract = AbsoluteTiming[raw = ExtractBaikovCoefficient[gf, sourcePkg];][[1]];
  tSimplify = AbsoluteTiming[res = SimplifyBaikovCoefficient[raw];][[1]];
  tCompare = AbsoluteTiming[
    Get[coeffFile];
    fireCoeff = Symbol[fireVariableName[coeffPrefix, sourceOrig, targetOrig]];
    compare = Quiet @ Simplify[Cancel[Together[res["Coefficient"] - fireCoeff]] == 0];
  ][[1]];

  <|
    "TargetOriginal" -> targetOrig,
    "TargetPackage" -> targetPkg,
    "Type" -> type,
    "CurrentGF" -> currentGF,
    "MappingCellText" -> mappingCellTextForGF[family, type, currentGF],
    "Comparison" -> compare,
    "Times" -> <|
      "Build" -> tBuild,
      "Extract" -> tExtract,
      "Simplify" -> tSimplify,
      "Compare" -> tCompare
    |>,
    "FireVariableName" -> fireVariableName[coeffPrefix, sourceOrig, targetOrig]
  |>
];

buildCaseCells[result_Association, caseIndex_Integer, typesSeen_Association, sourcePlaceholderCode_String] := Module[
  {
    type = result["Type"],
    targetPkg = result["TargetPackage"],
    targetLabel,
    buildText,
    targetName = "target" <> ToString[caseIndex],
    gfName = "gf" <> ToString[caseIndex],
    rawName = "raw" <> ToString[caseIndex],
    resName = "res" <> ToString[caseIndex],
    fireName = "fireCoeff" <> ToString[caseIndex],
    buildCode,
    extractCode,
    simplifyCode,
    compareCode,
    mappingCellText = result["MappingCellText"],
    fireVariableCode = result["FireVariableName"],
    updatedSeen
  },

  {updatedSeen, targetLabel} = targetSectionLabel[typesSeen, type, targetPkg];
  buildText = If[
    type === "Top",
    "This step builds the generating function for the top target and returns the runtime.",
    "This step builds the generating function for a representative " <> type <> " target and returns the runtime."
  ];

  buildCode = StringRiffle[
    {
      "{tBuild" <> ToString[caseIndex] <> ", " <> gfName <> "} = BuildBaikovGeneratingFunction[family, " <> targetName <> "] // AbsoluteTiming;",
      "tBuild" <> ToString[caseIndex]
    },
    "\n"
  ];

  extractCode = StringRiffle[
    {
      "{tExtract" <> ToString[caseIndex] <> ", " <> rawName <> "} = ExtractBaikovCoefficient[" <> gfName <> ", " <> sourcePlaceholderCode <> " /. sourcePowerRule] // AbsoluteTiming;",
      "tExtract" <> ToString[caseIndex]
    },
    "\n"
  ];

  simplifyCode = StringRiffle[
    {
      "{tSimplify" <> ToString[caseIndex] <> ", " <> resName <> "} = SimplifyBaikovCoefficient[" <> rawName <> "] // AbsoluteTiming;",
      "tSimplify" <> ToString[caseIndex]
    },
    "\n"
  ];

  compareCode = StringRiffle[
    {
      "{tCompare" <> ToString[caseIndex] <> ", compare" <> ToString[caseIndex] <> "} = (",
      "  Get[fireSourceFile];",
      "  " <> fireName <> " = Symbol[\"" <> First[StringSplit[fireVariableCode, "$src$"]] <> "$src$\" <> sourcePowerVarTag <> \"$to$" <> StringSplit[fireVariableCode, "$to$"][[2]] <> "\"];",
      "  Simplify[Cancel[Together[" <> resName <> "[\"Coefficient\"] - " <> fireName <> "]] == 0]",
      ") // AbsoluteTiming;",
      "<|\"Time\" -> tCompare" <> ToString[caseIndex] <> ", \"MatchQ\" -> compare" <> ToString[caseIndex] <> "|>"
    },
    "\n"
  ];

  {
    updatedSeen,
    {
      Cell[targetLabel, "Section"],
      Cell[buildText, "Text"],
      heldInputCell[buildCode],
      outputCell[result["Times"]["Build"]],
      Cell[mappingCellText, "Text"],
      Cell["This step extracts the unsimplified coefficient and returns the runtime.", "Text"],
      heldInputCell[extractCode],
      outputCell[result["Times"]["Extract"]],
      Cell["This step simplifies the extracted coefficient and returns the runtime.", "Text"],
      heldInputCell[simplifyCode],
      outputCell[result["Times"]["Simplify"]],
      Cell["Compare to FIRE", "Subsection"],
      heldInputCell[compareCode],
      outputCell[<|"Time" -> result["Times"]["Compare"], "MatchQ" -> result["Comparison"]|>]
    }
  }
];

makeNotebook[config_Association, spec_Association, results_List] := Module[
  {typesSeen = <||>, setupCode, caseData, caseCells = {}, auxSlots, sourcePkg, sourcePlaceholders, sourcePlaceholderCode},
  auxSlots = Lookup[spec, "AuxiliarySlots", {}];
  sourcePkg = reorderByAux[config["Source"], auxSlots];
  sourcePlaceholders = placeholderSymbols[Length[sourcePkg]];
  sourcePlaceholderCode = ToString[InputForm[sourcePlaceholders]];
  setupCode = buildSetupCode[config["Slug"], spec, config["Source"], config["Targets"]];

  Do[
    caseData = buildCaseCells[results[[i]], i, typesSeen, sourcePlaceholderCode];
    typesSeen = caseData[[1]];
    caseCells = Join[caseCells, caseData[[2]]];
    ,
    {i, Length[results]}
  ];

  Notebook[
    Join[
      {
        Cell[config["Title"], "Title"],
        Cell["Load Package", "Section"],
        Cell["This step loads the package and exposes the public interface used below.", "Text"],
        heldInputCell[loadPackageCode[]],
        Cell["Setup", "Section"],
        Cell["This step fixes the source-power rule, target powers, and integral-family object for the example.", "Text"],
        heldInputCell[setupCode]
      },
      caseCells
    ],
    StyleDefinitions -> "Default.nb",
    WindowTitle -> config["Title"],
    Magnification :> 1.1 Inherited
  ]
];

exampleConfigs = {
  <|"Slug" -> "hq_triangle_1loop", "Notebook" -> "hq_triangle_1loop_demo.nb", "Title" -> "Example: HQ Triangle (One Loop)", "Source" -> {3, 3, 3}, "Targets" -> {{1, 1, 1}, {1, 1, 0}}|>,
  <|"Slug" -> "vacuum_2loop", "Notebook" -> "vacuum_2loop_demo.nb", "Title" -> "Example: Two-Loop Vacuum", "Source" -> {2, 2, 3}, "Targets" -> {{1, 1, 1}, {1, 1, 0}}|>,
  <|"Slug" -> "vacuum_3loop", "Notebook" -> "vacuum_3loop_demo.nb", "Title" -> "Example: Three-Loop Vacuum", "Source" -> {2, 2, 2, 2, 2, 2}, "Targets" -> {{1, 1, 1, 1, 1, 1}, {0, 1, 1, 1, 1, 1}, {1, 1, 1, 0, 1, 1}}|>,
  <|"Slug" -> "sunset_4prop", "Notebook" -> "sunset_4prop_demo.nb", "Title" -> "Example: Sunset 4-Propagator Family", "Source" -> {3, 0, 3, 4, 4}, "Targets" -> {{1, 0, 1, 1, 1}}|>,
  <|"Slug" -> "self_energy_3loop_1ext", "Notebook" -> "self_energy_3loop_1ext_demo.nb", "Title" -> "Example: Three-Loop Self-Energy (One External Momentum)", "Source" -> {1, 1, 2, 0, 2, 2, 2, 2, 2}, "Targets" -> {{1, 1, 1, 0, 1, 1, 1, 1, 1}}|>,
  <|"Slug" -> "sunset_cut_vertical", "Notebook" -> "sunset_cut_vertical_demo.nb", "Title" -> "Example: Vertical Sunset Cut", "Source" -> {2, 2, 2, 2, 3}, "Targets" -> {{1, 1, 1, 1, 0}}|>,
  <|"Slug" -> "hq_potential_2loop", "Notebook" -> "hq_potential_2loop_demo.nb", "Title" -> "Example: HQ Potential (Two Loop)", "Source" -> {2, 2, 2, 2, 2, 2, 1}, "Targets" -> {{1, 1, 1, 1, 0, 1, 1}}|>,
  <|"Slug" -> "tadpole", "Notebook" -> "tadpole_demo.nb", "Title" -> "Example: Tadpole", "Source" -> {8}, "Targets" -> {{1}}|>
};

allStatuses = Association[];

Do[
  Module[{slug, spec, auxSlots, family, coeffFile, coeffPrefix, results, notebook, notebookPath},
    slug = config["Slug"];
    Print["Generating notebook for " <> slug <> " ..."];
    spec = Get[FileNameJoin[{fireRoot, slug, slug <> "_family.wl"}]];
    auxSlots = Lookup[spec, "AuxiliarySlots", {}];
    family = buildFamilyFromSpec[spec];
    coeffFile = FileNameJoin[{fireRoot, slug, "coefficients", sourceCoefficientFileName[slug, config["Source"]]}];
    coeffPrefix = coefficientPrefixFromFile[coeffFile];
    If[MissingQ[coeffPrefix],
      Print["Could not determine FIRE coefficient prefix from " <> coeffFile];
      Exit[1];
    ];
    results = runCase[family, slug, config["Source"], #, auxSlots, coeffPrefix] & /@ config["Targets"];
    If[!And @@ (TrueQ /@ Lookup[results, "Comparison"]),
      Print["Verification failed for " <> slug];
      Print[Select[results, TrueQ[Lookup[#, "Comparison"]] === False &] // InputForm];
      Exit[1];
    ];
    notebook = makeNotebook[config, spec, results];
    notebookPath = FileNameJoin[{examplesDir, config["Notebook"]}];
    Export[notebookPath, notebook];
    allStatuses[slug] = <|
      "Notebook" -> config["Notebook"],
      "Source" -> config["Source"],
      "Targets" -> config["Targets"],
      "PackageTargets" -> Lookup[results, "TargetPackage"],
      "Times" -> Lookup[results, "Times"],
      "AllMatched" -> True
    |>;
    Print["  -> wrote " <> notebookPath];
  ],
  {config, exampleConfigs}
];

Print["All requested example notebooks generated and verified."];
Print[allStatuses // InputForm];
