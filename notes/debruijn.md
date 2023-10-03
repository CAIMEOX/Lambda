# De Bruijn Index
- Names don't matter
- $\lambda xy. x(y(x))$ corresponds to $\lambda . \lambda.1(0(1))$
- The number $i$ stands for the variable bound by the $i\text{-th}$ binder $\lambda$
- The de bruijn index of Y combinator $Y=\lambda f.(\lambda x.f (x\ x))(\lambda x.f (x\ x))$ is $\lambda.(\lambda. 1(0\ 0))(\lambda. 1(0\ 0))$

## Substitution in De Bruijn Index
The index for the substituted variable can change
$$
\begin{align*}
(x\times (\lambda y.x+y)(z))[x:=\bar{2}] &= \bar{2}\times(\lambda y.\bar{2}+y)(z)
\\ 
(0\times(\lambda.1+0)(3))[0:=\bar{2}]&=\bar{2}\times(\lambda.\bar{2}+0)(3)    
\end{align*}
$$

```rescript
// t[i:=u]
let rec subst = (t: lambda, i, u) => {
    switch t {
        | Var(j) => if j == i {u} else {t}
        | Fn(b) => Fn(subst(b, i + 1, shift(1, u)))
        | App(a, b) => App(subst(a, i, u), subst(b, i, u))
    }
}
```

## Shift
- Shift should be only applied to **unbound variables**

### Shift Auxiliary
- $d$ is the cutoff
- $\uparrow^i_d(j)=j, j<d$
- $\uparrow^i_d(j)=i+j,j\geq d$
- $\uparrow^i_d(\lambda.t)=\lambda.\uparrow^i_{d+1}(t)$
- $\uparrow^i_d(t_1t_2)=\uparrow^i_d(t_1)\uparrow^i_d(t_2)$
- $\text{shift}(i,t)=\text{shift\_aux}(i,0,t)$
- Unbound variables shifted by $i$ and bounded variables kept intact

```rescript
let rec shift_aux = (i, d, u: lambda) => {
    switch u {
        | Var(j) => if (j >= d) { Var(i + j) } else {u}
        | Fn(b) => Fn(shift_aux(i, d + 1, b))
        | App(a, b) => App(shift_aux(i, d, a), shift_aux(i, d, b))
    }
}
let shift = (i, u) => shift_aux(i, 0, u)
```

The `shift` function can be used to shift by $-1$ after we drop a binder in **Interpreter**

