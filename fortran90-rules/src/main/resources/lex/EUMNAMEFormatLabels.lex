/************************************************************************************************/
/* i-Code CNES is a static code analyzer.                                                       */
/* This software is a free software, under the terms of the Eclipse Public License version 1.0. */
/* http://www.eclipse.org/legal/epl-v10.html                                                    */
/************************************************************************************************/

/********************************************************************************/
/* This file is used to generate a rule checker for EUM.NAME.FormatLabels.      */
/* FORMAT statement labels shall start at 1000 and increase by 10.              */
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

%class EUMNAMEFormatLabels
%extends AbstractChecker
%public
%column
%line
%ignorecase

%function run
%yylexthrow JFlexException
%type List<CheckResult>

%state COMMENT, NAMING, NEW_LINE, LINE

COMMENT_WORD    = \!
FUNC            = FUNCTION   | function
PROC            = PROCEDURE  | procedure
SUB             = SUBROUTINE | subroutine
PROG            = PROGRAM    | program
MOD             = MODULE     | module
TYPE            = {FUNC} | {PROC} | {SUB} | {PROG} | {MOD}
VAR             = [a-zA-Z][a-zA-Z0-9\_]*
STRING          = \'[^\']*\' | \"[^\"]*\"
FORMAT_KW       = FORMAT | format
LABEL           = [0-9]+
LABELED_FORMAT  = {LABEL}[\ \t]+{FORMAT_KW}

%{
    String location = "MAIN PROGRAM";
    private String parsedFileName;
    ArrayList<Integer> formatLabels = new ArrayList<Integer>();
    ArrayList<Integer> labelLines = new ArrayList<Integer>();

    public EUMNAMEFormatLabels() {}

    @Override
    public void setInputFile(final File file) throws FileNotFoundException {
        super.setInputFile(file);
        this.parsedFileName = file.toString();
        this.zzReader = new FileReader(new File(file.getAbsolutePath()));
    }

    private void addFormatLabel(String text) {
        String[] parts = text.trim().split("[\\ \\t]+");
        if(parts.length >= 2) {
            try {
                int label = Integer.parseInt(parts[0]);
                formatLabels.add(label);
                labelLines.add(yyline+1);
            } catch(NumberFormatException e) {
                /* ignore */
            }
        }
    }

    private void checkLabels() {
        if(formatLabels.isEmpty()) return;
        int expected = 1000;
        for(int i = 0; i < formatLabels.size(); i++) {
            int label = formatLabels.get(i);
            if(label != expected) {
                setError(location, "FORMAT label " + label + " does not follow the convention: expected " + expected + " (labels should start at 1000 and increase by 10).", labelLines.get(i));
            }
            expected += 10;
        }
    }
%}

%eofval{
    checkLabels();
    return getCheckResults();
%eofval}
%eofclose

%%

                {COMMENT_WORD}  {yybegin(COMMENT);}

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
<YYINITIAL>     {LABELED_FORMAT} {addFormatLabel(yytext()); yybegin(LINE);}
<YYINITIAL>     {TYPE}          {location = yytext(); yybegin(NAMING);}
<YYINITIAL>     \n              {yybegin(NEW_LINE);}
<YYINITIAL>     .               {yybegin(LINE);}

/************************/
/* NEW_LINE STATE       */
/************************/
<NEW_LINE>      {COMMENT_WORD}  {yybegin(COMMENT);}
<NEW_LINE>      {STRING}        {}
<NEW_LINE>      {LABELED_FORMAT} {addFormatLabel(yytext()); yybegin(LINE);}
<NEW_LINE>      {TYPE}          {location = yytext(); yybegin(NAMING);}
<NEW_LINE>      \n              {yybegin(NEW_LINE);}
<NEW_LINE>      .               {yybegin(LINE);}

/************************/
/* LINE STATE           */
/************************/
<LINE>          {COMMENT_WORD}  {yybegin(COMMENT);}
<LINE>          {STRING}        {}
<LINE>          {LABELED_FORMAT} {addFormatLabel(yytext());}
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
