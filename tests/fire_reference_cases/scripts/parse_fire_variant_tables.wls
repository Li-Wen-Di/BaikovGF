Get[FileNameJoin[{DirectoryName[$InputFileName], "fire_reference_specs.wl"}]];

ClearAll[
  ensureDir,
  powerLabel,
  safeExpr,
  makeSymbolBase,
  exportVariantSourceFile,
  parseVariantCase
];

ensureDir[path_String] := If[!DirectoryQ[path], CreateDirectory[path, CreateIntermediateDirectories -> True]];

powerLabel[powers_List] := StringRiffle[ToString /@ powers, "_"];

safeExpr[expr_] := Replace[expr, s_String :> ToExpression[s], {0}];

makeSymbolBase[base_String, tag_String] := If[tag === "", base, base <> "$" <> tag];

exportVariantSourceFile[
  spec_Association,
  coeffDir_String,
  symbolBase_String,
  filePrefix_String,
  sourceRecord_Association
] := Module[
  {sourceSymbol, coeffLines, fileName},
  ensureDir[coeffDir];
  sourceSymbol = symbolBase <> "$src$" <> StringRiffle[ToString /@ sourceRecord["SourcePowers"], "$"];
  coeffLines = KeyValueMap[
    Function[{key, rec},
      sourceSymbol <> "$to$" <> StringRiffle[ToString /@ rec["MasterPowers"], "$"] <> " = " <>
        ToString[InputForm[rec["Coefficient"]]] <> ";"
    ],
    sourceRecord["MasterCoefficients"]
  ];
  fileName = FileNameJoin[{coeffDir, filePrefix <> "__src_" <> powerLabel[sourceRecord["SourcePowers"]] <> ".wl"}];
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

parseVariantCase[
  spec_Association,
  tablesPath_String,
  outputDir_String,
  fileTag_String,
  symbolTag_String,
  metadata_Association
] := Module[
  {
    raw,
    reductionRows,
    idRows,
    idMap,
    reductionMap,
    missing = {},
    masterCatalog = <||>,
    files = <||>,
    sources,
    sourceID,
    terms,
    masterAssoc,
    sourceAssoc,
    sourceKey,
    filePrefix,
    symbolBase
  },
  raw = Get[tablesPath];
  If[!MatchQ[raw, {_List, _List}],
    Print["Bad FIRE tables file: ", tablesPath];
    Exit[1];
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
  filePrefix = spec["Slug"] <> "__" <> fileTag;
  symbolBase = makeSymbolBase[spec["SymbolBase"], symbolTag];

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
        "MasterCoefficients" -> masterAssoc,
        "Variant" -> metadata
      |>;
      sourceKey = powerLabel[powers];
      files[sourceKey] = exportVariantSourceFile[
        spec,
        FileNameJoin[{outputDir, "coefficients"}],
        symbolBase,
        filePrefix,
        sourceAssoc
      ];
      sourceKey -> sourceAssoc
    ],
    {powers, spec["SourcePowersList"]}
  ];

  Export[
    FileNameJoin[{outputDir, filePrefix <> "_index.wl"}],
    ToString[
      InputForm[
        <|
          "Family" -> spec["Name"],
          "Slug" -> spec["Slug"],
          "ProblemID" -> spec["ProblemID"],
          "Variant" -> metadata,
          "Sources" -> Association@sources,
          "Masters" -> masterCatalog,
          "Files" -> files
        |>
      ]
    ] <> "\n",
    "Text"
  ];

  Export[
    FileNameJoin[{outputDir, "variant_metadata.wl"}],
    ToString[InputForm[metadata]] <> "\n",
    "Text"
  ];

  <|
    "Slug" -> spec["Slug"],
    "Variant" -> metadata,
    "Status" -> If[missing === {}, "ok", "partial"],
    "GeneratedSources" -> Length[sources],
    "MasterCount" -> Length[masterCatalog],
    "MissingSources" -> missing
  |>
];

Module[
  {
    args = Rest[$ScriptCommandLine],
    slug,
    tablesPath,
    outputSubdir,
    fileTag,
    symbolTag,
    metadata,
    spec,
    outputDir,
    result
  },
  If[Length[args] < 5,
    Print["Usage: wolframscript -file parse_fire_variant_tables.wls <slug> <tablesPath> <outputSubdir> <fileTag> <symbolTag> [metadataExpr]"];
    Exit[1];
  ];

  slug = args[[1]];
  tablesPath = ExpandFileName[args[[2]]];
  outputSubdir = args[[3]];
  fileTag = args[[4]];
  symbolTag = args[[5]];
  metadata = If[Length[args] >= 6, ToExpression[args[[6]]], <||>];

  spec = FirstCase[paperFireCases, s_Association /; s["Slug"] === slug, Missing["NotFound"]];
  If[spec === Missing["NotFound"],
    Print["Unknown slug: ", slug];
    Exit[1];
  ];

  outputDir = FileNameJoin[{DirectoryName[tablesPath], outputSubdir}];
  ensureDir[outputDir];
  result = parseVariantCase[spec, tablesPath, outputDir, fileTag, symbolTag, metadata];
  Print[result];
];
