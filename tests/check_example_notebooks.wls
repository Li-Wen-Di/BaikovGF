scriptPath = ExpandFileName[$InputFileName];
testsDir = DirectoryName[scriptPath];
projectRoot = DirectoryName[testsDir];
examplesDir = FileNameJoin[{projectRoot, "examples"}];
singleCheckPath = FileNameJoin[{testsDir, "check_one_example_notebook.wls"}];

notebooks = {
  "bubble_massive_demo.nb",
  "hq_potential_2loop_demo.nb",
  "hq_triangle_1loop_demo.nb",
  "self_energy_3loop_1ext_demo.nb",
  "sunset_4prop_demo.nb",
  "sunset_cut_vertical_demo.nb",
  "tadpole_demo.nb",
  "vacuum_2loop_demo.nb",
  "vacuum_3loop_demo.nb"
};

results = Association @ Table[
  Module[{path, proc, stdout, summary},
    path = FileNameJoin[{examplesDir, name}];
    proc = RunProcess[{"wolframscript", "-script", singleCheckPath, path}];
    stdout = StringTrim[proc["StandardOutput"]];
    summary = Quiet @ Check[ToExpression[stdout, InputForm], $Failed];
    If[summary === $Failed || !AssociationQ[summary],
      name -> <|
        "Notebook" -> name,
        "Status" -> "invalid-summary",
        "ExitCode" -> proc["ExitCode"],
        "StandardOutput" -> stdout,
        "StandardError" -> StringTrim[proc["StandardError"]]
      |>,
      name -> Join[summary, <|"ExitCode" -> proc["ExitCode"]|>]
    ]
  ],
  {name, notebooks}
];

Print[results // InputForm];

If[!And @@ (TrueQ[Lookup[#, "AllMatched", False]] && Lookup[#, "ExitCode", 1] == 0 & /@ Values[results]),
  Exit[1];
];
