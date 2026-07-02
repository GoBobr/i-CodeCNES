/************************************************************************************************/
/* i-Code CNES is a static code analyzer.                                                       */
/* This software is a free software, under the terms of the Eclipse Public License version 1.0. */
/* http://www.eclipse.org/legal/epl-v10.html                                                    */
/************************************************************************************************/

/********************************************************************************/
/* This file is used to generate a rule checker for EUM.DESIGN.ModuleStructure. */
/* MODULE must have: IMPLICIT NONE, PRIVATE, CONTAINS, END MODULE.              */
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

%class EUMDESIGNModuleStructure
%extends AbstractChecker
%public
%column
%line
%ignorecase

%function run
%yylexthrow JFlexException
%type List<CheckResult>

%state COMMENT, NAMING, NEW_LINE, LINE

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
IMPLICIT_KW  = IMPLICIT[\ \t]+NONE
PRIVATE_KW   = PRIVATE  | private
CONTAINS_KW  = CONTAINS | contains
END_MOD      = END[\ \t]+MODULE | end[\ \t]+module

%{
    private static final Logger LOGGER = Logger.getLogger(EUMDESIGNModuleStructure.class.getName());
    String location = "MAIN PROGRAM";
    String parsedFileName;
    private boolean hasModule = false;
    private boolean hasImplicitNone = false;
    private boolean hasPrivate = false;
    private boolean hasContains = false;
    private boolean hasEndModule = false;

    public EUMDESIGNModuleStructure() {}

    @Override
    public void setInputFile(final File file) throws FileNotFoundException {
        super.setInputFile(file);
        this.parsedFileName = file.toString();
        this.zzReader = new FileReader(new File(file.getAbsolutePath()));
    }
%}

%eofval{
    if(hasModule) {
        if(!hasImplicitNone) {
            setError(location, "Module must have IMPLICIT NONE statement.", 1);
        }
        if(!hasPrivate) {
            setError(location, "Module must have PRIVATE statement.", 1);
        }
        if(!hasContains) {
            setError(location, "Module must have CONTAINS statement.", 1);
        }
        if(!hasEndModule) {
            setError(location, "Module must end with END MODULE.", 1);
        }
    }
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
<YYINITIAL>     {IMPLICIT_KW}   {hasImplicitNone = true; yybegin(LINE);}
<YYINITIAL>     {PRIVATE_KW}    {hasPrivate = true; yybegin(LINE);}
<YYINITIAL>     {CONTAINS_KW}   {hasContains = true; yybegin(LINE);}
<YYINITIAL>     {END_MOD}       {hasEndModule = true; yybegin(LINE);}
<YYINITIAL>     {MOD}           {hasModule = true; location = yytext(); yybegin(NAMING);}
<YYINITIAL>     {TYPE}          {location = yytext(); yybegin(NAMING);}
<YYINITIAL>     \n              {yybegin(NEW_LINE);}
<YYINITIAL>     .               {yybegin(LINE);}

/************************/
/* NEW_LINE STATE       */
/************************/
<NEW_LINE>      {COMMENT_WORD}  {yybegin(COMMENT);}
<NEW_LINE>      {STRING}        {}
<NEW_LINE>      {IMPLICIT_KW}   {hasImplicitNone = true; yybegin(LINE);}
<NEW_LINE>      {PRIVATE_KW}    {hasPrivate = true; yybegin(LINE);}
<NEW_LINE>      {CONTAINS_KW}   {hasContains = true; yybegin(LINE);}
<NEW_LINE>      {END_MOD}       {hasEndModule = true; yybegin(LINE);}
<NEW_LINE>      {MOD}           {hasModule = true; location = yytext(); yybegin(NAMING);}
<NEW_LINE>      {TYPE}          {location = yytext(); yybegin(NAMING);}
<NEW_LINE>      \n              {yybegin(NEW_LINE);}
<NEW_LINE>      .               {yybegin(LINE);}

/************************/
/* LINE STATE           */
/************************/
<LINE>          {COMMENT_WORD}  {yybegin(COMMENT);}
<LINE>          {STRING}        {}
<LINE>          {IMPLICIT_KW}   {hasImplicitNone = true;}
<LINE>          {PRIVATE_KW}    {hasPrivate = true;}
<LINE>          {CONTAINS_KW}   {hasContains = true;}
<LINE>          {END_MOD}       {hasEndModule = true;}
<LINE>          {MOD}           {hasModule = true; location = yytext(); yybegin(NAMING);}
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
