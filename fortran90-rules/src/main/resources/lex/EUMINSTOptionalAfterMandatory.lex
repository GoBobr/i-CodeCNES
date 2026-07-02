/************************************************************************************************/
/* i-Code CNES is a static code analyzer.                                                       */
/* This software is a free software, under the terms of the Eclipse Public License version 1.0. */
/* http://www.eclipse.org/legal/epl-v10.html                                                    */
/************************************************************************************************/

/********************************************************************************/
/* This file is used to generate a rule checker for EUM.INST.OptionalAfterMandatory. */
/* OPTIONAL arguments must be declared after mandatory (non-OPTIONAL) arguments.*/
/********************************************************************************/

package fr.cnes.icode.fortran90.rules;

import java.io.FileNotFoundException;
import java.io.FileReader;
import java.io.File;
import java.util.List;

import fr.cnes.icode.data.AbstractChecker;
import fr.cnes.icode.data.CheckResult;
import fr.cnes.icode.exception.JFlexException;

%%

%class EUMINSTOptionalAfterMandatory
%extends AbstractChecker
%public
%column
%line
%ignorecase

%function run
%yylexthrow JFlexException
%type List<CheckResult>

%state COMMENT, NAMING, NEW_LINE, LINE, FUNC_DEF, ARGS, DECL

COMMENT_WORD = \!
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
OPTIONAL_KW  = OPTIONAL | optional
DOUBLE_COLON = "::"
END_FUNC     = END[\ \t]+FUNCTION | end[\ \t]+function | END[\ \t]+SUBROUTINE | end[\ \t]+subroutine
TYPED_FUNC   = {DECL_KW}[\ \t]+{FUNC}

%{
    String location = "MAIN PROGRAM";
    private String parsedFileName;
    boolean seenOptional = false;
    boolean currentHasOptional = false;
    boolean inFunction = false;
    int errorLine = 0;
    int declLine = 0;

    public EUMINSTOptionalAfterMandatory() {}

    @Override
    public void setInputFile(final File file) throws FileNotFoundException {
        super.setInputFile(file);
        this.parsedFileName = file.toString();
        this.zzReader = new FileReader(new File(file.getAbsolutePath()));
    }

    private void checkOptional() {
        if(inFunction && !currentHasOptional && seenOptional) {
            setError(location, "Optional argument must be declared after mandatory arguments.", declLine);
        }
        if(currentHasOptional) seenOptional = true;
        currentHasOptional = false;
    }
%}

%eofval{
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
/* FUNC_DEF STATE       */
/************************/
<FUNC_DEF>      {VAR}[\ \t]*\(  {location = location + " " + yytext().substring(0, yytext().length()-1).trim(); yybegin(ARGS);}
<FUNC_DEF>      {VAR}           {location = location + " " + yytext(); yybegin(LINE);}
<FUNC_DEF>      \n              {yybegin(NEW_LINE);}
<FUNC_DEF>      .               {}

/************************/
/* ARGS STATE           */
/************************/
<ARGS>          \)              {yybegin(LINE);}
<ARGS>          \n              {yybegin(NEW_LINE);}
<ARGS>          \!              {yybegin(COMMENT);}
<ARGS>          .               {}

/************************/
/* DECL STATE           */
/************************/
<DECL>          {OPTIONAL_KW}   {currentHasOptional = true;}
<DECL>          \n              {checkOptional(); yybegin(NEW_LINE);}
<DECL>          \!              {checkOptional(); yybegin(COMMENT);}
<DECL>          {STRING}        {}
<DECL>          .               {}

/************************/
/* YYINITIAL STATE      */
/************************/
<YYINITIAL>     {COMMENT_WORD}  {yybegin(COMMENT);}
<YYINITIAL>     {TYPED_FUNC}    {location = "function"; inFunction = true; seenOptional = false; currentHasOptional = false; errorLine = yyline+1; yybegin(FUNC_DEF);}
<YYINITIAL>     {FUNC}          {location = "function"; inFunction = true; seenOptional = false; currentHasOptional = false; errorLine = yyline+1; yybegin(FUNC_DEF);}
<YYINITIAL>     {SUB}           {location = "subroutine"; inFunction = true; seenOptional = false; currentHasOptional = false; errorLine = yyline+1; yybegin(FUNC_DEF);}
<YYINITIAL>     {TYPE}          {location = yytext(); yybegin(NAMING);}
<YYINITIAL>     {DECL_KW}       {declLine = yyline+1; currentHasOptional = false; yybegin(DECL);}
<YYINITIAL>     {END_FUNC}      {inFunction = false; seenOptional = false; currentHasOptional = false; yybegin(LINE);}
<YYINITIAL>     \n              {yybegin(NEW_LINE);}
<YYINITIAL>     .               {yybegin(LINE);}

/************************/
/* NEW_LINE STATE       */
/************************/
<NEW_LINE>      {COMMENT_WORD}  {yybegin(COMMENT);}
<NEW_LINE>      {STRING}        {}
<NEW_LINE>      {TYPED_FUNC}    {location = "function"; inFunction = true; seenOptional = false; currentHasOptional = false; errorLine = yyline+1; yybegin(FUNC_DEF);}
<NEW_LINE>      {FUNC}          {location = "function"; inFunction = true; seenOptional = false; currentHasOptional = false; errorLine = yyline+1; yybegin(FUNC_DEF);}
<NEW_LINE>      {SUB}           {location = "subroutine"; inFunction = true; seenOptional = false; currentHasOptional = false; errorLine = yyline+1; yybegin(FUNC_DEF);}
<NEW_LINE>      {TYPE}          {location = yytext(); yybegin(NAMING);}
<NEW_LINE>      {DECL_KW}       {declLine = yyline+1; currentHasOptional = false; yybegin(DECL);}
<NEW_LINE>      {END_FUNC}      {inFunction = false; seenOptional = false; currentHasOptional = false; yybegin(LINE);}
<NEW_LINE>      \n              {yybegin(NEW_LINE);}
<NEW_LINE>      .               {yybegin(LINE);}

/************************/
/* LINE STATE           */
/************************/
<LINE>          {COMMENT_WORD}  {yybegin(COMMENT);}
<LINE>          {STRING}        {}
<LINE>          {TYPED_FUNC}    {location = "function"; inFunction = true; seenOptional = false; currentHasOptional = false; errorLine = yyline+1; yybegin(FUNC_DEF);}
<LINE>          {FUNC}          {location = "function"; inFunction = true; seenOptional = false; currentHasOptional = false; errorLine = yyline+1; yybegin(FUNC_DEF);}
<LINE>          {SUB}           {location = "subroutine"; inFunction = true; seenOptional = false; currentHasOptional = false; errorLine = yyline+1; yybegin(FUNC_DEF);}
<LINE>          {TYPE}          {location = yytext(); yybegin(NAMING);}
<LINE>          {DECL_KW}       {declLine = yyline+1; currentHasOptional = false; yybegin(DECL);}
<LINE>          {END_FUNC}      {inFunction = false; seenOptional = false; currentHasOptional = false;}
<LINE>          \n              {yybegin(NEW_LINE);}
<LINE>          .               {}

/************************/
/* ERROR STATE          */
/************************/
                [^]             {
                    final String errorMessage = "Analysis failure : Your file could not be analyzed. Please verify that it was encoded in an UNIX format.";
                    throw new JFlexException(this.getClass().getName(), parsedFileName, errorMessage, yytext(), yyline, yycolumn);
                }
