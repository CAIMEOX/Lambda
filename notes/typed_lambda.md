# Types and Lambda Calculus
## Type
> A concise, formal description of the behavior of a program fragment.

Why type?
> Well-typed programs do not go wrong

## Simply typed lambda calculus
- Types
$$T::=\text{Int}|\text{Bool}|T\to T$$
```ocaml
(* Tarr for TArray*)
type rec ty = TInt | TBool | TArr (ty, ty)
```
- Terms
$$t::=i|b|x|\lambda x:T.t|t\space t$$
```ocaml
type rec t = CstI (int) | CstB(bool) | Var (string) | App (t, t) | Abs (string, ty, t)
```

## Runtime semantics
- Type-passing semantics
$$
\frac{t_1\to t_1'}{t_1\space t_2\to t_1'\space t_2}\quad\frac{t_2\to t_2'}{v_1\space t_2\to v_1\space t_2'}\quad\frac{}{(\lambda x:T.t)v\to t[x:=v]}
$$
- Type-erasing semantics
  - $[\lambda  x:T.t]=\lambda x.t$
  - overloading (resolve overloading at compile time) vs. dynamic dispatch

## Typing
- Typing environment
$$
\begin{align*}
\Gamma&::=\\ &|\epsilon \\ &|\Gamma,x:T
\end{align*}
$$
- Typing rule
$$
\frac{x:T\in\Gamma}{\Gamma\vdash x:T} (\text{T-Var})
$$
We have trivially T-Bool and T-Int

$$
\frac{\Gamma,x:T_1\vdash t_2:T_2}{\Gamma\vdash\lambda x:T_1.t_2:T_1\to T_2}(\text{T-Abs})
\\  
\frac{\Gamma\vdash t_1:T_1\to T_2\quad\Gamma\vdash t_2:T_1}{\Gamma\vdash t_1\space t_2:T_2}(\text{T-App})
$$

## Type inference (constraint solving)
For example we want to infer the type $T$ in
$$
\vdash\lambda x.\lambda y.\lambda z. (x\space z)(y\space z):T
$$
- Insert type variables
$$
\vdash\lambda x:X.\lambda y:Y.\lambda z:Z. (x\space z)(y\space z):T
$$
- Generate constraints
  - $(x\space z)(y\space z):T$ means $(x\space z):T_1\to T$ and $(y\space z):T_1$ where $T_1$ is fresh
  - $x\space z:T_1\to T$ means $X=T_2\to(T_1\to T)$ and $Z=T_2$ where $T_2$ is fresh
  - $y\space z:T_1$ means $Y=T_3\to T_1$ and $Z=T_3$ where $T_3$ is fresh
- Overall the constrains we have collected
$$
\begin{align*}
X&=T_2\to(T_1\to T)\\ 
Y&=T_3\to T_1 \\
Z&=T_2\\ 
Z&=T_3  
\end{align*}
$$
- Solving by hand
$$
\vdash\lambda x:T_2\to(T_1\to T).\lambda y:T_3\to T_1.\lambda z:T_2.(x\space z)(y\space z):T
$$
- Type inference is decidable in STLC. 