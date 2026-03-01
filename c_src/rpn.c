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

int multiply(int a, int b) {
  //  NOTE: No mul instruction in base RV32I so we use repeated addition instead
  int result = 0;
  int i = 0;
  while (i < b) {
    result = result + a;
    i++;
  }
  return result;
}

int apply_operator(int a, int b, char op) {
  switch (op) {
    case '+': return a + b;
    case '-': return a - b;
    case '*': return multiply(a, b);
    case '/': return b == 0 ? 0 : a / b;
    default:  return 0;
  }
}


