# ------------------------------------------------------------
# SAD - Custom Instruction Version
# ------------------------------------------------------------

    lui   x1, 0x64785
    addi  x1, x1, 0x032

    lui   x2, 0x69766
    addi  x2, x2, -204

    # SAD x3, x1, x2
    # Custom instruction:
    # funct7 = 0000000
    # rs2    = x2
    # rs1    = x1
    # funct3 = 000
    # rd     = x3
    # opcode = CUSTOM_0 (0x0B)

    .word 0x0020818B

END:
    jal x0, END