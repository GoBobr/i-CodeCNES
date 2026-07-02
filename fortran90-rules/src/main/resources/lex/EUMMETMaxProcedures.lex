/************************************************************************************************/
/* i-Code CNES is a static code analyzer.                                                       */
/* This software is a free software, under the terms of the Eclipse Public License version 1.0. */
/* http://www.eclipse.org/legal/epl-v10.html                                                    */
/************************************************************************************************/

/********************************************************************************/
/* This file is used to generate a rule checker for EUM.MET.MaxProcedures.      */
/* Maximum 20 procedures per module.                                            */
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

%class EUMMETMaxProcedures
%extends AbstractChecker
%public
%column
%line
%ignorecase

%function run
%yylexthrow JFlexException
%type List<CheckResult>

%state COMMENT, NAMING, NEW_LINE, LINE, MODULE

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
END_MOD      = END[\ ]*{MOD} | end[\ ]*{MOD}
END_PROC     = END[\ ]*{PROCEDURES} | end[\ ]*{PROCEDURES}

%{
    String location = "MAIN PROGRAM";
    private String parsedFileName;
    int procCount = 0;
    boolean inModule = false;
    int moduleLine = 0;

    public EUMMETMaxProcedures() {}

    @Override
    public void setInputFile(final File file) throws FileNotFoundException {
        super.setInputFile(file);
        this.parsedFileName = file.toString();
        this.zzReader = new FileReader(new File(file.getAbsolutePath()));
    }

    private void checkModuleProcedures() {
        if (inModule && procCount > 20) {
            setError(location, "This module contains too many procedures: " + procCount + " (max 20).", moduleLine);
        }
        procCount = 0;
        inModule = false;
    }
%}

%eofval{
    checkModuleProcedures();
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
<YYINITIAL>     {MOD}           {location = yytext(); moduleLine = yyline+1; inModule = true; yybegin(NAMING);}
<YYINITIAL>     {PROCEDURES}    {if(inModule) procCount++; yybegin(LINE);}
<YYINITIAL>     {TYPE}          {location = yytext(); yybegin(NAMING);}
<YYINITIAL>     \n              {yybegin(NEW_LINE);}
<YYINITIAL>     .               {yybegin(LINE);}

/************************/
/* NEW_LINE STATE       */
/************************/
<NEW_LINE>      {COMMENT_WORD}  {yybegin(COMMENT);}
<NEW_LINE>      {STRING}        {}
<NEW_LINE>      {MOD}           {location = yytext(); moduleLine = yyline+1; inModule = true; yybegin(NAMING);}
<NEW_LINE>      {END_PROC}      {yybegin(LINE);}
<NEW_LINE>      {PROCEDURES}    {if(inModule) procCount++; yybegin(LINE);}
<NEW_LINE>      {TYPE}          {location = yytext(); yybegin(NAMING);}
<NEW_LINE>      {END_MOD}       {checkModuleProcedures(); yybegin(LINE);}
<NEW_LINE>      \n              {yybegin(NEW_LINE);}
<NEW_LINE>      .               {yybegin(LINE);}

/************************/
/* LINE STATE           */
/************************/
<LINE>          {COMMENT_WORD}  {yybegin(COMMENT);}
<LINE>          {STRING}        {}
<LINE>          {MOD}           {location = yytext(); moduleLine = yyline+1; inModule = true; yybegin(NAMING);}
<LINE>          {END_PROC}      {yybegin(LINE);}
<LINE>          {PROCEDURES}    {if(inModule) procCount++; yybegin(LINE);}
<LINE>          {TYPE}          {location = yytext(); yybegin(NAMING);}
<LINE>          {END_MOD}       {checkModuleProcedures(); yybegin(LINE);}
<LINE>          \n              {yybegin(NEW_LINE);}
<LINE>          .               {}

/************************/
/* ERROR STATE          */
/************************/
                [^]             {
                    final String errorMessage = "Analysis failure : Your file could not be analyzed. Please verify that it was encoded in an UNIX format.";
                    throw new JFlexException(this.getClass().getName(), parsedFileName, errorMessage, yytext(), yyline, yycolumn);
                }
