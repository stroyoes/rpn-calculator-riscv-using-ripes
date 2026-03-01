# =============================================================================
# RPN (Reverse Polish Notation) Calculator
# RISC-V RV32I Assembly - Ripes Simulator Compatible
#
# Supported operators: + - * /
# Multi-digit integers supported
# Uses ECALL for I/O (Ripes standard)
#
# ECALL reference (Ripes):
#   a7=4  -> print string (a0 = address)
#   a7=12 -> read char    (result in a0)
#   a7=1  -> print integer (a0 = value)
#   a7=10 -> exit
# =============================================================================

.data

prompt:
    .string "Evaluating . . .\n"
res_str:
    .string "Result: "
newline:
    .string "\n"
rpn_expr:
    .string "5 3 + 2 *" #  NOTE: Hardcoded expression for evaluation; You can change this to see a different result
num_stack:
    .zero 200

.text
.globl _start

_start:
    # Print the expression being evaluated
    li      a7, 4
    la      a0, prompt
    ecall

    # Evaluate the hardcoded RPN expression
    la      a0, rpn_expr
    call    evaluate_rpn

    mv      s0, a0

    li      a7, 4
    la      a0, res_str
    ecall

    li      a7, 1
    mv      a0, s0
    ecall

    li      a7, 4
    la      a0, newline
    ecall

    li      a7, 10
    ecall


# =============================================================================
# bool is_digit(char c)
# Args:   a0 = c
# Return: a0 = 1 if digit, 0 otherwise
# =============================================================================
is_digit:
    li      t0, 48
    li      t1, 57
    blt     a0, t0, not_digit
    blt     t1, a0, not_digit
    li      a0, 1
    ret
not_digit:
    li      a0, 0
    ret


# =============================================================================
# bool is_operator(char c)
# Args:   a0 = c
# Return: a0 = 1 if operator, 0 otherwise
# =============================================================================
is_operator:
    li      t0, 43
    beq     a0, t0, is_op_yes
    li      t0, 45
    beq     a0, t0, is_op_yes
    li      t0, 42
    beq     a0, t0, is_op_yes
    li      t0, 47
    beq     a0, t0, is_op_yes
    li      a0, 0
    ret
is_op_yes:
    li      a0, 1
    ret


# =============================================================================
# bool is_space(char c)
# Args:   a0 = c
# Return: a0 = 1 if whitespace, 0 otherwise
# ASCII: space=32, tab=9, newline=10, vtab=11, formfeed=12, carriage=13
# =============================================================================
is_space:
    li      t0, 32
    beq     a0, t0, is_sp_yes
    li      t0, 9
    beq     a0, t0, is_sp_yes
    li      t0, 10
    beq     a0, t0, is_sp_yes
    li      t0, 11
    beq     a0, t0, is_sp_yes
    li      t0, 12
    beq     a0, t0, is_sp_yes
    li      t0, 13
    beq     a0, t0, is_sp_yes
    li      a0, 0
    ret
is_sp_yes:
    li      a0, 1
    ret


# =============================================================================
# int char_to_digit(char c)  ->  c - 48
# Args:   a0 = c
# Return: a0 = digit value
# =============================================================================
char_to_digit:
    li      t0, 48
    sub     a0, a0, t0
    ret


# =============================================================================
# int multiply(int a, int b)  ->  repeated addition
# Args:   a0 = a,  a1 = b
# Return: a0 = a * b
# =============================================================================
multiply:
    li      t0, 0
    li      t1, 0
mul_loop:
    bge     t1, a1, mul_done
    add     t0, t0, a0
    addi    t1, t1, 1
    j       mul_loop
mul_done:
    mv      a0, t0
    ret


# =============================================================================
# int apply_operator(int a, int b, char op)
# Args:   a0 = a,  a1 = b,  a2 = op
# Return: a0 = result
# =============================================================================
apply_operator:
    li      t0, 43
    beq     a2, t0, op_add
    li      t0, 45
    beq     a2, t0, op_sub
    li      t0, 42
    beq     a2, t0, op_mul
    li      t0, 47
    beq     a2, t0, op_div
    li      a0, 0
    ret

op_add:
    add     a0, a0, a1
    ret

op_sub:
    sub     a0, a0, a1
    ret

op_mul:
    addi    sp, sp, -4
    sw      ra, 0(sp)
    call    multiply
    lw      ra, 0(sp)
    addi    sp, sp, 4
    ret

op_div:
    beqz    a1, div_by_zero
    li      t3, 0
    bge     a0, zero, div_a_pos
    sub     a0, zero, a0
    li      t3, 1
div_a_pos:
    bge     a1, zero, div_b_pos
    sub     a1, zero, a1
    xori    t3, t3, 1
