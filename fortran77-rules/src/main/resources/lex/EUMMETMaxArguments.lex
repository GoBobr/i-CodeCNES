/************************************************************************************************/
/* i-Code CNES is a static code analyzer.                                                       */
/* This software is a free software, under the terms of the Eclipse Public License version 1.0. */
/* http://www.eclipse.org/legal/epl-v10.html                                                    */
/************************************************************************************************/

/********************************************************************************/
/* This file is used to generate a rule checker for EUM.MET.MaxArguments.       */
/* Maximum 10 arguments per procedure.                                          */
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

%class EUMMETMaxArguments
%extends AbstractChecker
%public
%column
%line
%ignorecase

%function run
%yylexthrow JFlexException
%type List<CheckResult>

%state COMMENT, NAMING, NEW_LINE, LINE, ARGS

COMMENT_WORD = \!         | c          | C     | \*
FREE_COMMENT = \!
FUNC         = FUNCTION   | function
PROC         = PROCEDURE  | procedure
SUB          = SUBROUTINE | subroutine
PROG         = PROGRAM    | program
MOD          = MODULE     | module
TYPE         = {FUNC} | {PROC} | {SUB} | {PROG} | {MOD}
PROCEDURES   = {FUNC} | {SUB}
VAR          = [a-zA-Z][a-zA-Z0-9\_]*
STRING       = \'[^\']*\' | \"[^\"]*\"

%{
    private static final Logger LOGGER = Logger.getLogger(EUMMETMaxArguments.class.getName());

    String location = "MAIN PROGRAM";
    String parsedFileName;
    int argCount = 0;
    int errorLine = 0;
    boolean hasArgs = false;

    public EUMMETMaxArguments() {}

    @Override
    public void setInputFile(final File file) throws FileNotFoundException {
        super.setInputFile(file);
        this.parsedFileName = file.toString();
        this.zzReader = new FileReader(new File(file.getAbsolutePath()));
    }

    private void checkArguments() {
        if (hasArgs && argCount > 10) {
            setError(location, "This procedure has too many arguments: " + argCount + " (max 10).", errorLine);
        }
        argCount = 0;
        hasArgs = false;
    }
%}

%eofval{
    checkArguments();
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
<NAMING>        {VAR}           {location = location + " " + yytext(); yybegin(ARGS);}
<NAMING>        \n              {yybegin(NEW_LINE);}
<NAMING>        .               {if(yytext().equals("(")) {yybegin(ARGS);} }

/************************/
/* YYINITIAL STATE      */
/************************/
<YYINITIAL>     {COMMENT_WORD}  {yybegin(COMMENT);}
<YYINITIAL>     {PROCEDURES}    {location = yytext(); errorLine = yyline+1; argCount = 0; hasArgs = false; yybegin(NAMING);}
<YYINITIAL>     {TYPE}          {location = yytext(); yybegin(NAMING);}
<YYINITIAL>     \n              {yybegin(NEW_LINE);}
<YYINITIAL>     .               {yybegin(LINE);}

/************************/
/* ARGS STATE           */
/************************/
<ARGS>          {VAR}           {argCount++; hasArgs = true;}
<ARGS>          {STRING}        {}
<ARGS>          \)              {checkArguments(); yybegin(LINE);}
<ARGS>          \n              {yybegin(NEW_LINE);}
<ARGS>          .               {}

/************************/
/* NEW_LINE STATE       */
/************************/
<NEW_LINE>      {COMMENT_WORD}  {yybegin(COMMENT);}
<NEW_LINE>      {STRING}        {}
<NEW_LINE>      {PROCEDURES}    {location = yytext(); errorLine = yyline+1; argCount = 0; hasArgs = false; yybegin(NAMING);}
<NEW_LINE>      {TYPE}          {location = yytext(); yybegin(NAMING);}
<NEW_LINE>      \n              {yybegin(NEW_LINE);}
<NEW_LINE>      .               {yybegin(LINE);}

/************************/
/* LINE STATE           */
/************************/
<LINE>          {COMMENT_WORD}  {yybegin(COMMENT);}
<LINE>          {STRING}        {}
<LINE>          {PROCEDURES}    {location = yytext(); errorLine = yyline+1; argCount = 0; hasArgs = false; yybegin(NAMING);}
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
