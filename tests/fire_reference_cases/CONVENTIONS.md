# Naming Conventions

- Each paper family has its own folder: `<slug>/`.
- FIRE symbolic inputs and outputs live at the family root:
  - `PrepareStart.m`
  - `<slug>.config`
  - `<slug>int.m`
  - `<slug>.start`
  - `<slug>.tables`
  - `prepare.log`
  - `fire.log`
- Parsed symbolic coefficients live in:
  - `<slug>/<slug>_index.wl`
  - `<slug>/coefficients/<slug>__src_<a1>_<a2>_... .wl`
- In each coefficient file, Mathematica-safe symbols are named as:
  - `<symbolBase>$src$<a1>$<a2>$...`
  - `<symbolBase>$src$<a1>$<a2>$...$to$<b1>$<b2>$...`
- Here `<a1>,<a2>,...` are the source integral powers and `<b1>,<b2>,...` are the master-integral powers.

# Numeric Prime Fallback

- If symbolic FIRE tables are too slow, numeric prime-mode data is stored under a family subfolder such as:
  - `<slug>/prime_d13_m3_s5_p1/`
- Parsed numeric-prime coefficients live in:
  - `<slug>/prime_d13_m3_s5_p1/parsed/`
  - `<slug>/prime_d13_m3_s5_p1/parsed/coefficients/`
- The corresponding Mathematica symbol prefix is extended with a variant tag, for example:
  - `selfEnergyThreeLoopOneExt$prime$d13$m3$s5$p1$src$...`
