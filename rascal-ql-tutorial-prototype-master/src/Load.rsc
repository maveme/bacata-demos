module Load

import Parse;
import AST;
import ParseTree;

CommandForm load(loc l) = implodeQL(parseQL(l));
CommandForm load(str src) = implodeQL(parseQL(src));
CommandForm loadExample(str file) = load(|project://RascalQLTutorial/examples/<file>|);

CommandForm implodeQL(Tree f) = implode(#CommandForm, f);

CommandForm implodeForm(Tree f) = implode(#CommandForm, f);
