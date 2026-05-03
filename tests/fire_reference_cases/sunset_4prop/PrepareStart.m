SetDirectory[DirectoryName[$InputFileName]];
$HistoryLength = 0;
Get["/home/lwd/git/fire/FIRE6/FIRE6.m"];

Internal = {k1, k2};
External = {p1};
Propagators = {k1^2 - m, -m + (k1 + p1)^2, k2^2 - m, -m + (k2 + p1)^2, (k1 + k2)^2 - m};
Replacements = {p1^2 -> s};

PrepareIBP[];
Prepare[AutoDetectRestrictions -> True, LI -> True, Parallel -> False];
SaveStart["sunset_4prop"];