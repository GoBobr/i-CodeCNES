/************************************************************************************************/
/* i-Code CNES is a static code analyzer.                                                       */
/* This software is a free software, under the terms of the Eclipse Public License version 1.0. */
/* http://www.eclipse.org/legal/epl-v10.html                                                    */
/************************************************************************************************/

/********************************************************************************/
/* This file is used to generate a rule checker for EUM.FILE.HeaderContent.     */
/* File header must contain: Component Name, File, Author, Copyright,          */
/* Description.                                                                 */
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

%class EUMFILEHeaderContent
%extends AbstractChecker
%public
%column
%line
%ignorecase

%function run
%yylexthrow JFlexException
%type List<CheckResult>

%state COMMENT, NAMING, NEW_LINE, LINE, HEADER

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
SPACE        = [\ \r\t\f]
COMPONENT    = "COMPONENT NAME" | "Component Name" | "Component name" | "COMPONENT"
FILE_KW      = FILE | File
AUTHOR       = AUTHOR | Author
COPYRIGHT    = COPYRIGHT | Copyright
DESCRIPTION  = DESCRIPTION | Description
ENDHEADER    = use | USE | implicit | IMPLICIT

%{
    private static final Logger LOGGER = Logger.getLogger(EUMFILEHeaderContent.class.getName());

    String location = "MAIN PROGRAM";
    String parsedFileName;
    boolean hasComponent = false;
    boolean hasFile = false;
    boolean hasAuthor = false;
    boolean hasCopyright = false;
    boolean hasDescription = false;
    boolean startProgMod = true;
    boolean headerChecked = false;
    int line = 0;

    public EUMFILEHeaderContent() {}

    @Override
    public void setInputFile(final File file) throws FileNotFoundException {
        super.setInputFile(file);
        this.parsedFileName = file.toString();
        this.zzReader = new FileReader(new File(file.getAbsolutePath()));
    }

    private void checkFileHeader() {
        if (startProgMod && !headerChecked) {
            if (!hasComponent || !hasFile || !hasAuthor || !hasCopyright || !hasDescription) {
                String message = "Missing data in the file header: ";
                boolean first = true;
                if (!hasComponent) { message += "component name"; first = false; }
                if (!hasFile) { message += (first ? "" : ", ") + "file name"; first = false; }
                if (!hasAuthor) { message += (first ? "" : ", ") + "author"; first = false; }
                if (!hasCopyright) { message += (first ? "" : ", ") + "copyright"; first = false; }
                if (!hasDescription) { message += (first ? "" : ", ") + "description"; first = false; }
                message += ".";
                setError(location, message, line);
            }
            headerChecked = true;
        }
    }
%}

%eofval{
    checkFileHeader();
    return getCheckResults();
%eofval}
%eofclose

%%

                {FREE_COMMENT}  {if(!headerChecked) yybegin(HEADER); else yybegin(COMMENT);}

/************************/
/* COMMENT STATE        */
/************************/
<COMMENT>       \n              {yybegin(NEW_LINE);}
<COMMENT>       .               {}

/************************/
/* HEADER STATE         */
/************************/
<HEADER>        {COMPONENT}     {hasComponent = true;}
<HEADER>        {FILE_KW}       {hasFile = true;}
<HEADER>        {AUTHOR}        {hasAuthor = true;}
<HEADER>        {COPYRIGHT}     {hasCopyright = true;}
<HEADER>        {DESCRIPTION}   {hasDescription = true;}
<HEADER>        {ENDHEADER}     {checkFileHeader(); yybegin(LINE);}
<HEADER>        \n              {yybegin(NEW_LINE);}
<HEADER>        .               {}

/************************/
/* NAMING STATE         */
/************************/
<NAMING>        {VAR}           {location = location + " " + yytext(); if(!headerChecked) checkFileHeader(); yybegin(COMMENT);}
<NAMING>        \n              {yybegin(NEW_LINE);}
<NAMING>        .               {}

/************************/
/* YYINITIAL STATE      */
/************************/
<YYINITIAL>     {COMMENT_WORD}  {if(!headerChecked) yybegin(HEADER); else yybegin(COMMENT);}
<YYINITIAL>     {TYPE}          {location = yytext(); line = yyline+1; yybegin(NAMING);}
<YYINITIAL>     \n              {yybegin(NEW_LINE);}
<YYINITIAL>     .               {yybegin(LINE);}

/************************/
/* NEW_LINE STATE       */
/************************/
<NEW_LINE>      {COMMENT_WORD}  {if(!headerChecked) yybegin(HEADER); else yybegin(COMMENT);}
<NEW_LINE>      {STRING}        {}
<NEW_LINE>      {TYPE}          {location = yytext(); line = yyline+1; yybegin(NAMING);}
<NEW_LINE>      {ENDHEADER}     {if(startProgMod && !headerChecked) checkFileHeader(); yybegin(LINE);}
<NEW_LINE>      {SPACE}         {}
<NEW_LINE>      \n              {yybegin(NEW_LINE);}
<NEW_LINE>      .               {yybegin(LINE);}

/************************/
/* LINE STATE           */
/************************/
<LINE>          {COMMENT_WORD}  {if(!headerChecked) yybegin(HEADER); else yybegin(COMMENT);}
<LINE>          {STRING}        {}
<LINE>          {TYPE}          {location = yytext(); line = yyline+1; yybegin(NAMING);}
<LINE>          {ENDHEADER}     {if(startProgMod && !headerChecked) checkFileHeader();}
<LINE>          \n              {yybegin(NEW_LINE);}
<LINE>          .               {}

/************************/
/* ERROR STATE          */
/************************/
                [^]             {
                    final String errorMessage = "Analysis failure : Your file could not be analyzed. Please verify that it was encoded in an UNIX format.";
                    throw new JFlexException(this.getClass().getName(), parsedFileName, errorMessage, yytext(), yyline, yycolumn);
                }
