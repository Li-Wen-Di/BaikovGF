scriptPath = ExpandFileName[$InputFileName];
testsDir = DirectoryName[scriptPath];
projectRoot = DirectoryName[testsDir];
examplesDir = FileNameJoin[{projectRoot, "examples"}];
fireRoot = FileNameJoin[{testsDir, "fire_reference_cases"}];

reorderByAux[v_List, auxSlots_List] :=
  If[auxSlots === {}, v, Join[Delete[v, List /@ auxSlots], v[[auxSlots]]]];

exprCodeString[expr_] := ToString[InputForm[expr /. BaikovGF`SP -> SP]];

determineTargetType[targetPkg_List, nExp_Integer, nAux_Integer] := Module[
  {nTotal = Length[targetPkg], topPattern, typeIPattern},
  topPattern = ConstantArray[1, nTotal];
  typeIPattern = Join[ConstantArray[1, nExp], ConstantArray[0, nAux]];
  Which[
    nAux == 1 && targetPkg === typeIPattern, "TypeI",
    nAux == 0 && targetPkg === topPattern, "Top",
    nAux == 0 && Count[targetPkg, 0] == 1 && Count[targetPkg, 1] == nTotal - 1, "SubTop",
    True, "Unknown"
  ]
];

mappingPropagatorsForCase[spec_Association, targetOrig_List] := Module[
  {allProps, auxSlots, explicit, auxiliary, targetPkg, targetType},
  allProps = spec["Propagators"];
  auxSlots = Lookup[spec, "AuxiliarySlots", {}];
  explicit = If[auxSlots === {}, allProps, Delete[allProps, List /@ auxSlots]];
  auxiliary = If[auxSlots === {}, {}, allProps[[auxSlots]]];
  targetPkg = reorderByAux[targetOrig, auxSlots];
  targetType = determineTargetType[targetPkg, Length[explicit], Length[auxiliary]];
  <|
    "Type" -> targetType,
    "Propagators" -> If[targetType === "TypeI", explicit, Join[explicit, auxiliary]],
    "AuxiliaryPropagatorCount" -> Length[auxiliary]
  |>
];

extractTNamesFromOutputCell[cell_Cell] := SortBy[
  DeleteDuplicates @ StringCases[
    ToString[Unevaluated[cell], InputForm],
    RegularExpression["t\\$\\d+"]
  ],
  ToExpression[StringDrop[#, 2]] &
];

mappingCellText[spec_Association, targetOrig_List, outputCell_Cell] := Module[
  {info, tNames, props, lines, pairCount},
  info = mappingPropagatorsForCase[spec, targetOrig];
  tNames = extractTNamesFromOutputCell[outputCell];
  props = info["Propagators"];
  pairCount = Min[Length[tNames], Length[props]];
  lines = Join[
    {"t-variable mapping for the generating function above:"},
    Table[
      tNames[[i]] <> " <-> D" <> ToString[i] <> " = " <> exprCodeString[props[[i]]],
      {i, pairCount}
    ]
  ];
  If[info["Type"] === "TypeI" && info["AuxiliaryPropagatorCount"] > 0,
    lines = Join[lines, {"", "Only the explicit propagators carry t-variables in this TypeI generating function."}]
  ];
  If[Length[tNames] =!= Length[props],
    lines = Join[lines, {"", "Warning: the number of displayed t-variables does not match the expected propagator count."}]
  ];
  StringRiffle[lines, "\n"]
];

parseNotebookFile[path_String] := Module[{text, pos, held},
  text = Import[path, "Text"];
  pos = StringPosition[text, "Notebook[", 1];
  If[pos === {}, Return[$Failed]];
  held = ToExpression[StringDrop[text, pos[[1, 1]] - 1], InputForm, HoldComplete];
  If[Head[held] =!= HoldComplete || Length[held] < 1, Return[$Failed]];
  held[[1]]
];

removeExistingMappingCells[cells_List] := DeleteCases[
  cells,
  Cell[s_String, "Text", ___] /; StringStartsQ[s, "t-variable mapping for the generating function above:"]
];

gfOutputCellsInOrder[cells_List] := Module[{pending = False, outputs = {}},
  Scan[
    Function[cell,
      Which[
        MatchQ[cell, Cell[s_String, "Input", ___] /; StringStartsQ[StringTrim[s], "gf" ~~ DigitCharacter .. ~~ " = BuildBaikovGeneratingFunction"]],
          pending = True,
        pending && MatchQ[cell, Cell[BoxData[__], "Output", ___]],
          AppendTo[outputs, cell];
          pending = False,
        True,
          Null
      ]
    ],
    cells
  ];
  outputs
];

insertMappingCells[cells_List, mappingTexts_List] := Module[
  {pending = False, caseIndex = 1, newCells = {}},
  Scan[
    Function[cell,
      AppendTo[newCells, cell];
      Which[
        MatchQ[cell, Cell[s_String, "Input", ___] /; StringStartsQ[StringTrim[s], "gf" ~~ DigitCharacter .. ~~ " = BuildBaikovGeneratingFunction"]],
          pending = True,
        pending && MatchQ[cell, Cell[BoxData[__], "Output", ___]],
          AppendTo[newCells, Cell[mappingTexts[[caseIndex]], "Text"]];
          caseIndex++;
          pending = False,
        True,
          Null
      ]
    ],
    cells
  ];
  newCells
];

rewriteNotebookWithMappings[path_String, spec_Association, targetsOrig_List] := Module[
  {nb, cells, opts, cleanCells, outputs, mappingTexts, newCells, newNb},
  nb = parseNotebookFile[path];
  If[nb === $Failed || Head[nb] =!= Notebook, Return[$Failed]];
  cells = nb[[1]];
  opts = Rest[List @@ nb];
  cleanCells = removeExistingMappingCells[cells];
  outputs = gfOutputCellsInOrder[cleanCells];
  If[Length[outputs] =!= Length[targetsOrig],
    Return[<|"ExpectedOutputs" -> Length[targetsOrig], "ActualOutputs" -> Length[outputs]|>]
  ];
  mappingTexts = MapThread[mappingCellText[spec, #1, #2] &, {targetsOrig, outputs}];
  newCells = insertMappingCells[cleanCells, mappingTexts];
  newNb = Notebook[newCells, Sequence @@ opts];
  Put[newNb, path];
  True
];

exampleConfigs = {
  <|"Slug" -> "tadpole", "Notebook" -> "tadpole_demo.nb", "Targets" -> {{1}}|>,
  <|"Slug" -> "bubble_massive", "Notebook" -> "bubble_massive_demo.nb", "Targets" -> {{1, 1}, {1, 0}}|>,
  <|"Slug" -> "hq_triangle_1loop", "Notebook" -> "hq_triangle_1loop_demo.nb", "Targets" -> {{1, 1, 1}, {1, 1, 0}}|>,
  <|"Slug" -> "vacuum_2loop", "Notebook" -> "vacuum_2loop_demo.nb", "Targets" -> {{1, 1, 1}, {1, 1, 0}}|>,
  <|"Slug" -> "vacuum_3loop", "Notebook" -> "vacuum_3loop_demo.nb", "Targets" -> {{1, 1, 1, 1, 1, 1}, {0, 1, 1, 1, 1, 1}, {1, 1, 1, 0, 1, 1}}|>,
  <|"Slug" -> "sunset_4prop", "Notebook" -> "sunset_4prop_demo.nb", "Targets" -> {{1, 0, 1, 1, 1}}|>,
  <|"Slug" -> "self_energy_3loop_1ext", "Notebook" -> "self_energy_3loop_1ext_demo.nb", "Targets" -> {{1, 1, 1, 0, 1, 1, 1, 1, 1}}|>,
  <|"Slug" -> "sunset_cut_vertical", "Notebook" -> "sunset_cut_vertical_demo.nb", "Targets" -> {{1, 1, 1, 1, 0}}|>,
  <|"Slug" -> "hq_potential_2loop", "Notebook" -> "hq_potential_2loop_demo.nb", "Targets" -> {{1, 1, 1, 1, 0, 1, 1}}|>
};

results = Association[];

Do[
  Module[{spec, notebookPath, status},
    spec = Get[FileNameJoin[{fireRoot, config["Slug"], config["Slug"] <> "_family.wl"}]];
    notebookPath = FileNameJoin[{examplesDir, config["Notebook"]}];
    status = rewriteNotebookWithMappings[notebookPath, spec, config["Targets"]];
    results[config["Slug"]] = status;
  ],
  {config, exampleConfigs}
];

Print[results // InputForm];
