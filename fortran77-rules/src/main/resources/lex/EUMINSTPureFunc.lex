/************************************************************************************************/
/* i-Code CNES is a static code analyzer.                                                       */
/* This software is a free software, under the terms of the Eclipse Public License version 1.0. */
/* http://www.eclipse.org/legal/epl-v10.html                                                    */
/************************************************************************************************/

/********************************************************************************/
/* This file is used to generate a rule checker for EUM.INST.PureFunc.          */
/* Functions with all INTENT(IN) args and no READ/WRITE should be declared PURE.*/
/********************************************************************************/

package fr.cnes.icode.fortran77.rules;

import java.io.FileNotFoundException;
import java.io.FileReader;
import java.io.File;
import java.util.List;
import java.util.logging.Logger;

import fr.cnes.icode.data.AbstractChecker;
import fr.cnes.icode.data.CheckResult;
import fr.cnes.icode.exception.JFlexException;

%%

%class EUMINSTPureFunc
%extends AbstractChecker
%public
%column
%line
%ignorecase

%function run
%yylexthrow JFlexException
%type List<CheckResult>

%state COMMENT, NAMING, NEW_LINE, LINE, FUNC_DEF, ARGS

COMMENT_WORD  = \!         | c          | C     | \*
FREE_COMMENT  = \!
FUNC          = FUNCTION   | function
PROC          = PROCEDURE  | procedure
SUB           = SUBROUTINE | subroutine
PROG          = PROGRAM    | program
MOD           = MODULE     | module
TYPE          = {FUNC} | {PROC} | {SUB} | {PROG} | {MOD}
VAR           = [a-zA-Z][a-zA-Z0-9\_]*
STRING        = \'[^\']*\' | \"[^\"]*\"
PURE_KW       = PURE | pure
PURE_FUNC_KW  = {PURE_KW}[\ \t]+.*{FUNC}
DECL_KW       = INTEGER | integer | REAL | real | DOUBLE[\ \t]*PRECISION | double[\ \t]*precision |
                COMPLEX | complex | CHARACTER | character | LOGICAL | logical
INTENT_IN     = INTENT[\ \t]*\([\ \t]*IN[\ \t]*\) | intent[\ \t]*\([\ \t]*in[\ \t]*\)
INTENT_OUT    = INTENT[\ \t]*\([\ \t]*OUT[\ \t]*\) | intent[\ \t]*\([\ \t]*out[\ \t]*\)
INTENT_INOUT  = INTENT[\ \t]*\([\ \t]*IN[\ \t]*OUT[\ \t]*\) | intent[\ \t]*\([\ \t]*in[\ \t]*out[\ \t]*\) |
                INTENT[\ \t]*\([\ \t]*INOUT[\ \t]*\) | intent[\ \t]*\([\ \t]*inout[\ \t]*\)
IO_KW         = READ | read | WRITE | write
END_FUNC      = END[\ \t]+FUNCTION | end[\ \t]+function
TYPED_FUNC    = {DECL_KW}[\ \t]+{FUNC}

