module QLREPL

import IO;
import Dependencies;
import Resolve;
import Check;
import Outline;
import Compile;
import Normalize;
import Format;
import ParseTree;
import NotebookQL;
import QL;
import Load;
//import bacata::REPL;
import util::REPL;
//import bacata::salix::Bridge;
import bacata::util::Proposer;
import exercises::Part2;
import AST;
import vis::Figure;
import salix::App;
import salix::HTML;
import salix::Core;
import salix::Node;
import bacata::util::Util;
import salix::lib::Dagre;

import bacata::Notebook;

NotebookServer createQLnb(bool d = false) {
	Kernel k = kernel("QL-2020",  |home:///Documents/tmp/bacata-demos/rascal-ql-tutorial-prototype-master/src/|, "QLREPL::qlREPL", salixPath=|home:///Documents/Rascal/salix/src|);
	return createNotebook(k, debug = d );
}

public REPL qlREPL()
	= repl(handler = handl, completor = complet); 

map[str, AST::Form] history = ();

Form astt = AST::form("",[]);

Content handl(str line){
	errors=[];
	result = "";
	try {
		pt = parse(#start[CommandForm], line);
		switch(pt.top){
			case (CommandForm)`form <Id idss> = <Form form>`: {
				imploForm = implodeForm(form);
			    msgs = check(imploForm) + cyclicErrors(controlDeps(imploForm));
			    if (msgs == {}) {
			    	history += ("<idss>" : imploForm);
			    	return html("ok");
			        //return commandResult("ok", messages = errors);
			     }
			     else{
			     	errors = translateErrorMessages(msgs);
			     	return html(errors);
					//return commandResult(result, messages = errors);
			     }
			}
			case (CommandForm)`visualize(<Id idd>)`: {
				astt = getForm("<idd>");
				SalixApp[Model] app = makeApp("ql", init, view, update);
				return webApp(app, index = |tmp:///|, static = |tmp:///|, headers = ("Access-Control-Allow-Origin":"*","Access-Control-Allow-Headers":"Origin, X-Requested-With, Content-Type, Accept"));
				//return salix(makeApp(init, view, update));
			}
			case (CommandForm)`html(<Id idd>)`: {
				thisForm = getForm("<idd>");
				rst = "\<script\><compile(desugar(thisForm))>\</script\>";
			    rst += toHTML(viewQlForm);
			    return html("<rst> | <errors>");
				//return commandResult("<rst>", messages = errors);
			}
		}
	}
	catch ParseError(lo):
	{
		errors = [error("Parse error at <lo>")];
		return html("");
		//return commandResult("", messages = errors);
	}
}

Form getForm(str idd){
	try{
		return history["<idd>"];
	}
	catch: {	
		errors = translateErrorMessages(msgs);
		return html("");
		//return commandResult("", messages = errors);
	}
}

Completion complet(str prefix, int offset) {
	proposerFunction = proposer(#CommandForm);
   	return < 0, ["<prop.newText>" | prop <- proposerFunction(prefix, offset)] >;
}

void viewQlForm(){
	div(id("QL-content"));
}

Model init() = astt;

data Msg = ope();

alias Model = Form;

Model update(Msg msg, Model m) {
  return m;
}
 
 Form tmp(){
 	pt = parse(#start[Form], readFile(|project://RascalQLTutorial/examples/tax.tql|));
 	return implodeQL(pt);
 }

set[Node] getNodesH(rel[Node from, Node to] fa){
	return {from|<Node from, Node to> <-fa}+ {to|<Node from, Node to> <-fa};
}

void view(Model ast) {
  div(() {
    h4("Visualization");    
    dagre("mygraph", rankdir("LR"), title("M3 modules"), width(960), height(600), (N n, E e) {
    nos = resolve(controlDeps(ast) + dataDeps(ast)); 
    for(Node x <- getNodesH(nos)){
        n("<x.label>", shape("rect"), () {
            div(id("nod-label"),(){
                p("<x.label>");
            });
        });
        }
        for (<Node from, Node to> <- nos) {
             e("<from.label>", "<to.label>", lineInterpolate("cardinal"));
         }
    }); 
  });
}