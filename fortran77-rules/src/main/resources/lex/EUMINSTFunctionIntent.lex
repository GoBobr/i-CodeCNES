/************************************************************************************************/
/* i-Code CNES is a static code analyzer.                                                       */
/* This software is a free software, under the terms of the Eclipse Public License version 1.0. */
/* http://www.eclipse.org/legal/epl-v10.html                                                    */
/************************************************************************************************/

/********************************************************************************/
/* This file is used to generate a rule checker for EUM.INST.FunctionIntent.    */
/* All function arguments must have INTENT(IN).                                 */
/********************************************************************************/

package fr.cnes.icode.fortran77.rules;

import java.io.FileNotFoundException;
import java.io.FileReader;
import java.io.File;
import java.util.ArrayList;
import java.util.List;
import java.util.logging.Logger;

import fr.cnes.icode.data.AbstractChecker;
import fr.cnes.icode.data.CheckResult;
import fr.cnes.icode.exception.JFlexException;

%%

%class EUMINSTFunctionIntent
%extends AbstractChecker
%public
%column
%line
%ignorecase

%function run
%yylexthrow JFlexException
%type List<CheckResult>

%state COMMENT, NAMING, NEW_LINE, LINE, FUNC_DEF, ARGS, DECL, INTENT_CHECK

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
DECL_KW      = INTEGER | integer | REAL | real | DOUBLE[\ \t]*PRECISION | double[\ \t]*precision |
               COMPLEX | complex | CHARACTER | character | LOGICAL | logical
INTENT_KW    = INTENT[\ \t]*\([\ \t]*IN[\ \t]*\)
DOUBLE_COLON = "::"
END_FUNC     = END[\ \t]+FUNCTION | end[\ \t]+function
/* Typed function: "integer function" or "real function" etc. */
TYPED_FUNC   = {DECL_KW}[\ \t]+{FUNC}

%{
    private static final Logger LOGGER = Logger.getLogger(EUMINSTFunctionIntent.class.getName());

    String location = "MAIN PROGRAM";
    String parsedFileName;
    List<String> funcArgs = new ArrayList<String>();
    List<String> argsWithIntent = new ArrayList<String>();
    int errorLine = 0;

    public EUMINSTFunctionIntent() {}

    @Override
    public void setInputFile(final File file) throws FileNotFoundException {
        super.setInputFile(file);
        this.parsedFileName = file.toString();
        this.zzReader = new FileReader(new File(file.getAbsolutePath()));
    }
%}

%eofval{
    return getCheckResults();
%eofval}
%eofclose

%%

                {FREE_COMMENT}  {yybegin(COMMENT);}

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
/* FUNC_DEF STATE       */
/************************/
/* After FUNCTION keyword, capture the name and look for argument list */
<FUNC_DEF>      {VAR}[\ \t]*\(  {location = "function " + yytext().substring(0, yytext().length()-1).trim(); yybegin(ARGS);}
<FUNC_DEF>      {VAR}           {location = "function " + yytext(); yybegin(LINE);}
<FUNC_DEF>      \n              {yybegin(NEW_LINE);}
<FUNC_DEF>      .               {}

/************************/
/* ARGS STATE           */
/************************/
/* Inside function argument list — capture argument names */
<ARGS>          {VAR}           {funcArgs.add(yytext());}
<ARGS>          \)              {yybegin(LINE);}
<ARGS>          \n              {yybegin(NEW_LINE);}
<ARGS>          .               {}

/************************/
/* DECL STATE           */
/************************/
/* After declaration keyword, look for INTENT or variable names */
<DECL>          {INTENT_KW}     {yybegin(INTENT_CHECK);}
<DECL>          {DOUBLE_COLON}  {}
<DECL>          \n              {yybegin(NEW_LINE);}
<DECL>          \!              {yybegin(COMMENT);}
<DECL>          .               {}

/************************/
/* INTENT_CHECK STATE   */
/************************/
/* After INTENT(IN), capture variable names that have intent */
<INTENT_CHECK>  {VAR}           {argsWithIntent.add(yytext());}
<INTENT_CHECK>  \n              {yybegin(NEW_LINE);}
<INTENT_CHECK>  \!              {yybegin(COMMENT);}
<INTENT_CHECK>  {STRING}        {}
<INTENT_CHECK>  .               {}

/************************/
/* YYINITIAL STATE      */
/************************/
<YYINITIAL>     {COMMENT_WORD}  {yybegin(COMMENT);}
<YYINITIAL>     {TYPE}          {location = yytext(); yybegin(NAMING);}
<YYINITIAL>     {FUNC}          {funcArgs.clear(); argsWithIntent.clear(); errorLine = yyline+1; yybegin(FUNC_DEF);}
<YYINITIAL>     \n              {yybegin(NEW_LINE);}
<YYINITIAL>     .               {yybegin(LINE);}

/************************/
/* NEW_LINE STATE       */
/************************/
<NEW_LINE>      {COMMENT_WORD}  {yybegin(COMMENT);}
<NEW_LINE>      {STRING}        {}
<NEW_LINE>      {TYPE}          {location = yytext(); yybegin(NAMING);}
<NEW_LINE>      {TYPED_FUNC}    {funcArgs.clear(); argsWithIntent.clear(); errorLine = yyline+1; yybegin(FUNC_DEF);}
<NEW_LINE>      {FUNC}          {funcArgs.clear(); argsWithIntent.clear(); errorLine = yyline+1; yybegin(FUNC_DEF);}
<NEW_LINE>      {DECL_KW}       {yybegin(DECL);}
<NEW_LINE>      {END_FUNC}      {
                    /* Check that all function args have INTENT(IN) */
                    for(String arg : funcArgs) {
                        if(!argsWithIntent.contains(arg)) {
                            setError(location, "Function argument '" + arg + "' must have INTENT(IN).", errorLine);
                        }
                    }
                    funcArgs.clear();
                    argsWithIntent.clear();
                    yybegin(LINE);
                }
<NEW_LINE>      \n              {yybegin(NEW_LINE);}
<NEW_LINE>      .               {yybegin(LINE);}

/************************/
/* LINE STATE           */
/************************/
<LINE>          {COMMENT_WORD}  {yybegin(COMMENT);}
<LINE>          {STRING}        {}
<LINE>          {TYPE}          {location = yytext(); yybegin(NAMING);}
<LINE>          {TYPED_FUNC}    {funcArgs.clear(); argsWithIntent.clear(); errorLine = yyline+1; yybegin(FUNC_DEF);}
<LINE>          {FUNC}          {funcArgs.clear(); argsWithIntent.clear(); errorLine = yyline+1; yybegin(FUNC_DEF);}
<LINE>          {DECL_KW}       {yybegin(DECL);}
<LINE>          {END_FUNC}      {
                    /* Check that all function args have INTENT(IN) */
                    for(String arg : funcArgs) {
                        if(!argsWithIntent.contains(arg)) {
                            setError(location, "Function argument '" + arg + "' must have INTENT(IN).", errorLine);
                        }
                    }
                    funcArgs.clear();
                    argsWithIntent.clear();
                }
<LINE>          \n              {yybegin(NEW_LINE);}
<LINE>          .               {}

/************************/
/* ERROR STATE          */
/************************/
                [^]             {
                    final String errorMessage = "Analysis failure : Your file could not be analyzed. Please verify that it was encoded in an UNIX format.";
                    throw new JFlexException(this.getClass().getName(), parsedFileName, errorMessage, yytext(), yyline, yycolumn);
                }
