scriptPath = ExpandFileName[$InputFileName];
testsDir = DirectoryName[scriptPath];
projectRoot = DirectoryName[testsDir];
examplesDir = FileNameJoin[{projectRoot, "examples"}];
fireRoot = FileNameJoin[{testsDir, "fire_reference_cases"}];

reorderByAux[v_List, auxSlots_List] :=
  If[auxSlots === {}, v, Join[Delete[v, List /@ auxSlots], v[[auxSlots]]]];

placeholderSymbols[n_Integer] := Table["a" <> ToString[i], {i, n}];
underscorePowerLabel[powers_List] := StringRiffle[ToString /@ powers, "_"];
dollarPowerLabel[powers_List] := StringRiffle[ToString /@ powers, "$"];
exprCodeString[expr_] := ToString[InputForm[expr /. BaikovGF`SP -> SP]];

sourceCoefficientFileName[slug_String, sourceOrig_List] :=
  slug <> "__src_" <> underscorePowerLabel[sourceOrig] <> ".wl";

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
  prefix <> "$src$" <> dollarPowerLabel[sourceOrig] <> "$to$" <> dollarPowerLabel[targetOrig];

loadPackageCellCode[] := StringRiffle[
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

setupCellCode[slug_String, spec_Association, sourceOrig_List, targetsOrig_List] := Module[
  {
    auxSlots = Lookup[spec, "AuxiliarySlots", {}],
    allProps = spec["Propagators"],
    explicit,
    auxiliary,
    sourcePkg,
    sourcePlaceholders,
    targetPkgList,
    targetLines,
    sourceVectorCode
  },
  explicit = If[auxSlots === {}, allProps, Delete[allProps, List /@ auxSlots]];
  auxiliary = If[auxSlots === {}, {}, allProps[[auxSlots]]];
  sourcePkg = reorderByAux[sourceOrig, auxSlots];
  sourcePlaceholders = placeholderSymbols[Length[sourcePkg]];
  sourceVectorCode = "{" <> StringRiffle[sourcePlaceholders, ", "] <> "}";
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
        "sourcePowerRule = " <> ToString[InputForm[Thread[ToExpression /@ sourcePlaceholders -> sourcePkg]]] <> ";",
        "",
        "(* Build helper forms of the source powers from sourcePowerRule. *)",
        "sourcePowerVector = " <> sourceVectorCode <> " /. sourcePowerRule;",
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

compareCellCode[prefix_String, sourceOrig_List, targetOrig_List, caseIndex_Integer] := Module[
  {fireName, targetTag},
  fireName = "fireCoeff" <> ToString[caseIndex];
  targetTag = dollarPowerLabel[targetOrig];
  StringRiffle[
    {
      "(* Load the FIRE coefficient definitions for this source powers. *)",
      "Get[fireSourceFile];",
      "",
      "(* Pick the FIRE coefficient for this displayed target. *)",
      fireName <> " = Symbol[\"" <> prefix <> "$src$\" <> sourcePowerVarTag <> \"$to$" <> targetTag <> "\"];",
      "",
      "(* Check that the package result matches the FIRE result analytically. *)",
      "Simplify[Cancel[Together[res" <> ToString[caseIndex] <> "[\"Coefficient\"] - " <> fireName <> "]] == 0]"
    },
    "\n"
  ]
];

buildInputStrings[config_Association, spec_Association, coeffPrefix_String] := Module[
  {sourcePkg, placeholders},
  sourcePkg = reorderByAux[config["Source"], Lookup[spec, "AuxiliarySlots", {}]];
  placeholders = "{" <> StringRiffle[placeholderSymbols[Length[sourcePkg]], ", "] <> "}";
  Join[
    {
      loadPackageCellCode[],
      setupCellCode[config["Slug"], spec, config["Source"], config["Targets"]]
    },
    Flatten @ Table[
      {
        "gf" <> ToString[i] <> " = BuildBaikovGeneratingFunction[family, target" <> ToString[i] <> "];",
        "raw" <> ToString[i] <> " = ExtractBaikovCoefficient[gf" <> ToString[i] <> ", " <> placeholders <> " /. sourcePowerRule];",
        "res" <> ToString[i] <> " = SimplifyBaikovCoefficient[raw" <> ToString[i] <> "];",
        compareCellCode[coeffPrefix, config["Source"], config["Targets"][[i]], i]
      },
      {i, Length[config["Targets"]]}
    ]
  ]
];

replaceInputCells[cells_List, replacements_List] := Module[
  {counter = 0},
  cells /. cell : Cell[_, "Input", rest___] :> Module[{text},
    counter++;
    text = replacements[[counter]];
    Cell[text, "Input", rest]
  ]
];

parseNotebookFile[path_String] := Module[{text, pos, held},
  text = Import[path, "Text"];
  pos = StringPosition[text, "Notebook[", 1];
  If[pos === {}, Return[$Failed]];
  held = ToExpression[StringDrop[text, pos[[1, 1]] - 1], InputForm, HoldComplete];
  If[Head[held] =!= HoldComplete || Length[held] < 1, Return[$Failed]];
  held[[1]]
];

rewriteNotebookInputs[path_String, replacements_List] := Module[
  {nb, cells, opts, expectedInputs, actualInputs, newCells, newNb},
  nb = parseNotebookFile[path];
  If[nb === $Failed || Head[nb] =!= Notebook, Return[$Failed]];
  cells = nb[[1]];
  opts = Rest[List @@ nb];
  expectedInputs = Length[replacements];
  actualInputs = Count[cells, Cell[_, "Input", ___], Infinity];
  If[expectedInputs =!= actualInputs, Return[<|"ExpectedInputs" -> expectedInputs, "ActualInputs" -> actualInputs|>]];
  newCells = replaceInputCells[cells, replacements];
  newNb = Notebook[newCells, Sequence @@ opts];
  Put[newNb, path];
  True
];

exampleConfigs = {
  <|"Slug" -> "tadpole", "Notebook" -> "tadpole_demo.nb", "Source" -> {8}, "Targets" -> {{1}}|>,
  <|"Slug" -> "hq_triangle_1loop", "Notebook" -> "hq_triangle_1loop_demo.nb", "Source" -> {3, 3, 3}, "Targets" -> {{1, 1, 1}, {1, 1, 0}}|>,
  <|"Slug" -> "vacuum_2loop", "Notebook" -> "vacuum_2loop_demo.nb", "Source" -> {2, 2, 3}, "Targets" -> {{1, 1, 1}, {1, 1, 0}}|>,
  <|"Slug" -> "vacuum_3loop", "Notebook" -> "vacuum_3loop_demo.nb", "Source" -> {2, 2, 2, 2, 2, 2}, "Targets" -> {{1, 1, 1, 1, 1, 1}, {0, 1, 1, 1, 1, 1}, {1, 1, 1, 0, 1, 1}}|>,
  <|"Slug" -> "sunset_4prop", "Notebook" -> "sunset_4prop_demo.nb", "Source" -> {3, 0, 3, 4, 4}, "Targets" -> {{1, 0, 1, 1, 1}}|>,
  <|"Slug" -> "self_energy_3loop_1ext", "Notebook" -> "self_energy_3loop_1ext_demo.nb", "Source" -> {1, 1, 2, 0, 2, 2, 2, 2, 2}, "Targets" -> {{1, 1, 1, 0, 1, 1, 1, 1, 1}}|>,
  <|"Slug" -> "sunset_cut_vertical", "Notebook" -> "sunset_cut_vertical_demo.nb", "Source" -> {2, 2, 2, 2, 3}, "Targets" -> {{1, 1, 1, 1, 0}}|>,
  <|"Slug" -> "hq_potential_2loop", "Notebook" -> "hq_potential_2loop_demo.nb", "Source" -> {2, 2, 2, 2, 2, 2, 1}, "Targets" -> {{1, 1, 1, 1, 0, 1, 1}}|>
};

results = Association[];

Do[
  Module[{slug, spec, coeffFile, coeffPrefix, replacements, notebookPath, status},
    slug = config["Slug"];
    spec = Get[FileNameJoin[{fireRoot, slug, slug <> "_family.wl"}]];
    coeffFile = FileNameJoin[{fireRoot, slug, "coefficients", sourceCoefficientFileName[slug, config["Source"]]}];
    coeffPrefix = coefficientPrefixFromFile[coeffFile];
    replacements = buildInputStrings[config, spec, coeffPrefix];
    notebookPath = FileNameJoin[{examplesDir, config["Notebook"]}];
    status = rewriteNotebookInputs[notebookPath, replacements];
    results[slug] = status;
  ],
  {config, exampleConfigs}
];

Print[results // InputForm];
