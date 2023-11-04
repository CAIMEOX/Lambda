# Function compile
- The Funarg problem: The difficulty in implementing **first-class functions** (functions as first-class objects) in programming language implementations so as to use **stack-based memory allocation** of the functions.

## Tiny C
- Tiny Lang 4 (equivalent to tiny C) : No first-class objects
- No free variables: lifetime of variables are **aligned** with function invocation
- No indirect calls: resolve the function label **statically** 

```rescript
type prim = Add | Mul
type rec expr =
  | Cst(int)
  | Var(string)
  | Let(string, expr, expr)
  | Letfn(string, list<string>, expr, expr)
  | App(string, list<expr>)
  | Prim(prim, list<expr>)
  | If(expr, expr, expr)
```

### Example Program
```rescript
// A dialect of rescript
let fib(n) =>
  if n <= 1 {
    1
  } else {
    fib(n - 1) + fib(n - 2)
  }
in fib(5)
```

### Overview
- Pre-process: flatten the code by lifting the functions (Convert the tree-like structure into linear)
- Compilation: Compile the functions
  - Caller: push arguments to the stack
  - Callee: find the arguments on the stack
- Post-process: Add an entrance and an exit

### Whole program
- After post-process : The program becomes a list of functions $[main,f_1,\dots,f_n]$
$$\begin{align*}
  \text{Prog}[[prog]]&=\text{Prog}[[main,f_1,\dots,f_n]]\\
  &=\text{Call}(main,0);\text{Exit};\text{Fn}[[main]];\text{Fn}[[f_1]];\dots;\text{Fn}[[f_n]]
\end{align*}$$

```rescript
type fun = (string, list<string>, expr)
type prog = list<fun>
```
- Compile a function (The subscript of $\text{Expr}[[e]]_{p_n,\dots,p_1}$ denotes the compile-time environment) :
$$
\text{Fn}[[(f, [p_1,\dots,p_n],e)]] = \text{Label}(f);\text{Expr}[[e]]_{p_n,\dots,p_1};\text{Ret}(n)
$$

- Compile expression (There is no `Letfn` case because the flattened expression should not contain it)
$$
\begin{align*}
  \text{Expr}[[\text{Cst}(i)]]_s&=\text{Cst}(i)\\ 
  \text{Expr}[[\text{Var}(x)]]_s&=\text{Var}(\text{get\_index}(x))\\ 
  \text{Expr}[[\text{Let}(x,e_1,e_2)]]_s&=\text{Expr}[[e_1]]_s;\text{Expr}[[e_2]]_{x::s};\text{Swap};\text{Pop}\\ 
  \text{Expr}[[\text{Prim}(p,[e_1,\dots,e_n])]]_s&=\dots\\ 
  \text{Expr}[[\text{App}(f,[a_1,\dots,a_n])]]_s&=\text{Exprs}[[a_1,\dots,a_n]]_s;\text{Call}(f,n)\\ 
  \text{Expr}[[\text{If}(\text{cond},e_1,e_2)]]_s&=\dots\\ 
\end{align*}
$$
- Expressions (The $*$ denotes the temporary variable in the compile environment)
$$
\text{Exprs}[[a_1,\dots,a_n]]_s=\text{Expr}[[a_1]]_s;\text{Expr}[[a_2]]_{*::s};\cdots
$$
- When get through from $a_i$ to $a_{i+1}$, the $a_i$ will be pushed to the stack hence the environment index should plus $1$

## Callee: Find arguments
- According to the convention, the arguments are pushed to the stack by the **caller**
- The variable kinds: local / temp

```ocaml
(f, [a, b], a + let c = 2 in b * c)
```

resolve the variable references
```ocaml
(f, [a, b], Var(?) + let c = 2 in Var(?) * Var(?))
```

- Caller Push arguments and make the call
