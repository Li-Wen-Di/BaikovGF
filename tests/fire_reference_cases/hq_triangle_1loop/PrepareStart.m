SetDirectory[DirectoryName[$InputFileName]];
$HistoryLength = 0;
Get["/home/lwd/git/fire/FIRE6/FIRE6.m"];

Internal = {l};
External = {p, v};
Propagators = {l^2, (l + p)^2, l*v};
Replacements = {p^2 -> s, p*v -> u, v^2 -> t};

PrepareIBP[];
Prepare[AutoDetectRestrictions -> True, LI -> True, Parallel -> False];
SaveStart["hq_triangle_1loop"];