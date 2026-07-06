/************************************************************************************************/
/* i-Code CNES is a static code analyzer.                                                       */
/* This software is a free software, under the terms of the Eclipse Public License version 1.0. */ 
/* http://www.eclipse.org/legal/epl-v10.html                                                    */
/************************************************************************************************/ 

/*****************************************************************************/
/* This file is used to generate a rule checker for F77.DATA.LoopDO rule. 	 */
/* For further information on this, we advise you to refer to RNC manuals.	 */
/* As many comments have been done on the ExampleRule.lex file, this file    */
/* will restrain its comments on modifications.								 */
/*																			 */
/*****************************************************************************/

package fr.cnes.icode.fortran90.rules;

import java.io.FileNotFoundException;
import java.io.FileReader;
import java.io.File;
import java.util.LinkedList;
import java.util.List;

import fr.cnes.icode.exception.JFlexException;
import fr.cnes.icode.data.AbstractChecker;
import fr.cnes.icode.data.CheckResult;


%%

/* Column counting is used to deal with line completion problems. */
%class F90DESIGNObsoleteDoReal
%extends AbstractChecker
%public
%column
%line


%function run
%yylexthrow JFlexException
%type List<CheckResult>

/* A state called ENTER_DO is created. It allows to determine the condition	*/
/* of a DO-loop and certify that it's not a WHILE-loop.						*/
/* A state called INDEX is to determine whenever the equal sign is passed.	*/
/* A state called INIT is set to get all declared variables that are not an */
/* integer.																	*/
%state COMMENT, NAMING, NEW_LINE, LINE, ENTER_DO, INDEX, INIT, PAR, PARI, USE_STATE

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
SPACE		 = [\ \t\r]
STRUCT		 = {VAR}(\%{VAR})+
KEYWORD	 = "dimension"|"DIMENSION"|"allocatable"|"ALLOCATABLE"|"pointer"|"POINTER"|"intent"|"INTENT"|"save"|"SAVE"|"target"|"TARGET"|"external"|"EXTERNAL"|"intrinsic"|"INTRINSIC"|"optional"|"OPTIONAL"|"parameter"|"PARAMETER"|"public"|"PUBLIC"|"private"|"PRIVATE"|"volatile"|"VOLATILE"|"asynchronous"|"ASYNCHRONOUS"|"protected"|"PROTECTED"|"value"|"VALUE"|"contiguous"|"CONTIGUOUS"

