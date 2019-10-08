module CalcREPL

import IO;
import String;
import Exception;
import Syntax;
import Message;
import ParseTree;
import bacata::salix::Bridge;
import salix::App;
import salix::HTML;
import salix::Core;
import salix::Node;
import bacata::util::Util;
import salix::lib::Dagre;
import bacata::util::Proposer;


REPL myRepl() {
  Env env = ();
  
  CommandResult myHandler(str line) {
    try {
    	Syntax::Cmd cmd = parse(#start[Cmd], line).top;
    	if ((Cmd)`show <Exp e>` := cmd) {
 			return salix(expApp(e, env));
		}
		else {
      		<env, n> = exec(cmd, env);
      		return commandResult("<n>", messages = []);
      	}
    }
    catch ParseError(loc l):
      return commandResult("", messages = [error("Parse error", l)]);
  }

  Completion myCompletor(str prefix, int offset)
    =  <0, [ x | x <- env, startsWith(x, prefix) ]>; 

  return repl(myHandler, myCompletor, visualization = makeSalixMultiplexer(|http://localhost:3439|, |tmp:///|));
}

data Msg = change(str x, str val);

SalixApp[Env] expApp(Exp e, Env env) {
	Env init() = env; 
	
	void view(Env env) {
		div(() {
			for (x <- env) { 
				text("<x>: <env["<x>"]>");
				input(\value("<env["<x>"]>"), \type("range"), onInput(partial(change, "<x>")));
			}
			text("<e>: <eval(e, env)>");
		});
	}

	Env update(change(x, v), Env env) 
		= env + (x: toInt(v));
	return makeApp(init, view, update);
}