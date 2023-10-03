type label = string
type instr =
  | Cst(int)
  | Add
  | Mul
  | Var(int)
  | Pop
  | Swap
  | Label(label)
  | Call(label, int)
  | Ret(int)
  | Goto(label)
  | IfZero(label)
  | Exit
