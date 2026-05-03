Get[FileNameJoin[{DirectoryName[$InputFileName], "fire_reference_specs.wl"}]];

ClearAll[
  normalizeWinPath,
  ensureDir,
  powerLabel,
  listToInputString,
  fireExpr,
  fireString,
  buildPrepareText,
  buildConfigText,
  buildIntegralText,
  buildFamilyReadme,
  buildRootReadme
];

normalizeWinPath[path_String] := StringReplace[ExpandFileName[path], "\\" -> "/"];

ensureDir[path_String] := If[!DirectoryQ[path], CreateDirectory[path, CreateIntermediateDirectories -> True]];

powerLabel[powers_List] := StringRiffle[ToString /@ powers, "_"];

fireExpr[expr_] := expr /. {
  BaikovGF`SP[a_, b_] :> If[SameQ[a, b], a^2, a*b]
};

fireString[expr_] := ToString[InputForm[fireExpr[expr]]];

listToInputString[list_List] := "{" <> StringRiffle[fireString /@ list, ", "] <> "}";

buildPrepareText[spec_Association] := StringRiffle[
  {
    "SetDirectory[DirectoryName[$InputFileName]];",
    "$HistoryLength = 0;",
    "Get[\"/home/lwd/git/fire/FIRE6/FIRE6.m\"];",
    "",
    "Internal = " <> listToInputString[spec["LoopMomenta"]] <> ";",
    "External = " <> listToInputString[spec["ExternalMomenta"]] <> ";",
    "Propagators = " <> listToInputString[spec["Propagators"]] <> ";",
    "Replacements = " <> listToInputString[spec["KinematicRules"]] <> ";",
    "",
    "PrepareIBP[];",
    "Prepare[AutoDetectRestrictions -> True, LI -> True, Parallel -> False];",
    "SaveStart[\"" <> spec["Slug"] <> "\"];"
  },
  "\n"
];

buildConfigText[spec_Association] := StringRiffle[
  {
    "#threads           2",
    "#fthreads          2",
    "#variables         " <> StringRiffle[ToString /@ spec["Variables"], ","],
    "#start",
    "#folder            ./",
    "#problem           " <> ToString[spec["ProblemID"]] <> " " <> spec["Slug"] <> ".start",
    "#integrals         " <> spec["Slug"] <> "int.m",
    "#output            " <> spec["Slug"] <> ".tables"
  },
  "\n"
];

buildIntegralText[spec_Association] := Module[{rows},
  rows = ("  {" <> ToString[spec["ProblemID"]] <> ", {" <> StringRiffle[ToString /@ #, ", "] <> "}}") & /@ spec["SourcePowersList"];
  "{\n" <> StringRiffle[rows, ",\n"] <> "\n}\n"
];

buildFamilyReadme[spec_Association] := Module[{auxLine},
  auxLine = If[KeyExistsQ[spec, "AuxiliarySlots"], "- `AuxiliarySlots`: `" <> ToString[InputForm[spec["AuxiliarySlots"]]] <> "`", Nothing];
  StringRiffle[
    DeleteCases[
      {
        "# " <> spec["Name"],
        "",
        "- `Section`: `" <> spec["Section"] <> "`",
        "- `PaperType`: `" <> spec["PaperType"] <> "`",
        "- `ProblemID`: `" <> ToString[spec["ProblemID"]] <> "`",
        "- `Propagators`: `" <> ToString[Length[spec["Propagators"]]] <> "`",
        auxLine,
        "- `SourcePowersList`: `" <> ToString[InputForm[spec["SourcePowersList"]]] <> "`",
        If[KeyExistsQ[spec, "Notes"], "- `Notes`: " <> spec["Notes"], Nothing]
      },
      Nothing
    ],
    "\n"
  ] <> "\n"
];

buildRootReadme[specs_List] := Module[{rows},
  rows = ("| " <> #["Slug"] <> " | " <> #["Name"] <> " | " <> #["Section"] <> " | " <> #["PaperType"] <> " | " <>
      ToString[Length[#["Propagators"]]] <> " | " <> ToString[Length[#["SourcePowersList"]]] <> " |") & /@ specs;
  StringRiffle[
    Join[
      {
        "# FIRE Reference Cases",
        "",
        "This directory stores the FIRE fixtures used to test the Baikov generating-function package against the paper examples.",
        "",
        "Generation workflow:",
        "",
        "1. `wolframscript -file scripts/generate_fire_reference_inputs.wls`",
        "2. Run `PrepareStart.m` and `FIRE6 -c <slug>` inside each family directory.",
        "3. `wolframscript -file scripts/parse_fire_reference_tables.wls`",
        "",
        "| Slug | Family | Section | Type | #Propagators | #Sources |",
        "|---|---|---|---|---:|---:|"
      },
      rows
    ],
    "\n"
  ] <> "\n"
];

Module[
  {
    rootDir = FileNameJoin[{DirectoryName[$InputFileName], ".."}],
    selected = Rest[$ScriptCommandLine],
    specs,
    manifest,
    familyDir,
    coeffDir
  },
  specs = paperFireCases;
  If[selected =!= {},
    specs = Select[specs, MemberQ[selected, #["Slug"]] &];
  ];

  ensureDir[rootDir];

  Do[
    familyDir = FileNameJoin[{rootDir, spec["Slug"]}];
    coeffDir = FileNameJoin[{familyDir, "coefficients"}];
    ensureDir[familyDir];
    ensureDir[coeffDir];

    Export[FileNameJoin[{familyDir, "PrepareStart.m"}], buildPrepareText[spec], "Text"];
    Export[FileNameJoin[{familyDir, spec["Slug"] <> ".config"}], buildConfigText[spec], "Text"];
    Export[FileNameJoin[{familyDir, spec["Slug"] <> "int.m"}], buildIntegralText[spec], "Text"];
    Export[FileNameJoin[{familyDir, "README.md"}], buildFamilyReadme[spec], "Text"];
    Export[FileNameJoin[{familyDir, spec["Slug"] <> "_family.wl"}], ToString[InputForm[spec]], "Text"];
    ,
    {spec, specs}
  ];

  manifest = AssociationThread[Lookup[specs, "Slug"], specs];
  Export[FileNameJoin[{rootDir, "paper_case_manifest.wl"}], ToString[InputForm[manifest]], "Text"];
  Export[FileNameJoin[{rootDir, "README.md"}], buildRootReadme[specs], "Text"];
];
