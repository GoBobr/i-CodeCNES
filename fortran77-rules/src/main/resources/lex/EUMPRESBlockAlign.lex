/************************************************************************************************/
/* i-Code CNES is a static code analyzer.                                                       */
/* This software is a free software, under the terms of the Eclipse Public License version 1.0. */
/* http://www.eclipse.org/legal/epl-v10.html                                                    */
/************************************************************************************************/

/********************************************************************************/
/* This file is used to generate a rule checker for EUM.PRES.BlockAlign rule.   */
/* DO/END DO, IF/END IF, SELECT CASE/END SELECT must start at same column.      */
/********************************************************************************/

package fr.cnes.icode.fortran77.rules;

import java.io.FileNotFoundException;
import java.io.FileReader;
import java.io.File;
import java.util.List;
import java.util.Stack;
import java.util.logging.Logger;

import fr.cnes.icode.data.AbstractChecker;
import fr.cnes.icode.data.CheckResult;
import fr.cnes.icode.exception.JFlexException;

%%

%class EUMPRESBlockAlign
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
DO_KW        = DO[\ \t]+
IF_KW        = IF[\ \t]+.*THEN
SELECT_KW    = SELECT[\ \t]+CASE
END_DO       = END[\ \t]+DO
END_IF       = END[\ \t]+IF
END_SEL      = END[\ \t]+SELECT

%{
    private static final Logger LOGGER = Logger.getLogger(EUMPRESBlockAlign.class.getName());

    String location = "MAIN PROGRAM";
    String parsedFileName;
    Stack<Integer> colStack = new Stack<Integer>();

    public EUMPRESBlockAlign() {}

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
<YYINITIAL>     {STRING}        {}
<YYINITIAL>     {END_DO}        {
                    if(!colStack.isEmpty()) {
                        int col = colStack.pop();
                        if(col != yycolumn) {
                            setError(location, "END DO must be aligned with corresponding DO (column " + (col+1) + ").", yyline+1);
                        }
                    }
                    yybegin(LINE);
                }
<YYINITIAL>     {END_IF}        {
                    if(!colStack.isEmpty()) {
                        int col = colStack.pop();
                        if(col != yycolumn) {
                            setError(location, "END IF must be aligned with corresponding IF (column " + (col+1) + ").", yyline+1);
                        }
                    }
                    yybegin(LINE);
                }
<YYINITIAL>     {END_SEL}       {
                    if(!colStack.isEmpty()) {
                        int col = colStack.pop();
                        if(col != yycolumn) {
                            setError(location, "END SELECT must be aligned with corresponding SELECT CASE (column " + (col+1) + ").", yyline+1);
                        }
                    }
                    yybegin(LINE);
                }
<YYINITIAL>     {DO_KW}         {colStack.push(yycolumn); yybegin(LINE);}
<YYINITIAL>     {IF_KW}         {colStack.push(yycolumn); yybegin(LINE);}
<YYINITIAL>     {SELECT_KW}     {colStack.push(yycolumn); yybegin(LINE);}
<YYINITIAL>     {TYPE}          {location = yytext(); yybegin(NAMING);}
<YYINITIAL>     \n              {yybegin(NEW_LINE);}
<YYINITIAL>     .               {yybegin(LINE);}

/************************/
/* NEW_LINE STATE       */
/************************/
<NEW_LINE>      {COMMENT_WORD}  {yybegin(COMMENT);}
<NEW_LINE>      {STRING}        {}
<NEW_LINE>      {END_DO}        {
                    if(!colStack.isEmpty()) {
                        int col = colStack.pop();
                        if(col != yycolumn) {
                            setError(location, "END DO must be aligned with corresponding DO (column " + (col+1) + ").", yyline+1);
                        }
                    }
                    yybegin(LINE);
                }
<NEW_LINE>      {END_IF}        {
                    if(!colStack.isEmpty()) {
                        int col = colStack.pop();
                        if(col != yycolumn) {
                            setError(location, "END IF must be aligned with corresponding IF (column " + (col+1) + ").", yyline+1);
                        }
                    }
                    yybegin(LINE);
                }
<NEW_LINE>      {END_SEL}       {
                    if(!colStack.isEmpty()) {
                        int col = colStack.pop();
                        if(col != yycolumn) {
                            setError(location, "END SELECT must be aligned with corresponding SELECT CASE (column " + (col+1) + ").", yyline+1);
                        }
                    }
                    yybegin(LINE);
                }
<NEW_LINE>      {DO_KW}         {colStack.push(yycolumn); yybegin(LINE);}
<NEW_LINE>      {IF_KW}         {colStack.push(yycolumn); yybegin(LINE);}
<NEW_LINE>      {SELECT_KW}     {colStack.push(yycolumn); yybegin(LINE);}
<NEW_LINE>      {TYPE}          {location = yytext(); yybegin(NAMING);}
<NEW_LINE>      [ \t]+          {}
<NEW_LINE>      \n              {yybegin(NEW_LINE);}
<NEW_LINE>      .               {yybegin(LINE);}

/************************/
/* LINE STATE           */
/************************/
<LINE>          {COMMENT_WORD}  {yybegin(COMMENT);}
<LINE>          {STRING}        {}
<LINE>          {END_DO}        {
                    if(!colStack.isEmpty()) {
                        int col = colStack.pop();
                        if(col != yycolumn) {
                            setError(location, "END DO must be aligned with corresponding DO (column " + (col+1) + ").", yyline+1);
                        }
                    }
                }
<LINE>          {END_IF}        {
                    if(!colStack.isEmpty()) {
                        int col = colStack.pop();
                        if(col != yycolumn) {
                            setError(location, "END IF must be aligned with corresponding IF (column " + (col+1) + ").", yyline+1);
                        }
                    }
                }
<LINE>          {END_SEL}       {
                    if(!colStack.isEmpty()) {
                        int col = colStack.pop();
                        if(col != yycolumn) {
                            setError(location, "END SELECT must be aligned with corresponding SELECT CASE (column " + (col+1) + ").", yyline+1);
                        }
                    }
                }
<LINE>          {DO_KW}         {colStack.push(yycolumn);}
<LINE>          {IF_KW}         {colStack.push(yycolumn);}
<LINE>          {SELECT_KW}     {colStack.push(yycolumn);}
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