div_b_pos:
    li      t0, 0
div_loop:
    blt     a0, a1, div_loop_done
    sub     a0, a0, a1
    addi    t0, t0, 1
    j       div_loop
div_loop_done:
    beqz    t3, div_pos_result
    sub     t0, zero, t0
div_pos_result:
    mv      a0, t0
    ret
div_by_zero:
    li      a0, 0
    ret


# =============================================================================
# push(val): a0 = value to push
# Uses s11 as stack top index, num_stack as base
# =============================================================================
push:
    la      t0, num_stack
    slli    t1, s11, 2
    add     t0, t0, t1
    sw      a0, 0(t0)
    addi    s11, s11, 1
    ret

# pop(): returns a0 = popped value
pop:
    addi    s11, s11, -1
    la      t0, num_stack
    slli    t1, s11, 2
    add     t0, t0, t1
    lw      a0, 0(t0)
    ret


# =============================================================================
# int evaluate_rpn(const char* expr)
# Args:   a0 = pointer to null-terminated expression string
# Return: a0 = result
# =============================================================================
evaluate_rpn:
    addi    sp, sp, -20
    sw      ra,  0(sp)
    sw      s0,  4(sp)
    sw      s1,  8(sp)
    sw      s2, 12(sp)
    sw      s3, 16(sp)

    mv      s0, a0
    li      s1, 0
    li      s11, 0

eval_loop:
    add     t0, s0, s1
    lb      t1, 0(t0)
    beqz    t1, eval_done

    mv      a0, t1
    addi    sp, sp, -4
    sw      t1, 0(sp)
    call    is_space
    lw      t1, 0(sp)
    addi    sp, sp, 4
    bnez    a0, eval_next

    mv      a0, t1
    addi    sp, sp, -4
    sw      t1, 0(sp)
    call    is_digit
    lw      t1, 0(sp)
    addi    sp, sp, 4
    beqz    a0, check_op

    li      s2, 0
num_loop:
    add     t0, s0, s1
    lb      t2, 0(t0)

    mv      a0, t2
    addi    sp, sp, -8
    sw      t2, 0(sp)
    sw      s2, 4(sp)
    call    is_digit
    lw      s2, 4(sp)
    lw      t2, 0(sp)
    addi    sp, sp, 8
    beqz    a0, num_done

    mv      a0, s2
    li      a1, 10
    addi    sp, sp, -8
    sw      t2, 0(sp)
    sw      s1, 4(sp)
    call    multiply
    lw      s1, 4(sp)
    lw      t2, 0(sp)
    addi    sp, sp, 8

    mv      s2, a0
    mv      a0, t2
    addi    sp, sp, -4
    sw      s2, 0(sp)
    call    char_to_digit
    lw      s2, 0(sp)
    addi    sp, sp, 4

    add     s2, s2, a0
    addi    s1, s1, 1
    j       num_loop

num_done:
    mv      a0, s2
    addi    sp, sp, -4
    sw      s1, 0(sp)
    call    push
    lw      s1, 0(sp)
    addi    sp, sp, 4
    addi    s1, s1, -1
    j       eval_next

check_op:
    mv      a0, t1
    addi    sp, sp, -4
    sw      t1, 0(sp)
    call    is_operator
    lw      t1, 0(sp)
    addi    sp, sp, 4
    beqz    a0, eval_next

    addi    sp, sp, -8
    sw      t1, 0(sp)
    sw      s1, 4(sp)
    call    pop
    lw      s1, 4(sp)
    lw      t1, 0(sp)
    addi    sp, sp, 8
    mv      s2, a0

    addi    sp, sp, -12
    sw      t1,  0(sp)
    sw      s1,  4(sp)
    sw      s2,  8(sp)
    call    pop
    lw      s2,  8(sp)
    lw      s1,  4(sp)
    lw      t1,  0(sp)
    addi    sp, sp, 12
    mv      s3, a0

    mv      a0, s3
    mv      a1, s2
    mv      a2, t1
    addi    sp, sp, -4
    sw      s1, 0(sp)
    call    apply_operator
    lw      s1, 0(sp)
    addi    sp, sp, 4

    addi    sp, sp, -4
    sw      s1, 0(sp)
    call    push
    lw      s1, 0(sp)
    addi    sp, sp, 4

eval_next:
    addi    s1, s1, 1
    j       eval_loop

eval_done:
    addi    sp, sp, -4
    sw      s1, 0(sp)
    call    pop
    lw      s1, 0(sp)
    addi    sp, sp, 4

    lw      ra,  0(sp)
    lw      s0,  4(sp)
    lw      s1,  8(sp)
    lw      s2, 12(sp)
    lw      s3, 16(sp)
    addi    sp, sp, 20
    ret
