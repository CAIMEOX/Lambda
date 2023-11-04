type prim = Add | Mul | Self

type rec expr =
  | Cst(int)
  | Var(string)
  | Let(string, expr, expr)
  | Letfn(string, list<string>, expr, expr)
  | App(string, list<expr>)
  | Prim(prim, list<expr>)
  | If(expr, expr, expr)

module Flat = {
  type rec expr =
    | Cst(int)
    | Var(string)
    | Let(string, expr, expr)
    | App(string, list<expr>)
    | If(expr, expr, expr)
    | Prim(prim, list<expr>)
  type fun = (string, list<string>, expr)
}

type var =
  | Para(string)
  | Local(string)
  | Temp

type venv = list<var>

let fst = ((a, _)) => a
let snd = ((_, b)) => b

let rec remove_funs = (expr: expr): Flat.expr => {
  switch expr {
  | Cst(i) => Cst(i)
  | Prim(p, es) => Prim(p, List.map(remove_funs, es))
  | If(e1, e2, e3) => If(remove_funs(e1), remove_funs(e2), remove_funs(e3))
  | Var(s) => Var(s)
  | Let(s, e1, e2) => Let(s, remove_funs(e1), remove_funs(e2))
  | Letfn(_, _, _, scope) => remove_funs(scope)
  | App(s, es) => App(s, List.map(remove_funs, es))
  }
}

let rec collect_funs = (expr: expr): list<Flat.fun> => {
  switch expr {
  | Cst(_) | Var(_) => list{}
  | Prim(_, es) => List.concat(List.map(collect_funs, es))
  | Let(_, e1, e2) => List.concat(list{collect_funs(e1), collect_funs(e2)})
  | Letfn(name, args, body, scope) =>
    List.concat(list{
      list{(name, args, remove_funs(body))},
      collect_funs(body),
      collect_funs(scope),
    })
  | App(_, args) => List.concat(List.map(collect_funs, args))
  | If(e1, e2, e3) => List.concat(list{collect_funs(e1), collect_funs(e2), collect_funs(e3)})
  }
}

// prevent name collision
let generate_label_fresher = prefix => {
  let counter = ref(0)
  () => {
    counter := counter.contents + 1
    `${prefix}${Belt.Int.toString(counter.contents)}`
  }
}

let else_fresh = generate_label_fresher("__else__")
let exit_fresh = generate_label_fresher("__exit__")

let vindex = (venv: venv, x: string) => {
  let rec vindex_aux = (venv: venv, x: string, acc) => {
    switch venv {
    | list{} => raise(Not_found)
    | list{Temp, ...rest} => vindex_aux(rest, x, acc + 1)
    | list{Local(y), ...rest} => x === y ? acc : vindex_aux(rest, x, acc + 1)
    | list{Para(y), ...rest} => x === y ? acc : vindex_aux(rest, x, acc + 1)
    }
  }
  vindex_aux(venv, x, 0)
}

let rec compile_exprs = (venv: venv, exprs: list<Flat.expr>, name: string, num: int) => {
  let rec compile_exprs_aux = (venv, exprs, acc) => {
    switch exprs {
    | list{} => acc
    | list{expr, ...rest} => {
        let expr_code = compile_expr(venv, expr, name, num)
        compile_exprs_aux(list{Temp, ...venv}, rest, List.append(acc, expr_code))
      }
    }
  }
  compile_exprs_aux(venv, exprs, list{})
}

and compile_expr = (venv: venv, expr: Flat.expr, name: string, num: int): list<Stack.instr> => {
  switch expr {
  | Cst(i) => list{Cst(i)}
  | Prim(op, es) =>
    switch op {
    | Add | Mul | Self => {
        let es_code = compile_exprs(venv, es, name, num)
        let op_code: Stack.instr = switch op {
        | Add => Add
        | Mul => Mul
        | Self => Call(name, num)
        }
        List.append(es_code, list{op_code})
      }
    }

  | Var(x) => list{Var(vindex(venv, x))}
  | Let(x, e1, e2) =>
    List.concat(list{
      compile_expr(venv, e1, name, num),
      compile_expr(list{Local(x), ...venv}, e2, name, num),
      list{Swap, Pop},
    })
  | App(fn, args) => {
      let n = List.length(args)
      let args_code = compile_exprs(venv, args, name, num)
      List.append(args_code, list{Call(fn, n)})
    }

  | If(cond, ifso, ifelse) => {
      let elseLabel = else_fresh()
      let exitLabel = exit_fresh()
      List.concat(list{
        compile_expr(venv, cond, name, num),
        list{IFZERO(elseLabel)},
        compile_expr(venv, ifso, name, num),
        list{GOTO(exitLabel)},
        list{Label(elseLabel)},
        compile_expr(venv, ifelse, name, num),
        list{Label(exitLabel)},
      })
    }
  }
}

// compile a function
let compile_fun = (fun: Flat.fun) => {
  let (name, args, body) = fun
  let n = List.length(args)
  let venv = List.rev(List.map(a => Para(a), args))
  List.concat(list{list{Stack.Label(name)}, compile_expr(venv, body, name, n), list{Stack.Ret(n)}})
}

// preprocess the program
// What if we have environment variables?
let preprocess = (expr: expr) => {
  let main = ("main", list{}, remove_funs(expr))
  let rest = collect_funs(expr)
  list{main, ...rest}
}

let compile = (funs: list<Flat.fun>) => {
  // translate each function to machine code
  let funs_code = List.concat(List.map(compile_fun, funs))
  // add entrance and exit
  list{Stack.Call("main", 0), Stack.Exit, ...funs_code}
}

// driver
let compile_and_execute = prog => {
  let vmcode = prog->preprocess->compile
  let vm = Stack.initVm(Belt.List.toArray(vmcode))
  Stack.run(vm)
}

let compile_encode_and_execute = prog => {
  let vmcode = prog->preprocess->compile->Belt.List.toArray
  let encoded = fst(Stack.encode(vmcode))
  let init_pc = Stack.getInitPc(vmcode)
  let real_vm = Stack.RealVm.initVm(encoded, init_pc)
  Stack.RealVm.run(real_vm)
}

let compile_encode = prog => {
  let vmcode = prog->preprocess->compile->Belt.List.toArray
  let encoded = fst(Stack.encode(vmcode))
  encoded
}
