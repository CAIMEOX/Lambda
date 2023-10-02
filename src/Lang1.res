module Expr = {
  type rec expr =
    | Cst(int)
    | Add(expr, expr)
    | Mul(expr, expr)
    | Var(string)
    // Let expr in expr
    | Let(string, expr, expr)
  // terms : e ::= Cst(i) | Add(e1,e2) | Mul(e1,e2) | Var(i) | Let(x,e1,e2)
  // envs : F ::= e | (x,v) :: F
  // Variable access : F[x]
  // Variable update F[x:=v]
  // Evaluation rules :
  // F |- Cst(i) \downarrow (E-Const)
  // F |- e_1 \downarrow e_2 F[x:=v_1] |- e_2 \downarrow v
  // ----------------------------------------------------- (E-let)
  // F |- Let(x,e_1,e_2) \downarrow v

  type env = list<(string, int)>

  let rec eval = (expr: expr, env: env) => {
    switch expr {
    | Cst(i) => i
    | Add(a, b) => eval(a, env) + eval(b, env)
    | Mul(a, b) => eval(a, env) * eval(b, env)
    | Var(x) => List.assoc(x, env)
    | Let(x, e1, e2) => eval(e2, list{(x, eval(e1, env)), ...env})
    }
  }
}

module Nameless = {
  type rec expr =
    | Cst(int)
    | Add(expr, expr)
    | Mul(expr, expr)
    | Var(int)
    | Let(expr, expr)

  type env = list<int>
  let rec eval = (expr: expr, env: env) => {
    switch expr {
    | Cst(i) => i
    | Add(a, b) => eval(a, env) + eval(b, env)
    | Mul(a, b) => eval(a, env) * eval(b, env)
    | Var(n) => List.nth(env, n)
    | Let(e1, e2) => eval(e2, list{eval(e1, env), ...env})
    }
  }
}

let index = (cenv, x) => {
  let rec go = (cenv, n) => {
    switch cenv {
    | list{} => raise(Not_found)
    | list{a, ...rest} =>
      if a == x {
        n
      } else {
        go(rest, n + 1)
      }
    }
  }
  go(cenv, 0)
}

module Expr2Nameless = {
  type cenv = list<string>
  let rec comp = (expr: Expr.expr, cenv: cenv): Nameless.expr => {
    switch expr {
    | Cst(i) => Cst(i)
    | Add(a, b) => Add(comp(a, cenv), comp(b, cenv))
    | Mul(a, b) => Mul(comp(a, cenv), comp(b, cenv))
    | Var(x) => Var(index(cenv, x))
    | Let(x, e1, e2) => Let(comp(e1, cenv), comp(e2, list{x, ...cenv}))
    }
  }
}

module StackMachine = {
  type instruction = Cst(int) | Add | Mul | Var(int) | Pop | Swap
  type instructions = list<instruction>
  type operand = int
  type stack = list<operand>

  // Opti by tail rec
  let rec eval = (instrs: instructions, stk: stack): int => {
    switch (instrs, stk) {
    | (list{Cst(i), ...rest}, _) => eval(rest, list{i, ...stk})
    | (list{Add, ...rest}, list{a, b, ...stk}) => eval(rest, list{a + b, ...stk})
    | (list{Mul, ...rest}, list{a, b, ...stk}) => eval(rest, list{a * b, ...stk})
    | (list{Pop, ...rest}, list{_, ...stk}) => eval(rest, stk)
    | (list{Swap, ...rest}, list{a, b, ...stk}) => eval(rest, list{b, a, ...stk})
    | (list{Var(i), ...rest}, stk) => eval(rest, list{Belt.List.toArray(stk)[i], ...stk})
    | (list{}, list{r, ..._}) => r
    | _ => assert false
    }
  }

  let ins_name = (i: instruction): string => {
    switch i {
    | Cst(i) => "Cst " ++ Belt.Int.toString(i)
    | Add => "Add"
    | Mul => "Mul"
    | Pop => "Pop"
    | Swap => "Swap"
    | Var(i) => "Var " ++ Belt.Int.toString(i)
    }
  }

  let print_ins = (instrs: instructions): list<unit> => {
    instrs->Belt.List.map(x => Js.log(ins_name(x)))
  }
}

