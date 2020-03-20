module CalcREPL

import IO;
import Map;
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
//import bacata::REPL;
import bacata::util::Proposer;

import util::REPL;

import bacata::Notebook;

NotebookServer nb(bool d = false) {
	Kernel k = kernel("Calc",  |home:///Documents/tmp/bacata-demos/calc/src/|, "CalcREPL::myRepl", salixPath=|home:///salix/src|);
	return createNotebook(k, debug = d );
}


REPL myRepl() {
  Env env = ();
  
  Response myHandler(str input) {
    try {
    	Syntax::Cmd cmd = parse(#start[Cmd], input).top;
    	if ((Cmd)`show <Exp e>` := cmd) {
 			//return salix(expApp(e, env));
 			return plain(e); // TODO: update the Salix stuff.
		}
		else {
      		<env, n> = exec(cmd, env);
      		return plain("<n>");
      	}
    }
    catch ParseError(loc l):
    	return plain("Error");
  }

  Completion myCompletor(str prefix, int offset)
    =  <0, [ x | x <- env, startsWith(x, prefix) ]>; 

return repl(handler = myHandler, completor = myCompletor);
  //return repl(myHandler, myCompletor, visualization = makeSalixMultiplexer(|http://localhost:3437|, |tmp:///|));
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