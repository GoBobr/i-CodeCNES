/************************************************************************************************/
/* i-Code CNES is a static code analyzer.                                                       */
/* This software is a free software, under the terms of the Eclipse Public License version 1.0. */
/* http://www.eclipse.org/legal/epl-v10.html                                                    */
/************************************************************************************************/

/********************************************************************************/
/* This file is used to generate a rule checker for EUM.INST.OptionalDefault.   */
/* OPTIONAL arguments must have a default value assigned via present() check.   */
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

%class EUMINSTOptionalDefault
%extends AbstractChecker
%public
%column
%line
%ignorecase

%function run
%yylexthrow JFlexException
%type List<CheckResult>

%state COMMENT, NAMING, NEW_LINE, LINE, FUNC_DEF, ARGS, DECL, DECL_VARS, PRESENT_ARG

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
OPTIONAL_KW   = OPTIONAL | optional
PRESENT_KW    = PRESENT | present
PRESENT_OPEN  = {PRESENT_KW}[\ \t]*\(
DECL_KW       = INTEGER | integer | REAL | real | DOUBLE[\ \t]*PRECISION | double[\ \t]*precision |
                COMPLEX | complex | CHARACTER | character | LOGICAL | logical
DOUBLE_COLON  = "::"
END_FUNC      = END[\ \t]+FUNCTION | end[\ \t]+function | END[\ \t]+SUBROUTINE | end[\ \t]+subroutine
TYPED_FUNC    = {DECL_KW}[\ \t]+{FUNC}

%{
    private static final Logger LOGGER = Logger.getLogger(EUMINSTOptionalDefault.class.getName());

    String location = "MAIN PROGRAM";
    String parsedFileName;
    List<String> funcArgs = new ArrayList<String>();
    List<String> optionalArgs = new ArrayList<String>();
    boolean hasOptional = false;
    int errorLine = 0;

    public EUMINSTOptionalDefault() {}

    @Override
    public void setInputFile(final File file) throws FileNotFoundException {
        super.setInputFile(file);
        this.parsedFileName = file.toString();
        this.zzReader = new FileReader(new File(file.getAbsolutePath()));
    }

    private void checkOptionalArgs() {
        for(String arg : optionalArgs) {
            setError(location, "OPTIONAL argument '" + arg + "' must have a present() check at procedure start.", errorLine);
        }
        funcArgs.clear();
        optionalArgs.clear();
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
<ARGS>          {VAR}           {funcArgs.add(yytext().toLowerCase());}
<ARGS>          \)              {yybegin(LINE);}
<ARGS>          \n              {yybegin(NEW_LINE);}
<ARGS>          \!              {yybegin(COMMENT);}
<ARGS>          .               {}

/************************/
/* DECL STATE           */
/************************/
<DECL>          {OPTIONAL_KW}   {hasOptional = true;}
<DECL>          {DOUBLE_COLON}  {yybegin(DECL_VARS);}
<DECL>          \n              {hasOptional = false; yybegin(NEW_LINE);}
<DECL>          \!              {hasOptional = false; yybegin(COMMENT);}
<DECL>          {STRING}        {}
<DECL>          .               {}

/************************/
/* DECL_VARS STATE      */
/************************/
<DECL_VARS>     {VAR}           {
                    if(hasOptional && funcArgs.contains(yytext().toLowerCase())) {
                        optionalArgs.add(yytext().toLowerCase());
                    }
                }
<DECL_VARS>     \n              {hasOptional = false; yybegin(NEW_LINE);}
<DECL_VARS>     \!              {hasOptional = false; yybegin(COMMENT);}
<DECL_VARS>     {STRING}        {}
<DECL_VARS>     .               {}

/************************/
/* PRESENT_ARG STATE    */
/************************/
<PRESENT_ARG>   {VAR}           {optionalArgs.remove(yytext().toLowerCase());}
<PRESENT_ARG>   \)              {yybegin(LINE);}
<PRESENT_ARG>   \n              {yybegin(NEW_LINE);}
<PRESENT_ARG>   \![^\n]*        {}
<PRESENT_ARG>   .               {}

/************************/
/* YYINITIAL STATE      */
/************************/
<YYINITIAL>     {COMMENT_WORD}  {yybegin(COMMENT);}
<YYINITIAL>     {STRING}        {}
<YYINITIAL>     {TYPED_FUNC}    {location = "function"; funcArgs.clear(); optionalArgs.clear(); hasOptional = false; errorLine = yyline+1; yybegin(FUNC_DEF);}
<YYINITIAL>     {FUNC}          {location = "function"; funcArgs.clear(); optionalArgs.clear(); hasOptional = false; errorLine = yyline+1; yybegin(FUNC_DEF);}
<YYINITIAL>     {SUB}           {location = "subroutine"; funcArgs.clear(); optionalArgs.clear(); hasOptional = false; errorLine = yyline+1; yybegin(FUNC_DEF);}
<YYINITIAL>     {TYPE}          {location = yytext(); yybegin(NAMING);}
<YYINITIAL>     {DECL_KW}       {hasOptional = false; yybegin(DECL);}
<YYINITIAL>     {PRESENT_OPEN}  {yybegin(PRESENT_ARG);}
<YYINITIAL>     {END_FUNC}      {checkOptionalArgs(); yybegin(LINE);}
<YYINITIAL>     \n              {yybegin(NEW_LINE);}
<YYINITIAL>     .               {yybegin(LINE);}

/************************/
/* NEW_LINE STATE       */
/************************/
<NEW_LINE>      {COMMENT_WORD}  {yybegin(COMMENT);}
<NEW_LINE>      {STRING}        {}
<NEW_LINE>      {TYPED_FUNC}    {location = "function"; funcArgs.clear(); optionalArgs.clear(); hasOptional = false; errorLine = yyline+1; yybegin(FUNC_DEF);}
<NEW_LINE>      {FUNC}          {location = "function"; funcArgs.clear(); optionalArgs.clear(); hasOptional = false; errorLine = yyline+1; yybegin(FUNC_DEF);}
<NEW_LINE>      {SUB}           {location = "subroutine"; funcArgs.clear(); optionalArgs.clear(); hasOptional = false; errorLine = yyline+1; yybegin(FUNC_DEF);}
<NEW_LINE>      {TYPE}          {location = yytext(); yybegin(NAMING);}
<NEW_LINE>      {DECL_KW}       {hasOptional = false; yybegin(DECL);}
<NEW_LINE>      {PRESENT_OPEN}  {yybegin(PRESENT_ARG);}
<NEW_LINE>      {END_FUNC}      {checkOptionalArgs(); yybegin(LINE);}
<NEW_LINE>      [ \t]+          {}
<NEW_LINE>      \n              {yybegin(NEW_LINE);}
<NEW_LINE>      .               {yybegin(LINE);}

/************************/
/* LINE STATE           */
/************************/
<LINE>          {COMMENT_WORD}  {yybegin(COMMENT);}
<LINE>          {STRING}        {}
<LINE>          {TYPED_FUNC}    {location = "function"; funcArgs.clear(); optionalArgs.clear(); hasOptional = false; errorLine = yyline+1; yybegin(FUNC_DEF);}
<LINE>          {FUNC}          {location = "function"; funcArgs.clear(); optionalArgs.clear(); hasOptional = false; errorLine = yyline+1; yybegin(FUNC_DEF);}
<LINE>          {SUB}           {location = "subroutine"; funcArgs.clear(); optionalArgs.clear(); hasOptional = false; errorLine = yyline+1; yybegin(FUNC_DEF);}
<LINE>          {TYPE}          {location = yytext(); yybegin(NAMING);}
<LINE>          {DECL_KW}       {hasOptional = false; yybegin(DECL);}
<LINE>          {PRESENT_OPEN}  {yybegin(PRESENT_ARG);}
<LINE>          {END_FUNC}      {checkOptionalArgs();}
<LINE>          \n              {yybegin(NEW_LINE);}
<LINE>          .               {}

/************************/
/* ERROR STATE          */
/************************/
                [^]             {
                    final String errorMessage = "Analysis failure : Your file could not be analyzed. Please verify that it was encoded in an UNIX format.";
                    throw new JFlexException(this.getClass().getName(), parsedFileName, errorMessage, yytext(), yyline, yycolumn);
                }
