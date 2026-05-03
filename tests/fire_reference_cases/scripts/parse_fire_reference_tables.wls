Get[FileNameJoin[{DirectoryName[$InputFileName], "fire_reference_specs.wl"}]];

ClearAll[
  ensureDir,
  powerLabel,
  safeExpr,
  symbolStem,
  exportSourceFile,
  parseCase,
  buildSummaryMarkdown
];

ensureDir[path_String] := If[!DirectoryQ[path], CreateDirectory[path, CreateIntermediateDirectories -> True]];

powerLabel[powers_List] := StringRiffle[ToString /@ powers, "_"];

safeExpr[expr_] := Replace[expr, s_String :> ToExpression[s], {0}];

symbolStem[base_String, tag_String, powers_List] := base <> "$" <> tag <> "$" <> StringRiffle[ToString /@ powers, "$"];

exportSourceFile[spec_Association, caseDir_String, sourceRecord_Association] := Module[
  {
    coeffDir = FileNameJoin[{caseDir, "coefficients"}],
    sourceSymbol,
    coeffLines,
    fileName
  },
  ensureDir[coeffDir];
  sourceSymbol = symbolStem[spec["SymbolBase"], "src", sourceRecord["SourcePowers"]];
  coeffLines = KeyValueMap[
    Function[{key, rec},
      sourceSymbol <> "$to$" <> StringRiffle[ToString /@ rec["MasterPowers"], "$"] <> " = " <>
        ToString[InputForm[rec["Coefficient"]]] <> ";"
    ],
    sourceRecord["MasterCoefficients"]
  ];
  fileName = FileNameJoin[{coeffDir, spec["Slug"] <> "__src_" <> powerLabel[sourceRecord["SourcePowers"]] <> ".wl"}];
  Export[
    fileName,
    StringRiffle[
      Join[
        {
          sourceSymbol <> " = " <> ToString[InputForm[sourceRecord]] <> ";"
        },
        coeffLines
      ],
      "\n"
    ] <> "\n",
    "Text"
  ];
  FileNameTake[fileName]
];

parseCase[spec_Association, rootDir_String] := Module[
  {
    caseDir = FileNameJoin[{rootDir, spec["Slug"]}],
    tablesPath,
    raw,
    reductionRows,
    idRows,
    idMap,
    reductionMap,
    sources,
    missing = {},
    masterCatalog = <||>,
    files = <||>,
    sourceID,
    terms,
    masterAssoc,
    sourceAssoc,
    sourceKey,
    status
  },
  tablesPath = FileNameJoin[{caseDir, spec["Slug"] <> ".tables"}];
  If[!FileExistsQ[tablesPath],
    Return[<|"Slug" -> spec["Slug"], "Status" -> "missing_tables", "GeneratedSources" -> 0, "MissingSources" -> spec["SourcePowersList"]|>]
  ];

  raw = Get[tablesPath];
  If[!MatchQ[raw, {_List, _List}],
    Return[<|"Slug" -> spec["Slug"], "Status" -> "bad_tables", "GeneratedSources" -> 0, "MissingSources" -> spec["SourcePowersList"]|>]
  ];

  reductionRows = raw[[1]];
  idRows = raw[[2]];
  idMap = Association @ Map[
    Function[row,
      row[[1]] -> <|
        "ProblemID" -> row[[2, 1]],
        "Powers" -> row[[2, 2]]
      |>
    ],
    idRows
  ];
  reductionMap = Association @ Map[(#[[1]] -> #[[2]]) &, reductionRows];

  sources = Table[
    sourceID = FirstCase[
      idRows,
      {id_, {pid_, pows_}} /; pid === spec["ProblemID"] && pows === powers :> id,
      Missing["NotFound"]
    ];
    If[sourceID === Missing["NotFound"],
      AppendTo[missing, powers];
      Nothing,
      terms = Lookup[reductionMap, sourceID, {{sourceID, 1}}];
      masterAssoc = Association @ Map[
        Function[term,
          Module[{mid = term[[1]], coeff = safeExpr[term[[2]]], mpows},
            mpows = idMap[mid, "Powers"];
            masterCatalog[powerLabel[mpows]] = <|"MasterID" -> mid, "MasterPowers" -> mpows|>;
            powerLabel[mpows] -> <|
              "MasterID" -> mid,
              "MasterPowers" -> mpows,
              "Coefficient" -> coeff
            |>
          ]
        ],
        terms
      ];
      sourceAssoc = <|
        "Family" -> spec["Name"],
        "Slug" -> spec["Slug"],
        "ProblemID" -> spec["ProblemID"],
        "SourceID" -> sourceID,
        "SourcePowers" -> powers,
        "MasterCoefficients" -> masterAssoc
      |>;
      sourceKey = powerLabel[powers];
      files[sourceKey] = exportSourceFile[spec, caseDir, sourceAssoc];
      sourceKey -> sourceAssoc
    ],
    {powers, spec["SourcePowersList"]}
  ];

  Export[
    FileNameJoin[{caseDir, spec["Slug"] <> "_index.wl"}],
    ToString[
      InputForm[
        <|
          "Family" -> spec["Name"],
          "Slug" -> spec["Slug"],
          "ProblemID" -> spec["ProblemID"],
          "Sources" -> Association@sources,
          "Masters" -> masterCatalog,
          "Files" -> files
        |>
      ]
    ] <> "\n",
    "Text"
  ];

  status = If[missing === {}, "ok", "partial"];
  <|
    "Slug" -> spec["Slug"],
    "Status" -> status,
    "GeneratedSources" -> Length[sources],
    "MasterCount" -> Length[masterCatalog],
    "MissingSources" -> missing
  |>
];

buildSummaryMarkdown[rows_List] := Module[{lines},
  lines = ("| " <> #["Slug"] <> " | " <> #["Status"] <> " | " <> ToString[#["GeneratedSources"]] <> " | " <>
      ToString[Lookup[#, "MasterCount", 0]] <> " | " <>
      If[Lookup[#, "MissingSources", {}] === {}, "", ToString[InputForm[Lookup[#, "MissingSources"]]]] <> " |") & /@ rows;
  StringRiffle[
    Join[
      {
        "# FIRE Parse Summary",
        "",
        "| Slug | Status | Generated Sources | Master Count | Missing Sources |",
        "|---|---|---:|---:|---|"
      },
      lines
    ],
    "\n"
  ] <> "\n"
];

Module[
  {
    rootDir = FileNameJoin[{DirectoryName[$InputFileName], ".."}],
    selected = Rest[$ScriptCommandLine],
    specs,
    results
  },
  specs = paperFireCases;
  If[selected =!= {},
    specs = Select[specs, MemberQ[selected, #["Slug"]] &];
  ];
  results = parseCase[#, rootDir] & /@ specs;
  Export[FileNameJoin[{rootDir, "parse_summary.wl"}], ToString[InputForm[results]] <> "\n", "Text"];
  Export[FileNameJoin[{rootDir, "parse_summary.md"}], buildSummaryMarkdown[results], "Text"];
];
