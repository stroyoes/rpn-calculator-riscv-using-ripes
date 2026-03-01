# =============================================================================
# RPN (Reverse Polish Notation) Calculator
# RISC-V RV32I Assembly — Ripes Simulator Compatible
#
# Converted from rpn.h / rpn.c / main.c
#
# Supported operators: + - * /
# Multi-digit integers supported
# Uses ECALL for I/O (Ripes standard)
#
# ECALL reference (Ripes):
#   a7=4  → print string (a0 = address)
#   a7=5  → read integer   (result in a0)  [not used; we read a string instead]
#   a7=8  → read string    (a0 = buffer, a1 = max len)
#   a7=1  → print integer  (a0 = value)
#   a7=11 → print char     (a0 = char)
#   a7=10 → exit
# =============================================================================

.data

prompt:     .string "Enter RPN expression (e.g., 5 3 + 2 *):\n> "
res_str:    .string "Result: "
newline:    .string "\n"
expr:       .space  101          # input buffer (MAX_EXPR_LEN=100 + null)

# Stack: array of 50 ints
stack:      .space  200          # 50 * 4 bytes

.text
.globl _start
_start:

    # ----- print prompt -----
    li      a7, 4
    la      a0, prompt
    ecall

    # ----- read expression string -----
    li      a7, 8
    la      a0, expr
    li      a1, 101
    ecall

    # ----- evaluate RPN -----
    la      a0, expr
    call    evaluate_rpn         # result in a0

    # ----- save result -----
    mv      s0, a0

    # ----- print "Result: " -----
    li      a7, 4
    la      a0, res_str
    ecall

    # ----- print integer result -----
    li      a7, 1
    mv      a0, s0
    ecall

    # ----- print newline -----
    li      a7, 4
    la      a0, newline
    ecall

    # ----- exit -----
    li      a7, 10
    ecall


# =============================================================================
# bool is_digit(char c)   →  returns 1 if '0'<=c<='9', else 0
# Args:   a0 = c
# Return: a0 = bool
# =============================================================================
is_digit:
    li      t0, '0'
    li      t1, '9'
    blt     a0, t0, .not_digit
    bgt     a0, t1, .not_digit
    li      a0, 1
    ret
.not_digit:
    li      a0, 0
    ret


# =============================================================================
# bool is_operator(char c)   →  returns 1 if c in {+,-,*,/}
# Args:   a0 = c
# Return: a0 = bool
# =============================================================================
is_operator:
    li      t0, '+'
    beq     a0, t0, .is_op_yes
    li      t0, '-'
    beq     a0, t0, .is_op_yes
    li      t0, '*'
    beq     a0, t0, .is_op_yes
    li      t0, '/'
    beq     a0, t0, .is_op_yes
    li      a0, 0
    ret
.is_op_yes:
    li      a0, 1
    ret


# =============================================================================
# bool is_space(char c)
# Args:   a0 = c
# Return: a0 = bool
# =============================================================================
is_space:
    li      t0, ' '
    beq     a0, t0, .is_sp_yes
    li      t0, '\t'
    beq     a0, t0, .is_sp_yes
    li      t0, '\n'
    beq     a0, t0, .is_sp_yes
    li      t0, '\v'
    beq     a0, t0, .is_sp_yes
    li      t0, '\f'
    beq     a0, t0, .is_sp_yes
    li      t0, '\r'
    beq     a0, t0, .is_sp_yes
    li      a0, 0
    ret
.is_sp_yes:
    li      a0, 1
    ret


# =============================================================================
# int char_to_digit(char c)   →  c - '0'
# Args:   a0 = c
# Return: a0 = digit value
# =============================================================================
char_to_digit:
    li      t0, '0'
    sub     a0, a0, t0
    ret


# =============================================================================
# int multiply(int a, int b)   →  repeated addition (no MUL instruction)
# Args:   a0 = a,  a1 = b
# Return: a0 = a * b
# NOTE: handles b==0 correctly (returns 0); does NOT handle negative b
# =============================================================================
multiply:
    li      t0, 0            # result = 0
    li      t1, 0            # i = 0
.mul_loop:
    bge     t1, a1, .mul_done
    add     t0, t0, a0       # result += a
    addi    t1, t1, 1        # i++
    j       .mul_loop
.mul_done:
    mv      a0, t0
    ret


# =============================================================================
# int apply_operator(int a, int b, char op)
# Args:   a0 = a,  a1 = b,  a2 = op
# Return: a0 = result
# =============================================================================
apply_operator:
    li      t0, '+'
    beq     a2, t0, .op_add
    li      t0, '-'
    beq     a2, t0, .op_sub
    li      t0, '*'
    beq     a2, t0, .op_mul
    li      t0, '/'
    beq     a2, t0, .op_div
    li      a0, 0
    ret

.op_add:
    add     a0, a0, a1
    ret

.op_sub:
    sub     a0, a0, a1
    ret

.op_mul:
    # call multiply(a0, a1)  — args already in a0, a1
    addi    sp, sp, -4
    sw      ra, 0(sp)
    call    multiply
    lw      ra, 0(sp)
    addi    sp, sp, 4
    ret

.op_div:
    beqz    a1, .div_by_zero
    div     a0, a0, a1       # RV32IM has div; Ripes supports M-extension
    ret
.div_by_zero:
    li      a0, 0
    ret


