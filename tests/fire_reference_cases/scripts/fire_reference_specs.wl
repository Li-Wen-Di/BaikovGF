paperFireCases = {
  <|
    "Name" -> "Tadpole",
    "Slug" -> "tadpole",
    "SymbolBase" -> "tadpoleOneLoop",
    "Section" -> "5.1",
    "PaperType" -> "Top",
    "Description" -> "One-loop tadpole warm-up example.",
    "ProblemID" -> 2,
    "Propagators" -> {
      BaikovGF`SP[k1, k1] - m
    },
    "LoopMomenta" -> {k1},
    "ExternalMomenta" -> {},
    "KinematicRules" -> {},
    "Variables" -> {d, m},
    "SourcePowersList" -> {
      {2}, {3}, {4}, {5}, {6}, {8}
    }
  |>,
  <|
    "Name" -> "Massive Bubble",
    "Slug" -> "bubble_massive",
    "SymbolBase" -> "bubbleMassive",
    "Section" -> "5.2",
    "PaperType" -> "TypeII",
    "Description" -> "Massive one-loop bubble with two quadratic propagators.",
    "ProblemID" -> 2,
    "Propagators" -> {
      BaikovGF`SP[k1, k1] - m1sq,
      BaikovGF`SP[k1 + p1, k1 + p1] - m2sq
    },
    "LoopMomenta" -> {k1},
    "ExternalMomenta" -> {p1},
    "KinematicRules" -> {
      BaikovGF`SP[p1, p1] -> s
    },
    "Variables" -> {d, m1sq, m2sq, s},
    "SourcePowersList" -> {
      {1, 2}, {2, 1}, {2, 2}, {3, 3}, {4, 5}, {6, 6}
    }
  |>,
  <|
    "Name" -> "One-Loop Heavy-Quark Triangle",
    "Slug" -> "hq_triangle_1loop",
    "SymbolBase" -> "hqTriangleOneLoop",
    "Section" -> "5.3",
    "PaperType" -> "TypeII",
    "Description" -> "One-loop heavy-quark-potential triangle with one linear propagator.",
    "ProblemID" -> 2,
    "Propagators" -> {
      BaikovGF`SP[l, l],
      BaikovGF`SP[l + p, l + p],
      BaikovGF`SP[l, v]
    },
    "LoopMomenta" -> {l},
    "ExternalMomenta" -> {p, v},
    "KinematicRules" -> {
      BaikovGF`SP[p, p] -> s,
      BaikovGF`SP[p, v] -> u,
      BaikovGF`SP[v, v] -> t
    },
    "Variables" -> {d, s, t, u},
    "SourcePowersList" -> {
      {1, 1, 2}, {1, 2, 1}, {1, 2, 2}, {2, 1, 1}, {2, 2, 2}, {3, 3, 3}
    },
    "Notes" -> "The legacy notebook sets the quadratic masses to zero before reduction."
  |>,
  <|
    "Name" -> "Two-Loop Vacuum",
    "Slug" -> "vacuum_2loop",
    "SymbolBase" -> "vacuumTwoLoop",
    "Section" -> "6.1",
    "PaperType" -> "TypeII",
    "Description" -> "Two-loop vacuum diagram with three quadratic propagators.",
    "ProblemID" -> 2,
    "Propagators" -> {
      BaikovGF`SP[k1, k1] - m1sq,
      BaikovGF`SP[k2, k2] - m2sq,
      BaikovGF`SP[k1 + k2, k1 + k2] - m3sq
    },
    "LoopMomenta" -> {k1, k2},
    "ExternalMomenta" -> {},
    "KinematicRules" -> {},
    "Variables" -> {d, m1sq, m2sq, m3sq},
    "SourcePowersList" -> {
      {1, 1, 2}, {1, 1, 3}, {1, 2, 2}, {1, 2, 3}, {2, 2, 2}, {2, 2, 3}
    }
  |>,
  <|
    "Name" -> "Three-Loop Vacuum",
    "Slug" -> "vacuum_3loop",
    "SymbolBase" -> "vacuumThreeLoop",
    "Section" -> "6.1",
    "PaperType" -> "TypeII",
    "Description" -> "Three-loop vacuum diagram with six equal-mass propagators.",
    "ProblemID" -> 2,
    "Propagators" -> {
      BaikovGF`SP[k1, k1] - m,
      BaikovGF`SP[k2, k2] - m,
      BaikovGF`SP[k3, k3] - m,
      BaikovGF`SP[k1 - k2, k1 - k2] - m,
      BaikovGF`SP[k2 - k3, k2 - k3] - m,
      BaikovGF`SP[k1 - k3, k1 - k3] - m
    },
    "LoopMomenta" -> {k1, k2, k3},
    "ExternalMomenta" -> {},
    "KinematicRules" -> {},
    "Variables" -> {d, m},
    "SourcePowersList" -> {
      {1, 1, 1, 1, 1, 2},
      {1, 1, 1, 1, 2, 2},
      {1, 1, 1, 2, 2, 2},
      {1, 1, 2, 2, 2, 2},
      {1, 2, 2, 2, 2, 2},
      {2, 2, 2, 2, 2, 2}
    }
  |>,
  <|
    "Name" -> "Massless Sunset with Vertical Propagator",
    "Slug" -> "sunset_cut_vertical",
    "SymbolBase" -> "sunsetCutVertical",
    "Section" -> "6.2",
    "PaperType" -> "TypeIII",
    "Description" -> "Massless sunset-type diagram with a vertical propagator.",
    "ProblemID" -> 2,
    "Propagators" -> {
      BaikovGF`SP[k1, k1],
      BaikovGF`SP[k1 - p1, k1 - p1],
      BaikovGF`SP[k2, k2],
      BaikovGF`SP[k2 - p1, k2 - p1],
      BaikovGF`SP[k1 - k2, k1 - k2]
    },
    "LoopMomenta" -> {k1, k2},
    "ExternalMomenta" -> {p1},
    "KinematicRules" -> {
      BaikovGF`SP[p1, p1] -> s
    },
    "Variables" -> {d, s},
    "SourcePowersList" -> {
      {1, 1, 1, 1, 2},
      {1, 1, 1, 2, 2},
      {1, 1, 2, 2, 2},
      {1, 2, 2, 2, 2},
      {2, 2, 2, 2, 2},
      {2, 2, 2, 2, 3}
    }
  |>,
  <|
    "Name" -> "Sunset with Four Propagators",
    "Slug" -> "sunset_4prop",
    "SymbolBase" -> "sunsetFourProp",
    "Section" -> "6.3",
    "PaperType" -> "TypeI",
    "Description" -> "Sunset-type diagram with four propagators, embedded in a completed five-denominator family.",
    "ProblemID" -> 2,
    "Propagators" -> {
      BaikovGF`SP[k1, k1] - m,
      BaikovGF`SP[k1 + p1, k1 + p1] - m,
      BaikovGF`SP[k2, k2] - m,
      BaikovGF`SP[k2 + p1, k2 + p1] - m,
      BaikovGF`SP[k1 + k2, k1 + k2] - m
    },
    "LoopMomenta" -> {k1, k2},
    "ExternalMomenta" -> {p1},
    "KinematicRules" -> {
      BaikovGF`SP[p1, p1] -> s
    },
    "Variables" -> {d, m, s},
    "AuxiliarySlots" -> {2},
    "SourcePowersList" -> {
      {1, 0, 1, 1, 2},
      {1, 0, 1, 3, 1},
      {2, 0, 2, 2, 2},
      {2, 0, 2, 2, 3},
      {2, 0, 2, 3, 3},
      {3, 0, 3, 4, 4}
    }
  |>,
  <|
    "Name" -> "Two-Loop Heavy-Quark Potential",
    "Slug" -> "hq_potential_2loop",
    "SymbolBase" -> "hqPotentialTwoLoop",
    "Section" -> "6.4",
    "PaperType" -> "TypeIII-like",
    "Description" -> "Two-loop heavy-quark-potential family from figure 5(a).",
    "ProblemID" -> 2,
    "Propagators" -> {
      BaikovGF`SP[l, l],
      BaikovGF`SP[r, r],
      BaikovGF`SP[l - p, l - p],
      BaikovGF`SP[r - p, r - p],
      BaikovGF`SP[l - r, l - r],
      BaikovGF`SP[l, v],
      BaikovGF`SP[r, v]
    },
    "LoopMomenta" -> {l, r},
    "ExternalMomenta" -> {p, v},
    "KinematicRules" -> {
      BaikovGF`SP[p, p] -> s,
      BaikovGF`SP[p, v] -> u,
      BaikovGF`SP[v, v] -> t
    },
    "Variables" -> {d, s, t, u},
    "SourcePowersList" -> {
      {1, 1, 1, 1, 1, 1, 2},
      {1, 1, 1, 1, 1, 2, 1},
      {1, 1, 1, 1, 2, 2, 1},
      {1, 1, 1, 2, 2, 2, 1},
      {1, 1, 2, 2, 2, 2, 1},
      {2, 2, 2, 2, 2, 2, 1}
    },
    "Notes" -> "The paper states v.p = 0, but the legacy notebook keeps generic s, t, u."
  |>,
  <|
    "Name" -> "Three-Loop Self-Energy (One External Momentum)",
    "Slug" -> "self_energy_3loop_1ext",
    "SymbolBase" -> "selfEnergyThreeLoopOneExt",
    "Section" -> "6.4",
    "PaperType" -> "TypeI",
    "Description" -> "Three-loop one-external-momentum self-energy family from figure 5(b), using a completed nine-variable family.",
    "ProblemID" -> 2,
    "Propagators" -> {
      BaikovGF`SP[l1, l1] - m^2,
      BaikovGF`SP[l2, l2] - m^2,
      BaikovGF`SP[l3, l3] - m^2,
      BaikovGF`SP[l1 - p, l1 - p],
      BaikovGF`SP[l2 - p, l2 - p] - m^2,
      BaikovGF`SP[l3 - p, l3 - p] - m^2,
      BaikovGF`SP[l1 - l2, l1 - l2] - m^2,
      BaikovGF`SP[l1 - l3, l1 - l3] - m^2,
      BaikovGF`SP[l2 - l3, l2 - l3] - m^2
    },
    "LoopMomenta" -> {l1, l2, l3},
    "ExternalMomenta" -> {p},
    "KinematicRules" -> {
      BaikovGF`SP[p, p] -> s
    },
    "Variables" -> {d, m, s},
    "AuxiliarySlots" -> {4},
    "SourcePowersList" -> {
      {1, 1, 1, 0, 1, 1, 1, 1, 2},
      {1, 1, 1, 0, 1, 1, 1, 1, 3},
      {1, 1, 1, 0, 1, 1, 1, 1, 4},
      {1, 1, 1, 0, 1, 1, 1, 2, 2},
      {1, 1, 1, 0, 1, 2, 2, 2, 2},
      {1, 1, 2, 0, 2, 2, 2, 2, 2}
    }
  |>
};
