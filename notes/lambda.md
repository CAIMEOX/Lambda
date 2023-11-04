# $\lambda-\text{calculus}$
## Lambda terms
Expression in the lambda calculus are called $\lambda\text{-terms}$, we assume the existence of an infinite set $V$ of variables: $V=\{x,y,z,\cdots\}$.

The set $\Lambda$ of all $\lambda\text{-terms}$ is given:
- (Variable) If $u \in V$ then $u \in \Lambda$
- (Application) If $M$ and $N$ $\in V$ then $MN \in V$
- (Abstraction) If $M \in \Lambda$ and $u\in V$ then $(\lambda u.M)\in \Lambda$

Or via abstract syntax (The 3 possibilities are separated by the vertical bar |):
$$
\Lambda = \Lambda \Lambda | V | (\lambda V. \Lambda)
$$

### Examples
- $\lambda x.x$
- $(\lambda x.(xx))(\lambda y.(yy))$

```ocaml
type rec t = 
    | Var (string)
    | App (t,t)
    | Fun (string,t)
```

## Beta reduction
The One-step $\beta\text{-reduction}$:
- (Basic) $(\lambda x.M ) N \to _\beta M[x:=N]$
- (Compatibility) If $M \to_\beta N$ then $ML \to_\beta NL$, $LM \to _\beta LN$ and $\lambda x .M \to_\beta \lambda x .N$
- Name $(\lambda x.M ) N$ the redex (Reducible expression) and $M[x:=N]$ the contractum (of the redex)

(A remarkable expression: $(\lambda x . x \ x)(\lambda x . x \ x ) \to_\beta (\lambda x . x \ x )(\lambda x . x \ x )$)

**Church-Rosser Theorem** (Hard to prove)

Suppose that for a given $\lambda\text{-term} M$ we have $M \twoheadrightarrow_\beta N_1$ and $M \twoheadrightarrow_\beta N_2$ then there is a $\lambda\text{-term}$ $N_3$ such that $N_1 \twoheadrightarrow_\beta N_3$ and $N_2 \twoheadrightarrow_\beta N_3$

- Result of computation is independent of the evaluation order
- Languages can choose different order

## Substitution
Substitution rules:
- $x[x:=N]\equiv N$
- $y[x:=N]\equiv y$ if $x \not\equiv y$
- $(PQ)[x:=N] \equiv (P[x:= N])(Q[x:=N])$
- $(\lambda y.P [x:=N] \equiv \lambda z. (P^{y\to z}[x:=N])$ if $\lambda z.P ^{y\to z}$ is an $\alpha\text{-variant}$ of $\lambda y.P$ such that $z \not\in FV(N)$ (This prevents some terms from being bound)

(Note: The terms of the form $P[x:=N]$ are not $\lambda\text{-terms}$)

The substitutions is not communicative:
$$
x [x:=y][y:=x] \equiv x \\
x [y:=x][x:=y] \equiv y
$$

## Interpreter (Natural semantics)
Evaluate the closed term (Values are functions):
```ocaml
let rec eval = (t: lambda) => {
  switch t {
  | Var(_) => assert false
  | Fun(_, _) => t
  | App(f, arg) => {
      let Fun(x, body) = eval(f)
      let va = eval(arg)
      eval(subst(x, va, body))
    }
  }
}
```

The substitution without free variables $a[x:=va]$
```ocaml
let rec subst = (x: string, v: lambda, a: lambda) => {
    switch a {
        | Var(y) => if x == y {v} else {a}
        | Fun(y, b) => if x == y {a} else { Fun(y, subst(x, v, b))}
        | App(b, c) => App(subst(x, v, b), subst(x, v, c))
    }
}
```

## Primitives
- Boolean
$$\text{if\_then\_else}\ \bar{T}MN\twoheadrightarrow_\beta M\\ \text{if\_then\_else}\ \bar{F}MN\twoheadrightarrow_\beta N$$
- Boolean values
$$\bar{T} = \lambda xy.x\\\bar{F}=\lambda xy.y$$
- If then else
$$\text{if\_then\_else}=\lambda x.x$$

## Naturals
### Church Numerals
The church numerals $\bar{0},\bar{1},\dots$ are defined by
$$\bar{n}=\lambda fx.f^n(x)$$
- $\bar{0}=\lambda fx.x$
- $\bar{1}=\lambda fx.fx$
- $\bar{2}=\lambda fx.f(fx)$
- $\bar{3}=\lambda fx.f(f(fx))$
- $\cdots$
```ocaml
type c_nat<'a> = ('a => 'a, 'a) => 'a
let c_zero = (s, z) => z
let c_succ = (n) => (s, z) => s(n(s, z))
let c_three = (s, z) => s(s(s(z)))
```


### Peano Numbers
Peano numbers are isomorphic to church numerals
```ocaml
type rec nat = Z | S (nat)
let three = S (S (S Z))
```
The isomorphism:
```ocaml
let church_to_peano = (n) => n(x => S(x), Z)
let rec peano_to_church = (n) => {
    switch n {
        | Z => c_zero
        | S(n) => c_succ(peano_to_church(n))
    }
} 
```

### Arithmetic functions
$$
\begin{align*}
\text{succ} &= \lambda nfx.f(nfx)
\\
\text{add} &= \lambda nmfx.nf(mfx)
\end{align*}
$$

Prove that the succ is a successor function:

$$
\begin{align*}
    \text{succ}\ \bar{n}
    &= (\lambda nfx.f(nfx))(\lambda fx.f^nx)\\ 
    &\to_\beta \lambda fx.f((\lambda fx.f^nx)fx)\\
    &\twoheadrightarrow_\beta\lambda fx.f(f^nx)\\
    &=\lambda fx.f^{n+1}x\\
    &=\overline{n+1}
\end{align*}
$$

### More primitives
- Test whether a number is Zero
$$\text{isZero}=\lambda n.n(\lambda z.\bar{F})\bar{T}$$
- Pair
$$
\begin{align*}
    \text{pair}&=\lambda xyz.z\ x\ y\\ 
    \text{fst} &=\lambda p.p\ (\lambda xy.x)=\lambda p.p\ \bar{T}\\
    \text{snd} &=\lambda p.p\ (\lambda xy.y)=\lambda p.p\ \bar{F}
\end{align*}
$$
- Predecessor
$$
\text{pred}=\lambda n.\text{fst}(n (\lambda p.\text{pair} (\text{snd}\ p) (\text{succ}(\text{snd}\ p)))(\text{pair}\ \bar{0}\ \bar{0}))
$$

In ocaml
```ocaml
let pred = (n) => {
    let init = (c_zero, c_zero)
    let iter = ((_, y)) => (y, c_succ(y))
    let (res, _) = n(iter, init)
    res
}
```
