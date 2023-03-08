/*

This file convert smol states to react elements.

*/

open Smol
open Belt
open List

let todo = React.string("TODO")

let string_of_constant = c => {
  switch c {
  | Num(n) => Float.toString(n)
  | Lgc(l) =>
    if l {
      "#t"
    } else {
      "#f"
    }
  | Str(s) => "\"" ++ String.escaped(s) ++ "\""
  }
}

let string_of_function = f => {
  "#<procedure>"
}

let string_of_value = v => {
  switch v {
  | Uni => "#<void>"
  | Con(c) => string_of_constant(c)
  | Fun(f) => string_of_function(f)
  }
}

let blank = s => {
  <code className="blank"> {React.string(s)} </code>
}

let string_of_list = ss => {
  "(" ++ String.concat(" ", ss) ++ ")"
}

let string_of_def_var = (x, e) => {
  string_of_list(list{"defvar", x, e})
}

let string_of_def_fun = (f, xs, b) => {
  string_of_list(list{"deffun", string_of_list(list{f, ...xs}), b})
}

let string_of_expr_set = (x, e) => {
  string_of_list(list{"set!", x, e})
}

let string_of_expr_lam = (xs, b) => {
  string_of_list(list{"lambda", string_of_list(xs), b})
}

let string_of_expr_app = (e, es) => {
  string_of_list(list{"#%app", e, ...es})
}

let string_of_expr_cnd = (ebs, ob) => {
  let ebs = {
    switch ob {
    | None => ebs
    | Some(b) => list{...ebs, b}
    }
  }
  string_of_list(list{"cond", ...ebs})
}

let rec string_of_expr = (e: expression): string => {
  switch e {
  | Con(c) => string_of_constant(c)
  | Ref(x) => "#%ref." ++ String.escaped(x)
  | Set(x, e) => string_of_expr_set(x, string_of_expr(e))
  | Lam(xs, b) => string_of_expr_lam(xs, string_of_block(b))
  | App(e, es) => string_of_expr_app(string_of_expr(e), es->map(string_of_expr))
  | Cnd(ebs, ob) => string_of_expr_cnd(ebs->map(string_of_eb), string_of_ob(ob))
  }
}
and string_of_def = (d: definition): string => {
  switch d {
  | Var(x, e) => string_of_def_var(x, string_of_expr(e))
  | Fun(f, xs, b) => string_of_def_fun(f, xs, string_of_block(b))
  }
}
and string_of_eb = eb => {
  let (e, b) = eb
  string_of_expr(e) ++ "\n" ++ string_of_block(b)
}
and string_of_ob = ob => {
  Option.map(ob, string_of_block)
}
and string_of_block = b => {
  let (ts, e) = b
  String.concat("\n", list{...ts->map(string_of_term), string_of_expr(e)})
}
and string_of_term = t => {
  switch t {
  | Exp(e) => string_of_expr(e)
  | Def(d) => string_of_def(d)
  }
}

let show_expr = e => {
  blank(string_of_expr(e))
}

let show_value = e => {
  blank(string_of_value(e))
}

let shower_of_contextFrame = frm => {
  switch frm {
  | Set1(x, ()) => xyz => string_of_expr_set(x, xyz)
  | App1((), es) => xyz => string_of_expr_app(xyz, es->map(string_of_expr))
  | App2(v, vs, (), es) =>
    xyz => {
      let e = string_of_value(v)
      let es = list{...vs->map(string_of_value), xyz, ...es->map(string_of_expr)}
      string_of_expr_app(e, es)
    }
  | Cnd1((), b, ebs, ob) =>
    xyz => {
      let eb = xyz ++ "\n" ++ string_of_block(b)
      let ebs = list{eb, ...ebs->map(string_of_eb)}
      string_of_expr_cnd(ebs, string_of_ob(ob))
    }
  | BgnDef(x, (), b) =>
    xyz => {
      let d = string_of_def_var(x, xyz)
      d ++ "\n" ++ string_of_block(b)
    }
  | BgnExp((), b) =>
    xyz => {
      xyz ++ "\n" ++ string_of_block(b)
    }
  | PrgDef(vs, x, (), ts) =>
    xyz => {
      let vs = vs->map(string_of_value)
      let d = string_of_def_var(x, xyz)
      let ts = ts->map(string_of_term)
      String.concat("\n", list{...vs, d, ...ts})
    }
  | PrgExp(vs, (), ts) =>
    xyz => {
      let vs = vs->map(string_of_value)
      let ts = ts->map(string_of_term)
      String.concat("\n", list{...vs, xyz, ...ts})
    }
  }
}