%{
    private static final Logger LOGGER = Logger.getLogger(EUMINSTPureFunc.class.getName());

    String location = "MAIN PROGRAM";
    String parsedFileName;
    private boolean inFunction = false;
    private boolean isPure = false;
    private boolean allIntentIn = true;
    private boolean hasIO = false;
    int errorLine = 0;

    public EUMINSTPureFunc() {}

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
<FUNC_DEF>      {VAR}[\ \t]*\(  {location = location + " " + yytext().substring(0, yytext().length()-1).trim(); yybegin(ARGS);}
<FUNC_DEF>      {VAR}           {location = location + " " + yytext(); yybegin(LINE);}
<FUNC_DEF>      \n              {yybegin(NEW_LINE);}
<FUNC_DEF>      \!              {yybegin(COMMENT);}
<FUNC_DEF>      .               {}

/************************/
/* ARGS STATE           */
/************************/
<ARGS>          {VAR}           {}
<ARGS>          \)              {yybegin(LINE);}
<ARGS>          \n              {yybegin(NEW_LINE);}
<ARGS>          \!              {yybegin(COMMENT);}
<ARGS>          .               {}

/************************/
/* YYINITIAL STATE      */
/************************/
<YYINITIAL>     {COMMENT_WORD}  {yybegin(COMMENT);}
<YYINITIAL>     {STRING}        {}
<YYINITIAL>     {PURE_FUNC_KW}  {isPure = true; inFunction = true; allIntentIn = true; hasIO = false; errorLine = yyline+1; location = "function"; yybegin(FUNC_DEF);}
<YYINITIAL>     {TYPED_FUNC}    {isPure = false; inFunction = true; allIntentIn = true; hasIO = false; errorLine = yyline+1; location = "function"; yybegin(FUNC_DEF);}
<YYINITIAL>     {FUNC}          {isPure = false; inFunction = true; allIntentIn = true; hasIO = false; errorLine = yyline+1; location = "function"; yybegin(FUNC_DEF);}
<YYINITIAL>     {SUB}           {inFunction = false; location = yytext(); yybegin(NAMING);}
<YYINITIAL>     {TYPE}          {inFunction = false; location = yytext(); yybegin(NAMING);}
<YYINITIAL>     {INTENT_OUT}    {if(inFunction) allIntentIn = false; yybegin(LINE);}
<YYINITIAL>     {INTENT_INOUT}  {if(inFunction) allIntentIn = false; yybegin(LINE);}
<YYINITIAL>     {IO_KW}         {if(inFunction) hasIO = true; yybegin(LINE);}
<YYINITIAL>     {END_FUNC}      {
                    if(inFunction && !isPure && allIntentIn && !hasIO) {
                        setError(location, "Function with all INTENT(IN) arguments and no I/O should be declared PURE.", errorLine);
                    }
                    inFunction = false;
                    yybegin(LINE);
                }
<YYINITIAL>     \n              {yybegin(NEW_LINE);}
<YYINITIAL>     .               {yybegin(LINE);}

/************************/
/* NEW_LINE STATE       */
/************************/
<NEW_LINE>      {COMMENT_WORD}  {yybegin(COMMENT);}
<NEW_LINE>      {STRING}        {}
<NEW_LINE>      {PURE_FUNC_KW}  {isPure = true; inFunction = true; allIntentIn = true; hasIO = false; errorLine = yyline+1; location = "function"; yybegin(FUNC_DEF);}
<NEW_LINE>      {TYPED_FUNC}    {isPure = false; inFunction = true; allIntentIn = true; hasIO = false; errorLine = yyline+1; location = "function"; yybegin(FUNC_DEF);}
<NEW_LINE>      {FUNC}          {isPure = false; inFunction = true; allIntentIn = true; hasIO = false; errorLine = yyline+1; location = "function"; yybegin(FUNC_DEF);}
<NEW_LINE>      {SUB}           {inFunction = false; location = yytext(); yybegin(NAMING);}
<NEW_LINE>      {TYPE}          {inFunction = false; location = yytext(); yybegin(NAMING);}
<NEW_LINE>      {INTENT_OUT}    {if(inFunction) allIntentIn = false; yybegin(LINE);}
<NEW_LINE>      {INTENT_INOUT}  {if(inFunction) allIntentIn = false; yybegin(LINE);}
<NEW_LINE>      {IO_KW}         {if(inFunction) hasIO = true; yybegin(LINE);}
<NEW_LINE>      {END_FUNC}      {
                    if(inFunction && !isPure && allIntentIn && !hasIO) {
                        setError(location, "Function with all INTENT(IN) arguments and no I/O should be declared PURE.", errorLine);
                    }
                    inFunction = false;
                    yybegin(LINE);
                }
<NEW_LINE>      [ \t]+          {}
<NEW_LINE>      \n              {yybegin(NEW_LINE);}
<NEW_LINE>      .               {yybegin(LINE);}

/************************/
/* LINE STATE           */
/************************/
<LINE>          {COMMENT_WORD}  {yybegin(COMMENT);}
<LINE>          {STRING}        {}
<LINE>          {PURE_FUNC_KW}  {isPure = true; inFunction = true; allIntentIn = true; hasIO = false; errorLine = yyline+1; location = "function"; yybegin(FUNC_DEF);}
<LINE>          {TYPED_FUNC}    {isPure = false; inFunction = true; allIntentIn = true; hasIO = false; errorLine = yyline+1; location = "function"; yybegin(FUNC_DEF);}
<LINE>          {FUNC}          {isPure = false; inFunction = true; allIntentIn = true; hasIO = false; errorLine = yyline+1; location = "function"; yybegin(FUNC_DEF);}
<LINE>          {SUB}           {inFunction = false; location = yytext(); yybegin(NAMING);}
<LINE>          {TYPE}          {inFunction = false; location = yytext(); yybegin(NAMING);}
<LINE>          {INTENT_OUT}    {if(inFunction) allIntentIn = false;}
<LINE>          {INTENT_INOUT}  {if(inFunction) allIntentIn = false;}
<LINE>          {IO_KW}         {if(inFunction) hasIO = true;}
<LINE>          {END_FUNC}      {
                    if(inFunction && !isPure && allIntentIn && !hasIO) {
                        setError(location, "Function with all INTENT(IN) arguments and no I/O should be declared PURE.", errorLine);
                    }
                    inFunction = false;
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
