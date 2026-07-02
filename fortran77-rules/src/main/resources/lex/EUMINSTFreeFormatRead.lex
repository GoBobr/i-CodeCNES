/************************************************************************************************/
/* i-Code CNES is a static code analyzer.                                                       */
/* This software is a free software, under the terms of the Eclipse Public License version 1.0. */
/* http://www.eclipse.org/legal/epl-v10.html                                                    */
/************************************************************************************************/

/********************************************************************************/
/* This file is used to generate a rule checker for EUM.INST.FreeFormatRead.    */
/* READ statements shall use free format (*) for data input, not explicit       */
/* format labels.                                                               */
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

%class EUMINSTFreeFormatRead
%extends AbstractChecker
%public
%column
%line
%ignorecase

%function run
%yylexthrow JFlexException
%type List<CheckResult>

%state COMMENT, NAMING, NEW_LINE, LINE, READ_STATE

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
FORMAT_NUM   = [0-9]+

%{
    private static final Logger LOGGER = Logger.getLogger(EUMINSTFreeFormatRead.class.getName());

    String location = "MAIN PROGRAM";
    String parsedFileName;
    int par = 0;
    int commaCount = 0;
    boolean checkFormat = false;

    public EUMINSTFreeFormatRead() {}

    @Override
    public void setInputFile(final File file) throws FileNotFoundException {
        super.setInputFile(file);
        this.parsedFileName = file.toString();
        this.zzReader = new FileReader(new File(file.getAbsolutePath()));
    }

    private void handleReadKeyword(String text) {
        if(text.equalsIgnoreCase("read")) {
            par = 0;
            commaCount = 0;
            checkFormat = false;
            yybegin(READ_STATE);
        }
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
<YYINITIAL>     {FREE_COMMENT}  {yybegin(COMMENT);}
<YYINITIAL>     {STRING}        {}
<YYINITIAL>     {TYPE}          {location = yytext(); yybegin(NAMING);}
<YYINITIAL>     {VAR}           {handleReadKeyword(yytext());}
<YYINITIAL>     \n              {yybegin(NEW_LINE);}
<YYINITIAL>     .               {yybegin(LINE);}

/************************/
/* NEW_LINE STATE       */
/************************/
<NEW_LINE>      {FREE_COMMENT}  {yybegin(COMMENT);}
<NEW_LINE>      {STRING}        {}
<NEW_LINE>      {TYPE}          {location = yytext(); yybegin(NAMING);}
<NEW_LINE>      {VAR}           {handleReadKeyword(yytext());}
<NEW_LINE>      \n              {yybegin(NEW_LINE);}
<NEW_LINE>      .               {yybegin(LINE);}

/************************/
/* LINE STATE           */
/************************/
<LINE>          {FREE_COMMENT}  {yybegin(COMMENT);}
<LINE>          {STRING}        {}
<LINE>          {TYPE}          {location = yytext(); yybegin(NAMING);}
<LINE>          {VAR}           {handleReadKeyword(yytext());}
<LINE>          \n              {yybegin(NEW_LINE);}
<LINE>          .               {}

/************************/
/* READ_STATE           */
/************************/
<READ_STATE>    \(              {par++;}
<READ_STATE>    \)              {par--; if(par==0) yybegin(LINE);}
<READ_STATE>    \,              {if(par==1) {commaCount++; if(commaCount==1) checkFormat=true;}}
<READ_STATE>    \*              {checkFormat=false;}
<READ_STATE>    {FORMAT_NUM}    {if(checkFormat) {setError(location, "READ statement shall use free format (*) for data input, not explicit format labels.", yyline+1);} checkFormat=false;}
<READ_STATE>    {VAR}           {checkFormat=false;}
<READ_STATE>    {STRING}        {}
<READ_STATE>    \![^\n]*        {}
<READ_STATE>    [ \t]+          {}
<READ_STATE>    \n              {if(par==0) yybegin(NEW_LINE);}
<READ_STATE>    .               {if(par==0) {yybegin(LINE);} else {checkFormat=false;}}

/************************/
/* ERROR STATE          */
/************************/
                [^]             {
                    final String errorMessage = "Analysis failure : Your file could not be analyzed. Please verify that it was encoded in an UNIX format.";
                    throw new JFlexException(this.getClass().getName(), parsedFileName, errorMessage, yytext(), yyline, yycolumn);
                }
