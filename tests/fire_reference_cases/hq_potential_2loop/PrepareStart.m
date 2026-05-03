SetDirectory[DirectoryName[$InputFileName]];
$HistoryLength = 0;
Get["/home/lwd/git/fire/FIRE6/FIRE6.m"];

Internal = {l, r};
External = {p, v};
Propagators = {l^2, r^2, (l - p)^2, (-p + r)^2, (l - r)^2, l*v, r*v};
Replacements = {p^2 -> s, p*v -> u, v^2 -> t};

PrepareIBP[];
Prepare[AutoDetectRestrictions -> True, LI -> True, Parallel -> False];
SaveStart["hq_potential_2loop"];