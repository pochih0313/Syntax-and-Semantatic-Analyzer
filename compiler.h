#ifndef COMPILER_H
#define COMPILER_H

typedef struct Value Value;
struct Value {
    union {
        int i_val;
        float f_val;
        int b_val;
        char *string;
        struct {
            char *id_name;
            Value *value_ptr;
        };
    };
};

#endif