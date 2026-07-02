/************************************************************************************************/
/* i-Code CNES is a static code analyzer.                                                       */
/* This software is a free software, under the terms of the Eclipse Public License version 1.0. */
/* http://www.eclipse.org/legal/epl-v10.html                                                    */
/************************************************************************************************/

/********************************************************************************/
/* This file is used to generate a rule checker for EUM.BLOC.NamedLoops.        */
/* Unnamed DO loops must be named when nested at depth >= 2.                    */
/* EXIT/CYCLE must not be used in unnamed DO loops.                             */
/********************************************************************************/

package fr.cnes.icode.fortran77.rules;

import java.io.FileNotFoundException;
import java.io.FileReader;
import java.io.File;
import java.util.List;
import java.util.Stack;
import java.util.logging.Logger;

import fr.cnes.icode.data.AbstractChecker;
import fr.cnes.icode.data.CheckResult;
import fr.cnes.icode.exception.JFlexException;

%%

%class EUMBLOCNamedLoops
%extends AbstractChecker
%public
%column
%line
%ignorecase

%function run
%yylexthrow JFlexException
%type List<CheckResult>

%state COMMENT, NAMING, NEW_LINE, LINE

COMMENT_WORD = \!         | c          | C     | \*
FREE_COMMENT = \!
FUNC         = FUNCTION   | function
PROC         = PROCEDURE  | procedure
SUB          = SUBROUTINE | subroutine
PROG         = PROGRAM    | program
MOD          = MODULE     | module
TYPE         = {FUNC} | {PROC} | {SUB} | {PROG} | {MOD}
VAR          = [a-zA-Z][a-zA-Z0-9\_]*
STRING       = \'[^\']*\' | \"[^\"]*\"
NAMED_DO     = [a-zA-Z][a-zA-Z0-9\_]*[\ \t]*\:[\ \t]*(DO)
END_DO       = (END)[\ \t]+(DO)

%{
    private static final Logger LOGGER = Logger.getLogger(EUMBLOCNamedLoops.class.getName());

    String location = "MAIN PROGRAM";
    String parsedFileName;
    Stack<Boolean> namedStack = new Stack<Boolean>();

    public EUMBLOCNamedLoops() {}

    @Override
    public void setInputFile(final File file) throws FileNotFoundException {
        super.setInputFile(file);
        this.parsedFileName = file.toString();
        this.zzReader = new FileReader(new File(file.getAbsolutePath()));
    }

    private void handleKeyword(String text) {
        String lower = text.toLowerCase();
        if(lower.equals("do")) {
            namedStack.push(false);
            if(namedStack.size() >= 2) {
                setError(location, "Unnamed DO loops must be named when nested at depth >= 2.", yyline+1);
            }
        } else if(lower.equals("enddo")) {
            if(!namedStack.isEmpty()) namedStack.pop();
        } else if(lower.equals("exit")) {
            if(!namedStack.isEmpty() && !namedStack.peek()) {
                setError(location, "EXIT must not be used in unnamed DO loops.", yyline+1);
            }
        } else if(lower.equals("cycle")) {
            if(!namedStack.isEmpty() && !namedStack.peek()) {
                setError(location, "CYCLE must not be used in unnamed DO loops.", yyline+1);
            }
        }
    }
%}

%eofval{
    namedStack.clear();
    return getCheckResults();
%eofval}
%eofclose

%%

/************************/
/* COMMENT STATE        */
/************************/
<COMMENT>       \n              {yybegin(NEW_LINE);}
<COMMENT>       .               {}

/************************/
/* NAMING STATE         */
/************************/
<NAMING>        {VAR}           {location = location + " " + yytext(); yybegin(COMMENT);}
<NAMING>        \n              {yybegin(NEW_LINE);}
<NAMING>        .               {}

/************************/
/* YYINITIAL STATE      */
/************************/
<YYINITIAL>     {FREE_COMMENT}  {yybegin(COMMENT);}
<YYINITIAL>     {STRING}        {}
<YYINITIAL>     {NAMED_DO}      {namedStack.push(true);}
<YYINITIAL>     {END_DO}        {if(!namedStack.isEmpty()) namedStack.pop();}
<YYINITIAL>     {TYPE}          {location = yytext(); yybegin(NAMING);}
<YYINITIAL>     {VAR}           {handleKeyword(yytext());}
<YYINITIAL>     \n              {yybegin(NEW_LINE);}
<YYINITIAL>     .               {yybegin(LINE);}

/************************/
/* NEW_LINE STATE       */
/************************/
<NEW_LINE>      {FREE_COMMENT}  {yybegin(COMMENT);}
<NEW_LINE>      {STRING}        {}
<NEW_LINE>      {NAMED_DO}      {namedStack.push(true);}
<NEW_LINE>      {END_DO}        {if(!namedStack.isEmpty()) namedStack.pop();}
<NEW_LINE>      {TYPE}          {location = yytext(); yybegin(NAMING);}
<NEW_LINE>      {VAR}           {handleKeyword(yytext());}
<NEW_LINE>      \n              {yybegin(NEW_LINE);}
<NEW_LINE>      .               {yybegin(LINE);}

/************************/
/* LINE STATE           */
/************************/
<LINE>          {FREE_COMMENT}  {yybegin(COMMENT);}
<LINE>          {STRING}        {}
<LINE>          {NAMED_DO}      {namedStack.push(true);}
<LINE>          {END_DO}        {if(!namedStack.isEmpty()) namedStack.pop();}
<LINE>          {TYPE}          {location = yytext(); yybegin(NAMING);}
<LINE>          {VAR}           {handleKeyword(yytext());}
<LINE>          \n              {yybegin(NEW_LINE);}
<LINE>          .               {}

/************************/
/* ERROR STATE          */
/************************/
                [^]             {
                    final String errorMessage = "Analysis failure : Your file could not be analyzed. Please verify that it was encoded in an UNIX format.";
                    throw new JFlexException(this.getClass().getName(), parsedFileName, errorMessage, yytext(), yyline, yycolumn);
                }
