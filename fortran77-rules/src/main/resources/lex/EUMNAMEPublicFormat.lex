/************************************************************************************************/
/* i-Code CNES is a static code analyzer.                                                       */
/* This software is a free software, under the terms of the Eclipse Public License version 1.0. */
/* http://www.eclipse.org/legal/epl-v10.html                                                    */
/************************************************************************************************/

/********************************************************************************/
/* This file is used to generate a rule checker for EUM.NAME.PublicFormat.      */
/* PUBLIC elements must be prefixed the same as the module name (first 4 chars  */
/* of module name, e.g., if module is XXyy_MyModule, public variables should    */
/* be XXyy_iMyVar).                                                             */
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

%class EUMNAMEPublicFormat
%extends AbstractChecker
%public
%column
%line
%ignorecase

%function run
%yylexthrow JFlexException
%type List<CheckResult>

%state COMMENT, NAMING, NEW_LINE, LINE, DECL

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
PUBLIC_KW    = PUBLIC | public
DOUBLE_COLON = "::"
DECL_KW      = INTEGER | integer | REAL | real | DOUBLE[\ \t]*PRECISION | double[\ \t]*precision |
               COMPLEX | complex | CHARACTER | character | LOGICAL | logical

%{
    private static final Logger LOGGER = Logger.getLogger(EUMNAMEPublicFormat.class.getName());

    String location = "MAIN PROGRAM";
    String parsedFileName;
    String moduleName = "";
    int errorLine = 0;

    public EUMNAMEPublicFormat() {}

    @Override
    public void setInputFile(final File file) throws FileNotFoundException {
        super.setInputFile(file);
        this.parsedFileName = file.toString();
        this.zzReader = new FileReader(new File(file.getAbsolutePath()));
    }

    private void checkPublicPrefix(String varname) {
        if(!moduleName.isEmpty()) {
            String prefix = moduleName.length() >= 4 ? moduleName.substring(0, 4) : moduleName;
            if(!varname.startsWith(prefix)) {
                setError(location, "Public element '" + varname + "' must be prefixed with module identifier '" + prefix + "'.", errorLine);
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
<NAMING>        {VAR}           {location = location + " " + yytext(); moduleName = yytext(); yybegin(COMMENT);}
<NAMING>        \n              {yybegin(NEW_LINE);}
<NAMING>        .               {}

/************************/
/* DECL STATE           */
/************************/
<DECL>          {DOUBLE_COLON}  {}
<DECL>          {VAR}           {checkPublicPrefix(yytext());}
<DECL>          \n              {yybegin(NEW_LINE);}
<DECL>          \!              {yybegin(COMMENT);}
<DECL>          {STRING}        {}
<DECL>          .               {}

/************************/
/* YYINITIAL STATE      */
/************************/
<YYINITIAL>     {COMMENT_WORD}  {yybegin(COMMENT);}
<YYINITIAL>     {MOD}           {location = yytext(); yybegin(NAMING);}
<YYINITIAL>     {TYPE}          {location = yytext(); yybegin(LINE);}
<YYINITIAL>     {DECL_KW}       {yybegin(LINE);}
<YYINITIAL>     {PUBLIC_KW}     {errorLine = yyline+1; yybegin(DECL);}
<YYINITIAL>     \n              {yybegin(NEW_LINE);}
<YYINITIAL>     .               {yybegin(LINE);}

/************************/
/* NEW_LINE STATE       */
/************************/
<NEW_LINE>      {COMMENT_WORD}  {yybegin(COMMENT);}
<NEW_LINE>      {STRING}        {}
<NEW_LINE>      {MOD}           {location = yytext(); yybegin(NAMING);}
<NEW_LINE>      {TYPE}          {location = yytext(); yybegin(LINE);}
<NEW_LINE>      {DECL_KW}       {yybegin(LINE);}
<NEW_LINE>      {PUBLIC_KW}     {errorLine = yyline+1; yybegin(DECL);}
<NEW_LINE>      \n              {yybegin(NEW_LINE);}
<NEW_LINE>      .               {yybegin(LINE);}

/************************/
/* LINE STATE           */
/************************/
<LINE>          {COMMENT_WORD}  {yybegin(COMMENT);}
<LINE>          {STRING}        {}
<LINE>          {MOD}           {location = yytext(); yybegin(NAMING);}
<LINE>          {TYPE}          {location = yytext();}
<LINE>          {DECL_KW}       {}
<LINE>          {PUBLIC_KW}     {errorLine = yyline+1; yybegin(DECL);}
<LINE>          \n              {yybegin(NEW_LINE);}
<LINE>          .               {}

/************************/
/* ERROR STATE          */
/************************/
                [^]             {
                    final String errorMessage = "Analysis failure : Your file could not be analyzed. Please verify that it was encoded in an UNIX format.";
                    throw new JFlexException(this.getClass().getName(), parsedFileName, errorMessage, yytext(), yyline, yycolumn);
                }
