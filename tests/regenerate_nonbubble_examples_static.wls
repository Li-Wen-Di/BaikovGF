(* ::Package:: *)

scriptPath = ExpandFileName[$InputFileName];
testsDir = DirectoryName[scriptPath];
projectRoot = DirectoryName[testsDir];
examplesDir = FileNameJoin[{projectRoot, "examples"}];
fireRoot = FileNameJoin[{testsDir, "fire_reference_cases"}];
packagePath = FileNameJoin[{projectRoot, "BaikovGF", "BaikovGF.wl"}];

If[!FileExistsQ[packagePath],
  Print["Package file not found: " <> packagePath];
  Exit[1];
];

Get[packagePath];

ClearAll[
  textCell,
  sectionCell,
  subsectionCell,
  titleCell,
  inputStringCell,
  outputCell,
  exprCodeString,
  placeholderSymbols,
  reorderByAux,
  toOriginalFromPackageCode,
  sourceCoefficientFileName,
  splitExplicitAuxiliary,
  familyCommentString,
  buildSetupCode,
  buildTargetCode,
  mappingTextForGF,
  targetSectionLabel,
  buildNotebook
];

textCell[str_String] := Cell[str, "Text"];
sectionCell[str_String] := Cell[str, "Section"];
subsectionCell[str_String] := Cell[str, "Subsection"];
titleCell[str_String] := Cell[str, "Title"];
inputStringCell[str_String] := Cell[str, "Input"];
outputCell[expr_] := Cell[BoxData @ ToBoxes[expr], "Output"];

exprCodeString[expr_] := ToString[InputForm[expr /. HoldPattern[BaikovGF`SP] -> SP]];

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

splitExplicitAuxiliary[allProps_List, auxSlots_List] := <|
  "Explicit" -> If[auxSlots === {}, allProps, Delete[allProps, List /@ auxSlots]],
  "Auxiliary" -> If[auxSlots === {}, {}, allProps[[auxSlots]]]
|>;

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
    split,
    explicit,
    auxiliary,
    sourcePkg,
    sourcePlaceholders,
    targetPkgList,
    targetLines
  },
  split = splitExplicitAuxiliary[allProps, auxSlots];
  explicit = split["Explicit"];
  auxiliary = split["Auxiliary"];
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

  StringRiffle[
    Join[
      {
        "(* Fix the numeric source powers used in this example. *)",
        "sourcePowerRule = " <> ToString[InputForm[Thread[sourcePlaceholders -> sourcePkg]]] <> ";",
        "",
        "(* Build helper forms of the source powers from sourcePowerRule. *)",
        "sourcePowerVectorPackage = " <> ToString[InputForm[sourcePlaceholders]] <> " /. sourcePowerRule;"
      },
      If[
        auxSlots === {},
        {"sourcePowerVector = sourcePowerVectorPackage;"},
        {toOriginalFromPackageCode["sourcePowerVector", Length[allProps], auxSlots]}
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
    ],
    "\n"
  ]
];

targetSectionLabel[targetPkg_List, paperType_String] :=
  If[
    targetPkg === ConstantArray[1, Length[targetPkg]],
    "Top Target " <> ToString[InputForm[targetPkg]],
    "Representative " <> paperType <> " Target " <> ToString[InputForm[targetPkg]]
  ];

buildTargetCode[symbolBase_String, targetOrig_List, index_Integer] := Module[
  {
    typeSuffix
  },
  typeSuffix = "$to$" <> StringRiffle[ToString /@ targetOrig, "$"];
  <|
    "BuildCode" -> StringRiffle[
      {
        "{tBuild" <> ToString[index] <> ", gf" <> ToString[index] <> "} = BuildBaikovGeneratingFunction[family, target" <> ToString[index] <> "] // AbsoluteTiming;",
        "tBuild" <> ToString[index]
      },
      "\n"
    ],
    "ExtractCode" -> StringRiffle[
      {
        "{tExtract" <> ToString[index] <> ", raw" <> ToString[index] <> "} = ExtractBaikovCoefficient[gf" <> ToString[index] <> ", sourcePowerVectorPackage] // AbsoluteTiming;",
        "tExtract" <> ToString[index]
      },
      "\n"
    ],
    "SimplifyCode" -> StringRiffle[
      {
        "{tSimplify" <> ToString[index] <> ", res" <> ToString[index] <> "} = SimplifyBaikovCoefficient[raw" <> ToString[index] <> "] // AbsoluteTiming;",
        "tSimplify" <> ToString[index]
      },
      "\n"
    ],
    "CompareCode" -> StringRiffle[
      {
        "{tCompare" <> ToString[index] <> ", compare" <> ToString[index] <> "} = (",
        "  Get[fireSourceFile];",
        "  fireCoeff" <> ToString[index] <> " = Symbol[\"" <> symbolBase <> "$src$\" <> sourcePowerVarTag <> \"" <> typeSuffix <> "\"];",
        "  Simplify[Cancel[Together[res" <> ToString[index] <> "[\"Coefficient\"] - fireCoeff" <> ToString[index] <> "]] == 0]",
        ") // AbsoluteTiming;",
        "<|\"Time\" -> tCompare" <> ToString[index] <> ", \"MatchQ\" -> compare" <> ToString[index] <> "|>"
      },
      "\n"
    ]
  |>
];

mappingTextForGF[family_Association, gf_Association] := Module[
  {activeTVars, props, pairCount, lines},
  activeTVars = gf["Internal", "FamilyData", "ActiveTVariables"];
  props = If[
    gf["Type"] === "TypeI",
    family["Input", "Propagators"],
    Join[family["Input", "Propagators"], family["Input", "AuxiliaryPropagators"]]
  ];
  pairCount = Min[Length[activeTVars], Length[props]];
  lines = Table[
    SymbolName[activeTVars[[i]]] <> " <-> D" <> ToString[i] <> " = " <>
      ToString[InputForm[props[[i]] /. BaikovGF`SP -> SP]],
    {i, pairCount}
  ];
  StringRiffle[lines, "\n"]
];

