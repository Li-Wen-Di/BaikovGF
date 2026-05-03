(* 输入检查辅助函数。这个文件只定义检查逻辑，由主包在 Private 上下文中载入。 *)

ClearAll[
  expectedExternalScalarProducts,
  droppedOnePatternQ,
  targetDroppedIndex,
  validateCreateFeynmanIntegralInput,
  validateTargetPowersForGF,
  validateSourcePowersForExtraction
];

expectedExternalScalarProducts[externalMomenta_List] := DeleteDuplicates @ Flatten @ Table[
  BaikovGF`SP[externalMomenta[[i]], externalMomenta[[j]]],
  {i, Length[externalMomenta]},
  {j, i, Length[externalMomenta]}
];

droppedOnePatternQ[list_List] :=
  VectorQ[list, (# === 0 || # === 1) &] &&
  Count[list, 0] == 1 &&
  Count[list, 1] == Length[list] - 1;

targetDroppedIndex[target_List] :=
  FirstCase[Position[target, 0], {i_Integer} :> i, Missing["NoDroppedIndex"]];

validateCreateFeynmanIntegralInput[input_Association] := Module[
  {
    loopMomenta,
    externalMomenta,
    propagators,
    auxiliaryPropagators,
    kinematicRules,
    dimensionSymbol,
    loopDuplicates,
    externalDuplicates,
    overlap,
    normalizedKinematicRules,
    kinematicLHS,
    allMomenta,
    allPropagators,
    invalidPropagators,
    undeclared,
    expanded,
    expectedKinematics,
    missingKinematics,
    nSP,
    nExp,
    nAux
  },
  loopMomenta = Lookup[input, "LoopMomenta", Missing["KeyAbsent", "LoopMomenta"]];
  externalMomenta = Lookup[input, "ExternalMomenta", Missing["KeyAbsent", "ExternalMomenta"]];
  propagators = Lookup[input, "Propagators", Missing["KeyAbsent", "Propagators"]];
  auxiliaryPropagators = Lookup[input, "AuxiliaryPropagators", Missing["KeyAbsent", "AuxiliaryPropagators"]];
  kinematicRules = Lookup[input, "KinematicRules", Missing["KeyAbsent", "KinematicRules"]];
  dimensionSymbol = Lookup[input, "DimensionSymbol", Missing["KeyAbsent", "DimensionSymbol"]];

  If[!VectorQ[loopMomenta, MatchQ[_Symbol]],
    Return @ baikovFailure[
      "InvalidLoopMomenta",
      "LoopMomenta must be a list of symbols.",
      <|"LoopMomenta" -> loopMomenta|>
    ]
  ];
  If[!VectorQ[externalMomenta, MatchQ[_Symbol]],
    Return @ baikovFailure[
      "InvalidExternalMomenta",
      "ExternalMomenta must be a list of symbols.",
      <|"ExternalMomenta" -> externalMomenta|>
    ]
  ];
  If[!ListQ[propagators] || !ListQ[auxiliaryPropagators],
    Return @ baikovFailure[
      "InvalidPropagatorLists",
      "Propagators and AuxiliaryPropagators must both be lists.",
      <||>
    ]
  ];
  If[!VectorQ[kinematicRules, MatchQ[_Rule | _RuleDelayed]],
    Return @ baikovFailure[
      "InvalidKinematicRules",
      "KinematicRules must be a list of rules.",
      <|"KinematicRules" -> kinematicRules|>
    ]
  ];
  If[!MatchQ[dimensionSymbol, _Symbol],
    Return @ baikovFailure[
      "InvalidDimensionSymbol",
      "DimensionSymbol must be a symbol.",
      <|"DimensionSymbol" -> dimensionSymbol|>
    ]
  ];
  If[containsApproximateNumberQ[propagators] || containsApproximateNumberQ[auxiliaryPropagators] || containsApproximateNumberQ[kinematicRules],
    Return @ baikovFailure[
      "ApproximateInput",
      "Approximate machine numbers are not accepted in analytic mode.",
      <||>
    ]
  ];

  loopDuplicates = listDuplicates[loopMomenta];
  If[loopDuplicates =!= {},
    Return @ baikovFailure[
      "DuplicateLoopMomenta",
      "LoopMomenta contains duplicates.",
      <|"Duplicates" -> loopDuplicates|>
    ]
  ];
  externalDuplicates = listDuplicates[externalMomenta];
  If[externalDuplicates =!= {},
    Return @ baikovFailure[
      "DuplicateExternalMomenta",
      "ExternalMomenta contains duplicates.",
      <|"Duplicates" -> externalDuplicates|>
    ]
  ];
  overlap = Intersection[loopMomenta, externalMomenta];
  If[overlap =!= {},
    Return @ baikovFailure[
      "OverlappingMomenta",
      "LoopMomenta and ExternalMomenta must be disjoint.",
      <|"Overlap" -> overlap|>
    ]
  ];
  If[Length[auxiliaryPropagators] > 1,
    Return @ baikovFailure[
      "TooManyAuxiliaryPropagators",
      "The current package only supports at most one auxiliary propagator.",
      <|"AuxiliaryPropagators" -> auxiliaryPropagators|>
    ]
  ];

  allMomenta = Join[loopMomenta, externalMomenta];
  allPropagators = Join[propagators, auxiliaryPropagators];
  invalidPropagators = Reap[
    Do[
      undeclared = undeclaredMomentumCandidates[allPropagators[[i]], allMomenta];
      expanded = expandSP[allPropagators[[i]], allMomenta];
      If[undeclared =!= {} || !propagatorLinearInSPQ[expanded, allMomenta],
        Sow[<|
          "Index" -> i,
          "Propagator" -> allPropagators[[i]],
          "UndeclaredMomenta" -> undeclared,
          "LinearSPQ" -> propagatorLinearInSPQ[expanded, allMomenta]
        |>]
      ],
      {i, Length[allPropagators]}
    ]
  ][[2]];
  If[invalidPropagators =!= {} && invalidPropagators[[1]] =!= {},
    Return @ baikovFailure[
      "InvalidPropagatorInput",
      "Each propagator must be a linear combination of scalar products built from the declared momenta.",
      <|"Details" -> invalidPropagators[[1]]|>
    ]
  ];

  normalizedKinematicRules = normalizeKinematicRuleLHS /@ kinematicRules;
  kinematicLHS = normalizedKinematicRules /. {
    HoldPattern[(lhs_ -> _)] :> lhs,
    HoldPattern[(lhs_ :> _)] :> lhs
  };
  expectedKinematics = expectedExternalScalarProducts[externalMomenta];
  missingKinematics = Complement[expectedKinematics, kinematicLHS];
  If[missingKinematics =!= {},
    Return @ baikovFailure[
      "IncompleteKinematicRules",
      "KinematicRules must cover all scalar products of the declared external momenta.",
      <|"MissingScalarProducts" -> missingKinematics|>
    ]
  ];

  nSP = Length[independentScalarProducts[loopMomenta, externalMomenta]];
  nExp = Length[propagators];
  nAux = Length[auxiliaryPropagators];
  If[!(nExp == nSP || nExp == nSP - 1),
    Return @ baikovFailure[
      "UnsupportedPropagatorCount",
      "The current package only supports explicit propagator counts equal to Nsp or Nsp-1.",
      <|"ExplicitPropagatorCount" -> nExp, "ScalarProductCount" -> nSP|>
    ]
  ];
  If[nExp + nAux =!= nSP,
    Return @ baikovFailure[
      "CompletedFamilySizeMismatch",
      "After adding auxiliary propagators, the completed family must contain exactly Nsp propagators.",
      <|"ExplicitPropagatorCount" -> nExp, "AuxiliaryPropagatorCount" -> nAux, "ScalarProductCount" -> nSP|>
    ]
  ];
  If[nExp == nSP && nAux =!= 0,
    Return @ baikovFailure[
      "UnexpectedAuxiliaryPropagator",
      "A complete family should not include auxiliary propagators.",
      <|"AuxiliaryPropagatorCount" -> nAux|>
    ]
  ];
  If[nExp == nSP - 1 && nAux =!= 1,
    Return @ baikovFailure[
      "MissingAuxiliaryPropagator",
      "An incomplete family currently requires exactly one auxiliary propagator.",
      <|"AuxiliaryPropagatorCount" -> nAux|>
    ]
  ];

  <|
    "LoopMomenta" -> loopMomenta,
    "ExternalMomenta" -> externalMomenta,
    "Propagators" -> (expandSP[#, allMomenta] & /@ propagators),
    "AuxiliaryPropagators" -> (expandSP[#, allMomenta] & /@ auxiliaryPropagators),
    "KinematicRules" -> normalizedKinematicRules,
    "DimensionSymbol" -> dimensionSymbol
  |>
];

validateTargetPowersForGF[family_Association, targetPowers_List] := Module[
  {
    familyData = family["Internal"],
    nTotal,
    nExp,
    nAux,
    topPattern,
    typeIPattern
  },
  nTotal = familyData["TotalPropagatorCount"];
  nExp = familyData["ExplicitPropagatorCount"];
  nAux = familyData["AuxiliaryPropagatorCount"];

  If[!VectorQ[targetPowers, IntegerQ[#] && # >= 0 &],
    Return @ baikovFailure[
      "InvalidTargetPowers",
      "Target powers must be a list of non-negative integers.",
      <|"TargetPowers" -> targetPowers|>
    ]
  ];
  If[Length[targetPowers] =!= nTotal,
    Return @ baikovFailure[
      "TargetPowerLengthMismatch",
      "Target powers must have the same length as the completed family.",
      <|"TargetPowers" -> targetPowers, "ExpectedLength" -> nTotal|>
    ]
  ];

  topPattern = ConstantArray[1, nTotal];
  typeIPattern = Join[ConstantArray[1, nExp], ConstantArray[0, nAux]];

  Which[
    nAux == 1 && targetPowers === typeIPattern,
      <|"Kind" -> "TypeI", "DroppedIndex" -> nTotal|>,
    nAux == 0 && targetPowers === topPattern,
      <|"Kind" -> "Top", "DroppedIndex" -> Missing["NotApplicable"]|>,
    nAux == 0 && droppedOnePatternQ[targetPowers],
      <|"Kind" -> "SubTop", "DroppedIndex" -> targetDroppedIndex[targetPowers]|>,
    True,
      baikovFailure[
        "UnsupportedTargetPattern",
        "The current package only supports complete-family top targets, complete-family single-dropped targets, or incomplete-family Type I targets.",
        <|"TargetPowers" -> targetPowers|>
      ]
  ]
];

validateSourcePowersForExtraction[gfObject_Association, sourcePowers_List] := Module[
  {
    family = gfObject["Family"],
    familyData,
    nTotal,
    nExp,
    nAux,
    type
  },
  familyData = family["Internal"];
  nTotal = familyData["TotalPropagatorCount"];
  nExp = familyData["ExplicitPropagatorCount"];
  nAux = familyData["AuxiliaryPropagatorCount"];
  type = gfObject["Type"];

  If[!VectorQ[sourcePowers, IntegerQ[#] && # >= 0 &],
    Return @ baikovFailure[
      "InvalidSourcePowers",
      "Source powers must be a list of non-negative integers.",
      <|"SourcePowers" -> sourcePowers|>
    ]
  ];
  If[Length[sourcePowers] =!= nTotal,
    Return @ baikovFailure[
      "SourcePowerLengthMismatch",
      "Source powers must have the same length as the completed family.",
      <|"SourcePowers" -> sourcePowers, "ExpectedLength" -> nTotal|>
    ]
  ];

  Switch[type,
    "TypeI",
      If[!VectorQ[Take[sourcePowers, nExp], # >= 1 &] || (nAux == 1 && sourcePowers[[nTotal]] =!= 0),
        Return @ baikovFailure[
          "InvalidTypeISourcePowers",
          "For Type I, explicit propagator powers must be positive and the auxiliary propagator power must be 0.",
          <|"SourcePowers" -> sourcePowers|>
        ]
      ],
    "Top" | "TypeII" | "TypeIII",
      If[!VectorQ[sourcePowers, # >= 1 &],
        Return @ baikovFailure[
          "InvalidSourcePowers",
          "For the current target type, all source powers must be positive integers.",
          <|"SourcePowers" -> sourcePowers|>
        ]
      ],
    _,
      Return @ baikovFailure[
        "UnsupportedGFObject",
        "The generating-function object is not supported for coefficient extraction.",
        <|"Type" -> type|>
      ]
  ];

  True
];
