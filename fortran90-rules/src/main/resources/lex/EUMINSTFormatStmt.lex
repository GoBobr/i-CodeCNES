/************************************************************************************************/
/* i-Code CNES is a static code analyzer.                                                       */
/* This software is a free software, under the terms of the Eclipse Public License version 1.0. */
/* http://www.eclipse.org/legal/epl-v10.html                                                    */
/************************************************************************************************/

/********************************************************************************/
/* This file is used to generate a rule checker for EUM.INST.FormatStmt.        */
/* READ/WRITE shall use FORMAT statement labels, not inline format strings.     */
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

%class EUMINSTFormatStmt
%extends AbstractChecker
%public
%column
%line
%ignorecase

%function run
%yylexthrow JFlexException
%type List<CheckResult>

%state COMMENT, NAMING, NEW_LINE, LINE, IO_STATE, IO_PAREN

COMMENT_WORD = \!
FUNC         = FUNCTION   | function
PROC         = PROCEDURE  | procedure
SUB          = SUBROUTINE | subroutine
PROG         = PROGRAM    | program
MOD          = MODULE     | module
TYPE         = {FUNC} | {PROC} | {SUB} | {PROG} | {MOD}
VAR          = [a-zA-Z][a-zA-Z0-9\_]*
STRING       = \'[^\']*\' | \"[^\"]*\"

%{
    String location = "MAIN PROGRAM";
    private String parsedFileName;
    int par = 0;
    int commaCount = 0;
    boolean checkFormat = false;

    public EUMINSTFormatStmt() {}

    @Override
    public void setInputFile(final File file) throws FileNotFoundException {
        super.setInputFile(file);
        this.parsedFileName = file.toString();
        this.zzReader = new FileReader(new File(file.getAbsolutePath()));
    }

    private void handleIOKeyword(String text) {
        String lower = text.toLowerCase();
        if(lower.equals("read") || lower.equals("write")) {
            par = 0;
            commaCount = 0;
            checkFormat = false;
            yybegin(IO_STATE);
        }
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
/* YYINITIAL STATE      */
/************************/
<YYINITIAL>     {COMMENT_WORD}  {yybegin(COMMENT);}
<YYINITIAL>     {STRING}        {}
<YYINITIAL>     {TYPE}          {location = yytext(); yybegin(NAMING);}
<YYINITIAL>     {VAR}           {handleIOKeyword(yytext());}
<YYINITIAL>     \n              {yybegin(NEW_LINE);}
<YYINITIAL>     .               {yybegin(LINE);}

/************************/
/* NEW_LINE STATE       */
/************************/
<NEW_LINE>      {COMMENT_WORD}  {yybegin(COMMENT);}
<NEW_LINE>      {STRING}        {}
<NEW_LINE>      {TYPE}          {location = yytext(); yybegin(NAMING);}
<NEW_LINE>      {VAR}           {handleIOKeyword(yytext());}
<NEW_LINE>      \n              {yybegin(NEW_LINE);}
<NEW_LINE>      .               {yybegin(LINE);}

/************************/
/* LINE STATE           */
/************************/
<LINE>          {COMMENT_WORD}  {yybegin(COMMENT);}
<LINE>          {STRING}        {}
<LINE>          {TYPE}          {location = yytext(); yybegin(NAMING);}
<LINE>          {VAR}           {handleIOKeyword(yytext());}
<LINE>          \n              {yybegin(NEW_LINE);}
<LINE>          .               {}

/************************/
/* IO_STATE             */
/************************/
<IO_STATE>      \(              {par = 1; commaCount = 0; checkFormat = false; yybegin(IO_PAREN);}
<IO_STATE>      [ \t]+          {}
<IO_STATE>      \n              {yybegin(NEW_LINE);}
<IO_STATE>      .               {yybegin(LINE);}

/************************/
/* IO_PAREN STATE       */
/************************/
<IO_PAREN>      \(              {par++;}
<IO_PAREN>      \)              {par--; if(par==0) yybegin(LINE);}
<IO_PAREN>      \,              {if(par==1) {commaCount++; if(commaCount==1) checkFormat=true;}}
<IO_PAREN>      {STRING}        {if(checkFormat) setError(location, "READ/WRITE shall use FORMAT statement labels, not inline format strings.", yyline+1); checkFormat=false;}
<IO_PAREN>      \*              {checkFormat=false;}
<IO_PAREN>      [0-9]+          {checkFormat=false;}
<IO_PAREN>      \![^\n]*        {}
<IO_PAREN>      [ \t]+          {}
<IO_PAREN>      \n              {}
<IO_PAREN>      .               {checkFormat=false;}

/************************/
/* ERROR STATE          */
/************************/
                [^]             {
                    final String errorMessage = "Analysis failure : Your file could not be analyzed. Please verify that it was encoded in an UNIX format.";
                    throw new JFlexException(this.getClass().getName(), parsedFileName, errorMessage, yytext(), yyline, yycolumn);
                }
