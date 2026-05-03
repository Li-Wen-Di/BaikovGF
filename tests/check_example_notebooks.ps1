$ErrorActionPreference = 'Stop'

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = Split-Path -Parent $scriptDir
$examplesDir = Join-Path $projectRoot 'examples'

$notebooks = @(
  'bubble_massive_demo.nb',
  'hq_potential_2loop_demo.nb',
  'hq_triangle_1loop_demo.nb',
  'self_energy_3loop_1ext_demo.nb',
  'sunset_4prop_demo.nb',
  'sunset_cut_vertical_demo.nb',
  'tadpole_demo.nb',
  'vacuum_2loop_demo.nb',
  'vacuum_3loop_demo.nb'
)

$wlCode = @'
projectRoot = Environment["PROJECT_ROOT"];
packagePath = FileNameJoin[{projectRoot, "BaikovGF", "BaikovGF.wl"}];
notebookPath = Environment["NB_PATH"];
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

Get[packagePath];
Needs["BaikovGF`"];

Block[{$Context = "Global`", $ContextPath = {"System`", "Global`", "BaikovGF`"}},
  nb = parseNotebookFile[notebookPath];
  If[nb === $Failed || Head[nb] =!= Notebook,
    Print[<|"Notebook" -> FileNameTake[notebookPath], "Status" -> "parse-failed"|> // InputForm];
    Exit[1];
  ];
  heldInputs = Cases[nb, Cell[content_, "Input", ___] :> parseHeldInput[content], Infinity];
  If[heldInputs === {} || MemberQ[heldInputs, HoldComplete[$Failed]],
    Print[<|"Notebook" -> FileNameTake[notebookPath], "Status" -> "input-parse-failed"|> // InputForm];
    Exit[1];
  ];
  results = ReleaseHold /@ (Rest[heldInputs] /. HoldPattern[NotebookDirectory[]] :> notebookDir);
  compareResults = Select[results, AssociationQ[#] && KeyExistsQ[#, "MatchQ"] &];
  summary = <|
    "Notebook" -> FileNameTake[notebookPath],
    "Status" -> "ok",
    "InputCount" -> Length[heldInputs],
    "CompareCount" -> Length[compareResults],
    "CompareResults" -> compareResults,
    "AllMatched" -> Length[compareResults] > 0 && And @@ (TrueQ[Lookup[#, "MatchQ", False]] & /@ compareResults)
  |>;
];

Print[summary // InputForm];

If[!TrueQ[summary["AllMatched"]],
  Exit[1];
];
'@

$results = @()

foreach ($name in $notebooks) {
  $path = Join-Path $examplesDir $name
  $env:PROJECT_ROOT = $projectRoot
  $env:NB_PATH = $path

  $output = $wlCode | wolframscript -
  $exitCode = $LASTEXITCODE

  if ($output) {
    $output | Write-Output
  }

  if ($exitCode -ne 0) {
    throw "Notebook check failed for $name"
  }
}
