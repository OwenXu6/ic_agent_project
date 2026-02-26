# 4-Bit Ripple Carry Adder

## 📖 项目简介

本项目实现了一个 **4位波纹进位加法器（Ripple Carry Adder）**，采用结构化 Verilog 设计，由4个全加器（Full Adder）级联构成。进位信号从最低位（LSB）依次传播到最高位（MSB）。

```
        ┌──────┐   ┌──────┐   ┌──────┐   ┌──────┐
 a[3]──►│  FA  │◄──│  FA  │◄──│  FA  │◄──│  FA  │◄── cin
 b[3]──►│  #3  │   │  #2  │   │  #1  │   │  #0  │
        └──┬───┘   └──┬───┘   └──┬───┘   └──┬───┘
 cout◄─────┘          │          │          │
        sum[3]     sum[2]     sum[1]     sum[0]
```

## 📁 项目结构

```
.
├── designs/
│   ├── full_adder.v                    # 1位全加器模块
│   └── ripple_carry_adder_4bit.v       # 4位波纹进位加法器（顶层）
├── tb/
│   └── ripple_carry_adder_4bit_tb.v    # 完整自检测试平台
├── scripts/
│   ├── constraints.sdc                 # SDC 时序约束文件
│   └── innovus_pnr.tcl                 # Innovus 布局布线 TCL 脚本（模板）
├── results/                            # 仿真与P&R输出目录
└── README.md                           # 本文件
```

## 🔧 设计规格

| 参数         | 值                          |
|-------------|----------------------------|
| 位宽         | 4-bit                      |
| 架构         | 波纹进位（Ripple Carry）     |
| 输入端口     | `a[3:0]`, `b[3:0]`, `cin`  |
| 输出端口     | `sum[3:0]`, `cout`         |
| 全加器数量   | 4                          |
| 关键路径     | cin → FA0 → FA1 → FA2 → FA3 → cout |
| 可综合       | ✅ 是                       |
| 时钟         | 无（纯组合逻辑）             |

## 🧪 仿真方法

### 使用 Icarus Verilog 进行功能仿真

```bash
# 1. 编译设计和测试平台
iverilog -o results/ripple_carry_adder_4bit_sim \
    designs/full_adder.v \
    designs/ripple_carry_adder_4bit.v \
    tb/ripple_carry_adder_4bit_tb.v

# 2. 运行仿真
vvp results/ripple_carry_adder_4bit_sim

# 3. 查看波形（可选）
gtkwave results/ripple_carry_adder_4bit.vcd
```

### 测试覆盖范围

测试平台包含两个阶段：
- **Phase 1**: 11 个精选角落用例（corner cases）
  - 全零输入、全一输入
  - 最大进位传播链（如 `0111 + 0001`、`1111 + 0001`）
  - 交替位模式（`1010 + 0101`）
  - 溢出场景
- **Phase 2**: 全部 512 种输入组合的穷举测试
  - 遍历 `a[3:0]` × `b[3:0]` × `cin` 的所有可能

### 预期输出

```
==========================================================
  4-bit Ripple Carry Adder - Testbench
==========================================================

--- Phase 1: Corner Cases ---
  Corner cases completed: 11 passed, 0 failed

--- Phase 2: Exhaustive Test (512 combinations) ---
  Exhaustive test completed: 512 passed, 0 failed

==========================================================
  *** ALL TESTS PASSED *** (512 / 512)
==========================================================
```

## 🏭 布局布线 (Place & Route)

### 使用 Innovus 进行 P&R

```bash
# 前提：需要先用综合工具（如 Genus/Design Compiler）生成门级网表
# 然后运行 Innovus：
innovus -batch -source scripts/innovus_pnr.tcl
```

### P&R 流程步骤

| 步骤 | 描述                           |
|------|-------------------------------|
| 1    | 读取设计数据（LEF/LIB/Netlist）|
| 2    | 建立 Floorplan（70% 利用率）   |
| 3    | 电源规划（Power Rings/Stripes）|
| 4    | 标准单元布局（Placement）       |
| 5    | 时钟树综合（组合逻辑跳过）      |
| 6    | 布线（Global + Detail Route）  |
| 7    | 时序优化（Post-Route Opt）     |
| 8    | 签核检查（DRC/Connectivity）   |
| 9    | 导出结果（GDS/DEF/SDF/SPEF）  |

> ⚠️ 注意：`scripts/innovus_pnr.tcl` 为模板脚本，需根据实际 PDK 修改库文件路径。

## 📝 备注

- 仿真工具 `iverilog` 暂未在当前环境安装，仿真步骤暂时跳过
- Innovus P&R 脚本作为模板保留，暂不执行
- 设计采用 `generate` 语句实现参数化结构，便于扩展到 N 位
