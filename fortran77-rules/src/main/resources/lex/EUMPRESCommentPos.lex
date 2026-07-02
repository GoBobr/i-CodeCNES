/************************************************************************************************/
/* i-Code CNES is a static code analyzer.                                                       */
/* This software is a free software, under the terms of the Eclipse Public License version 1.0. */
/* http://www.eclipse.org/legal/epl-v10.html                                                    */
/************************************************************************************************/

/********************************************************************************/
/* This file is used to generate a rule checker for EUM.PRES.CommentPos rule.   */
/* Comments must precede IF/DO/SELECT/CALL/READ/WRITE constructs.               */
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

%class EUMPRESCommentPos
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
IF_KW        = IF[\ \t]*\(
DO_KW        = DO[\ \t]+
SELECT_KW    = SELECT[\ \t]+
CALL_KW      = CALL[\ \t]+
READ_KW      = READ[\ \t]*[\(\*]
WRITE_KW     = WRITE[\ \t]*[\(\*]
BLOCK_START  = {IF_KW} | {DO_KW} | {SELECT_KW} | {CALL_KW} | {READ_KW} | {WRITE_KW}

%{
    private static final Logger LOGGER = Logger.getLogger(EUMPRESCommentPos.class.getName());
    String location = "MAIN PROGRAM";
    String parsedFileName;
    private boolean hadComment = false;

    public EUMPRESCommentPos() {}

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
<YYINITIAL>     {COMMENT_WORD}  {hadComment = true; yybegin(COMMENT);}
<YYINITIAL>     {TYPE}          {hadComment = false; location = yytext(); yybegin(NAMING);}
<YYINITIAL>     \n              {yybegin(NEW_LINE);}
<YYINITIAL>     .               {yybegin(LINE);}

/************************/
/* NEW_LINE STATE       */
/************************/
<NEW_LINE>      {COMMENT_WORD}  {hadComment = true; yybegin(COMMENT);}
<NEW_LINE>      {STRING}        {}
<NEW_LINE>      {TYPE}          {hadComment = false; location = yytext(); yybegin(NAMING);}
<NEW_LINE>      {BLOCK_START}   {
                    if(!hadComment) {
                        setError(location, "A comment must precede this construct (IF/DO/SELECT/CALL/READ/WRITE).", yyline+1);
                    }
                    yybegin(LINE);
                }
<NEW_LINE>      [ \t]+          {}
<NEW_LINE>      \n              {yybegin(NEW_LINE);}
<NEW_LINE>      .               {yybegin(LINE);}

/************************/
/* LINE STATE           */
/************************/
<LINE>          {COMMENT_WORD}  {hadComment = true; yybegin(COMMENT);}
<LINE>          {STRING}        {}
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
