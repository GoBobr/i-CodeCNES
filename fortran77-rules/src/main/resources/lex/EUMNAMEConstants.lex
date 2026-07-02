/************************************************************************************************/
/* i-Code CNES is a static code analyzer.                                                       */
/* This software is a free software, under the terms of the Eclipse Public License version 1.0. */
/* http://www.eclipse.org/legal/epl-v10.html                                                    */
/************************************************************************************************/

/********************************************************************************/
/* This file is used to generate a rule checker for EUM.NAME.Constants.         */
/* PARAMETER constants must contain no lowercase characters (except type        */
/* indicator in Hungarian notation).                                            */
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

%class EUMNAMEConstants
%extends AbstractChecker
%public
%column
%line
%ignorecase

%function run
%yylexthrow JFlexException
%type List<CheckResult>

%state COMMENT, NAMING, NEW_LINE, LINE, PARAM_DECL

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
PARAM_KW     = PARAMETER | parameter
DOUBLE_COLON = "::"
/* A constant name that contains lowercase letters (after optional 1-char type prefix) */
/* Matches VAR names with lowercase after first char (allowing first char as type prefix) */
BAD_CONST    = [a-zA-Z][a-zA-Z0-9\_]*[a-z][a-zA-Z0-9\_]*

%{
    String location = "MAIN PROGRAM";
    private static final Logger LOGGER = Logger.getLogger(EUMNAMEConstants.class.getName());
    String parsedFileName;
    int errorLine = 0;

    public EUMNAMEConstants() {}

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
/* PARAM_DECL STATE     */
/************************/
/* After PARAMETER(::), check variable names for lowercase */
/* Note: use \! for inline comments, not {COMMENT_WORD}, because */
/* {COMMENT_WORD} includes c/C which conflicts with variable names */
<PARAM_DECL>    {VAR}           {if(yytext().matches(".*[a-z].*") && !yytext().matches("^[a-zA-Z][A-Z0-9_]*")) setError(location, "Constant '" + yytext() + "' should use uppercase only (except type prefix).", errorLine);}
<PARAM_DECL>    \n              {yybegin(NEW_LINE);}
<PARAM_DECL>    \!              {yybegin(COMMENT);}
<PARAM_DECL>    {STRING}        {}
<PARAM_DECL>    .               {}

/************************/
/* YYINITIAL STATE      */
/************************/
<YYINITIAL>     {COMMENT_WORD}  {yybegin(COMMENT);}
<YYINITIAL>     {TYPE}          {location = yytext(); yybegin(NAMING);}
<YYINITIAL>     \n              {yybegin(NEW_LINE);}
<YYINITIAL>     .               {yybegin(LINE);}

/************************/
/* NEW_LINE STATE       */
/************************/
<NEW_LINE>      {COMMENT_WORD}  {yybegin(COMMENT);}
<NEW_LINE>      {STRING}        {}
<NEW_LINE>      {TYPE}          {location = yytext(); yybegin(NAMING);}
<NEW_LINE>      {PARAM_KW}      {errorLine = yyline+1; yybegin(LINE);}
<NEW_LINE>      \n              {yybegin(NEW_LINE);}
<NEW_LINE>      .               {yybegin(LINE);}

/************************/
/* LINE STATE           */
/************************/
<LINE>          {COMMENT_WORD}  {yybegin(COMMENT);}
<LINE>          {STRING}        {}
<LINE>          {TYPE}          {location = yytext(); yybegin(NAMING);}
<LINE>          {PARAM_KW}      {errorLine = yyline+1;}
<LINE>          {DOUBLE_COLON}  {yybegin(PARAM_DECL);}
<LINE>          \n              {yybegin(NEW_LINE);}
<LINE>          .               {}

/************************/
/* ERROR STATE          */
/************************/
                [^]             {
                    final String errorMessage = "Analysis failure : Your file could not be analyzed. Please verify that it was encoded in an UNIX format.";
                    throw new JFlexException(this.getClass().getName(), parsedFileName, errorMessage, yytext(), yyline, yycolumn);
                }
