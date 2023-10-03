## Function call and return
Calling convention (Caller <-> Callee)
- Remember the PC (Program Counter) [Return Address] before the function call and jump back when it returns 
- Pass argument and return values
- Call-by-value is strictly evaluated hence you can write a function `if_then_else`

### New instructions 
#### Label
- Pseudo instruction (prevent controls PC directly)
```rescript
type label = string
type instr = ... | Label(label)
```
### Call and Ret
```rescript
type instr = ... | Call(label, int) | Ret(int)
```
- The `int` part corresponds to the arity of the function, which is part of the metadata
- The arity information is used to maintain the **stack balance property**
- The arity information is not necessary

### Goto and IfZero
```rescript
type instr = ... | Goto(label) | IfZero(label)
```
`[[if a then b else c]]` compiles to 
```
[[a]]
IfZero(if_not) -- a = 0 -> jump to if_not else fall through
[[b]]
Goto(end_if)
Label(if_not)
[[c]]
Label(end_if)
```

### Exit
Terminates the execution and return the value off the top of the stack.

## Stack frame
Stack frames keep track of the program counter , arguments, etc.

## Assembler
The assembler translates assembly to binary code
### Encoding specification 
|Instr|Opcode|Operand1|Operand2|Size|
|-----|------|--------|--------|----|
|Cst(i)|0|i|-|2|
|Add|1|-|-|1|
|Mul|2|-|-|1|
|Var(i)|3|i|-|2|
|Pop|4|-|-|1|
|Swap|5|-|-|1|
|Call(l,n)|6|get_addr(l)|n|3|
|Ret(n)|7|n|-|2|
|IfZero(l)|8|get_addr(l)|-|2|
|Goto(l)|9|get_addr(l)|-|2|
|Exit|10|-|-|1|

- Opcode and operand are Int32 type
- Size is used to compute offset

