# Computer-Architecture-Project

JHU Computer Architecture 525.612 Project

FPGA Implementation of extended integer instructions `log2()` and `sqrt()`

## Project Details

The project implements two extended integer instructions, `log2()` and `sqrt()`, on an FPGA. The implementation is done using Verilog HDL and is designed to be integrated into a RISC-V processor pipeline. The `log2()` instruction calculates the base-2 logarithm of an integer, while the `sqrt()` instruction computes the square root of an integer.

Note: The `log2()` instruction is equivalent to `ceil(log2(x))` for positive integers, and the `sqrt()` instruction is equivalent to `floor(sqrt(x))` for non-negative integers.

## Implementation Details

### Custom ISA Extension

![RISC-V Core Instruction Format](/img/RISC-V%20Core%20Instruction%20Format.png)

I use the RISC-V instruction reference data green card as a reference for the instruction format. The custom instructions `log2()` and `sqrt()` are implemented as R-type instructions, which consist of an opcode, funct3, funct7, and register fields.

Since the RISC-V ISA does not have built-in instructions for logarithm and square root, we will define custom opcodes and function codes for these operations. The implementation will involve creating a new instruction format that can be decoded by the processor's control unit.

Instruction | Name | Format | Opcode | funct3 | funct7 | Description
--- | --- | --- | --- | --- | --- | ---
`log2` | Logarithm Base 2 | R-type | 0b0110011 | 0x0 | 0x08 | Computes the base-2 logarithm of an integer
`sqrt` | Square Root | R-type | 0b0110011 | 0x1 | 0x08 | Computes the square root of an integer

* `sqrt` - `funct7 = 0001000`, `funct3 = 001`, `opcode = 0110011` 
* `log2` - `funct7 = 0001000`, `funct3 = 000`, `opcode = 0110011`

``` assembly
sqrt rd, rs1, x0   -> rd = isqrt(rs1)
log2 rd, rs1, x0   -> rd = ceil(log2(rs1))
```

### Algorithm

#### Integer Logarithm Base 2 (`log2()`)

The `log2()` instruction can be implemented using a simple loop that shifts the input integer to the right until it becomes zero. The number of shifts required to reduce the integer to zero gives the value of `log2(x)`.

However, this method can be inefficient on FPGA for large integers. Instead, we can use a more efficient approach based on the position of the most significant bit (MSB). The `log2(x)` can be calculated by finding the position of the MSB in the binary representation of the integer.

#### Integer Square Root (`sqrt()`)

## Limitations

Getting a high-level language compiler to generate assembly that uses these new instructions, or modifying the assembler/compiler flow so custom RISC-V assembly can be translated into machine code, would require compiler changes. That is really a separate  area of computer engineering. 

I may explore how compilers work after this course, but for this project my focus is narrower: I will manually encode the `log2` and `sqrt` instructions into  machine code and load them onto the FPGA. The RISC-V CPU running on the FPGA will then decode those machine words and invoke the corresponding arithmetic hardware.

## This Repository

## Reference

1. [RISC-V Reference Data Green Card](/RISC-V-Reference-Data-Green-Card.pdf)

2. [An Efficient Implementation of the Non-Restoring Square Root Algorithm in Gate Level](https://www.ijcte.org/papers/281-G850.pdf)

3. [Parallel-array implementations of a non-restoring square root algorithm](https://ieeexplore.ieee.org/document/628940/metrics#metrics)

4. [Non-Restoring Algorithm for Square Root](https://digitalsystemdesign.in/non-restoring-algorithm-for-square-root/?srsltid=AfmBOooe-J1mTJxCGnhCMuo_kYEsorPiwPaaQxmiC2l5sYe-qcwxKrWD)