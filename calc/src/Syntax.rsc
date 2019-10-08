module Syntax

import String;
extend lang::std::Id;
extend lang::std::Layout;

start syntax Cmd 
		= Id "=" Exp
		| "show" Exp 
		| Exp;

syntax Exp
  = Id 
  | Num 
  | left Exp "*" Exp 
  > left Exp "+" Exp
  ;

lexical Num 
	= [\-]?[0-9]+;

alias Env = map[str, int];


tuple[Env, int] exec(Cmd s, Env env) {
  switch (s) {
    case (Cmd)`<Id x> = <Exp e>`: {
      n = eval(e, env);
      return <env + ("<x>": n), n>;
    }
    case (Cmd)`<Exp e>`:
      return <env, eval(e, env)>;
  }
}

int eval(Exp e, Env env) {
  switch (e) {
    case (Exp)`<Num x>`: return toInt("<x>");
    case (Exp)`<Id x>`: return env["<x>"];
    case (Exp)`<Exp l> + <Exp r>`:
      return  eval(l, env) + eval(r, env);
    case (Exp)`<Exp l> * <Exp r>`:
      return  eval(l, env) * eval(r, env);
  }
}