buildNotebook[config_Association, spec_Association] := Module[
  {
    slug = config["Slug"],
    sourceOrig = config["Source"],
    targetsOrig = config["Targets"],
    auxSlots = Lookup[spec, "AuxiliarySlots", {}],
    allProps = spec["Propagators"],
    split,
    explicit,
    auxiliary,
    sourcePkg,
    sourcePlaceholders,
    sourcePowerRule,
    sourcePowerVectorPackage,
    sourcePowerVector,
    sourcePowerFileTag,
    sourcePowerVarTag,
    fireSourceFile,
    familyRuntime,
    targetsPkg,
    setupCode,
    paperType,
    symbolBase,
    cells,
    targetData,
    targetLabel,
    targetOrig,
    targetPkg,
    typeSuffix,
    tBuild,
    gf,
    mappingText,
    tExtract,
    raw,
    tSimplify,
    res,
    tCompare,
    compare,
    fireCoeff
  },
  split = splitExplicitAuxiliary[allProps, auxSlots];
  explicit = split["Explicit"];
  auxiliary = split["Auxiliary"];
  sourcePkg = reorderByAux[sourceOrig, auxSlots];
  sourcePlaceholders = placeholderSymbols[Length[sourcePkg]];
  sourcePowerRule = Thread[sourcePlaceholders -> sourcePkg];
  sourcePowerVectorPackage = sourcePlaceholders /. sourcePowerRule;
  sourcePowerVector = sourceOrig;
  sourcePowerFileTag = StringRiffle[ToString /@ sourcePowerVector, "_"];
  sourcePowerVarTag = StringRiffle[ToString /@ sourcePowerVector, "$"];
  fireSourceFile = FileNameJoin[{fireRoot, slug, "coefficients", sourceCoefficientFileName[slug, sourcePowerVector]}];
  familyRuntime = BaikovGF`CreateFeynmanIntegral[
    "LoopMomenta" -> spec["LoopMomenta"],
    "ExternalMomenta" -> spec["ExternalMomenta"],
    "Propagators" -> explicit,
    "AuxiliaryPropagators" -> auxiliary,
    "KinematicRules" -> spec["KinematicRules"],
    "DimensionSymbol" -> d
  ];
  targetsPkg = reorderByAux[#, auxSlots] & /@ targetsOrig;
  setupCode = buildSetupCode[slug, spec, sourceOrig, targetsOrig];
  paperType = Lookup[spec, "PaperType", "Target"];
  symbolBase = Lookup[spec, "SymbolBase", slug];

  cells = {
    titleCell[config["Title"]],
    sectionCell["Load Package"],
    textCell["This step loads the package and exposes the public interface used below."],
    inputStringCell[
      StringRiffle[
        {
          "Get[FileNameJoin[{DirectoryName@NotebookDirectory[], \"BaikovGF\", \"BaikovGF.wl\"}]];",
          "",
          "Needs[\"BaikovGF`\"];"
        },
        "\n"
      ]
    ],
    sectionCell["Setup"],
    textCell["This step fixes the source-power rule, target powers, and integral-family object for the example."],
    inputStringCell[setupCode]
  };

  Do[
    targetOrig = targetsOrig[[i]];
    targetPkg = targetsPkg[[i]];
    targetData = buildTargetCode[symbolBase, targetsOrig[[i]], i];
    targetLabel = targetSectionLabel[targetPkg, paperType];
    typeSuffix = "$to$" <> StringRiffle[ToString /@ targetOrig, "$"];
    tBuild = AbsoluteTiming[gf = BaikovGF`BuildBaikovGeneratingFunction[familyRuntime, targetPkg];][[1]];
    mappingText = mappingTextForGF[familyRuntime, gf];
    tExtract = AbsoluteTiming[raw = BaikovGF`ExtractBaikovCoefficient[gf, sourcePowerVectorPackage];][[1]];
    tSimplify = AbsoluteTiming[res = BaikovGF`SimplifyBaikovCoefficient[raw];][[1]];
    tCompare = AbsoluteTiming[
      Get[fireSourceFile];
      fireCoeff = Symbol[symbolBase <> "$src$" <> sourcePowerVarTag <> typeSuffix];
      compare = Simplify[Cancel[Together[res["Coefficient"] - fireCoeff]] == 0];
    ][[1]];
    If[!TrueQ[compare],
      Print["Verification failed for " <> slug <> " target " <> ToString[InputForm[targetOrig]]];
      Print[<|"Slug" -> slug, "Target" -> targetOrig, "MatchQ" -> compare|> // InputForm];
      Exit[1];
    ];
    cells = Join[
      cells,
      {
        Cell[targetLabel, "Section"],
        textCell["This step builds the generating-function object for the selected target and returns the runtime after evaluation."],
        inputStringCell[targetData["BuildCode"]],
        outputCell[tBuild],
        textCell[mappingText],
        textCell["This step extracts the unsimplified coefficient and returns the runtime after evaluation."],
        inputStringCell[targetData["ExtractCode"]],
        outputCell[tExtract],
        textCell["This step simplifies the extracted coefficient and returns the runtime after evaluation."],
        inputStringCell[targetData["SimplifyCode"]],
        outputCell[tSimplify],
        subsectionCell["Compare to FIRE"],
        inputStringCell[targetData["CompareCode"]],
        outputCell[<|"Time" -> tCompare, "MatchQ" -> compare|>]
      }
    ],
    {i, Length[targetsOrig]}
  ];

  Notebook[
    cells,
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

Do[
  Module[{slug, spec, notebook, notebookPath},
    slug = config["Slug"];
    spec = Get[FileNameJoin[{fireRoot, slug, slug <> "_family.wl"}]];
    notebook = buildNotebook[config, spec];
    notebookPath = FileNameJoin[{examplesDir, config["Notebook"]}];
    Export[notebookPath, notebook];
    Print["Wrote " <> notebookPath];
  ],
  {config, exampleConfigs}
];

Print["Finished regenerating non-bubble example notebooks with outputs."];