%{
	String location = "MAIN PROGRAM";
    private String parsedFileName;
	
	
	public F90DESIGNObsoleteDoReal() {
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

/* A boolean called error is to determine if a non integer value is found. */
/* A list of String will contain name of declared variables.			   */
/* An integer called LAST_STATE is used when line completion is found.	   */
%{
	boolean violation = false;
	List<String> wrongTypeVariables = new LinkedList<String>();
	int LAST_STATE = LINE;
	int par = 0;
	String variable = "";
%}

/* Transition word is do (or DO). If WHILE is found, nothing has to be done. */
/* Words are set to identify undesired types, such as real or complex.		 */
RULE_WORD = do    | DO
WHILE	  = while | WHILE
END		  = end	  | END

REAL        = real 				| REAL
DOUBLE_PREC = double[\ ]+precision 	| DOUBLE[\ ]+PRECISION
COMPLEX     = complex			| COMPLEX
LOGICAL		= logical			| LOGICAL
CHAR		= character			| CHARACTER
WRONG_TYPE  = {REAL} 			| {DOUBLE_PREC} | {COMPLEX} | {LOGICAL} | {CHAR}
INTRIN_INT  = "size" | "SIZE" | "lbound" | "LBOUND" | "ubound" | "UBOUND" | "len" | "LEN" |
			  "len_trim" | "LEN_TRIM" | "kind" | "KIND" | "shape" | "SHAPE" | "count" | "COUNT" |
			  "merge" | "MERGE" | "pack" | "PACK" | "unpack" | "UNPACK" | "reshape" | "RESHAPE" |
			  "spread" | "SPREAD" | "cshift" | "CSHIFT" | "eoshift" | "EOSHIFT" | "transpose" | "TRANSPOSE" |
			  "matmul" | "MATMUL" | "dot_product" | "DOT_PRODUCT" | "scan" | "SCAN" | "verify" | "VERIFY" |
			  "index" | "INDEX" | "repeat" | "REPEAT" | "trim" | "TRIM" | "adjustl" | "ADJUSTL" |
			  "adjustr" | "ADJUSTR" | "selected_int_kind" | "SELECTED_INT_KIND" | "selected_char_kind" | "SELECTED_CHAR_KIND" |
			  "command_argument_count" | "COMMAND_ARGUMENT_COUNT" | "storage_size" | "STORAGE_SIZE" |
			  "new_line" | "NEW_LINE" | "leadz" | "LEADZ" | "trailz" | "TRAILZ" | "popcnt" | "POPCNT" |
			  "poppar" | "POPPAR" | "maskl" | "MASKL" | "maskr" | "MASKR" | "shiftl" | "SHIFTL" |
			  "shiftr" | "SHIFTR" | "shifta" | "SHIFTA" | "merge_bits" | "MERGE_BITS" | "iand" | "IAND" |
			  "ior" | "IOR" | "ieor" | "IEOR" | "not" | "NOT" | "ibclr" | "IBCLR" | "ibset" | "IBSET" |
			  "btest" | "BTEST" | "ishft" | "ISHFT" | "ishftc" | "ISHFTC" | "mvbits" | "MVBITS" |
			  "dshiftl" | "DSHIFTL" | "dshiftr" | "DSHIFTR" | "digits" | "DIGITS" | "radix" | "RADIX" |
			  "minexponent" | "MINEXPONENT" | "maxexponent" | "MAXEXPONENT" | "exponent" | "EXPONENT" |
			  "precision" | "PRECISION" | "range" | "RANGE" | "floor" | "FLOOR" | "ceiling" | "CEILING" |
			  "nint" | "NINT" | "int" | "INT" | "abs" | "ABS" | "min" | "MIN" | "max" | "MAX" |
			  "mod" | "MOD" | "modulo" | "MODULO" | "sign" | "SIGN" | "dim" | "DIM" | "dprod" | "DPROD" |
			  "product" | "PRODUCT" | "sum" | "SUM" | "any" | "ANY" | "all" | "ALL" | "allocated" | "ALLOCATED" |
			  "associated" | "ASSOCIATED" | "present" | "PRESENT" | "bit_size" | "BIT_SIZE"
%%
/*************************/
/*	FREE COMMENT CATCH	 */
/*************************/
				{FREE_COMMENT}	{yybegin(COMMENT);}

/*********************/
/*	COMMENT PART	 */
/*********************/
<COMMENT>   	\n             	{yybegin(NEW_LINE);}  
<COMMENT>   	.              	{}

/*****************/
/*	NAMING PART	 */
/*****************/
<NAMING>		{VAR}			{location = location + " " + yytext();
								 wrongTypeVariables.clear();
								 yybegin(COMMENT);}
<NAMING>    	\n             	{wrongTypeVariables.clear();
								 yybegin(NEW_LINE);}
<NAMING>    	.              	{}

/*****************************/
/*	INITIALIZATION STATE	 */
/*****************************/
/* Whenever a type declaration is found, we check that only one variable is on the */
/* line, which there is no comma (,).											   */ 
<INIT> 			{KEYWORD}		{}
<INIT> 			{VAR}			{wrongTypeVariables.add(yytext());}
<INIT>			\&{SPACE}*\n		{}
<INIT>			\(				{par=1; yybegin(PARI);}
<INIT>			.				{}
<INIT>			\n				{LAST_STATE = INIT;
								 yybegin(NEW_LINE);}
								 
<PARI>			\(				{par++;}
<PARI>			\)				{par--; if(par==0) yybegin(INIT);}
<PARI>			\n				{yybegin(LAST_STATE);}
<PARI>			.				{}

/*****************************/
/*	 DO DECLARATION STATE	 */
/*****************************/
/* If an equal sign appears, we go straight to INDEX part. */
<ENTER_DO>		{WHILE}			{yybegin(COMMENT);}
<ENTER_DO>		{INTRIN_INT}{SPACE}*\(		{par=1; yybegin(PAR);}
<ENTER_DO>		{STRUCT}			{}
<ENTER_DO>		{VAR}			{if (wrongTypeVariables.contains(yytext())) { violation = true; variable = variable + " " + yytext(); }}
<ENTER_DO>		\=				{yybegin(INDEX);}
<ENTER_DO>		.				{}
<ENTER_DO>		\n				{violation=false; yybegin(NEW_LINE);}

/*****************************/
/*	 INDEX CHECKING STATE	 */
/*****************************/
/* We do nothing for integer, blank and end of line. Otherwise, an error is set. */
<INDEX>			[0-9]+			{}
<INDEX>			{INTRIN_INT}{SPACE}*\(		{par=1; yybegin(PAR);}
<INDEX>			{STRUCT}			{}
<INDEX>			{VAR}			{if (wrongTypeVariables.contains(yytext())) { violation = true; variable = variable + " " + yytext(); }}
<INDEX>			\(				{par=1; yybegin(PAR);}
<INDEX>			\,				{}
<INDEX>			[0-9]*\.[0-9]+	{violation = true;  variable = variable + " " + yytext();}
<INDEX> 		.				{}
<INDEX>			\n				{if (violation) this.setError(location,"The variable " + variable + " is a real used in a do loop. Use only INTEGER.", yyline + 1);
								 violation = false; variable = "";
								 yybegin(NEW_LINE);}
								 
<PAR>			\(				{par++;}
<PAR>			\)				{par--; if(par==0) yybegin(INDEX);}
<PAR>			\n				{yybegin(NEW_LINE);}
<PAR>			.				{}

/*********************/
/*	INITIAL STATE	 */
/*********************/
<YYINITIAL>  	{COMMENT_WORD} 	{yybegin(COMMENT);}
<YYINITIAL>		{STRING}		{yybegin(LINE);}
<YYINITIAL>  	{TYPE}         	{location = yytext();
								 yybegin(NAMING);}
<YYINITIAL>		{WRONG_TYPE}	{yybegin(INIT);}
<YYINITIAL>		{RULE_WORD}		{yybegin(ENTER_DO);}
<YYINITIAL> 	\n             	{yybegin(NEW_LINE);}
<YYINITIAL> 	.              	{yybegin(LINE);}

/*********************/
/*	NEW LINE STATE	 */
/*********************/	
/* If END is found, we check whether it corresponds to a DO-loop. If it is	*/
/* we remove the last condition word. Then, we remove last indentifier.		*/
<NEW_LINE>  	{COMMENT_WORD} 	{yybegin(COMMENT);}
<NEW_LINE>		{STRING}		{yybegin(LINE);}
<NEW_LINE>  	{TYPE}         	{location = yytext();
								 yybegin(NAMING);}
<NEW_LINE>		{WRONG_TYPE}	{yybegin(INIT);}
<NEW_LINE>		{RULE_WORD}		{yybegin(ENTER_DO);}
<NEW_LINE>		"use"			{yybegin(USE_STATE);}
<NEW_LINE>		{END}			{yybegin(COMMENT);}
<NEW_LINE>		{VAR}			{}
<NEW_LINE>		{SPACE}			{}
<NEW_LINE>  	\n             	{}
<NEW_LINE>  	.              	{yybegin(LINE);}

/*****************/
/*	LINE STATE	 */
/*****************/
<LINE>			{STRING}		{}
<LINE>		  	{TYPE}         	{location = yytext();
								 yybegin(NAMING);}
<LINE>			{RULE_WORD}		{yybegin(ENTER_DO);}
<LINE>			"use"			{yybegin(USE_STATE);}
<LINE>			{END}			{yybegin(COMMENT);}
<LINE>			{VAR}			{}
<LINE>      	\n             	{yybegin(NEW_LINE);}
<LINE>			.				{}

/************************/
/* USE_STATE    	    */
/************************/
<USE_STATE>		\![^\n]*		{}
<USE_STATE>		"only"[\ \t]*":"	{}
<USE_STATE>		{VAR}			{wrongTypeVariables.remove(yytext());}
<USE_STATE>		\&[\ \t]*\n		{}
<USE_STATE>		\n				{yybegin(NEW_LINE);}
<USE_STATE>		.				{}


/*********************/
/*	ERROR THROWN	 */
/*********************/
				[^]            {
                                    
				                    final String errorMessage = "Analysis failure : Your file could not be analyzed. Please verify that it was encoded in an UNIX format.";
				                    throw new JFlexException(this.getClass().getName(), parsedFileName,
				                                    errorMessage, yytext(), yyline, yycolumn);
                                }