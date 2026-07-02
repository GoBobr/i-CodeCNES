/************************************************************************************************/
/* i-Code CNES is a static code analyzer.                                                       */
/* This software is a free software, under the terms of the Eclipse Public License version 1.0. */
/* http://www.eclipse.org/legal/epl-v10.html                                                    */
/************************************************************************************************/

/********************************************************************************/
/* This file is used to generate a rule checker for EUM.BLOC.WhereElse.         */
/* WHERE constructs with ELSE WHERE must have a final empty ELSE WHERE.         */
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

%class EUMBLOCWhereElse
%extends AbstractChecker
%public
%column
%line
%ignorecase

%function run
%yylexthrow JFlexException
%type List<CheckResult>

%state COMMENT, NAMING, NEW_LINE, LINE, WHERE_COND, WHERE_AFTER, WHERE_BLOCK, ELSE_WHERE_BLOCK

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
WHERE_KW     = [^a-zA-Z0-9\_](WHERE)[\ \t]*\(
ELSE_WHERE   = (ELSE)[\ \t]+(WHERE) | (ELSEWHERE)
END_WHERE    = (END)[\ \t]+(WHERE) | (ENDWHERE)

%{
    private static final Logger LOGGER = Logger.getLogger(EUMBLOCWhereElse.class.getName());

    String location = "MAIN PROGRAM";
    String parsedFileName;
    int par = 0;
    boolean hasElseWhere = false;
    boolean elseWhereHasContent = false;

    public EUMBLOCWhereElse() {}

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
<YYINITIAL>     {WHERE_KW}      {par = 1; yybegin(WHERE_COND);}
<YYINITIAL>     \n              {yybegin(NEW_LINE);}
<YYINITIAL>     .               {yybegin(LINE);}

/************************/
/* NEW_LINE STATE       */
/************************/
<NEW_LINE>      {FREE_COMMENT}  {yybegin(COMMENT);}
<NEW_LINE>      {STRING}        {}
<NEW_LINE>      {TYPE}          {location = yytext(); yybegin(NAMING);}
<NEW_LINE>      {WHERE_KW}      {par = 1; yybegin(WHERE_COND);}
<NEW_LINE>      \n              {yybegin(NEW_LINE);}
<NEW_LINE>      .               {yybegin(LINE);}

/************************/
/* LINE STATE           */
/************************/
<LINE>          {FREE_COMMENT}  {yybegin(COMMENT);}
<LINE>          {STRING}        {}
<LINE>          {TYPE}          {location = yytext(); yybegin(NAMING);}
<LINE>          {WHERE_KW}      {par = 1; yybegin(WHERE_COND);}
<LINE>          \n              {yybegin(NEW_LINE);}
<LINE>          .               {}

/************************/
/* WHERE_COND STATE     */
/************************/
<WHERE_COND>    {STRING}        {}
<WHERE_COND>    \(              {par++;}
<WHERE_COND>    \)              {par--; if(par==0) yybegin(WHERE_AFTER);}
<WHERE_COND>    \n              {yybegin(NEW_LINE);}
<WHERE_COND>    .               {}

/************************/
/* WHERE_AFTER STATE    */
/************************/
<WHERE_AFTER>   [ \t]+          {}
<WHERE_AFTER>   \![^\n]*        {}
<WHERE_AFTER>   \n              {hasElseWhere = false; elseWhereHasContent = false; yybegin(WHERE_BLOCK);}
<WHERE_AFTER>   .               {yybegin(LINE);}

/************************/
/* WHERE_BLOCK STATE    */
/************************/
<WHERE_BLOCK>   {ELSE_WHERE}    {hasElseWhere = true; elseWhereHasContent = false; yybegin(ELSE_WHERE_BLOCK);}
<WHERE_BLOCK>   {END_WHERE}     {hasElseWhere = false; elseWhereHasContent = false; yybegin(LINE);}
<WHERE_BLOCK>   \![^\n]*        {}
<WHERE_BLOCK>   {STRING}        {}
<WHERE_BLOCK>   \n              {}
<WHERE_BLOCK>   .               {}

/************************/
/* ELSE_WHERE_BLOCK     */
/************************/
<ELSE_WHERE_BLOCK>  {ELSE_WHERE}    {hasElseWhere = true; elseWhereHasContent = false;}
<ELSE_WHERE_BLOCK>  {END_WHERE}     {
                        if(hasElseWhere && elseWhereHasContent) {
                            setError(location, "WHERE construct with ELSE WHERE must have a final empty ELSE WHERE.", yyline+1);
                        }
                        hasElseWhere = false;
                        elseWhereHasContent = false;
                        yybegin(LINE);
                    }
<ELSE_WHERE_BLOCK>  \![^\n]*        {}
<ELSE_WHERE_BLOCK>  {STRING}        {elseWhereHasContent = true;}
<ELSE_WHERE_BLOCK>  \n              {}
<ELSE_WHERE_BLOCK>  [ \t]+          {}
<ELSE_WHERE_BLOCK>  .               {elseWhereHasContent = true;}

/************************/
/* ERROR STATE          */
/************************/
                [^]             {
                    final String errorMessage = "Analysis failure : Your file could not be analyzed. Please verify that it was encoded in an UNIX format.";
                    throw new JFlexException(this.getClass().getName(), parsedFileName, errorMessage, yytext(), yyline, yycolumn);
                }
