SetDirectory[DirectoryName[$InputFileName]];
$HistoryLength = 0;
Get["/home/lwd/git/fire/FIRE6/FIRE6.m"];

Internal = {k1, k2};
External = {};
Propagators = {k1^2 - m1sq, k2^2 - m2sq, (k1 + k2)^2 - m3sq};
Replacements = {};

PrepareIBP[];
Prepare[AutoDetectRestrictions -> True, LI -> True, Parallel -> False];
SaveStart["vacuum_2loop"];