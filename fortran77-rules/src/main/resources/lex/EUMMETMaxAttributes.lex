/************************************************************************************************/
/* i-Code CNES is a static code analyzer.                                                       */
/* This software is a free software, under the terms of the Eclipse Public License version 1.0. */
/* http://www.eclipse.org/legal/epl-v10.html                                                    */
/************************************************************************************************/

/********************************************************************************/
/* This file is used to generate a rule checker for EUM.MET.MaxAttributes.      */
/* Maximum 10 attributes per abstract type.                                     */
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

%class EUMMETMaxAttributes
%extends AbstractChecker
%public
%column
%line
%ignorecase

%function run
%yylexthrow JFlexException
%type List<CheckResult>

%state COMMENT, NAMING, NEW_LINE, LINE, TYPE_DEF

COMMENT_WORD = \!         | c          | C     | \*
FREE_COMMENT = \!
FUNC         = FUNCTION   | function
PROC         = PROCEDURE  | procedure
SUB          = SUBROUTINE | subroutine
PROG         = PROGRAM    | program
MOD          = MODULE     | module
UNIT         = {FUNC} | {PROC} | {SUB} | {PROG} | {MOD}
VAR          = [a-zA-Z][a-zA-Z0-9\_]*
STRING       = \'[^\']*\' | \"[^\"]*\"
TYPE_KW      = TYPE | type
END_TYPE     = END[\ ]*TYPE | end[\ ]*type
DECL_KW      = INTEGER | integer | REAL | real | DOUBLE | double | COMPLEX | complex |
               CHARACTER | character | LOGICAL | logical

%{
    private static final Logger LOGGER = Logger.getLogger(EUMMETMaxAttributes.class.getName());

    String location = "MAIN PROGRAM";
    String parsedFileName;
    int attrCount = 0;
    int errorLine = 0;
    boolean inType = false;

    public EUMMETMaxAttributes() {}

    @Override
    public void setInputFile(final File file) throws FileNotFoundException {
        super.setInputFile(file);
        this.parsedFileName = file.toString();
        this.zzReader = new FileReader(new File(file.getAbsolutePath()));
    }

    private void checkAttributes() {
        if (inType && attrCount > 10) {
            setError(location, "This type contains too many attributes: " + attrCount + " (max 10).", errorLine);
        }
        attrCount = 0;
        inType = false;
    }
%}

%eofval{
    checkAttributes();
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
<YYINITIAL>     {UNIT}          {location = yytext(); yybegin(NAMING);}
<YYINITIAL>     {TYPE_KW}       {errorLine = yyline+1; inType = true; attrCount = 0; yybegin(TYPE_DEF);}
<YYINITIAL>     \n              {yybegin(NEW_LINE);}
<YYINITIAL>     .               {yybegin(LINE);}

/************************/
/* TYPE_DEF STATE       */
/************************/
<TYPE_DEF>      {COMMENT_WORD}  {yybegin(COMMENT);}
<TYPE_DEF>      {STRING}        {}
<TYPE_DEF>      {DECL_KW}       {attrCount++; yybegin(LINE);}
<TYPE_DEF>      {END_TYPE}      {checkAttributes(); yybegin(LINE);}
<TYPE_DEF>      \n              {yybegin(NEW_LINE);}
<TYPE_DEF>      .               {}

/************************/
/* NEW_LINE STATE       */
/************************/
<NEW_LINE>      {COMMENT_WORD}  {yybegin(COMMENT);}
<NEW_LINE>      {STRING}        {}
<NEW_LINE>      {UNIT}          {location = yytext(); yybegin(NAMING);}
<NEW_LINE>      {TYPE_KW}       {errorLine = yyline+1; inType = true; attrCount = 0; yybegin(TYPE_DEF);}
<NEW_LINE>      {DECL_KW}       {if(inType) attrCount++; yybegin(LINE);}
<NEW_LINE>      {END_TYPE}      {checkAttributes(); yybegin(LINE);}
<NEW_LINE>      \n              {yybegin(NEW_LINE);}
<NEW_LINE>      .               {yybegin(LINE);}

/************************/
/* LINE STATE           */
/************************/
<LINE>          {COMMENT_WORD}  {yybegin(COMMENT);}
<LINE>          {STRING}        {}
<LINE>          {UNIT}          {location = yytext(); yybegin(NAMING);}
<LINE>          {TYPE_KW}       {errorLine = yyline+1; inType = true; attrCount = 0; yybegin(TYPE_DEF);}
<LINE>          {DECL_KW}       {if(inType) attrCount++;}
<LINE>          {END_TYPE}      {checkAttributes();}
<LINE>          \n              {yybegin(NEW_LINE);}
<LINE>          .               {}

/************************/
/* ERROR STATE          */
/************************/
                [^]             {
                    final String errorMessage = "Analysis failure : Your file could not be analyzed. Please verify that it was encoded in an UNIX format.";
                    throw new JFlexException(this.getClass().getName(), parsedFileName, errorMessage, yytext(), yyline, yycolumn);
                }
