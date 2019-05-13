#ifndef COMPILER_H
#define COMPILER_H

typedef struct Value Value;
struct Value {
    int i_val;
    float f_val;
    int b_val;
    char *string;
    char *id_name;
};

#endif