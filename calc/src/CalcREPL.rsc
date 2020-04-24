module CalcREPL

import IO;
import Map;
import String;
import Exception;
import Syntax;
import Message;
import ParseTree;
import salix::App;
import salix::HTML;
import salix::Core;
import bacata::util::Util;
import salix::lib::Dagre;
import bacata::util::Proposer;

import util::REPL;

import bacata::Notebook;

NotebookServer nb(bool d = false) {
	Kernel k = kernel("Calc",  |home:///Documents/tmp/bacata-demos/calc/src/|, "CalcREPL::myRepl", salixPath=|home:///Documents/Rascal/salix/src|);
	return createNotebook(k, debug = d );
}


REPL myRepl() {
  Env env = ();
  
  Content myHandler(str input) {
    try {
    	Syntax::Cmd cmd = parse(#start[Cmd], input).top;
    	if ((Cmd)`show <Exp e>` := cmd) {
    		SalixApp[Env] app = expApp(e, env);
			App[Env] calcAppz = webApp(app, index = |home:///Documents/tmp/bacata-demos/calc/src/index.html|, static = |home:///Documents/Rascal/salix/src|, headers = ("Access-Control-Allow-Origin":"*","Access-Control-Allow-Headers":"Origin, X-Requested-With, Content-Type, Accept"));
			return calcAppz;
		}
		else {
      		<env, n> = exec(cmd, env);
      		return html("<n>");
      	}
    }
    catch ParseError(loc l):
    	return html("Error");
  }

  Completion myCompletor(str prefix, int offset)
    =  <0, [ x | x <- env, startsWith(x, prefix) ]>; 

	return repl(handler = myHandler, completor = myCompletor);
  //return repl(myHandler, myCompletor, visualization = makeSalixMultiplexer(|http://localhost:3437|, |tmp:///|));
}



data Msg
  = change(str x, str y)
  ;
  
//SalixApp[Env] calcApp
//  = makeApp("calc", init, view, update);


SalixApp[Env] expApp(Exp e, Env env) {
	Env init() =  env;
	str id = "calc";
	
	void view(Env env) {
		div(() {
			for (x <- env) {
				salix::HTML::text("<x>: <env["<x>"]>");
				input(\value("<env["<x>"]>"), \type("range"), onInput(partial(id, change, "<x>")));
			}
			salix::HTML::text("<e>: <eval(e, env)>");
		});
	}
	
	Env update(change(x, y), Env m)
		= m + (x: toInt(y));
	
	return makeApp(id, init, view, update);
}

//
// OLD
//

//data Msg = change(str x, str val);
//
//
//SalixApp[Env] expApp(Exp e, Env env) {
//	Env init() = env; 
//	
//	void view(Env env) {
//		div(() {
//			for (x <- env) { 
//				text("<x>: <env["<x>"]>");
//				input(\value("<env["<x>"]>"), \type("range"), onInput(partial(change, "<x>")));
//			}
//			text("<e>: <eval(e, env)>");
//		});
//	}
//
//	Env update(change(x, v), Env env) 
//		= env + (x: toInt(v));
//		
//	return makeApp("calc", init, view, update);
//}