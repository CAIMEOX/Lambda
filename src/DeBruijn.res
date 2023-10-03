type rec debru =
  | Var(int)
  | App(debru, debru)
  | Fun(debru)

let rec shift_aux = (i, d, u: debru) => {
  switch u {
  | Var(j) =>
    if j >= d {
      Var(i + j)
    } else {
      u
    }
  | Fun(b) => Fun(shift_aux(i, d + 1, b))
  | App(a, b) => App(shift_aux(i, d, a), shift_aux(i, d, b))
  }
}
let shift = (i, u) => shift_aux(i, 0, u)

let rec subst = (t: debru, i, u) => {
  switch t {
  | Var(j) =>
    if j == i {
      u
    } else {
      t
    }
  | Fun(b) => Fun(subst(b, i + 1, shift(1, u)))
  | App(a, b) => App(subst(a, i, u), subst(b, i, u))
  }
}

let rec eval = (t: debru) => {
  switch t {
  | Var(_) => assert false
  | Fun(_) => t
  | App(f, arg) => {
      let Fun(body) = eval(f)
      let idx = eval(arg)
      eval(subst(idx, 0, shift(-1, body)))
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
    | Var(x) => Belt.Int.toString(x)
    | Fun(a) => print_paren(p > 0, `λ.${go(a, 0)}`)
    | App(a, b) => print_paren(p > 1, go(a, 1) ++ " " ++ go(b, 2))
    }
  }
  go(l, 0)
}
