/************************************************************************************************/
/* i-Code CNES is a static code analyzer.                                                       */
/* This software is a free software, under the terms of the Eclipse Public License version 1.0. */
/* http://www.eclipse.org/legal/epl-v10.html                                                    */
/************************************************************************************************/

/********************************************************************************/
/* This file is used to generate a rule checker for EUM.PROJECT.HeaderContent.  */
/* Each function/subroutine header must contain: Name, Purpose, Argument I/O,  */
/* Returns.                                                                     */
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

%class EUMPROJECTHeaderContent
%extends AbstractChecker
%public
%column
%line
%ignorecase

%function run
%yylexthrow JFlexException
%type List<CheckResult>

%state COMMENT, NAMING, NEW_LINE, LINE, HEADER

COMMENT_WORD = \!
FUNC         = FUNCTION   | function
PROC         = PROCEDURE  | procedure
SUB          = SUBROUTINE | subroutine
PROG         = PROGRAM    | program
MOD          = MODULE     | module
TYPE         = {FUNC} | {PROC} | {SUB} | {PROG} | {MOD}
PROCEDURES   = {FUNC} | {SUB}
VAR          = [a-zA-Z][a-zA-Z0-9\_]*
STRING       = \'[^\']*\' | \"[^\"]*\"
SPACE        = [\ \r\t\f]
NAME_KW      = NAME | Name | NAME_OF | "Name of"
PURPOSE_KW   = PURPOSE | Purpose | DESCRIPTION | Description | BRIEF | Brief
ARGUMENT_KW  = ARGUMENT | Argument | ARGUMENTS | Arguments | INPUT | Input | OUTPUT | Output | "I/O" | "INPUTS" | "OUTPUTS"
RETURNS_KW   = RETURNS | Returns | RETURN | Return | RESULT | Result

%{
    String location = "MAIN PROGRAM";
    private String parsedFileName;
    boolean hasName = false;
    boolean hasPurpose = false;
    boolean hasArgument = false;
    boolean hasReturns = false;
    boolean inCommentBlock = false;
    boolean headerChecked = true;
    int errorLine = 0;

    public EUMPROJECTHeaderContent() {}

    @Override
    public void setInputFile(final File file) throws FileNotFoundException {
        super.setInputFile(file);
        this.parsedFileName = file.toString();
        this.zzReader = new FileReader(new File(file.getAbsolutePath()));
    }

    private void startHeader() {
        hasName = false;
        hasPurpose = false;
        hasArgument = false;
        hasReturns = false;
        inCommentBlock = true;
        headerChecked = false;
    }

    private void checkProcHeader() {
        if (!headerChecked) {
            if (!hasName || !hasPurpose || !hasArgument || !hasReturns) {
                String message = "Missing data in the procedure header: ";
                boolean first = true;
                if (!hasName) { message += "name"; first = false; }
                if (!hasPurpose) { message += (first ? "" : ", ") + "purpose"; first = false; }
                if (!hasArgument) { message += (first ? "" : ", ") + "argument I/O"; first = false; }
                if (!hasReturns) { message += (first ? "" : ", ") + "returns"; first = false; }
                message += ".";
                setError(location, message, errorLine);
            }
            headerChecked = true;
        }
        inCommentBlock = false;
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
/* HEADER STATE         */
/************************/
<HEADER>        {NAME_KW}       {hasName = true;}
<HEADER>        {PURPOSE_KW}    {hasPurpose = true;}
<HEADER>        {ARGUMENT_KW}   {hasArgument = true;}
<HEADER>        {RETURNS_KW}    {hasReturns = true;}
<HEADER>        \n              {yybegin(NEW_LINE);}
<HEADER>        .               {}

/************************/
/* NAMING STATE         */
/************************/
<NAMING>        {VAR}           {location = location + " " + yytext(); if(!headerChecked) checkProcHeader(); yybegin(COMMENT);}
<NAMING>        \n              {yybegin(NEW_LINE);}
<NAMING>        .               {}

/************************/
/* YYINITIAL STATE      */
/************************/
<YYINITIAL>     {COMMENT_WORD}  {startHeader(); yybegin(HEADER);}
<YYINITIAL>     {PROCEDURES}    {location = yytext(); errorLine = yyline+1; yybegin(NAMING);}
<YYINITIAL>     {TYPE}          {location = yytext(); yybegin(NAMING);}
<YYINITIAL>     \n              {yybegin(NEW_LINE);}
<YYINITIAL>     .               {if(!headerChecked) checkProcHeader(); yybegin(LINE);}

/************************/
/* NEW_LINE STATE       */
/************************/
<NEW_LINE>      {COMMENT_WORD}  {if(!headerChecked) yybegin(HEADER); else yybegin(COMMENT);}
<NEW_LINE>      {STRING}        {}
<NEW_LINE>      {PROCEDURES}    {location = yytext(); errorLine = yyline+1; yybegin(NAMING);}
<NEW_LINE>      {TYPE}          {location = yytext(); yybegin(NAMING);}
<NEW_LINE>      {SPACE}         {}
<NEW_LINE>      \n              {yybegin(NEW_LINE);}
<NEW_LINE>      .               {if(!headerChecked) checkProcHeader(); yybegin(LINE);}

/************************/
/* LINE STATE           */
/************************/
<LINE>          {COMMENT_WORD}  {if(!headerChecked) yybegin(HEADER); else yybegin(COMMENT);}
<LINE>          {STRING}        {}
<LINE>          {PROCEDURES}    {location = yytext(); errorLine = yyline+1; yybegin(NAMING);}
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
