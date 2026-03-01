#include "rpn.h"

#define STACK_SIZE 50

// Private variables and funcs (belongs to this file only)

static int stack[STACK_SIZE];

static int top = 0;

static void push(int val) {
  stack[top++] = val;
}

static int pop(void) {
  return stack[--top];
}

// Checks if the char is a digit 
bool is_digit(char c) {
  return c >= '0' && c <= '9';
}

// Checks if its an operator 
bool is_operator(char c) {
  return c == '+' || c == '-' || c == '*' || c == '/';
}

// Checks if its a space
bool is_space(char c) {
  return c == ' ' || c == '\t' || c == '\n' || c == '\v' || c == '\f' || c == '\r';
}

int char_to_digit(char c) {
  return c - '0'; //  NOTE: Subtracting ASCII '0' (48) gives the actual integer value
}
