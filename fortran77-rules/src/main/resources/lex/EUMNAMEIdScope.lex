/************************************************************************************************/
/* i-Code CNES is a static code analyzer.                                                       */
/* This software is a free software, under the terms of the Eclipse Public License version 1.0. */
/* http://www.eclipse.org/legal/epl-v10.html                                                    */
/************************************************************************************************/

/********************************************************************************/
/* This file is used to generate a rule checker for EUM.NAME.IdScope.           */
/* Meta-rule ensuring EUM.NAME.IdFormat (Hungarian notation) applies to all     */
/* identifier scopes: Modules, Functions/Subroutines, Variables, Types.         */
/* Variable names in declarations must follow Hungarian notation with type      */
/* prefix (c=character, i=integer, r=real, x=complex, l=logical, t=type,        */
/* a=array, p=pointer). Skip all-uppercase names (constants) and names          */
/* starting with underscore.                                                    */
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

%class EUMNAMEIdScope
%extends AbstractChecker
%public
%column
%line
%ignorecase

%function run
%yylexthrow JFlexException
%type List<CheckResult>

%state COMMENT, NAMING, NEW_LINE, LINE, DECL, DECL_VARS

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
DOUBLE_COLON = "::"

%{
    private static final Logger LOGGER = Logger.getLogger(EUMNAMEIdScope.class.getName());

    String location = "MAIN PROGRAM";
    String parsedFileName;
    int declLine = 0;

    public EUMNAMEIdScope() {}

    @Override
    public void setInputFile(final File file) throws FileNotFoundException {
        super.setInputFile(file);
        this.parsedFileName = file.toString();
        this.zzReader = new FileReader(new File(file.getAbsolutePath()));
    }

    private void checkIdentifier(String varname) {
        if(varname.startsWith("_")) return;
        if(varname.length() >= 2 && !varname.equals(varname.toUpperCase())) {
            char first = varname.charAt(0);
            if("cirxltapCIRXLTAP".indexOf(first) < 0) {
                setError(location, "Identifier '" + varname + "' must follow Hungarian notation with type prefix (c,i,r,x,l,t,a,p) in all scopes.", declLine);
            }
        }
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
/* DECL STATE           */
/************************/
<DECL>          {DOUBLE_COLON}  {yybegin(DECL_VARS);}
<DECL>          \n              {yybegin(NEW_LINE);}
<DECL>          \!              {yybegin(COMMENT);}
<DECL>          {STRING}        {}
<DECL>          .               {}

/************************/
/* DECL_VARS STATE      */
/************************/
<DECL_VARS>     {VAR}           {checkIdentifier(yytext());}
<DECL_VARS>     \n              {yybegin(NEW_LINE);}
<DECL_VARS>     \!              {yybegin(COMMENT);}
<DECL_VARS>     {STRING}        {}
<DECL_VARS>     .               {}

/************************/
/* YYINITIAL STATE      */
/************************/
<YYINITIAL>     {FREE_COMMENT}  {yybegin(COMMENT);}
<YYINITIAL>     {TYPE}          {location = yytext(); yybegin(NAMING);}
<YYINITIAL>     {DECL_KW}       {declLine = yyline+1; yybegin(DECL);}
<YYINITIAL>     \n              {yybegin(NEW_LINE);}
<YYINITIAL>     .               {yybegin(LINE);}

/************************/
/* NEW_LINE STATE       */
/************************/
<NEW_LINE>      {FREE_COMMENT}  {yybegin(COMMENT);}
<NEW_LINE>      {STRING}        {}
<NEW_LINE>      {TYPE}          {location = yytext(); yybegin(NAMING);}
<NEW_LINE>      {DECL_KW}       {declLine = yyline+1; yybegin(DECL);}
<NEW_LINE>      \n              {yybegin(NEW_LINE);}
<NEW_LINE>      .               {yybegin(LINE);}

/************************/
/* LINE STATE           */
/************************/
<LINE>          {FREE_COMMENT}  {yybegin(COMMENT);}
<LINE>          {STRING}        {}
<LINE>          {TYPE}          {location = yytext(); yybegin(NAMING);}
<LINE>          {DECL_KW}       {declLine = yyline+1; yybegin(DECL);}
<LINE>          \n              {yybegin(NEW_LINE);}
<LINE>          .               {}

/************************/
/* ERROR STATE          */
/************************/
                [^]             {
                    final String errorMessage = "Analysis failure : Your file could not be analyzed. Please verify that it was encoded in an UNIX format.";
                    throw new JFlexException(this.getClass().getName(), parsedFileName, errorMessage, yytext(), yyline, yycolumn);
                }
