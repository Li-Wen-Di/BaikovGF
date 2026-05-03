# FIRE Reference Cases

This directory stores the FIRE fixtures used to test the Baikov generating-function package against the paper examples.

Generation workflow:

1. `wolframscript -file scripts/generate_fire_reference_inputs.wls`
2. Run `PrepareStart.m` and `FIRE6 -c <slug>` inside each family directory.
3. `wolframscript -file scripts/parse_fire_reference_tables.wls`

| Slug | Family | Section | Type | #Propagators | #Sources |
|---|---|---|---|---:|---:|
| self_energy_3loop_1ext | Three-Loop Self-Energy (One External Momentum) | 6.4 | TypeI | 9 | 6 |
