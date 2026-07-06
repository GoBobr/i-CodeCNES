/************************************************************************************************/
/* i-Code CNES is a static code analyzer.                                                       */
/* This software is a free software, under the terms of the Eclipse Public License version 1.0. */
/* http://www.eclipse.org/legal/epl-v10.html                                                    */
/************************************************************************************************/

/********************************************************************************/
/* This file is used to generate a rule checker for EUM.INST.Redundant.         */
/* Composite check for redundant features: CHARACTER*(*) notation,             */
/* and statement functions. (D exponent removed — it is standard Fortran.)     */
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

%class EUMINSTRedundant
%extends AbstractChecker
%public
%column
%line
%ignorecase

%function run
%yylexthrow JFlexException
%type List<CheckResult>

%state COMMENT, NAMING, NEW_LINE, LINE

COMMENT_WORD = \!
FUNC         = FUNCTION   | function
PROC         = PROCEDURE  | procedure
SUB          = SUBROUTINE | subroutine
PROG         = PROGRAM    | program
MOD          = MODULE     | module
TYPE         = {FUNC} | {PROC} | {SUB} | {PROG} | {MOD}
VAR          = [a-zA-Z][a-zA-Z0-9\_]*
STRING       = \'[^\']*\' | \"[^\"]*\"
CHAR_STAR    = CHARACTER[\ \t]*\*[\ \t]*\(\*\) | character[\ \t]*\*[\ \t]*\(\*\)
/* Derived-type component access: var%component or var(args)%component etc. */
/* Must be matched BEFORE STMT_FUNC so var%component(args) = expr is not */
/* misidentified as a statement function. */
STRUCT       = {VAR}(\([^)]*\))?(\%{VAR}(\([^)]*\))?)+
/* Statement function: name(args) = expr — simple name with argument list and = */
STMT_FUNC    = {VAR}\([\ \t]*{VAR}[\ \t]*([,\ \t]*{VAR}[\ \t]*)*\)[\ \t]*=

%{
    String location = "MAIN PROGRAM";
    private String parsedFileName;

    public EUMINSTRedundant() {}

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

                {COMMENT_WORD}  {yybegin(COMMENT);}

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
<YYINITIAL>     {CHAR_STAR}     {setError(location, "CHARACTER*(*) notation is obsolete. Use CHARACTER(*) instead.", yyline+1); yybegin(LINE);}
<YYINITIAL>     {STRUCT}        {yybegin(LINE);}
<YYINITIAL>     {STMT_FUNC}     {setError(location, "Statement functions are obsolete. Use internal functions instead.", yyline+1); yybegin(LINE);}
<YYINITIAL>     {TYPE}          {location = yytext(); yybegin(NAMING);}
<YYINITIAL>     {VAR}           {yybegin(LINE);}
<YYINITIAL>     \n              {yybegin(NEW_LINE);}
<YYINITIAL>     .               {yybegin(LINE);}

/************************/
/* NEW_LINE STATE       */
/************************/
<NEW_LINE>      {COMMENT_WORD}  {yybegin(COMMENT);}
<NEW_LINE>      {STRING}        {}
<NEW_LINE>      {CHAR_STAR}     {setError(location, "CHARACTER*(*) notation is obsolete. Use CHARACTER(*) instead.", yyline+1); yybegin(LINE);}
<NEW_LINE>      {STRUCT}        {yybegin(LINE);}
<NEW_LINE>      {STMT_FUNC}     {setError(location, "Statement functions are obsolete. Use internal functions instead.", yyline+1); yybegin(LINE);}
<NEW_LINE>      {TYPE}          {location = yytext(); yybegin(NAMING);}
<NEW_LINE>      {VAR}           {yybegin(LINE);}
<NEW_LINE>      \n              {yybegin(NEW_LINE);}
<NEW_LINE>      .               {yybegin(LINE);}

/************************/
/* LINE STATE           */
/************************/
<LINE>          {COMMENT_WORD}  {yybegin(COMMENT);}
<LINE>          {STRING}        {}
<LINE>          {CHAR_STAR}     {setError(location, "CHARACTER*(*) notation is obsolete. Use CHARACTER(*) instead.", yyline+1);}
<LINE>          {STRUCT}        {}
<LINE>          {STMT_FUNC}     {setError(location, "Statement functions are obsolete. Use internal functions instead.", yyline+1);}
<LINE>          {TYPE}          {location = yytext(); yybegin(NAMING);}
<LINE>          {VAR}           {}
<LINE>          \n              {yybegin(NEW_LINE);}
<LINE>          .               {}

/************************/
/* ERROR STATE          */
/************************/
                [^]             {
                    final String errorMessage = "Analysis failure : Your file could not be analyzed. Please verify that it was encoded in an UNIX format.";
                    throw new JFlexException(this.getClass().getName(), parsedFileName, errorMessage, yytext(), yyline, yycolumn);
                }
