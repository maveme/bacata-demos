module Interpreter

import AST;

import util::Maybe;

data Phrase
  = normalized_question(Label label, Id name, QType ty, Expr cond, Maybe[Expr] def)
  | answer(Id name, Val v)
  ;
  
data Val
  = integer(int intValue)
  | string(str strValue)
  | money(real realValue)
  | \true()
  | \false()
  ;
  
data FormElement
  = form_element(Phrase, bool display, Maybe[Val] val)
  ;

alias Store       = map[Id,maybe[Val]];
alias Display     = map[Id,bool];
alias Environment = map[Id,Phrase];
alias Flow        = rel[Id from, Id to];

data Context = context(Environment env, Store sto, Display dis, set[Id] nodes, Flow flow, list[FormElement] res);

Context eval(decl : normalized_question(_,name,_,cond, def), Context c) {
  if (name notin c.env) {
     c.env = c.env + (name : decl);
     c.dis = c.dis + (name : false);
     c.sto = c.sto + (name : nothing());
     c.nodes = c.nodes + {name};
     
     //TODO more efficient, greedy update to graph while keeping it closed under transitivity?
     c.flow += { <name, s> | Id s <- successors_of(c.env, name)};
     f.flow += { <a, name> | Id a <- usedIn(def)};
     return do_visit(name, c, true);
  }
  fail;
}

Context eval(answer(Id name, Val val), Context c) {
  old = c.sto[name];
  new = just(val);
  if (old != new) {
    c.sto[name] = new;
    return do_visit(name, c, true);
  } else {
    return c;
  }
}

Context do_visit(Id name, Context c) = do_visit(name, c, false);

Context do_visit(Id name, Context c, bool force_output) {
  if (normalized_question(_, name, _, Expr cond, Maybe[Expr] def) := c.env[name]) {  
    def_old = c.sto[name];
    if ( ( true | it && assigned(c,pred) | Id pred <- usedIn(def)) ) {
      c.sto[name] = eval(def, c);
    }    
    cond_old = c.dis[name];
    if ( ( true | it && assigned(c,pred) | Id pred <- usedIn(cond))) {
      cond_res = eval(cond, c);
      if (\true() := cond_res || \false() := cond_res) {
        c.dis[name] = cond_res;
      }
    }
    if (force_output || def_old != c.sto[name] || cond_old != c.dis[name]) {
      c = output_form_element(name, c);
    }
    if (just(_) := c.sto[name]) { //is assigned
      return ( c | do_visit(s, it) | Id s <- successors(c.flow, name));
    } 
  }
  fail;
}

Maybe[Val] eval(nothing(), _) = nothing();
Maybe[Val] eval(just(e), c) = just(eval(e, c));

Val eval(\true(), c) = \true();
Val eval(\false(), c) = \false();
//TODO, rest

void output_form_element(name, c) {
  c.res = c.res + [ form_element(c.env[name], c.dis[name], c.sto[name]) ];
  return c;
}

set[Id] successors_of(Environment env, Id name) {
  res = {};
  for (normalized_question(_, x, _, _, opt_def) <- range(env)) {
    if (name in usedIn(opt_def)) { res += {x};}
  }
  return res;
}

set[Id] definedIn(Question q)
  = { d.name | /Question d := q, d has name };
    
set[Id] usedIn(Expr e)    = { x | /Id x := e };
set[Id] usedIn(nothing()) = {};
set[Id] usedIn(Just(e))   = usedIn(e);