/************************************************************************************************/
/* i-Code CNES is a static code analyzer.                                                       */
/* This software is a free software, under the terms of the Eclipse Public License version 1.0. */
/* http://www.eclipse.org/legal/epl-v10.html                                                    */
/************************************************************************************************/

/********************************************************************************/
/* This file is used to generate a rule checker for EUM.PRES.CommentBlock rule. */
/* Big (>=5 lines) IF/DO constructs must be preceded by a comment block.        */
/********************************************************************************/

package fr.cnes.icode.fortran77.rules;

import java.io.FileNotFoundException;
import java.io.FileReader;
import java.io.File;
import java.util.ArrayList;
import java.util.List;

import java.util.logging.Logger;

import fr.cnes.icode.data.AbstractChecker;
import fr.cnes.icode.data.CheckResult;
import fr.cnes.icode.exception.JFlexException;

%%

%class EUMPRESCommentBlock
%extends AbstractChecker
%public
%line
%ignorecase
%column

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
TYPE		 = {FUNC}     | {PROC}	   | {SUB} | {PROG} | {MOD}
VAR		     = [a-zA-Z][a-zA-Z0-9\_]*
STRING		 = \'[^\']*\' | \"[^\"]*\"
DO_KW		 = [^a-zA-Z0-9\_]("do")[^a-zA-Z0-9\_]
IF_KW		 = [^a-zA-Z0-9\_]("if")[\ \t]*\(
END_DO		 = ("end"[\ ]+("do")) | [^a-zA-Z0-9\_]("continue")[^a-zA-Z0-9\_]
END_IF		 = ("end"[\ ]+("if"))

%{
    private static final Logger LOGGER = Logger.getLogger(EUMPRESCommentBlock.class.getName());

	String location = "MAIN PROGRAM";
    String parsedFileName;
    boolean lastLineWasComment = false;
    List<Integer> blockStartLines = new ArrayList<>();
    List<Boolean> blockHasComment = new ArrayList<>();

	public EUMPRESCommentBlock(){
	}

	@Override
	public void setInputFile(final File file) throws FileNotFoundException {
		super.setInputFile(file);
        LOGGER.finest("begin method setInputFile");
        this.parsedFileName = file.toString();
        this.zzReader = new FileReader(new File(file.getAbsolutePath()));
        LOGGER.finest("end method setInputFile");
	}

	private void checkBlocks(int currentLine) {
	    for (int i = 0; i < blockStartLines.size(); i++) {
	        if (!blockHasComment.get(i) && (currentLine - blockStartLines.get(i)) >= 5) {
	            LOGGER.fine("Setting error line "+(blockStartLines.get(i)+1)+" due to big block without comment");
	            setError(location, "Big IF/DO constructs (>=5 lines) must be preceded by a comment.", blockStartLines.get(i)+1);
	            blockHasComment.set(i, true);
	        }
	    }
	}

%}

%eofval{
  	checkBlocks(yyline+1);
return getCheckResults();
%eofval}
%eofclose

%%

/************************/

				{FREE_COMMENT}	{
                                    LOGGER.fine("["+this.parsedFileName+":"+(yyline+1)+":"+yycolumn+"] - [ALL] -> COMMENT (Transition : FREE_COMMENT \""+yytext()+"\" )");
                    				lastLineWasComment = true;
                    				yybegin(COMMENT);
                				}

/************************/
/* COMMENT STATE	    */
/************************/
<COMMENT>   	\n             	{
                                    LOGGER.fine("["+this.parsedFileName+":"+(yyline+1)+":"+yycolumn+"] - COMMENT -> NEW_LINE (Transition : \\n )");
                                    yybegin(NEW_LINE);
                                }
<COMMENT>   	.              	{}

/************************/
/* NAMING STATE	        */
/************************/
<NAMING>		{VAR}			{
                                    location = location + " " + yytext();
                                    LOGGER.fine("["+this.parsedFileName+":"+(yyline+1)+":"+yycolumn+"] - NAMING -> COMMENT (Transition : VAR \""+yytext()+"\" )");
                                    yybegin(COMMENT);
                                }
<NAMING>    	\n             	{yybegin(NEW_LINE);}
<NAMING>    	.              	{}

/************************/
/* YYINITIAL STATE	    */
/************************/
<YYINITIAL>  	{COMMENT_WORD} 	{
                                    LOGGER.fine("["+this.parsedFileName+":"+(yyline+1)+":"+yycolumn+"] - YYINITIAL -> COMMENT (Transition : COMMENT_WORD \""+yytext()+"\" )");
                                    lastLineWasComment = true;
                                    yybegin(COMMENT);
                                }
<YYINITIAL>		{TYPE}        	{
                                    location = yytext();
                                    LOGGER.fine("["+this.parsedFileName+":"+(yyline+1)+":"+yycolumn+"] - YYINITIAL -> NAMING (Transition : TYPE \""+yytext()+"\" )");
                                    yybegin(NAMING);
                                }
<YYINITIAL> 	\n             	{
                                    LOGGER.fine("["+this.parsedFileName+":"+(yyline+1)+":"+yycolumn+"] - YYINITIAL -> NEW_LINE (Transition : \\n )");
                                    yybegin(NEW_LINE);
                                }
<YYINITIAL> 	.              	{
                                    LOGGER.fine("["+this.parsedFileName+":"+(yyline+1)+":"+yycolumn+"] - YYINITIAL -> LINE (Transition : . )");
                                    yybegin(LINE);
                                }

/************************/
/* NEW_LINE STATE	    */
/************************/
<NEW_LINE>  	{COMMENT_WORD} 	{
                                    LOGGER.fine("["+this.parsedFileName+":"+(yyline+1)+":"+yycolumn+"] - NEW_LINE -> COMMENT (Transition : COMMENT_WORD \""+yytext()+"\" )");
                                    lastLineWasComment = true;
                                    yybegin(COMMENT);
                                }
<NEW_LINE>		{STRING}		{}
<NEW_LINE>		{TYPE}        	{
                                    location = yytext();
                                    LOGGER.fine("["+this.parsedFileName+":"+(yyline+1)+":"+yycolumn+"] - NEW_LINE -> NAMING (Transition : TYPE \""+yytext()+"\" )");
                                    yybegin(NAMING);
                                }
<NEW_LINE>		{DO_KW}			{
							blockStartLines.add(yyline);
							blockHasComment.add(lastLineWasComment);
							checkBlocks(yyline+1);
							yybegin(LINE);
						}
<NEW_LINE>		{IF_KW}			{
							blockStartLines.add(yyline);
							blockHasComment.add(lastLineWasComment);
							checkBlocks(yyline+1);
							yybegin(LINE);
						}
<NEW_LINE>		{END_DO}		{checkBlocks(yyline+1); yybegin(LINE);}
<NEW_LINE>		{END_IF}		{checkBlocks(yyline+1); yybegin(LINE);}
<NEW_LINE>  	\n             	{lastLineWasComment = false;}
<NEW_LINE>  	.              	{yybegin(LINE);}

/************************/
/* LINE STATE    	    */
/************************/
<LINE>			{STRING}		{}
<LINE>			{TYPE}        	{
                                    location = yytext();
                                    LOGGER.fine("["+this.parsedFileName+":"+(yyline+1)+":"+yycolumn+"] - LINE -> NAMING (Transition : TYPE \""+yytext()+"\" )");
                                    yybegin(NAMING);
                                }
<LINE>			{DO_KW}			{
							blockStartLines.add(yyline);
							blockHasComment.add(lastLineWasComment);
							checkBlocks(yyline+1);
						}
<LINE>			{IF_KW}			{
							blockStartLines.add(yyline);
							blockHasComment.add(lastLineWasComment);
							checkBlocks(yyline+1);
						}
<LINE>			{END_DO}		{checkBlocks(yyline+1);}
<LINE>			{END_IF}		{checkBlocks(yyline+1);}
<LINE>      	\n             	{
                                    LOGGER.fine("["+this.parsedFileName+":"+(yyline+1)+":"+yycolumn+"] - LINE -> NEW_LINE (Transition : \\n )");
                                    lastLineWasComment = false;
                                    yybegin(NEW_LINE);
                                }
<LINE>      	.              	{}

/************************/
/* ERROR STATE	        */
/************************/
				[^]            {
                                    final String errorMessage = "Analysis failure : Your file could not be analyzed. Please verify that it was encoded in an UNIX format.";
				                    throw new JFlexException(this.getClass().getName(), parsedFileName,
				                                    errorMessage, yytext(), yyline, yycolumn);
                                }
