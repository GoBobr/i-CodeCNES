/************************************************************************************************/
/* i-Code CNES is a static code analyzer.                                                       */
/* This software is a free software, under the terms of the Eclipse Public License version 1.0. */
/* http://www.eclipse.org/legal/epl-v10.html                                                    */
/************************************************************************************************/

/********************************************************************************/
/* This file is used to generate a rule checker for EUM.DESIGN.ProgramStructure.*/
/* PROGRAM must have: PROGRAM statement, IMPLICIT NONE, END PROGRAM.            */
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

%class EUMDESIGNProgramStructure
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
IMPLICIT_KW  = IMPLICIT[\ \t]+NONE
END_PROG     = END[\ \t]+PROGRAM | end[\ \t]+program

%{
    String location = "MAIN PROGRAM";
    private String parsedFileName;
    private boolean hasProgram = false;
    private boolean hasImplicitNone = false;
    private boolean hasEndProgram = false;

    public EUMDESIGNProgramStructure() {}

    @Override
    public void setInputFile(final File file) throws FileNotFoundException {
        super.setInputFile(file);
        this.parsedFileName = file.toString();
        this.zzReader = new FileReader(new File(file.getAbsolutePath()));
    }
%}

%eofval{
    if(hasProgram) {
        if(!hasImplicitNone) {
            setError(location, "Program must have IMPLICIT NONE statement.", 1);
        }
        if(!hasEndProgram) {
            setError(location, "Program must end with END PROGRAM (not just END).", 1);
        }
    }
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
<YYINITIAL>     {IMPLICIT_KW}   {hasImplicitNone = true; yybegin(LINE);}
<YYINITIAL>     {END_PROG}      {hasEndProgram = true; yybegin(LINE);}
<YYINITIAL>     {PROG}          {hasProgram = true; location = yytext(); yybegin(NAMING);}
<YYINITIAL>     {TYPE}          {location = yytext(); yybegin(NAMING);}
<YYINITIAL>     \n              {yybegin(NEW_LINE);}
<YYINITIAL>     .               {yybegin(LINE);}

/************************/
/* NEW_LINE STATE       */
/************************/
<NEW_LINE>      {COMMENT_WORD}  {yybegin(COMMENT);}
<NEW_LINE>      {STRING}        {}
<NEW_LINE>      {IMPLICIT_KW}   {hasImplicitNone = true; yybegin(LINE);}
<NEW_LINE>      {END_PROG}      {hasEndProgram = true; yybegin(LINE);}
<NEW_LINE>      {PROG}          {hasProgram = true; location = yytext(); yybegin(NAMING);}
<NEW_LINE>      {TYPE}          {location = yytext(); yybegin(NAMING);}
<NEW_LINE>      \n              {yybegin(NEW_LINE);}
<NEW_LINE>      .               {yybegin(LINE);}

/************************/
/* LINE STATE           */
/************************/
<LINE>          {COMMENT_WORD}  {yybegin(COMMENT);}
<LINE>          {STRING}        {}
<LINE>          {IMPLICIT_KW}   {hasImplicitNone = true;}
<LINE>          {END_PROG}      {hasEndProgram = true;}
<LINE>          {PROG}          {hasProgram = true; location = yytext(); yybegin(NAMING);}
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
