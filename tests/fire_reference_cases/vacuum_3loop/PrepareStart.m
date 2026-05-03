SetDirectory[DirectoryName[$InputFileName]];
$HistoryLength = 0;
Get["/home/lwd/git/fire/FIRE6/FIRE6.m"];

Internal = {k1, k2, k3};
External = {};
Propagators = {k1^2 - m, k2^2 - m, k3^2 - m, (k1 - k2)^2 - m, (k2 - k3)^2 - m, (k1 - k3)^2 - m};
Replacements = {};

PrepareIBP[];
Prepare[AutoDetectRestrictions -> True, LI -> True, Parallel -> False];
SaveStart["vacuum_3loop"];