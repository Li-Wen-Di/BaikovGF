# self_energy_3loop_1ext supported-target validation

只列当前程序支持的目标：

`{1,1,1,0,1,1,1,1,1}`

| Source | Status | Build(s) | Extract(s) | Compare(s) | Total(s) | Note |
| --- | --- | ---: | ---: | ---: | ---: | --- |
| `{1,1,1,0,1,1,1,1,2}` | `analytic-ok` | 18.171 | 0.076 | 0.001 | 18.248 | `Ratio = 1` |
| `{1,1,1,0,1,1,1,1,3}` | `mismatch` | 0.000 | 2.173 | 0.296 | 2.468 | Differs by a branch factor involving `Sqrt[(3 m^2 - s)^(-1)] Sqrt[3 m^2 - s]`. |
| `{1,1,1,0,1,1,1,1,4}` | `analytic-ok` | 0.000 | 1.366 | 0.001 | 1.368 | `Ratio = 1` |
| `{1,1,1,0,1,1,1,2,2}` | `analytic-ok` | 0.000 | 0.070 | 0.001 | 0.071 | `Ratio = 1` |
| `{1,1,1,0,1,2,2,2,2}` | `analytic-ok` | 0.000 | 0.208 | 0.001 | 0.209 | `Ratio = 1` |
| `{1,1,2,0,2,2,2,2,2}` | `failure` | 0.000 | 240.137 | 0.000 | 240.137 | Symbolic extraction hit the 240 s limit and aborted. |