let show_ctx = ctx => {
  let ctx = ctx->map(shower_of_contextFrame)
  let ctx = reduce(ctx, "???", (sofar, f) => f(sofar))
  blank(ctx)
}

let show_envFrm = (frm: environmentFrame) => {
  React.array(
    Array.map(frm, xv => {
      let (x, v) = xv
      let ov = v.contents
      let v = switch ov {
      | None => "💣"
      | Some(v) => string_of_value(v)
      }
      <div className="bind">
        {blank(x)}
        {React.string("↦")}
        {blank(v)}
      </div>
    }),
  )
}

let show_env = env => {
//   if length(env) <= 1 {
//     React.string("the primordial environment")
//   } else {
    <div> {React.array(env->map(show_envFrm)->toArray)} </div>
//   }
}

let render_error = err => {
  switch err {
  | UnboundIdentifier(symbol) => `The variable ${symbol} is not bound.`
  | UsedBeforeInitialization(symbol) => `The variable ${symbol} hasn't be declared.`
  | ExpectButGiven(string, _value) => `Expecting a ${string}.`
  | ArityMismatch(_arity, int) => `Expecting a function that accept ${Int.toString(int)} arguments`
  }
}

let show_stkFrm = (frm: stackFrame) => {
  let (ctx, env) = frm
  <div>
    <p>
      {React.string("Waiting for a value in")}
      {show_ctx(ctx)}
    </p>
    <p>
      {React.string("where")}
      {show_env(env)}
    </p>
  </div>
}

let show_stack = (frms: list<React.element>) => {
  <div>
    <div> {React.string("Stack")} </div>
    {React.array(frms->List.toArray)}
  </div>
}

let show_state = (stack, now, envs, heap) => {
  <div id="smol-state">
    <div id="stack-and-now">
      <div> {stack} </div>
      <div> {now} </div>
    </div>
    <div>
      <div> {React.string("Environments")} </div>
      {envs}
    </div>
    <div>
      <div> {React.string("The Heap")} </div>
      {heap}
    </div>
  </div>
}

let render: state => React.element = s => {
  switch s {
  | Terminated(Err(err)) =>
    show_state(show_stack(list{}), React.string(render_error(err)), todo, todo)
  | Terminated(Tm(vs)) => {
      let now = React.string("terminated\n" ++ String.concat("\n", vs->map(string_of_value)))
      show_state(show_stack(list{}), now, todo, todo)
    }

  | Continuing(Ev(e, stt)) => {
      let {ctx, env, stk} = stt
      let stk = show_stack(stk->map(show_stkFrm))
      let now =
        <div>
          <p>
            {React.string("Evaluating")}
            {show_expr(e)}
          </p>
          <p>
            {React.string("in")}
            {show_ctx(ctx)}
          </p>
          <p>
            {React.string("where")}
            {show_env(env)}
          </p>
        </div>
      show_state(stk, now, todo, todo)
    }

  | Continuing(Setting(x, v, stt)) => {
      let {ctx, env, stk} = stt
      let stk = show_stack(stk->map(show_stkFrm))
      let now =
        <div>
          <p>
            {React.string("Replacing the value of")}
            {blank(x)}
            {React.string("with")}
            {show_value(v)}
          </p>
          <p>
            {React.string("in")}
            {show_ctx(ctx)}
          </p>
          <p>
            {React.string("where")}
            {show_env(env)}
          </p>
        </div>
      show_state(stk, now, todo, todo)
    }

  | Continuing(Returning(v, stk)) => {
      let stk = show_stack(stk->map(show_stkFrm))
      let now =
        <div>
          <p>
            {React.string("Returning")}
            {show_value(v)}
          </p>
        </div>
      show_state(stk, now, todo, todo)
    }
  }
}
