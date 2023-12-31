type rec lambda =
  | Var(string)
  | App(lambda, lambda)
  | Fun(string, lambda)

let alpha_equiv = (t, old, new) => {
  let rec go = t => {
    switch t {
    | Var(x) =>
      if x == old {
        Var(new)
      } else {
        t
      }
    | Fun(x, a) =>
      if x == old {
        Fun(new, go(a))
      } else {
        Fun(x, go(a))
      }
    | App(a, b) => App(go(a), go(b))
    }
  }
  go(t)
}

// No free variables
let n = ref(0)

let rec subst = (x, v, a) => {
  switch a {
  | Var(y) =>
    if x == y {
      v
    } else {
      a
    }
  | Fun(y, b) =>
    if x == y {
      a
    } else {
      let y' = Belt.Int.toString(n.contents)
      n := n.contents + 1
      let b' = alpha_equiv(b, y, y')
      Fun(y', subst(x, v, b'))
    }
  | App(b, c) => App(subst(x, v, b), subst(x, v, c))
  }
}

// Natural Semantics
let rec eval = (t: lambda) => {
  switch t {
  | Var(_) => assert false
  | Fun(_, _) => t
  | App(f, arg) => {
      let Fun(x, body) = eval(f)
      let va = eval(arg)
      // body[va:=x]
      eval(subst(x, va, body))
    }
  }
}

let print_lambda = l => {
  let print_paren = (b, s) => {
    if b {
      "(" ++ s ++ ")"
    } else {
      s
    }
  }
  let rec go = (l, p) => {
    switch l {
    | Var(x) => x
    | Fun(x, a) => print_paren(p > 0, "λ " ++ x ++ " . " ++ go(a, 0))
    | App(a, b) => print_paren(p > 1, go(a, 1) ++ " " ++ go(b, 2))
    }
  }
  go(l, 0)
}

Js.log(print_lambda(App(Fun("x", Var("x")), Var("y"))))
Js.log(print_lambda(eval(App(Fun("x", Var("x")), Fun("y", Var("x"))))))
