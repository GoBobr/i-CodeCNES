/************************************************************************************************/
/* i-Code CNES is a static code analyzer.                                                       */
/* This software is a free software, under the terms of the Eclipse Public License version 1.0. */
/* http://www.eclipse.org/legal/epl-v10.html                                                    */
/************************************************************************************************/

/********************************************************************************/
/* This file is used to generate a rule checker for                            */
/* EUM.DESIGN.SubroutineStructure.                                             */
/* Subroutine must have: header comment before definition,                     */
/* END SUBROUTINE/FUNCTION (in full form, not just END).                       */
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

%class EUMDESIGNSubroutineStructure
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
DECL_KW      = INTEGER | integer | REAL | real | DOUBLE[\ \t]*PRECISION | double[\ \t]*precision |
               COMPLEX | complex | CHARACTER | character | LOGICAL | logical
END_SUB      = END[\ \t]+SUBROUTINE | end[\ \t]+subroutine
END_FUNC     = END[\ \t]+FUNCTION | end[\ \t]+function
TYPED_FUNC   = {DECL_KW}[\ \t]+{FUNC}

%{
    private static final Logger LOGGER = Logger.getLogger(EUMDESIGNSubroutineStructure.class.getName());
    String location = "MAIN PROGRAM";
    String parsedFileName;
    private boolean hadComment = false;
    private boolean inSubroutine = false;
    private boolean hasEndSubroutine = false;

    public EUMDESIGNSubroutineStructure() {}

    @Override
    public void setInputFile(final File file) throws FileNotFoundException {
        super.setInputFile(file);
        this.parsedFileName = file.toString();
        this.zzReader = new FileReader(new File(file.getAbsolutePath()));
    }

    private void checkSubroutine() {
        if(!hadComment) {
            setError(location, "Subroutine must have a header comment.", yyline+1);
        }
        if(inSubroutine && !hasEndSubroutine) {
            setError(location, "Subroutine must end with END SUBROUTINE/FUNCTION (not just END).", yyline+1);
        }
    }
%}

%eofval{
    if(inSubroutine && !hasEndSubroutine) {
        setError(location, "Subroutine must end with END SUBROUTINE/FUNCTION (not just END).", yyline+1);
    }
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
<YYINITIAL>     {FREE_COMMENT}  {hadComment = true; yybegin(COMMENT);}
<YYINITIAL>     {END_SUB}       {hasEndSubroutine = true; inSubroutine = false; hadComment = false; yybegin(LINE);}
<YYINITIAL>     {END_FUNC}      {hasEndSubroutine = true; inSubroutine = false; hadComment = false; yybegin(LINE);}
<YYINITIAL>     {TYPED_FUNC}    {checkSubroutine(); hadComment = false; location = "function"; inSubroutine = true; hasEndSubroutine = false; yybegin(NAMING);}
<YYINITIAL>     {SUB}           {checkSubroutine(); hadComment = false; location = "subroutine"; inSubroutine = true; hasEndSubroutine = false; yybegin(NAMING);}
<YYINITIAL>     {FUNC}          {checkSubroutine(); hadComment = false; location = "function"; inSubroutine = true; hasEndSubroutine = false; yybegin(NAMING);}
<YYINITIAL>     {TYPE}          {hadComment = false; location = yytext(); yybegin(NAMING);}
<YYINITIAL>     \n              {yybegin(NEW_LINE);}
<YYINITIAL>     .               {yybegin(LINE);}

/************************/
/* NEW_LINE STATE       */
/************************/
<NEW_LINE>      {FREE_COMMENT}  {hadComment = true; yybegin(COMMENT);}
<NEW_LINE>      {STRING}        {}
<NEW_LINE>      {END_SUB}       {hasEndSubroutine = true; inSubroutine = false; hadComment = false; yybegin(LINE);}
<NEW_LINE>      {END_FUNC}      {hasEndSubroutine = true; inSubroutine = false; hadComment = false; yybegin(LINE);}
<NEW_LINE>      {TYPED_FUNC}    {checkSubroutine(); hadComment = false; location = "function"; inSubroutine = true; hasEndSubroutine = false; yybegin(NAMING);}
<NEW_LINE>      {SUB}           {checkSubroutine(); hadComment = false; location = "subroutine"; inSubroutine = true; hasEndSubroutine = false; yybegin(NAMING);}
<NEW_LINE>      {FUNC}          {checkSubroutine(); hadComment = false; location = "function"; inSubroutine = true; hasEndSubroutine = false; yybegin(NAMING);}
<NEW_LINE>      {TYPE}          {hadComment = false; location = yytext(); yybegin(NAMING);}
<NEW_LINE>      \n              {yybegin(NEW_LINE);}
<NEW_LINE>      .               {yybegin(LINE);}

/************************/
/* LINE STATE           */
/************************/
<LINE>          {FREE_COMMENT}  {hadComment = true; yybegin(COMMENT);}
<LINE>          {STRING}        {}
<LINE>          {END_SUB}       {hasEndSubroutine = true; inSubroutine = false; hadComment = false;}
<LINE>          {END_FUNC}      {hasEndSubroutine = true; inSubroutine = false; hadComment = false;}
<LINE>          {TYPED_FUNC}    {checkSubroutine(); hadComment = false; location = "function"; inSubroutine = true; hasEndSubroutine = false; yybegin(NAMING);}
<LINE>          {SUB}           {checkSubroutine(); hadComment = false; location = "subroutine"; inSubroutine = true; hasEndSubroutine = false; yybegin(NAMING);}
<LINE>          {FUNC}          {checkSubroutine(); hadComment = false; location = "function"; inSubroutine = true; hasEndSubroutine = false; yybegin(NAMING);}
<LINE>          {TYPE}          {hadComment = false; location = yytext(); yybegin(NAMING);}
<LINE>          \n              {hadComment = false; yybegin(NEW_LINE);}
<LINE>          .               {}

/************************/
/* ERROR STATE          */
/************************/
                [^]             {
                    final String errorMessage = "Analysis failure : Your file could not be analyzed. Please verify that it was encoded in an UNIX format.";
                    throw new JFlexException(this.getClass().getName(), parsedFileName, errorMessage, yytext(), yyline, yycolumn);
                }
