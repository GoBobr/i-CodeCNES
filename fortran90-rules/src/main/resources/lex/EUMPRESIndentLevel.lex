/************************************************************************************************/
/* i-Code CNES is a static code analyzer.                                                       */
/* This software is a free software, under the terms of the Eclipse Public License version 1.0. */
/* http://www.eclipse.org/legal/epl-v10.html                                                    */
/************************************************************************************************/

/********************************************************************************/
/* This file is used to generate a rule checker for EUM.PRES.IndentLevel.       */
/* Each indentation level must be exactly 2 spaces.                             */
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

%class EUMPRESIndentLevel
%extends AbstractChecker
%public
%column
%line
%ignorecase

%function run
%yylexthrow JFlexException
%type List<CheckResult>

%state COMMENT, NAMING, NEW_LINE, LINE, LEADING

COMMENT_WORD = \!
FUNC         = FUNCTION   | function
PROC         = PROCEDURE  | procedure
SUB          = SUBROUTINE | subroutine
PROG         = PROGRAM    | program
MOD          = MODULE     | module
TYPE         = {FUNC} | {PROC} | {SUB} | {PROG} | {MOD}
VAR          = [a-zA-Z][a-zA-Z0-9\_]*
STRING       = \'[^\']*\' | \"[^\"]*\"
END_KW       = (END|end)[\ \t]+(PROGRAM|program|MODULE|module|SUBROUTINE|subroutine|FUNCTION|function|PROCEDURE|procedure)

%{
    String location = "MAIN PROGRAM";
    private String parsedFileName;
    int depth = 0;
    int leadingSpaces = 0;

    public EUMPRESIndentLevel() {}

    @Override
    public void setInputFile(final File file) throws FileNotFoundException {
        super.setInputFile(file);
        this.parsedFileName = file.toString();
        this.zzReader = new FileReader(new File(file.getAbsolutePath()));
    }

    private void checkIndent() {
        int expected = depth * 2;
        if(leadingSpaces > expected) {
            setError(location, "Indentation level must be " + expected + " spaces (found " + leadingSpaces + ").", yyline+1);
        }
        leadingSpaces = 0;
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
<NAMING>        {VAR}           {location = location + " " + yytext(); depth++; yybegin(COMMENT);}
<NAMING>        \n              {yybegin(NEW_LINE);}
<NAMING>        .               {}

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
/* Count leading spaces, then check indent on first content */
<NEW_LINE>      [\ \t]*\n       {yybegin(NEW_LINE);}
<NEW_LINE>      [\ \t]+         {leadingSpaces = yycolumn + yylength(); yybegin(LEADING);}
<NEW_LINE>      {COMMENT_WORD}  {yybegin(COMMENT);}
<NEW_LINE>      {END_KW}        {checkIndent(); depth--; yybegin(LINE);}
<NEW_LINE>      {STRING}        {checkIndent(); yybegin(LINE);}
<NEW_LINE>      {TYPE}          {checkIndent(); location = yytext(); yybegin(NAMING);}
<NEW_LINE>      \n              {yybegin(NEW_LINE);}
<NEW_LINE>      .               {checkIndent(); yybegin(LINE);}

/************************/
/* LEADING STATE        */
/************************/
/* After leading spaces, check indent on first content character */
<LEADING>       {COMMENT_WORD}  {yybegin(COMMENT);}
<LEADING>       {END_KW}        {checkIndent(); depth--; yybegin(LINE);}
<LEADING>       {STRING}        {checkIndent(); yybegin(LINE);}
<LEADING>       {TYPE}          {checkIndent(); location = yytext(); yybegin(NAMING);}
<LEADING>       \n              {leadingSpaces = 0; yybegin(NEW_LINE);}
<LEADING>       .               {checkIndent(); yybegin(LINE);}

/************************/
/* LINE STATE           */
/************************/
<LINE>          {COMMENT_WORD}  {yybegin(COMMENT);}
<LINE>          {END_KW}        {depth--;}
<LINE>          {STRING}        {}
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
