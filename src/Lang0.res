module Expr = {
  type rec expr =
    | Cst(int)
    | Add(expr, expr)
    | Mul(expr, expr)

  let rec eval = (expr: expr) => {
    switch expr {
    | Cst(i) => i
    | Add(a, b) => eval(a) + eval(b)
    | Mul(a, b) => eval(a) * eval(b)
    }
  }
}

module StackMachine = {
  type instruction = Cst(int) | Add | Mul
  type instructions = list<instruction>
  type operand = int
  type stack = list<operand>

  // Opti by tail rec
  let rec eval = (instrs: instructions, stk: stack) => {
    switch (instrs, stk) {
    | (list{Cst(i), ...rest}, _) => eval(rest, list{i, ...stk})
    | (list{Add, ...rest}, list{a, b, ...stk}) => eval(rest, list{a + b, ...stk})
    | (list{Mul, ...rest}, list{a, b, ...stk}) => eval(rest, list{a * b, ...stk})
    | (list{}, list{r}) => r
    | _ => assert false
    }
  }
}

// Stack Transform
// (Push v on s) s -> v :: s
// (Pop v off s) v :: s -> s

// Transition of Stack Machine (e for empty command set)
// code : c ::= e | i ; c
// stack : s :: e | v :: s

// Transition of machine
// I-Cst (Cst(i);c,s) -> (c, i::s)
// I-Add (Add;c,n_2 :: n_1 :: s) -> (c, (n_2 + n_1) :: s)
// I-Mul (Mul;c,n_2 :: n_1 :: s) -> (c, (n_2 * n_1) :: s)

// (c,e) -> * (e, v::e)
// --------------------
// c \downarrow v

// Stack balanced property (Invariant)

module Compiler = {
  let rec compile = (expr: Expr.expr) => {
    switch expr {
    | Cst(i) => list{StackMachine.Cst(i)}
    | Add(a, b) => list{...compile(a), ...compile(b), StackMachine.Add}
    | Mul(a, b) => list{...compile(a), ...compile(b), StackMachine.Mul}
    }
  }
}

let example: Expr.expr = Add(Cst(1), Mul(Cst(5), Cst(10)))
Js.log(StackMachine.eval(Compiler.compile(example), list{}))