module Indexed = {
  type rec expr =
    | Cst(int)
    | Add(expr, expr)
    | Mul(expr, expr)
    // Inline record
    | Var({bind: int, stack_index: int})
    | Let(expr, expr)

  type sv = Slocal | Stmp
  type senv = list<sv>
  let sindex = (senv, i) => {
    let rec go = (senv, i, acc) => {
      switch senv {
      | list{} => raise(Not_found)
      | list{Slocal, ...rest} =>
        if i == 0 {
          acc
        } else {
          go(rest, i - 1, acc + 1)
        }
      | list{Stmp, ...rest} => go(rest, i, acc + 1)
      }
    }
    go(senv, i, 0)
  }
  let compile = expr => {
    let rec go = (expr: Nameless.expr, senv: senv): expr => {
      switch expr {
      | Cst(i) => Cst(i)
      | Var(s) =>
        Var({
          bind: s,
          stack_index: sindex(senv, s),
        })
      | Add(e1, e2) => Add(go(e1, senv), go(e2, list{Stmp, ...senv}))
      | Mul(e1, e2) => Mul(go(e1, senv), go(e2, list{Stmp, ...senv}))
      | Let(e1, e2) => Let(go(e1, senv), go(e2, list{Slocal, ...senv}))
      }
    }
    go(expr, list{})
  }
  let rec scompile = (expr: Nameless.expr): list<StackMachine.instruction> => {
    let rec go = (expr: Nameless.expr, senv: senv): list<StackMachine.instruction> => {
      switch expr {
      | Cst(i) => list{Cst(i)}
      | Var(s) => list{Var(sindex(senv, s))}
      | Add(e1, e2) => list{...go(e1, senv), ...go(e2, list{Stmp, ...senv}), Add}
      | Mul(e1, e2) => list{...go(e1, senv), ...go(e2, list{Stmp, ...senv}), Mul}
      | Let(e1, e2) => list{...go(e1, senv), ...go(e2, list{Slocal, ...senv}), Swap, Pop}
      }
    }
    go(expr, list{})
  }
}

module Compiler = {
  let rec compile = (expr: Indexed.expr) => {
    switch expr {
    | Cst(i) => list{StackMachine.Cst(i)}
    | Add(a, b) => list{...compile(a), ...compile(b), StackMachine.Add}
    | Mul(a, b) => list{...compile(a), ...compile(b), StackMachine.Mul}
    | Var({stack_index, _}) => list{StackMachine.Var(stack_index)}
    | Let(e1, e2) => list{...compile(e1), ...compile(e2), StackMachine.Swap, StackMachine.Pop}
    }
  }

  type sv = Slocal(string) | Stmp
  type senv = list<sv>

  // let rec single_pass_compile = (expr: Expr.expr): StackMachine.instructions => {
  //   let rec go = (expr: Expr.expr, senv: senv): StackMachine.instructions => {
  //     switch expr {
  //     | Cst(i) => list{Cst(i)}
  //     | Var(s) => list{Var(sindex(senv, s))}
  //     | Add(e1, e2) => list{...go(e1, senv), ...go(e2, list{Stmp, ...senv}), Add}
  //     | Mul(e1, e2) => list{...go(e1, senv), ...go(e2, list{Stmp, ...senv}), Mul}
  //     | Let(x, e1, e2) => list{...go(e1, senv), ...go(e2, list{Slocal(x), ...senv}), Swap, Pop}
  //     }
  //   }
  //   go(expr, list{})
  // }
}

let example: Expr.expr = Let("a", Cst(2), Let("b", Mul(Cst(5), Cst(5)), Mul(Var("b"), Var("a"))))
let nameless: Nameless.expr = Expr2Nameless.comp(example, list{})
let indexed: Indexed.expr = Indexed.compile(nameless)
let compiled: StackMachine.instructions = Compiler.compile(indexed)
let scompiled: StackMachine.instructions = Indexed.scompile(nameless)
Js.log(StackMachine.print_ins(compiled))
Js.log(StackMachine.eval(compiled, list{}))
Js.log(StackMachine.eval(scompiled, list{}))
// Js.log(StackMachine.eval(Compiler.compile(example), list{}))
