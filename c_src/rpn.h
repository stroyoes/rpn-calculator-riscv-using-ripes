#ifndef RPN_H
#define RPN_H

#include <stdbool.h>

#define MAX_EXPR_LEN 100

bool is_digit(char c);    // Check if character is a digit ('0'-'9')
bool is_operator(char c);   // Checks if character is a operator 
bool is_space(char c);    // Checks if character is any form of space or newline 
int char_to_digit(char c);    // Convert char digits into normal digits 
int multiply(int a, int b);   // Multiply; logic of repeated addition
int apply_operator(int a, int b, char op);    // Apply operators to two operands
int  evaluate_rpn(const char *expr);    // Evaluate an RPN expression 
#endif
