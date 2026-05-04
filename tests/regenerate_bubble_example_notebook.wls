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

topTarget = {1, 1};
typeIITarget = {1, 0};
sourcePowerRule = {a1 -> 6, a2 -> 6};
sourcePowerVector = {a1, a2} /. sourcePowerRule;
sourcePowerFileTag = StringRiffle[ToString /@ sourcePowerVector, "_"];
sourcePowerVarTag = StringRiffle[ToString /@ sourcePowerVector, "$"];
fireSourceFile = FileNameJoin[{fireRoot, "bubble_massive", "coefficients", "bubble_massive__src_" <> sourcePowerFileTag <> ".wl"}];

familyExpr = BaikovGF`CreateFeynmanIntegral[
  "LoopMomenta" -> {k1},
  "ExternalMomenta" -> {p1},
  "Propagators" -> {
    BaikovGF`SP[k1, k1] - m1sq,
    BaikovGF`SP[k1 + p1, k1 + p1] - m2sq
  },
  "AuxiliaryPropagators" -> {},
  "KinematicRules" -> {BaikovGF`SP[p1, p1] -> s},
  "DimensionSymbol" -> d
];

family = familyExpr;

tBuildTop = AbsoluteTiming[gfTop = BaikovGF`BuildBaikovGeneratingFunction[family, topTarget];][[1]];
mappingTop = mappingTextForGF[family, gfTop];
tExtractTop = AbsoluteTiming[rawTop = BaikovGF`ExtractBaikovCoefficient[gfTop, {a1, a2} /. sourcePowerRule];][[1]];
tSimplifyTop = AbsoluteTiming[resTop = BaikovGF`SimplifyBaikovCoefficient[rawTop];][[1]];
tCompareTop = AbsoluteTiming[
  Get[fireSourceFile];
  fireTop = Symbol["bubbleMassive$src$" <> sourcePowerVarTag <> "$to$1$1"];
  topCheck = Simplify[Cancel[Together[resTop["Coefficient"] - fireTop]] == 0];
][[1]];

tBuildTypeII = AbsoluteTiming[gfTypeII = BaikovGF`BuildBaikovGeneratingFunction[family, typeIITarget];][[1]];
mappingTypeII = mappingTextForGF[family, gfTypeII];
tExtractTypeII = AbsoluteTiming[rawTypeII = BaikovGF`ExtractBaikovCoefficient[gfTypeII, {a1, a2} /. sourcePowerRule];][[1]];
tSimplifyTypeII = AbsoluteTiming[resTypeII = BaikovGF`SimplifyBaikovCoefficient[rawTypeII];][[1]];
tCompareTypeII = AbsoluteTiming[
  Get[fireSourceFile];
  fireTypeII = Symbol["bubbleMassive$src$" <> sourcePowerVarTag <> "$to$1$0"];
  typeIICheck = Simplify[Cancel[Together[resTypeII["Coefficient"] - fireTypeII]] == 0];
][[1]];

