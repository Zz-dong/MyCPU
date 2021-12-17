# MyCPU
## 版本更新

### 2021-12-18 更新

- 重写乘法器为32周期移位乘法器，并整合乘除法器，复用转换补码模块。

### 2021-12-8 更新

- 添加div_mul模块 

- 通过选择信号 ，简单整合除法器和乘法器

### 2021-12-8 更新

- 通过passpoint 58

- 添加hilo特殊寄存器，除法器，乘法器 指令

- 添加mfhi, mflo , mthi ,mtlo指令

- 解决移动指令数据相关问题。 解决手段： 添加MEM, WB 到 EX段的定向路径

### 2021-12-1 更新

- 通过passpoint 43

- 添加bgez, bgtz, blez, bltz, bltzal, bgezal, jalr 指令

### 2021-11-28 更新

- 通过passpoint 36

- 添加slt, slti, sltiu, j, add, addi, sub, and, andi, nor, xori, sllv, sra, srav, srl, srlv指令

### 2021-11-27 更新

- 通过passpoint 8

- 解决load指令产生的数据相关。 解决手段：在ID段插入气泡 

- 添加sltu指令


### 2021-11-24 更新
- 解决基础的数据相关。 解决手段：添加EX, MEM, WB到ID段的定向路径


- 添加ori, lui, addiu, beq, subu, jr, jal, addu, sll, or, lw, xor , sw, bne指令



