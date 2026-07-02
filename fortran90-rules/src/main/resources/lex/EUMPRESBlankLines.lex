/************************************************************************************************/
/* i-Code CNES is a static code analyzer.                                                       */
/* This software is a free software, under the terms of the Eclipse Public License version 1.0. */
/* http://www.eclipse.org/legal/epl-v10.html                                                    */
/************************************************************************************************/

/********************************************************************************/
/* This file is used to generate a rule checker for EUM.PRES.BlankLines rule.   */
/* Maximum 2 consecutive blank lines are allowed.                               */
/********************************************************************************/

package fr.cnes.icode.fortran90.rules;

import java.io.FileNotFoundException;
import java.io.FileReader;
import java.io.File;
import java.util.List;

import fr.cnes.icode.data.AbstractChecker;
import fr.cnes.icode.data.CheckResult;
import fr.cnes.icode.exception.JFlexException;

%%

%class EUMPRESBlankLines
%extends AbstractChecker
%public
%column
%line
%ignorecase

%function run
%yylexthrow JFlexException
%type List<CheckResult>


%state COMMENT, NAMING, NEW_LINE, LINE, BLANK

COMMENT_WORD = \!         | c          | C     | \*
FREE_COMMENT = \!
FUNC         = FUNCTION   | function
PROC         = PROCEDURE  | procedure
SUB          = SUBROUTINE | subroutine
PROG         = PROGRAM    | program
MOD          = MODULE     | module
TYPE		 = {FUNC}     | {PROC}	   | {SUB} | {PROG} | {MOD}
VAR		     = [a-zA-Z][a-zA-Z0-9\_]*
STRING		 = \'[^\']*\' | \"[^\"]*\"

%{
	String location = "MAIN PROGRAM";
    private String parsedFileName;
    private int blankCount = 0;
    private boolean errorReported = false;

	public EUMPRESBlankLines(){
	}

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

				{FREE_COMMENT}	{yybegin(COMMENT);}

/************************/
/* COMMENT STATE	    */
/************************/
<COMMENT>   	\n             	{yybegin(NEW_LINE);}
<COMMENT>   	.              	{}

/************************/
/* NAMING STATE	        */
/************************/
<NAMING>		{VAR}			{location = location + " " + yytext(); yybegin(COMMENT);}
<NAMING>    	\n             	{yybegin(NEW_LINE);}
<NAMING>    	.              	{}

/************************/
/* YYINITIAL STATE	    */
/************************/
<YYINITIAL>  	{COMMENT_WORD} 	{yybegin(COMMENT);}
<YYINITIAL>		{TYPE}        	{location = yytext(); yybegin(NAMING);}
<YYINITIAL> 	\n             	{blankCount = 1; yybegin(BLANK);}
<YYINITIAL> 	.              	{yybegin(LINE);}

/************************/
/* NEW_LINE STATE	    */
/************************/
<NEW_LINE>  	{COMMENT_WORD} 	{yybegin(COMMENT);}
<NEW_LINE>		{STRING}		{}
<NEW_LINE>		{TYPE}        	{location = yytext(); yybegin(NAMING);}
<NEW_LINE>  	\n             	{blankCount = 1; yybegin(BLANK);}
<NEW_LINE>  	.              	{yybegin(LINE);}

/************************/
/* BLANK STATE          */
/************************/
<BLANK>			{COMMENT_WORD}	{errorReported = false; yybegin(COMMENT);}
<BLANK>			{TYPE}			{errorReported = false; location = yytext(); yybegin(NAMING);}
<BLANK>			.				{errorReported = false; yybegin(LINE);}
<BLANK>			\n				{
									blankCount++;
									if(blankCount > 2 && !errorReported) {
										setError(location,"More than 2 consecutive blank lines are not allowed.", yyline+1);
										errorReported = true;
									}
								}

/************************/
/* LINE STATE    	    */
/************************/
<LINE>			{TYPE}        	{location = yytext(); yybegin(NAMING);}
<LINE>			{STRING}		{}
<LINE>      	\n             	{yybegin(NEW_LINE);}
<LINE>      	.              	{}

/************************/
/* ERROR STATE	        */
/************************/
				[^]            {
                                    final String errorMessage = "Analysis failure : Your file could not be analyzed. Please verify that it was encoded in an UNIX format.";
				                    throw new JFlexException(this.getClass().getName(), parsedFileName,
				                                    errorMessage, yytext(), yyline, yycolumn);
                                }
