/************************************************************************************************/
/* i-Code CNES is a static code analyzer.                                                       */
/* This software is a free software, under the terms of the Eclipse Public License version 1.0. */
/* http://www.eclipse.org/legal/epl-v10.html                                                    */
/************************************************************************************************/

/********************************************************************************/
/* This file is used to generate a rule checker for EUM.INST.OneVarPerLine.     */
/* Only one variable per declaration statement.                                 */
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

%class EUMINSTOneVarPerLine
%extends AbstractChecker
%public
%column
%line
%ignorecase

%function run
%yylexthrow JFlexException
%type List<CheckResult>

%state COMMENT, NAMING, NEW_LINE, LINE, DECL

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
DOUBLE_COLON = "::"

%{
    String location = "MAIN PROGRAM";
    private static final Logger LOGGER = Logger.getLogger(EUMINSTOneVarPerLine.class.getName());
    String parsedFileName;
    int varCount = 0;
    int declLine = 0;

    public EUMINSTOneVarPerLine() {}

    @Override
    public void setInputFile(final File file) throws FileNotFoundException {
        super.setInputFile(file);
        this.parsedFileName = file.toString();
        this.zzReader = new FileReader(new File(file.getAbsolutePath()));
    }

    private void checkVarCount() {
        if (varCount > 1) {
            setError(location, "Only one variable per declaration line is allowed: found " + varCount + " variables.", declLine);
        }
        varCount = 0;
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
/* DECL STATE           */
/************************/
/* After :: in a declaration, count variables separated by commas */
/* Note: use \! for inline comments, not {COMMENT_WORD}, because */
/* {COMMENT_WORD} includes c/C which conflicts with variable names */
<DECL>          {VAR}           {varCount++;}
<DECL>          \n              {checkVarCount(); yybegin(NEW_LINE);}
<DECL>          \!              {checkVarCount(); yybegin(COMMENT);}
<DECL>          {STRING}        {}
<DECL>          .               {}

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
<NEW_LINE>      {DECL_KW}       {declLine = yyline+1; varCount = 0; yybegin(LINE);}
<NEW_LINE>      \n              {yybegin(NEW_LINE);}
<NEW_LINE>      .               {yybegin(LINE);}

/************************/
/* LINE STATE           */
/************************/
<LINE>          {COMMENT_WORD}  {yybegin(COMMENT);}
<LINE>          {STRING}        {}
<LINE>          {TYPE}          {location = yytext(); yybegin(NAMING);}
<LINE>          {DECL_KW}       {declLine = yyline+1; varCount = 0;}
<LINE>          {DOUBLE_COLON}  {yybegin(DECL);}
<LINE>          \n              {yybegin(NEW_LINE);}
<LINE>          .               {}

/************************/
/* ERROR STATE          */
/************************/
                [^]             {
                    final String errorMessage = "Analysis failure : Your file could not be analyzed. Please verify that it was encoded in an UNIX format.";
                    throw new JFlexException(this.getClass().getName(), parsedFileName, errorMessage, yytext(), yyline, yycolumn);
                }