If[!TrueQ[topCheck] || !TrueQ[typeIICheck],
  Print["Bubble example verification failed."];
  Print[<|"TopCheck" -> topCheck, "TypeIICheck" -> typeIICheck|> // InputForm];
  Exit[1];
];

nb = Notebook[
  {
    Cell["Example: Massive Bubble", "Title"],

    Cell["Load Package", "Section"],
    Cell["This step loads the package and exposes the public interface used below.", "Text"],
    inputCell[
      Get[FileNameJoin[{DirectoryName@NotebookDirectory[], "BaikovGF", "BaikovGF.wl"}]];

      Needs["BaikovGF`"];
    ],

    Cell["Setup", "Section"],
    Cell["This step fixes the source-power rule, target powers, and integral-family object for the example.", "Text"],
    inputCell[
      (* Fix the numeric source powers used in this example. *)
      sourcePowerRule = {a1 -> 6, a2 -> 6};

      (* Build helper forms of the source powers from sourcePowerRule. *)
      sourcePowerVector = {a1, a2} /. sourcePowerRule;
      sourcePowerFileTag = StringRiffle[ToString /@ sourcePowerVector, "_"];
      sourcePowerVarTag = StringRiffle[ToString /@ sourcePowerVector, "$"];

      (* Set the top-sector target powers. *)
      topTarget = {1, 1};

      (* Set a representative TypeII target powers. *)
      typeIITarget = {1, 0};

      (* Build the Feynman-integral family object with loop momentum k1, external momentum p1, explicit propagators {SP[k1, k1] - m1sq, SP[k1 + p1, k1 + p1] - m2sq}, no auxiliary propagators, kinematic rule {SP[p1, p1] -> s}, and dimension symbol d. *)
      family = BaikovGF`CreateFeynmanIntegral[
        "LoopMomenta" -> {k1},
        "ExternalMomenta" -> {p1},
        "Propagators" -> {
          BaikovGF`SP[k1, k1] - m1sq,
          BaikovGF`SP[k1 + p1, k1 + p1] - m2sq
        },
        "AuxiliaryPropagators" -> {},
        "KinematicRules" -> {BaikovGF`SP[p1, p1] -> s},
        "DimensionSymbol" -> d
      ];

      (* Point to the FIRE coefficient file for this source powers. *)
      fireSourceFile = FileNameJoin[{DirectoryName@NotebookDirectory[], "tests", "fire_reference_cases", "bubble_massive", "coefficients", "bubble_massive__src_" <> sourcePowerFileTag <> ".wl"}];
    ],

    Cell["Top Target {1, 1}", "Section"],
    Cell["This step builds the generating function for the top target and returns the runtime.", "Text"],
    inputCell[
      {tBuild1, gf1} = BaikovGF`BuildBaikovGeneratingFunction[family, topTarget] // AbsoluteTiming;
      tBuild1
    ],
    outputCell[tBuildTop],
    Cell[mappingTop, "Text"],

    Cell["This step extracts the unsimplified coefficient and returns the runtime.", "Text"],
    inputCell[
      {tExtract1, raw1} = BaikovGF`ExtractBaikovCoefficient[gf1, {a1, a2} /. sourcePowerRule] // AbsoluteTiming;
      tExtract1
    ],
    outputCell[tExtractTop],

    Cell["This step simplifies the extracted coefficient and returns the runtime.", "Text"],
    inputCell[
      {tSimplify1, res1} = BaikovGF`SimplifyBaikovCoefficient[raw1] // AbsoluteTiming;
      tSimplify1
    ],
    outputCell[tSimplifyTop],

    Cell["Compare to FIRE", "Subsection"],
    inputCell[
      {tCompare1, compare1} = (
        Get[fireSourceFile];
        fireCoeff1 = Symbol["bubbleMassive$src$" <> sourcePowerVarTag <> "$to$1$1"];
        Simplify[Cancel[Together[res1["Coefficient"] - fireCoeff1]] == 0]
      ) // AbsoluteTiming;
      <|"Time" -> tCompare1, "MatchQ" -> compare1|>
    ],
    outputCell[<|"Time" -> tCompareTop, "MatchQ" -> topCheck|>],

    Cell["Representative TypeII Target {1, 0}", "Section"],
    Cell["This step builds the generating function for a representative TypeII target and returns the runtime.", "Text"],
    inputCell[
      {tBuild2, gf2} = BaikovGF`BuildBaikovGeneratingFunction[family, typeIITarget] // AbsoluteTiming;
      tBuild2
    ],
    outputCell[tBuildTypeII],
    Cell[mappingTypeII, "Text"],

    Cell["This step extracts the unsimplified coefficient and returns the runtime.", "Text"],
    inputCell[
      {tExtract2, raw2} = BaikovGF`ExtractBaikovCoefficient[gf2, {a1, a2} /. sourcePowerRule] // AbsoluteTiming;
      tExtract2
    ],
    outputCell[tExtractTypeII],

    Cell["This step simplifies the extracted coefficient and returns the runtime.", "Text"],
    inputCell[
      {tSimplify2, res2} = BaikovGF`SimplifyBaikovCoefficient[raw2] // AbsoluteTiming;
      tSimplify2
    ],
    outputCell[tSimplifyTypeII],

    Cell["Compare to FIRE", "Subsection"],
    inputCell[
      {tCompare2, compare2} = (
        Get[fireSourceFile];
        fireCoeff2 = Symbol["bubbleMassive$src$" <> sourcePowerVarTag <> "$to$1$0"];
        Simplify[Cancel[Together[res2["Coefficient"] - fireCoeff2]] == 0]
      ) // AbsoluteTiming;
      <|"Time" -> tCompare2, "MatchQ" -> compare2|>
    ],
    outputCell[<|"Time" -> tCompareTypeII, "MatchQ" -> typeIICheck|>]
  },
  StyleDefinitions -> "Default.nb",
  WindowTitle -> "Example: Massive Bubble",
  Magnification :> 1.1 Inherited
];

Export[FileNameJoin[{examplesDir, "bubble_massive_demo.nb"}], nb];
Print["Regenerated bubble_massive_demo.nb successfully."];
Print[<|
  "TopCheck" -> topCheck,
  "TypeIICheck" -> typeIICheck,
  "TopTimes" -> {tBuildTop, tExtractTop, tSimplifyTop, tCompareTop},
  "TypeIITimes" -> {tBuildTypeII, tExtractTypeII, tSimplifyTypeII, tCompareTypeII}
|> // InputForm];
