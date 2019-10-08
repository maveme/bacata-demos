module javascript::JSRepl

import String;
import ParseTree;
import bacata::salix::Bridge;
import bacata::Notebook;
import bacata::util::Util;
import bacata::util::Proposer;
import javascript::Resolve;
import javascript::Syntax;
import javascript::Desugar;
import demo::HAML;
import salix::HTML;
import demo::SelectQuery;
import demo::StateMachine;


public REPL jsREPL(){
	return repl( handl, complet);
} 

start[Source] rename(start[Source] src, map[loc, str] renaming) {
  return visit (src) {
    case Id x => parse(#Id, renaming[x@\loc])
      when x@\loc in renaming
  }
}

tuple[start[Source], Refs, map[loc, str]] desugarAndResolve(start[Source] src) {
  js = uniqueify(desugarAll(src));
  <lookup, getRenaming> = makeResolver();
  xref = resolve(js.top, lookup);
  renaming = getRenaming(xref);
  return <js, xref, renaming>;
}

CommandResult handl(str line){
	errors=[];
	rst = "";
	try{
		pt = parse(#start[Source], line);
		<js, xref, renaming> = desugarAndResolve(pt);
        fixed = rename(js, renaming);
        original = translate(pt);

        desugared = translate(fixed);
        desugaredSrc = unparse(fixed);

        rst = toHTML(jsView);
        
        str merge(str template) {
			template = replaceAll(template, "{{original}}", original);
			template = replaceAll(template, "{{desugared}}", desugared);
			template = replaceAll(template, "{{desugaredSrc}}", desugaredSrc);
			return template;
		}
        
        rst += merge(jsTemplate());
        return textual("<rst>", messages = errors);
	}
	catch ParseError(lo):
	{
		errors = [error("Parse error at <lo>")];
		return textual(rst, messages = errors);
	}
}

Completion complet(str prefix, int offset) {
	proposerFunction = proposer(#Source);
   	return < 0, ["<prop.newText>" | prop <- proposerFunction(prefix, offset)] >;
}

str translate(start[Source] orig) {
 	str toJsStr(str code) {
		code = replaceAll(code, "\n", " \\n \\\n");
		code = replaceAll(code, "\"", "\\\"");
		code = replaceAll(code, "\'", "\\\'");
		return code;
	}
 	return toJsStr(unparse(orig));
}

void jsView(){
	div(class("row"), () {
		    ul(class("nav nav-tabs"), (){
		    	li(class("active"), (){
		    		a(dataToggle("tab"), href("#home"), "Desugared JS source");
		    	});
		    	li((){
		    		a(dataToggle("tab"), href("#menu1"), "Console output");
		    	});
		    });
		    
		    div(class("tab-content"), () {
		    	div(id("menu1"), class("tab-pane fade"), () {
					div(class("col-md-12"), () {
			    			div(id("log"), () {});
			    	});
		    	});
		    	div(id("home"), class("tab-pane fade in active"), () {
					div(class("col-md-12"), () {
			    		div(class("code"), id("transformed"), () {});
			    	});
		    	});
		    });
    });
}

str jsTemplate() =
"\<script\>
'		CodeMirror(document.getElementById(\"original\"), {
'			value: 
'\" \\
'{{original}} \\
'\",
'			mode: \"javascript\",
'			lineNumbers: true,
'			readOnly: true,
'			}); 
'
'		CodeMirror(document.getElementById(\"transformed\"), {
'			value: 
'\" \\
'{{desugared}} \\
'\",
'			mode: \"javascript\",
'			lineNumbers: true,
'			readOnly: true,
'			}); 
'
'\</script\>
'
'\<script\>
'var DEBUG_FLAG = true;
'var logger = document.getElementById(\'log\');
'var createElem = function(elemType, className, innerText) {
'	var elem = document.createElement(elemType);
'	if (className !== undefined) {
'		elem.className = className;
'	}
'
'	if (innerText !== undefined) {
'		elem.textContent = innerText;
'		elem.innerText = innerText;
'	}
'	return elem;
' }
'
'console.log = function (message) {
'    if (typeof message == \'object\') {
'        logger.appendChild(createElem(\"p\", \"info\", JSON && JSON.stringify ? JSON.stringify(message) : message));
'    } else {
'        logger.appendChild(createElem(\"p\", \"info\", message));
'    }       
'}
'
'console.error = function (message) {
'    if (typeof message == \'object\') {
'        logger.appendChild(createElem(\"p\", \"error\", JSON && JSON.stringify ? JSON.stringify(message) : message));
'      	} else {
'        logger.appendChild(createElem(\"p\", \"error\", message));
'    }       
'}    
'
'\</script\>
'
'\<script\>
'	try {
'		{{desugaredSrc}}
'	} catch (e) {
'		if (e instanceof Error) {
'			console.error(e.message);
'		} else {
'			console.error(e);
'		}
'	}
'\</script\>";