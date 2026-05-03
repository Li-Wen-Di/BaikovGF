SetDirectory[DirectoryName[$InputFileName]];
$HistoryLength = 0;
Get["/home/lwd/git/fire/FIRE6/FIRE6.m"];

Internal = {k1};
External = {};
Propagators = {k1^2 - m};
Replacements = {};

PrepareIBP[];
Prepare[AutoDetectRestrictions -> True, LI -> True, Parallel -> False];
SaveStart["tadpole"];