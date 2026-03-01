#ifndef RPN_H
#define RPN_H

#include <stdbool.h>

#define MAX_EXPR_LEN 100

bool is_digit(char c);    // Check if character is a digit ('0'-'9')
bool is_operator(char c);   // Checks if character is a operator 
bool is_space(char c); // Checks if character is any form of space or newline 

#endif
