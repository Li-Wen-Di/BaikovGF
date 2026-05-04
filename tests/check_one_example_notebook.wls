scriptPath = ExpandFileName[$InputFileName];
testsDir = DirectoryName[scriptPath];
projectRoot = DirectoryName[testsDir];
packagePath = FileNameJoin[{projectRoot, "BaikovGF", "BaikovGF.wl"}];

args = Rest[$ScriptCommandLine];
If[Length[args] < 1,
  Print["Usage: wolframscript -script check_one_example_notebook.wls <notebook-path>"];
  Exit[1];
];

notebookPath = ExpandFileName[First[args]];
notebookDir = DirectoryName[notebookPath];

parseNotebookFile[path_String] := Module[{text, pos, held},
  text = Import[path, "Text"];
  pos = StringPosition[text, "Notebook[", 1];
  If[pos === {}, Return[$Failed]];
  held = ToExpression[StringDrop[text, pos[[1, 1]] - 1], InputForm, HoldComplete];
  If[Head[held] =!= HoldComplete || Length[held] < 1, Return[$Failed]];
  held[[1]]
];

parseHeldInput[content_] := Module[{parsed},
  parsed = Which[
    MatchQ[content, BoxData[HoldComplete[__]]],
      ToExpression[StringReplace[ToString[content[[1]], InputForm], "$CellContext`" -> ""], InputForm, HoldComplete],
    MatchQ[content, BoxData[_]],
      ToExpression[content[[1]], StandardForm, HoldComplete],
    StringQ[content],
      ToExpression[StringReplace[content, "$CellContext`" -> ""], InputForm, HoldComplete],
    True,
      HoldComplete[$Failed]
  ];
  If[MatchQ[parsed, HoldComplete[HoldComplete[__]]], parsed[[1]], parsed]
];

nb = parseNotebookFile[notebookPath];
If[nb === $Failed || Head[nb] =!= Notebook,
  Print[<|"Notebook" -> FileNameTake[notebookPath], "Status" -> "parse-failed"|> // InputForm];
  Exit[1];
];

Get[packagePath];
Needs["BaikovGF`"];

Block[{$Context = "Global`", $ContextPath = {"System`", "Global`", "BaikovGF`"}},
  heldInputs = Cases[nb, Cell[content_, "Input", ___] :> parseHeldInput[content], Infinity];
  If[heldInputs === {} || MemberQ[heldInputs, HoldComplete[$Failed]],
    Print[<|"Notebook" -> FileNameTake[notebookPath], "Status" -> "input-parse-failed"|> // InputForm];
    Exit[1];
  ];
  results = ReleaseHold /@ (Rest[heldInputs] /. HoldPattern[NotebookDirectory[]] :> notebookDir);
  compareResults = Select[results, AssociationQ[#] && KeyExistsQ[#, "MatchQ"] &];
];

summary = <|
  "Notebook" -> FileNameTake[notebookPath],
  "Status" -> "ok",
  "InputCount" -> Length[heldInputs],
  "CompareCount" -> Length[compareResults],
  "CompareResults" -> compareResults,
  "AllMatched" -> Length[compareResults] > 0 && And @@ (TrueQ[Lookup[#, "MatchQ", False]] & /@ compareResults)
|>;

Print[summary // InputForm];

If[!TrueQ[summary["AllMatched"]],
  Exit[1];
];