# =============================================================================
# Stack helpers  (stack base = stack label, top tracked in s11 globally)
#
# We use s10 = pointer to stack base
#      s11 = top index (number of items)
# These are preserved as global state within evaluate_rpn's lifetime.
# =============================================================================

# push(val):  a0 = value to push
push:
    la      t0, stack
    slli    t1, s11, 2       # top * 4
    add     t0, t0, t1
    sw      a0, 0(t0)
    addi    s11, s11, 1
    ret

# pop():  returns a0 = popped value
pop:
    addi    s11, s11, -1
    la      t0, stack
    slli    t1, s11, 2
    add     t0, t0, t1
    lw      a0, 0(t0)
    ret


# =============================================================================
# int evaluate_rpn(const char *expr)
# Args:   a0 = pointer to null-terminated expression string
# Return: a0 = result
#
# Register allocation (callee-saved, preserved across calls):
#   s0  = expr base pointer
#   s1  = i (current index)
#   s11 = stack top
# =============================================================================
evaluate_rpn:
    addi    sp, sp, -20
    sw      ra,  0(sp)
    sw      s0,  4(sp)
    sw      s1,  8(sp)
    sw      s2, 12(sp)
    sw      s3, 16(sp)

    mv      s0, a0           # s0 = expr
    li      s1, 0            # i = 0
    li      s11, 0           # top = 0 (reset stack)

.eval_loop:
    add     t0, s0, s1       # &expr[i]
    lb      t1, 0(t0)        # token = expr[i]
    beqz    t1, .eval_done   # null terminator → done

    # is_space(token)?
    mv      a0, t1
    addi    sp, sp, -4
    sw      t1, 0(sp)
    call    is_space
    lw      t1, 0(sp)
    addi    sp, sp, 4
    bnez    a0, .eval_next   # skip spaces

    # is_digit(token)?
    mv      a0, t1
    addi    sp, sp, -4
    sw      t1, 0(sp)
    call    is_digit
    lw      t1, 0(sp)
    addi    sp, sp, 4
    beqz    a0, .check_op

    # --- parse multi-digit number ---
    li      s2, 0            # num = 0
.num_loop:
    add     t0, s0, s1
    lb      t2, 0(t0)        # expr[i]

    mv      a0, t2
    addi    sp, sp, -8
    sw      t2, 0(sp)
    sw      s2, 4(sp)
    call    is_digit
    lw      s2, 4(sp)
    lw      t2, 0(sp)
    addi    sp, sp, 8
    beqz    a0, .num_done

    # num = multiply(num, 10) + char_to_digit(expr[i])
    mv      a0, s2
    li      a1, 10
    addi    sp, sp, -8
    sw      t2, 0(sp)
    sw      s1, 4(sp)
    call    multiply
    lw      s1, 4(sp)
    lw      t2, 0(sp)
    addi    sp, sp, 8

    mv      s2, a0           # s2 = multiply(num,10)
    mv      a0, t2
    addi    sp, sp, -4
    sw      s2, 0(sp)
    call    char_to_digit
    lw      s2, 0(sp)
    addi    sp, sp, 4

    add     s2, s2, a0       # num = num*10 + digit
    addi    s1, s1, 1        # i++
    j       .num_loop

.num_done:
    mv      a0, s2           # push(num)
    addi    sp, sp, -4
    sw      s1, 0(sp)
    call    push
    lw      s1, 0(sp)
    addi    sp, sp, 4
    addi    s1, s1, -1       # i-- (backtrack)
    j       .eval_next

.check_op:
    # is_operator(token)?
    mv      a0, t1
    addi    sp, sp, -4
    sw      t1, 0(sp)
    call    is_operator
    lw      t1, 0(sp)
    addi    sp, sp, 4
    beqz    a0, .eval_next   # unknown char, skip

    # b = pop()
    addi    sp, sp, -8
    sw      t1, 0(sp)
    sw      s1, 4(sp)
    call    pop
    lw      s1, 4(sp)
    lw      t1, 0(sp)
    addi    sp, sp, 8
    mv      s2, a0           # s2 = b

    # a = pop()
    addi    sp, sp, -12
    sw      t1,  0(sp)
    sw      s1,  4(sp)
    sw      s2,  8(sp)
    call    pop
    lw      s2,  8(sp)
    lw      s1,  4(sp)
    lw      t1,  0(sp)
    addi    sp, sp, 12
    mv      s3, a0           # s3 = a

    # apply_operator(a, b, op)
    mv      a0, s3
    mv      a1, s2
    mv      a2, t1
    addi    sp, sp, -4
    sw      s1, 0(sp)
    call    apply_operator
    lw      s1, 0(sp)
    addi    sp, sp, 4

    # push(result)
    addi    sp, sp, -4
    sw      s1, 0(sp)
    call    push
    lw      s1, 0(sp)
    addi    sp, sp, 4

.eval_next:
    addi    s1, s1, 1        # i++
    j       .eval_loop

.eval_done:
    addi    sp, sp, -4
    sw      s1, 0(sp)
    call    pop              # final result
    lw      s1, 0(sp)
    addi    sp, sp, 4

    lw      ra,  0(sp)
    lw      s0,  4(sp)
    lw      s1,  8(sp)
    lw      s2, 12(sp)
    lw      s3, 16(sp)
    addi    sp, sp, 20
    ret
