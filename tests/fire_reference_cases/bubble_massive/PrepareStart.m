SetDirectory[DirectoryName[$InputFileName]];
$HistoryLength = 0;
Get["/home/lwd/git/fire/FIRE6/FIRE6.m"];

Internal = {k1};
External = {p1};
Propagators = {k1^2 - m1sq, -m2sq + (k1 + p1)^2};
Replacements = {p1^2 -> s};

PrepareIBP[];
Prepare[AutoDetectRestrictions -> True, LI -> True, Parallel -> False];
SaveStart["bubble_massive"];