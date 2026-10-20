# ============================================================
# RV32I Sort and Statistics Test
#
# Original array:
# [0, -7, 18, 99, 2, -42, 51, 11]
#
# Operations:
# 1. Store array in Data Memory
# 2. Bubble Sort - ascending order
# 3. Find MIN and MAX
# 4. Calculate SUM
# 5. Count positive numbers
# 6. Store results in memory
# ============================================================


# ------------------------------------------------------------
# Initialize array in Data Memory
# x10 = base address of array = 0
# ------------------------------------------------------------

addi x10, x0, 0

addi x11, x0, 0
sw   x11, 0(x10)

addi x11, x0, -7
sw   x11, 4(x10)

addi x11, x0, 18
sw   x11, 8(x10)

addi x11, x0, 99
sw   x11, 12(x10)

addi x11, x0, 2
sw   x11, 16(x10)

addi x11, x0, -42
sw   x11, 20(x10)

addi x11, x0, 51
sw   x11, 24(x10)

addi x11, x0, 11
sw   x11, 28(x10)


# ------------------------------------------------------------
# Bubble Sort
#
# x12 = i
# x13 = 7
# x14 = j
# x15 = inner limit = 7 - i
# ------------------------------------------------------------

addi x12, x0, 0
addi x13, x0, 7


outer_cond:

    # if i >= 7 -> sorting finished
    bge  x12, x13, after_sort

    # j = 0
    addi x14, x0, 0

    # inner limit = 7 - i
    addi x15, x0, 7
    sub  x15, x15, x12


inner_cond:

    # if j >= (7 - i) -> finish this pass
    bge  x14, x15, outer_inc

    # offset = j * 4
    slli x16, x14, 2

    # address = base + offset
    add  x17, x10, x16

    # x18 = A[j]
    lw   x18, 0(x17)

    # x19 = A[j+1]
    lw   x19, 4(x17)

    # if A[j+1] < A[j] -> swap
    blt  x19, x18, do_swap

    # otherwise skip swap
    jal  x0, no_swap


do_swap:

    # A[j] = old A[j+1]
    sw   x19, 0(x17)

    # A[j+1] = old A[j]
    sw   x18, 4(x17)


no_swap:

    # j++
    addi x14, x14, 1

    # continue inner loop
    jal  x0, inner_cond


outer_inc:

    # i++
    addi x12, x12, 1

    # continue outer loop
    jal  x0, outer_cond


# ------------------------------------------------------------
# Array is now sorted
# ------------------------------------------------------------

after_sort:

    # MIN = A[0]
    lw   x22, 0(x10)

    # MAX = A[7]
    lw   x23, 28(x10)


# ------------------------------------------------------------
# Calculate statistics
#
# x24 = sum
# x25 = positive count
# x26 = index
# x27 = array size = 8
# ------------------------------------------------------------

addi x24, x0, 0
addi x25, x0, 0
addi x26, x0, 0
addi x27, x0, 8


stats_cond:

    # if index >= 8 -> finished
    bge  x26, x27, store_results

    # offset = index * 4
    slli x28, x26, 2

    # address = base + offset
    add  x29, x10, x28

    # load current array element
    lw   x30, 0(x29)

    # sum += current element
    add  x24, x24, x30

    # if 0 < current element -> positive
    blt  x0, x30, positive

    # otherwise don't increment count
    jal  x0, no_positive


positive:

    # positive_count++
    addi x25, x25, 1


no_positive:

    # index++
    addi x26, x26, 1

    # continue statistics loop
    jal  x0, stats_cond


# ------------------------------------------------------------
# Store calculated results
# ------------------------------------------------------------

store_results:

    # Memory[32] = MIN
    sw   x22, 32(x10)

    # Memory[36] = MAX
    sw   x23, 36(x10)

    # Memory[40] = SUM
    sw   x24, 40(x10)

    # Memory[44] = POSITIVE COUNT
    sw   x25, 44(x10)


# ------------------------------------------------------------
# End program
# ------------------------------------------------------------

halt:

    jal x0, halt