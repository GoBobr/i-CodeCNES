/************************************************************************************************/
/* i-Code CNES is a static code analyzer.                                                       */
/* This software is a free software, under the terms of the Eclipse Public License version 1.0. */
/* http://www.eclipse.org/legal/epl-v10.html                                                    */
/************************************************************************************************/

/********************************************************************************/
/* This file is used to generate a rule checker for EUM.INST.NoUnderscoreKind.  */
/* Detect identifier_kind patterns (e.g., integer_8) — use kind= notation.      */
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

%class EUMINSTNoUnderscoreKind
%extends AbstractChecker
%public
%column
%line
%ignorecase

%function run
%yylexthrow JFlexException
%type List<CheckResult>

%state COMMENT, NAMING, NEW_LINE, LINE

COMMENT_WORD    = \!         | c          | C     | \*
FREE_COMMENT    = \!
FUNC            = FUNCTION   | function
PROC            = PROCEDURE  | procedure
SUB             = SUBROUTINE | subroutine
PROG            = PROGRAM    | program
MOD             = MODULE     | module
TYPE            = {FUNC} | {PROC} | {SUB} | {PROG} | {MOD}
VAR             = [a-zA-Z][a-zA-Z0-9\_]*
STRING          = \'[^\']*\' | \"[^\"]*\"
UNDERSCORE_KIND = [a-zA-Z][a-zA-Z0-9]*_[0-9]+

%{
    private static final Logger LOGGER = Logger.getLogger(EUMINSTNoUnderscoreKind.class.getName());

    String location = "MAIN PROGRAM";
    String parsedFileName;

    public EUMINSTNoUnderscoreKind() {}

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
/* YYINITIAL STATE      */
/************************/
<YYINITIAL>     {COMMENT_WORD}  {yybegin(COMMENT);}
<YYINITIAL>     {STRING}        {}
<YYINITIAL>     {UNDERSCORE_KIND} {
                    setError(location, "Avoid using underscore kind notation (e.g., '" + yytext() + "'). Use 'kind=' instead.", yyline+1);
                    yybegin(LINE);
                }
<YYINITIAL>     {TYPE}          {location = yytext(); yybegin(NAMING);}
<YYINITIAL>     \n              {yybegin(NEW_LINE);}
<YYINITIAL>     .               {yybegin(LINE);}

/************************/
/* NEW_LINE STATE       */
/************************/
<NEW_LINE>      {COMMENT_WORD}  {yybegin(COMMENT);}
<NEW_LINE>      {STRING}        {}
<NEW_LINE>      {UNDERSCORE_KIND} {
                    setError(location, "Avoid using underscore kind notation (e.g., '" + yytext() + "'). Use 'kind=' instead.", yyline+1);
                    yybegin(LINE);
                }
<NEW_LINE>      {TYPE}          {location = yytext(); yybegin(NAMING);}
<NEW_LINE>      [ \t]+          {}
<NEW_LINE>      \n              {yybegin(NEW_LINE);}
<NEW_LINE>      .               {yybegin(LINE);}

/************************/
/* LINE STATE           */
/************************/
<LINE>          {COMMENT_WORD}  {yybegin(COMMENT);}
<LINE>          {STRING}        {}
<LINE>          {UNDERSCORE_KIND} {
                    setError(location, "Avoid using underscore kind notation (e.g., '" + yytext() + "'). Use 'kind=' instead.", yyline+1);
                }
<LINE>          {TYPE}          {location = yytext(); yybegin(NAMING);}
<LINE>          \n              {yybegin(NEW_LINE);}
<LINE>          .               {}

/************************/
/* ERROR STATE          */
/************************/
                [^]             {
                    final String errorMessage = "Analysis failure : Your file could not be analyzed. Please verify that it was encoded in an UNIX format.";
                    throw new JFlexException(this.getClass().getName(), parsedFileName, errorMessage, yytext(), yyline, yycolumn);
                }
