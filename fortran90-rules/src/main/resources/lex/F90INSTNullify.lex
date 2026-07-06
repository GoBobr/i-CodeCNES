/************************************************************************************************/
/* i-Code CNES is a static code analyzer.                                                       */
/* This software is a free software, under the terms of the Eclipse Public License version 1.0. */ 
/* http://www.eclipse.org/legal/epl-v10.html                                                    */
/************************************************************************************************/ 

/*****************************************************************************/
/* This file is used to generate a rule checker for F90.INST.Nullify rule.	 */
/* For further information on this, we advise you to refer to RNC manuals.	 */
/* As many comments have been done on the ExampleRule.lex file, this file    */
/* will restrain its comments on modifications.								 */
/*																			 */
/*****************************************************************************/

package fr.cnes.icode.fortran90.rules;

import java.io.FileNotFoundException;
import java.io.FileReader;
import java.io.File;
import java.util.HashSet;
import java.util.LinkedList;
import java.util.List;
import java.util.Set;

import fr.cnes.icode.exception.JFlexException;
import fr.cnes.icode.data.AbstractChecker;
import fr.cnes.icode.data.CheckResult;

%%

%class F90INSTNullify
%extends AbstractChecker
%public
%column
%line
%ignorecase

%function run
%yylexthrow JFlexException
%type List<CheckResult>

%state COMMENT, NAMING, NEW_LINE, LINE, DEALLOC, SET_NULL, NULL_VAR, DECL

COMMENT_WORD = "!"
TYPE			 = "function"  | "procedure" | "subroutine"  | "program" | "module" |"interface"
FALSE        = [a-zA-Z0-9\_]({TYPE}) | ({TYPE})[a-zA-Z0-9\_] | [a-zA-Z0-9\_]({TYPE})[a-zA-Z0-9\_]
			   | [^a-zA-Z0-9\_]("module")({SPACE}*)("procedure")[^a-zA-Z0-9\_]
SPACE        = [\ \t\f]
VAR		     = [a-zA-Z][a-zA-Z0-9\_]*(\%[a-zA-Z][a-zA-Z0-9\_]*)*
STRING			 = \'[^\']*\' | \"[^\"]*\"

DEALLOCATE	 = [^a-zA-Z0-9\_]("deallocate"){SPACE}*("(")
NULLIFY			 = [^a-zA-Z0-9\_]("nullify"){SPACE}*("(")

DATA_TYPE	 = ("integer"  | "real"     | "complex"     | "double"{SPACE}*("precision") |
			   "logical"  | "character" | "type"){SPACE}*("(")?
POINTER_ATTR = "pointer"
ALLOCATABLE_ATTR = "allocatable"

%{
	/** Variable used to store violation location and variable involved. **/
	String location = "MAIN PROGRAM";
    private String parsedFileName;
	/** Variable used to store file value and function values associated. **/
	List<String> pointers = new LinkedList<String>(); 
	List<Integer> lines = new LinkedList<Integer>();
	int errorLine = 0;
	boolean isPointer = false;
	/** Set of variables declared with POINTER attribute. **/
	Set<String> pointerVars = new HashSet<String>();
	/** Set of variables declared with ALLOCATABLE attribute. **/
	Set<String> allocatableVars = new HashSet<String>();
	/** Flag: next variables in DECL are POINTER. **/
	boolean declIsPointer = false;
	boolean declIsAllocatable = false;
	
	public F90INSTNullify() {
    }
	
	@Override
	public void setInputFile(final File file) throws FileNotFoundException {
		super.setInputFile(file);
		this.parsedFileName = file.toString();
        this.zzReader = new FileReader(new File(file.getAbsolutePath()));
	}
	
	
	
	private void raiseRemainingErrors() throws JFlexException{
		for (int i = 0; i < pointers.size(); i++){
			setError(location,"It misses the instruction NULLIFY after the DEALLOCATION of" + pointers.get(i), lines.get(i));
		}
		pointers.clear();
		lines.clear();
	}
%}

/* At the end of analysis, atEOF is set at true. This is not meant to be modified. */
%eofval{ 
	raiseRemainingErrors();
	 
	return getCheckResults();
%eofval}
%eofclose

%%          
			{COMMENT_WORD}	{yybegin(COMMENT);}

/************************/
/* COMMENT STATE        */
/************************/
<COMMENT>   	
		{
			\n|\r           {yybegin(YYINITIAL);}  
			.              	{}
		}

/************************/
/* NAMING STATE        */
/************************/
<NAMING>		
		{
			{VAR}			{location = location + " " + yytext(); 
							 yybegin(COMMENT);}
			\n|\r           {yybegin(YYINITIAL);}
			.              	{}
		}

/************************/
/* YYINITAL STATE       */
/************************/
<YYINITIAL>		
		{
			{STRING}		{}
			{FALSE}			{}
			{TYPE}        	{raiseRemainingErrors();
							 location = yytext(); 
							 yybegin(NAMING);}
			{DATA_TYPE}		{declIsPointer = false; declIsAllocatable = false; yybegin(DECL);}
			{DEALLOCATE}	{errorLine = yyline + 1; yybegin(DEALLOC);}
			{NULLIFY}		{yybegin(NULL_VAR);}
			{VAR}			{if(pointers.contains(yytext())) {
								setError(location,"It misses the instruction NULLIFY after the DEALLOCATION of " + yytext(), lines.get(pointers.indexOf(yytext())));
								lines.remove(pointers.indexOf(yytext()));
								pointers.remove(yytext());
							 }
							}
			\n             	{}
			.              	{}
		}

/************************/
/* DEALLOC STATE        */
/************************/
<DEALLOC>		
		{
			{VAR}			{if(!isPointer) { 
							// Only require NULLIFY for POINTER variables, not ALLOCATABLE
							if (pointerVars.contains(yytext()) && !allocatableVars.contains(yytext())) {
								pointers.add(yytext()); 
								lines.add(errorLine);
								isPointer = true; 
							}
						 } 
						}
			\n				{isPointer = false; yybegin(YYINITIAL);}
			.				{}
		}

/************************/
/* NULL_VAR STATE       */
/************************/
<NULL_VAR>
		{
			{VAR}			{if(pointers.contains(yytext())) {
								lines.remove(pointers.indexOf(yytext()));
								pointers.remove(yytext());
							 }
							}
			\n				{yybegin(YYINITIAL);}
			.				{}
		}
		
/************************//* DECL STATE           */
/************************/
<DECL>		
		{
			{POINTER_ATTR}		{declIsPointer = true;}
			{ALLOCATABLE_ATTR}	{declIsAllocatable = true;}
			::					{}
			{VAR}			{if(declIsPointer) pointerVars.add(yytext());
							 if(declIsAllocatable) allocatableVars.add(yytext());}
			\n             	{declIsPointer = false; declIsAllocatable = false; yybegin(YYINITIAL);}
			.				{}
		}
		
/************************//* THROW ERROR          */
/************************/
				[^]            {
                                    
				                    final String errorMessage = "Analysis failure : Your file could not be analyzed. Please verify that it was encoded in an UNIX format.";
				                    throw new JFlexException(this.getClass().getName(), parsedFileName,
				                                    errorMessage, yytext(), yyline, yycolumn);
                                }