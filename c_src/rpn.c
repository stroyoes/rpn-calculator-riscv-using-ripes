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

// To make sure the char is a digit 
bool is_digit(char c) {
  return c >= '0' && c <= '9';
}

