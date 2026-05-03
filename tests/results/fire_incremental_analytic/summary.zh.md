# FIRE 解析回归测试

由 `tests/run_fire_incremental_analytic.wls` 自动生成。

## 状态统计

| 状态 | 数量 |
| --- | ---: |
| analytic-ok | 131 |

## 逐例结果

| 图族 | 源幂次 | 目标幂次 | 类型 | 包时间(s) | 状态 | 备注 |
| --- | --- | --- | --- | ---: | --- | --- |
| bubble_massive | {1, 2} | {0, 1} | TypeII | 0.663 | analytic-ok |  |
| bubble_massive | {1, 2} | {1, 0} | TypeII | 0.441 | analytic-ok |  |
| bubble_massive | {1, 2} | {1, 1} | Top | 0.051 | analytic-ok |  |
| bubble_massive | {2, 1} | {0, 1} | TypeII | 0.540 | analytic-ok |  |
| bubble_massive | {2, 1} | {1, 0} | TypeII | 0.617 | analytic-ok |  |
| bubble_massive | {2, 1} | {1, 1} | Top | 0.067 | analytic-ok |  |
| bubble_massive | {2, 2} | {0, 1} | TypeII | 0.637 | analytic-ok |  |
| bubble_massive | {2, 2} | {1, 0} | TypeII | 0.643 | analytic-ok |  |
| bubble_massive | {2, 2} | {1, 1} | Top | 0.118 | analytic-ok |  |
| bubble_massive | {3, 3} | {0, 1} | TypeII | 0.957 | analytic-ok |  |
| bubble_massive | {3, 3} | {1, 0} | TypeII | 0.857 | analytic-ok |  |
| bubble_massive | {3, 3} | {1, 1} | Top | 0.220 | analytic-ok |  |
| bubble_massive | {4, 5} | {0, 1} | TypeII | 5.197 | analytic-ok |  |
| bubble_massive | {4, 5} | {1, 0} | TypeII | 11.414 | analytic-ok |  |
| bubble_massive | {4, 5} | {1, 1} | Top | 0.127 | analytic-ok |  |
| bubble_massive | {6, 6} | {0, 1} | TypeII | 58.324 | analytic-ok |  |
| bubble_massive | {6, 6} | {1, 0} | TypeII | 54.295 | analytic-ok |  |
| bubble_massive | {6, 6} | {1, 1} | Top | 0.348 | analytic-ok |  |
| hq_potential_2loop | {1, 1, 1, 1, 1, 1, 2} | {1, 1, 1, 1, 0, 1, 1} | TypeIII | 1.035 | analytic-ok |  |
| hq_potential_2loop | {1, 1, 1, 1, 1, 2, 1} | {1, 1, 1, 1, 0, 1, 1} | TypeIII | 0.931 | analytic-ok |  |
| hq_potential_2loop | {1, 1, 1, 1, 2, 2, 1} | {1, 1, 1, 1, 0, 1, 1} | TypeIII | 1.365 | analytic-ok |  |
| hq_potential_2loop | {1, 1, 1, 2, 2, 2, 1} | {1, 1, 1, 1, 0, 1, 1} | TypeIII | 5.485 | analytic-ok |  |
| hq_potential_2loop | {1, 1, 2, 2, 2, 2, 1} | {1, 1, 1, 1, 0, 1, 1} | TypeIII | 27.893 | analytic-ok |  |
| hq_potential_2loop | {2, 2, 2, 2, 2, 2, 1} | {1, 1, 1, 1, 0, 1, 1} | TypeIII | 605.756 | analytic-ok |  |
| hq_triangle_1loop | {1, 1, 2} | {0, 1, 1} | TypeII | 2.819 | analytic-ok |  |
| hq_triangle_1loop | {1, 1, 2} | {1, 1, 0} | TypeII | 2.471 | analytic-ok |  |
| hq_triangle_1loop | {1, 1, 2} | {1, 1, 1} | Top | 0.094 | analytic-ok |  |
| hq_triangle_1loop | {1, 2, 1} | {0, 1, 1} | TypeII | 2.392 | analytic-ok |  |
| hq_triangle_1loop | {1, 2, 1} | {1, 1, 1} | Top | 0.090 | analytic-ok |  |
| hq_triangle_1loop | {1, 2, 2} | {0, 1, 1} | TypeII | 3.267 | analytic-ok |  |
| hq_triangle_1loop | {1, 2, 2} | {1, 1, 0} | TypeII | 2.604 | analytic-ok |  |
| hq_triangle_1loop | {1, 2, 2} | {1, 1, 1} | Top | 0.096 | analytic-ok |  |
| hq_triangle_1loop | {2, 1, 1} | {0, 1, 1} | TypeII | 2.622 | analytic-ok |  |
| hq_triangle_1loop | {2, 1, 1} | {1, 1, 0} | TypeII | 2.522 | analytic-ok |  |
| hq_triangle_1loop | {2, 1, 1} | {1, 1, 1} | Top | 0.098 | analytic-ok |  |
| hq_triangle_1loop | {2, 2, 2} | {0, 1, 1} | TypeII | 3.730 | analytic-ok |  |
| hq_triangle_1loop | {2, 2, 2} | {1, 1, 0} | TypeII | 3.327 | analytic-ok |  |
| hq_triangle_1loop | {2, 2, 2} | {1, 1, 1} | Top | 0.149 | analytic-ok |  |
| hq_triangle_1loop | {3, 3, 3} | {0, 1, 1} | TypeII | 7.032 | analytic-ok |  |
| hq_triangle_1loop | {3, 3, 3} | {1, 1, 0} | TypeII | 5.762 | analytic-ok |  |
| hq_triangle_1loop | {3, 3, 3} | {1, 1, 1} | Top | 0.151 | analytic-ok |  |
| self_energy_3loop_1ext | {1, 1, 1, 0, 1, 1, 1, 1, 2} | {1, 1, 1, 0, 1, 1, 1, 1, 1} | TypeI | 21.085 | analytic-ok |  |
| self_energy_3loop_1ext | {1, 1, 1, 0, 1, 1, 1, 1, 3} | {1, 1, 1, 0, 1, 1, 1, 1, 1} | TypeI | 21.705 | analytic-ok |  |
| self_energy_3loop_1ext | {1, 1, 1, 0, 1, 1, 1, 1, 4} | {1, 1, 1, 0, 1, 1, 1, 1, 1} | TypeI | 21.465 | analytic-ok |  |
| self_energy_3loop_1ext | {1, 1, 1, 0, 1, 1, 1, 2, 2} | {1, 1, 1, 0, 1, 1, 1, 1, 1} | TypeI | 20.980 | analytic-ok |  |
| self_energy_3loop_1ext | {1, 1, 1, 0, 1, 2, 2, 2, 2} | {1, 1, 1, 0, 1, 1, 1, 1, 1} | TypeI | 21.236 | analytic-ok |  |
| self_energy_3loop_1ext | {1, 1, 2, 0, 2, 2, 2, 2, 2} | {1, 1, 1, 0, 1, 1, 1, 1, 1} | TypeI | 67.337 | analytic-ok |  |
| sunset_4prop | {1, 0, 1, 1, 2} | {1, 0, 1, 1, 1} | TypeI | 2.020 | analytic-ok |  |
| sunset_4prop | {1, 0, 1, 3, 1} | {1, 0, 1, 1, 1} | TypeI | 2.275 | analytic-ok |  |
| sunset_4prop | {2, 0, 2, 2, 2} | {1, 0, 1, 1, 1} | TypeI | 3.014 | analytic-ok |  |
| sunset_4prop | {2, 0, 2, 2, 3} | {1, 0, 1, 1, 1} | TypeI | 4.011 | analytic-ok |  |
| sunset_4prop | {2, 0, 2, 3, 3} | {1, 0, 1, 1, 1} | TypeI | 7.203 | analytic-ok |  |
| sunset_4prop | {3, 0, 3, 4, 4} | {1, 0, 1, 1, 1} | TypeI | 848.244 | analytic-ok |  |
| sunset_cut_vertical | {1, 1, 1, 1, 2} | {1, 1, 1, 1, 0} | TypeIII | 0.350 | analytic-ok |  |
| sunset_cut_vertical | {1, 1, 1, 2, 2} | {1, 1, 1, 1, 0} | TypeIII | 0.520 | analytic-ok |  |
| sunset_cut_vertical | {1, 1, 2, 2, 2} | {1, 1, 1, 1, 0} | TypeIII | 2.058 | analytic-ok |  |
| sunset_cut_vertical | {1, 2, 2, 2, 2} | {1, 1, 1, 1, 0} | TypeIII | 9.152 | analytic-ok |  |
| sunset_cut_vertical | {2, 2, 2, 2, 2} | {1, 1, 1, 1, 0} | TypeIII | 32.267 | analytic-ok |  |
| sunset_cut_vertical | {2, 2, 2, 2, 3} | {1, 1, 1, 1, 0} | TypeIII | 33.650 | analytic-ok |  |
| tadpole | {2} | {1} | Top | 0.011 | analytic-ok |  |
| tadpole | {3} | {1} | Top | 0.012 | analytic-ok |  |
| tadpole | {4} | {1} | Top | 0.010 | analytic-ok |  |
| tadpole | {5} | {1} | Top | 0.013 | analytic-ok |  |
| tadpole | {6} | {1} | Top | 0.013 | analytic-ok |  |
| tadpole | {8} | {1} | Top | 0.024 | analytic-ok |  |
| vacuum_2loop | {1, 1, 2} | {0, 1, 1} | TypeII | 0.669 | analytic-ok |  |
| vacuum_2loop | {1, 1, 2} | {1, 0, 1} | TypeII | 0.794 | analytic-ok |  |
| vacuum_2loop | {1, 1, 2} | {1, 1, 0} | TypeII | 0.777 | analytic-ok |  |
| vacuum_2loop | {1, 1, 2} | {1, 1, 1} | Top | 0.047 | analytic-ok |  |
| vacuum_2loop | {1, 1, 3} | {0, 1, 1} | TypeII | 0.743 | analytic-ok |  |
| vacuum_2loop | {1, 1, 3} | {1, 0, 1} | TypeII | 0.811 | analytic-ok |  |
| vacuum_2loop | {1, 1, 3} | {1, 1, 0} | TypeII | 0.742 | analytic-ok |  |
| vacuum_2loop | {1, 1, 3} | {1, 1, 1} | Top | 0.097 | analytic-ok |  |
| vacuum_2loop | {1, 2, 2} | {0, 1, 1} | TypeII | 0.945 | analytic-ok |  |
| vacuum_2loop | {1, 2, 2} | {1, 0, 1} | TypeII | 0.913 | analytic-ok |  |
| vacuum_2loop | {1, 2, 2} | {1, 1, 0} | TypeII | 0.919 | analytic-ok |  |
| vacuum_2loop | {1, 2, 2} | {1, 1, 1} | Top | 0.101 | analytic-ok |  |
| vacuum_2loop | {1, 2, 3} | {0, 1, 1} | TypeII | 1.542 | analytic-ok |  |
| vacuum_2loop | {1, 2, 3} | {1, 0, 1} | TypeII | 1.173 | analytic-ok |  |
| vacuum_2loop | {1, 2, 3} | {1, 1, 0} | TypeII | 0.988 | analytic-ok |  |
| vacuum_2loop | {1, 2, 3} | {1, 1, 1} | Top | 0.111 | analytic-ok |  |
| vacuum_2loop | {2, 2, 2} | {0, 1, 1} | TypeII | 1.358 | analytic-ok |  |
| vacuum_2loop | {2, 2, 2} | {1, 0, 1} | TypeII | 1.277 | analytic-ok |  |
| vacuum_2loop | {2, 2, 2} | {1, 1, 0} | TypeII | 1.381 | analytic-ok |  |
| vacuum_2loop | {2, 2, 2} | {1, 1, 1} | Top | 0.098 | analytic-ok |  |
| vacuum_2loop | {2, 2, 3} | {0, 1, 1} | TypeII | 1.980 | analytic-ok |  |
| vacuum_2loop | {2, 2, 3} | {1, 0, 1} | TypeII | 2.314 | analytic-ok |  |
| vacuum_2loop | {2, 2, 3} | {1, 1, 0} | TypeII | 2.036 | analytic-ok |  |
| vacuum_2loop | {2, 2, 3} | {1, 1, 1} | Top | 0.078 | analytic-ok |  |
| vacuum_3loop | {1, 1, 1, 1, 1, 2} | {0, 1, 1, 1, 1, 1} | TypeII | 10.754 | analytic-ok |  |
| vacuum_3loop | {1, 1, 1, 1, 1, 2} | {1, 0, 1, 1, 1, 1} | TypeII | 4.037 | analytic-ok |  |
| vacuum_3loop | {1, 1, 1, 1, 1, 2} | {1, 1, 0, 1, 1, 1} | TypeII | 10.633 | analytic-ok |  |
| vacuum_3loop | {1, 1, 1, 1, 1, 2} | {1, 1, 1, 0, 1, 1} | TypeII | 4.275 | analytic-ok |  |
| vacuum_3loop | {1, 1, 1, 1, 1, 2} | {1, 1, 1, 1, 0, 1} | TypeII | 4.325 | analytic-ok |  |
| vacuum_3loop | {1, 1, 1, 1, 1, 2} | {1, 1, 1, 1, 1, 0} | TypeII | 3.945 | analytic-ok |  |
| vacuum_3loop | {1, 1, 1, 1, 1, 2} | {1, 1, 1, 1, 1, 1} | Top | 0.107 | analytic-ok |  |
| vacuum_3loop | {1, 1, 1, 1, 2, 2} | {0, 1, 1, 1, 1, 1} | TypeII | 11.027 | analytic-ok |  |
| vacuum_3loop | {1, 1, 1, 1, 2, 2} | {1, 0, 1, 1, 1, 1} | TypeII | 4.768 | analytic-ok |  |
| vacuum_3loop | {1, 1, 1, 1, 2, 2} | {1, 1, 0, 1, 1, 1} | TypeII | 10.465 | analytic-ok |  |
| vacuum_3loop | {1, 1, 1, 1, 2, 2} | {1, 1, 1, 0, 1, 1} | TypeII | 4.334 | analytic-ok |  |
| vacuum_3loop | {1, 1, 1, 1, 2, 2} | {1, 1, 1, 1, 0, 1} | TypeII | 4.426 | analytic-ok |  |
| vacuum_3loop | {1, 1, 1, 1, 2, 2} | {1, 1, 1, 1, 1, 0} | TypeII | 4.320 | analytic-ok |  |
| vacuum_3loop | {1, 1, 1, 1, 2, 2} | {1, 1, 1, 1, 1, 1} | Top | 0.079 | analytic-ok |  |
| vacuum_3loop | {1, 1, 1, 2, 2, 2} | {0, 1, 1, 1, 1, 1} | TypeII | 13.452 | analytic-ok |  |
| vacuum_3loop | {1, 1, 1, 2, 2, 2} | {1, 0, 1, 1, 1, 1} | TypeII | 7.505 | analytic-ok |  |
| vacuum_3loop | {1, 1, 1, 2, 2, 2} | {1, 1, 0, 1, 1, 1} | TypeII | 14.704 | analytic-ok |  |
| vacuum_3loop | {1, 1, 1, 2, 2, 2} | {1, 1, 1, 0, 1, 1} | TypeII | 5.471 | analytic-ok |  |
| vacuum_3loop | {1, 1, 1, 2, 2, 2} | {1, 1, 1, 1, 0, 1} | TypeII | 5.412 | analytic-ok |  |
| vacuum_3loop | {1, 1, 1, 2, 2, 2} | {1, 1, 1, 1, 1, 0} | TypeII | 5.316 | analytic-ok |  |
| vacuum_3loop | {1, 1, 1, 2, 2, 2} | {1, 1, 1, 1, 1, 1} | Top | 0.129 | analytic-ok |  |
| vacuum_3loop | {1, 1, 2, 2, 2, 2} | {0, 1, 1, 1, 1, 1} | TypeII | 32.928 | analytic-ok |  |
| vacuum_3loop | {1, 1, 2, 2, 2, 2} | {1, 0, 1, 1, 1, 1} | TypeII | 25.582 | analytic-ok |  |
| vacuum_3loop | {1, 1, 2, 2, 2, 2} | {1, 1, 0, 1, 1, 1} | TypeII | 15.502 | analytic-ok |  |
| vacuum_3loop | {1, 1, 2, 2, 2, 2} | {1, 1, 1, 0, 1, 1} | TypeII | 13.028 | analytic-ok |  |
| vacuum_3loop | {1, 1, 2, 2, 2, 2} | {1, 1, 1, 1, 0, 1} | TypeII | 6.420 | analytic-ok |  |
| vacuum_3loop | {1, 1, 2, 2, 2, 2} | {1, 1, 1, 1, 1, 0} | TypeII | 6.251 | analytic-ok |  |
| vacuum_3loop | {1, 1, 2, 2, 2, 2} | {1, 1, 1, 1, 1, 1} | Top | 0.097 | analytic-ok |  |
| vacuum_3loop | {1, 2, 2, 2, 2, 2} | {0, 1, 1, 1, 1, 1} | TypeII | 18.857 | analytic-ok |  |
| vacuum_3loop | {1, 2, 2, 2, 2, 2} | {1, 0, 1, 1, 1, 1} | TypeII | 20.561 | analytic-ok |  |
| vacuum_3loop | {1, 2, 2, 2, 2, 2} | {1, 1, 0, 1, 1, 1} | TypeII | 22.971 | analytic-ok |  |
| vacuum_3loop | {1, 2, 2, 2, 2, 2} | {1, 1, 1, 0, 1, 1} | TypeII | 20.541 | analytic-ok |  |
| vacuum_3loop | {1, 2, 2, 2, 2, 2} | {1, 1, 1, 1, 0, 1} | TypeII | 4.480 | analytic-ok |  |
| vacuum_3loop | {1, 2, 2, 2, 2, 2} | {1, 1, 1, 1, 1, 0} | TypeII | 20.442 | analytic-ok |  |
| vacuum_3loop | {1, 2, 2, 2, 2, 2} | {1, 1, 1, 1, 1, 1} | Top | 0.055 | analytic-ok |  |
| vacuum_3loop | {2, 2, 2, 2, 2, 2} | {0, 1, 1, 1, 1, 1} | TypeII | 30.690 | analytic-ok |  |
| vacuum_3loop | {2, 2, 2, 2, 2, 2} | {1, 0, 1, 1, 1, 1} | TypeII | 28.536 | analytic-ok |  |
| vacuum_3loop | {2, 2, 2, 2, 2, 2} | {1, 1, 0, 1, 1, 1} | TypeII | 31.340 | analytic-ok |  |
| vacuum_3loop | {2, 2, 2, 2, 2, 2} | {1, 1, 1, 0, 1, 1} | TypeII | 25.157 | analytic-ok |  |
| vacuum_3loop | {2, 2, 2, 2, 2, 2} | {1, 1, 1, 1, 0, 1} | TypeII | 28.381 | analytic-ok |  |
| vacuum_3loop | {2, 2, 2, 2, 2, 2} | {1, 1, 1, 1, 1, 0} | TypeII | 27.697 | analytic-ok |  |
| vacuum_3loop | {2, 2, 2, 2, 2, 2} | {1, 1, 1, 1, 1, 1} | Top | 0.068 | analytic-ok |  |
