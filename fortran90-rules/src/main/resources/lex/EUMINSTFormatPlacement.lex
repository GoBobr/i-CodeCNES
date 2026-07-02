/************************************************************************************************/
/* i-Code CNES is a static code analyzer.                                                       */
/* This software is a free software, under the terms of the Eclipse Public License version 1.0. */
/* http://www.eclipse.org/legal/epl-v10.html                                                    */
/************************************************************************************************/

/********************************************************************************/
/* This file is used to generate a rule checker for EUM.INST.FormatPlacement.   */
/* FORMAT statements shall appear at the end of a procedure scope, before       */
/* END SUBROUTINE/END FUNCTION, not interspersed with executable code.          */
/********************************************************************************/

package fr.cnes.icode.fortran90.rules;

import java.io.FileNotFoundException;
import java.io.FileReader;
import java.io.File;
import java.util.ArrayList;
import java.util.List;

import fr.cnes.icode.data.AbstractChecker;
import fr.cnes.icode.data.CheckResult;
import fr.cnes.icode.exception.JFlexException;

%%

%class EUMINSTFormatPlacement
%extends AbstractChecker
%public
%column
%line
%ignorecase

%function run
%yylexthrow JFlexException
%type List<CheckResult>

%state COMMENT, NAMING, NEW_LINE, LINE, FUNC_BODY

COMMENT_WORD = \!
FUNC         = FUNCTION   | function
PROC         = PROCEDURE  | procedure
SUB          = SUBROUTINE | subroutine
PROG         = PROGRAM    | program
MOD          = MODULE     | module
TYPE         = {FUNC} | {PROC} | {SUB} | {PROG} | {MOD}
PROC_KW      = {FUNC} | {SUB}
VAR          = [a-zA-Z][a-zA-Z0-9\_]*
STRING       = \'[^\']*\' | \"[^\"]*\"
FORMAT_KW    = FORMAT | format
END_FUNC     = END[\ \t]+FUNCTION | end[\ \t]+function | END[\ \t]+SUBROUTINE | end[\ \t]+subroutine
DECL_KW      = INTEGER | integer | REAL | real | DOUBLE[\ \t]*PRECISION | double[\ \t]*precision |
               COMPLEX | complex | CHARACTER | character | LOGICAL | logical
TYPED_FUNC   = {DECL_KW}[\ \t]+{FUNC}

%{
    String location = "MAIN PROGRAM";
    private String parsedFileName;
    boolean inFuncBody = false;
    boolean funcLineStart = false;
    int lastExecLine = 0;
    int funcStartLine = 0;
    ArrayList<Integer> formatLines = new ArrayList<Integer>();

    public EUMINSTFormatPlacement() {}

    @Override
    public void setInputFile(final File file) throws FileNotFoundException {
        super.setInputFile(file);
        this.parsedFileName = file.toString();
        this.zzReader = new FileReader(new File(file.getAbsolutePath()));
    }

    private void checkFormats() {
        for(int i = 0; i < formatLines.size(); i++) {
            int fmtLine = formatLines.get(i);
            if(lastExecLine > fmtLine) {
                setError(location, "FORMAT statement at line " + fmtLine + " is not at the end of the procedure. FORMAT statements should appear after all executable code, before END SUBROUTINE/END FUNCTION.", fmtLine);
            }
        }
        formatLines.clear();
        lastExecLine = 0;
    }
%}

%eofval{
    checkFormats();
    return getCheckResults();
%eofval}
%eofclose

%%

                {COMMENT_WORD}  {yybegin(COMMENT);}

/************************/
/* COMMENT STATE        */
/************************/
<COMMENT>       \n              {if(inFuncBody) {funcLineStart=true; yybegin(FUNC_BODY);} else yybegin(NEW_LINE);}
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
<YYINITIAL>     {TYPED_FUNC}    {location = yytext(); inFuncBody=true; funcStartLine=yyline+1; yybegin(NAMING);}
<YYINITIAL>     {PROC_KW}       {location = yytext(); inFuncBody=true; funcStartLine=yyline+1; yybegin(NAMING);}
<YYINITIAL>     {TYPE}          {location = yytext(); yybegin(NAMING);}
<YYINITIAL>     \n              {yybegin(NEW_LINE);}
<YYINITIAL>     .               {yybegin(LINE);}

/************************/
/* NEW_LINE STATE       */
/************************/
<NEW_LINE>      {COMMENT_WORD}  {yybegin(COMMENT);}
<NEW_LINE>      {STRING}        {}
<NEW_LINE>      {TYPED_FUNC}    {location = yytext(); inFuncBody=true; funcStartLine=yyline+1; yybegin(NAMING);}
<NEW_LINE>      {PROC_KW}       {location = yytext(); inFuncBody=true; funcStartLine=yyline+1; yybegin(NAMING);}
<NEW_LINE>      {TYPE}          {location = yytext(); yybegin(NAMING);}
<NEW_LINE>      \n              {yybegin(NEW_LINE);}
<NEW_LINE>      .               {yybegin(LINE);}

/************************/
/* LINE STATE           */
/************************/
<LINE>          {COMMENT_WORD}  {yybegin(COMMENT);}
<LINE>          {STRING}        {}
<LINE>          {TYPED_FUNC}    {location = yytext(); inFuncBody=true; funcStartLine=yyline+1; yybegin(NAMING);}
<LINE>          {PROC_KW}       {location = yytext(); inFuncBody=true; funcStartLine=yyline+1; yybegin(NAMING);}
<LINE>          {TYPE}          {location = yytext(); yybegin(NAMING);}
<LINE>          \n              {yybegin(NEW_LINE);}
<LINE>          .               {}

/************************/
/* FUNC_BODY STATE      */
/************************/
<FUNC_BODY>     {COMMENT_WORD}  {yybegin(COMMENT);}
<FUNC_BODY>     {STRING}        {}
<FUNC_BODY>     {END_FUNC}      {checkFormats(); inFuncBody=false; yybegin(LINE);}
<FUNC_BODY>     {FORMAT_KW}     {formatLines.add(yyline+1); funcLineStart=false;}
<FUNC_BODY>     {DECL_KW}       {funcLineStart=false;}
<FUNC_BODY>     {VAR}           {if(funcLineStart) lastExecLine=yyline+1; funcLineStart=false;}
<FUNC_BODY>     [0-9]+          {funcLineStart=false;}
<FUNC_BODY>     \n              {funcLineStart=true;}
<FUNC_BODY>     .               {if(funcLineStart) lastExecLine=yyline+1; funcLineStart=false;}

/************************/
/* ERROR STATE          */
/************************/
                [^]             {
                    final String errorMessage = "Analysis failure : Your file could not be analyzed. Please verify that it was encoded in an UNIX format.";
                    throw new JFlexException(this.getClass().getName(), parsedFileName, errorMessage, yytext(), yyline, yycolumn);
                }
