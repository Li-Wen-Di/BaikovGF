SetDirectory[DirectoryName[$InputFileName]];
$HistoryLength = 0;
Get["/home/lwd/git/fire/FIRE6/FIRE6.m"];

Internal = {l1, l2, l3};
External = {p};
Propagators = {l1^2 - m^2, l2^2 - m^2, l3^2 - m^2, (l1 - p)^2, -m^2 + (l2 - p)^2, -m^2 + (l3 - p)^2, (l1 - l2)^2 - m^2, (l1 - l3)^2 - m^2, (l2 - l3)^2 - m^2};
Replacements = {p^2 -> s};

PrepareIBP[];
Prepare[AutoDetectRestrictions -> True, LI -> True, Parallel -> False];
SaveStart["self_energy_3loop_1ext"];