#include <stdio.h>
#include <string.h>

#include "rpn.h"

int main() {
  char expr[MAX_EXPR_LEN];

  printf("Enter RPN expression (e.g., 5 3 + 2 *):\n> ");
  fgets(expr, sizeof(expr), stdin);

  //  NOTE: strcspn returns the number of characters before the first occurrence of any char in the second string
  expr[strcspn(expr, "\n")] = '\0'; // Remove trailing newline

  int result = evaluate_rpn(expr);
  printf("Result: %d\n", result);

  return 0;
}
