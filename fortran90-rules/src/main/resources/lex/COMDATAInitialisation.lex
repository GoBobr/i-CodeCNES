/************************************************************************************************/
/* i-Code CNES is a static code analyzer.                                                       */
/* This software is a free software, under the terms of the Eclipse Public License version 1.0. */ 
/* http://www.eclipse.org/legal/epl-v10.html                                                    */
/************************************************************************************************/ 

/**********************************************************************************/
/* This file is used to generate a rule checker for COM.DATA.Initialisation rule. */
/* For further information on this, we advise you to refer to RNC manuals.	      */
/* As many comments have been done on the ExampleRule.lex file, this file         */
/* will restrain its comments on modifications.								      */
/*																			      */
/**********************************************************************************/


package fr.cnes.icode.fortran90.rules;

import java.io.FileNotFoundException;
import java.io.FileReader;
import java.io.File;
import java.util.HashMap;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashSet;
import java.util.LinkedList;
import java.util.List;
import java.util.Map;
import java.util.Set;

import fr.cnes.icode.data.AbstractChecker;
import fr.cnes.icode.data.CheckResult;
import fr.cnes.icode.exception.JFlexException;

%%

%class COMDATAInitialisation
%extends AbstractChecker
%public
%column
%line
%ignorecase

%function run
%yylexthrow JFlexException
%type List<CheckResult>


%state COMMENT, NAMING, NEW_LINE, LINE, INIT, VAR_EQ, WAIT, FUNC, AVOID, DATA, WAIT_ARRAY, PARAMS, ARRAY, DECLARATION, USE_STATE

COMMENT_WORD = \! 
FREE_COMMENT = \!
COMMENT_LINE = \! [^\n]*
FUNC         = FUNCTION   | function
PROC         = PROCEDURE  | procedure
SUB          = SUBROUTINE | subroutine
PROG         = PROGRAM    | program
MOD          = MODULE     | module
TYPE		 = {FUNC}     | {PROC}	   | {SUB}    | {PROG} | {MOD}
EQUAL        = \=
INTEGER      = INTEGER    | integer
LOGICAL		 = LOGICAL	  | logical
CHARAC		 = CHARACTER  | character
REAL		 = REAL		  | real
COMPLEX      = COMPLEX    | complex
DOUBLE		 = DOUBLE     | double
PREC		 = PRECISION  | precision
DOUBLE_PREC	 = {DOUBLE}([\ ]*){PREC}
STRUCT		 = TYPE[\ ]*\(| type[\ ]*\(
DIMENSION	 = "dimension"
DATA		 = "data"
INTENT		 = "intent" {SPACE}* \( 
INTENTIN		 = "intent" {SPACE}*\({SPACE}*"in"{SPACE}*\)|"INTENT" {SPACE}*\({SPACE}*"IN"{SPACE}*\)
INTENTOUT		 = "intent" {SPACE}*\({SPACE}*"out"{SPACE}*\)|"INTENT" {SPACE}*\({SPACE}*"OUT"{SPACE}*\)
INTENTINOUT		 = "intent" {SPACE}*\({SPACE}*"inout"{SPACE}*\)|"INTENT" {SPACE}*\({SPACE}*"INOUT"{SPACE}*\)
PARAMETER		 = "parameter"
POINTER_ASSIGN	 = \=\>
NUM_LITERAL	 = [0-9]+\.?[0-9]*[dDeE][\-\+]?[0-9]+([_][a-zA-Z0-9_]+)? | \.[0-9]+[dDeE][\-\+]?[0-9]+([_][a-zA-Z0-9_]+)?
IMPLIED_DO	 = \/\/?\s*\(?\s*{VAR}\s*,\s*{VAR}\s*\=
READ		 = ([^a-zA-Z0-9\_])?"read"[^a-zA-Z0-9\_\n]
COMMON		 = ([^a-zA-Z0-9\_])?"common"[^a-zA-Z0-9\_\n]
NAMELIST	 = ([^a-zA-Z0-9\_])?"namelist"[^a-zA-Z0-9\_\n]
SAVE		 = ([^a-zA-Z0-9\_])?"save"[^a-zA-Z0-9\_\n] 
EQUIV		 = ([^a-zA-Z0-9\_])?"equivalence"[^a-zA-Z0-9\_\n] 
END			 = ([^a-zA-Z0-9\_])?"end"[^a-zA-Z0-9\_\n]
GOTO		 = ([^a-zA-Z0-9\_])?"go"[\ ]*"to"[^a-zA-Z0-9\_\n]
EXT			 = ([^a-zA-Z0-9\_])?"external"[^a-zA-Z0-9\_\n]
CALL		 = ([^a-zA-Z0-9\_])?"call"[^a-zA-Z0-9\_\n]
IMPLICIT	 = ([^a-zA-Z0-9\_])?"implicit"[^a-zA-Z0-9\_\n]
USE_KW		 = ([^a-zA-Z0-9\_])?"use"[^a-zA-Z0-9\_\n]
INITILIAZE 	 = {READ} 	| {DATA}	| {COMMON}		| {NAMELIST}	| {SAVE}	| {EQUIV}	| {CALL}
CLE			 = {END}	| {GOTO}	| {EXT}			| {IMPLICIT}
VAR_T     	 = {INTEGER}  | {LOGICAL}  | {CHARAC} | {REAL} | {COMPLEX} | {DOUBLE_PREC} | {STRUCT} 
VAR_PAR		 = {VAR}{SPACE}*\( 
VAR		     = [a-zA-Z][a-zA-Z0-9\_]*
NUM			 = [0-9]+\.([0-9]*("e"|"d")(\-|\+)?[0-9]+)?((\_)?{VAR})?
POINT		 = (\%{VAR})+
SPACE		 = [\ \r\t\f]
STRING		 = \'[^\']*\' | \"[^\"]*\"
SIMBOL		 = \& 		  | \$ 		   | \+			| [A-Za-z][\ ]	| \.	| [0-9]
COMP		 = "/=" | "==" | ".eq." | ".ne." | ".NE." | ".EQ."
SEE_FUNC	 = ([^a-zA-Z0-9\_])?("if" | "elseif" | "forall" | "while" | "where" | "WHERE" | "FORALL" | "IF" | "ELSEIF" | "WHILE"){SPACE}*"("
																
%{
	String location = "MAIN PROGRAM";
    private String parsedFileName;
	
	Map<String, Boolean> variables = new HashMap<String, Boolean>();
	List<String> dimension = new LinkedList<String>();
	
	//mantis EGL 316
	Map<String, List<String>> mVariableByCallType = new HashMap<String, List<String>>();
	Map<String, List<String>> mVariableByType = new HashMap<String, List<String>>();
	
	String variable = "";
	boolean initialized = false;
	int par = 0;
	boolean dim = false, fin = true;

	//mantis EGL 312/316/324/313
	boolean isPotentialError = false;
	//when a call is fire
	boolean isCall=false;
	boolean firstCall=false;
	//when an intent(in) is declared (variable is initialized by caller)
	boolean isIntentIn=false;
	//when an intent(out) is declared (variable is assigned by subroutine)
	boolean isIntentOut=false;
	//name of sunroutine
	String nameType="";
	//when parameter attribute is present (variable is initialized)
	boolean isParameter=false;
	//when USE without ONLY is present (suppress undeclared errors)
	boolean useWithoutOnly=false;
	boolean hasOnly=false;
	
	// Fortran attribute keywords that should not be treated as variables
	Set<String> fortranKeywords = new HashSet<String>(Arrays.asList(
		"allocatable", "pointer", "public", "private", "optional", "parameter",
		"dimension", "intent", "save", "target", "external", "intrinsic",
		"allocated", "associated", "volatile", "asynchronous", "bind",
		"protected", "value", "contiguous", "sequence", "abstract",
		"extends", "import", "non_overridable", "deferred", "final",
		"generic", "procedure", "operator", "assignment", "read", "write",
		"pass", "nopass", "entry", "result", "recursive", "pure", "elemental",
		"module", "submodule", "block", "data", "namelist", "common",
		"equivalence", "implicit", "none", "use", "only", "include",
		"interface", "end", "enddo", "endif", "endtype", "endmodule",
		"endsubroutine", "endfunction", "endprogram", "endinterface",
		"contains", "return", "call", "continue", "goto", "go", "to",
		"pause", "stop", "cycle", "exit", "allocate", "deallocate",
		"nullify", "inquire", "rewind", "backspace", "endfile", "flush",
		"wait", "lock", "unlock", "sync", "critical", "block",
		"associate", "endassociate", "change", "endteam", "form",
		"event", "endevent", "coarray"
	));
	// Fortran intrinsic functions that should not be treated as variables
	Set<String> fortranIntrinsics = new HashSet<String>(Arrays.asList(
		"size", "lbound", "ubound", "len", "len_trim", "kind", "shape",
		"allocated", "associated", "present", "abs", "min", "max",
		"mod", "modulo", "sign", "dim", "dprod", "floor", "ceiling",
		"nint", "int", "real", "dble", "cmplx", "aimag", "conjg",
		"sqrt", "exp", "log", "log10", "sin", "cos", "tan",
		"asin", "acos", "atan", "atan2", "sinh", "cosh", "tanh",
		"minval", "maxval", "minloc", "maxloc", "sum", "product",
		"count", "any", "all", "merge", "pack", "unpack", "reshape",
		"spread", "cshift", "eoshift", "transpose", "matmul",
		"dot_product", "trim", "adjustl", "adjustr", "scan",
		"verify", "index", "repeat", "char", "achar", "ichar",
		"iachar", "string", "transfer", "leadz", "trailz", "popcnt",
		"poppar", "maskl", "maskr", "shiftl", "shiftr", "shifta",
		"merge_bits", "iand", "ior", "ieor", "not", "ibclr", "ibset",
		"btest", "ishft", "ishftc", "mvbits", "dshiftl", "dshiftr",
		"selected_int_kind", "selected_real_kind", "selected_char_kind",
		"epsilon", "tiny", "huge", "precision", "range", "radix",
		"digits", "minexponent", "maxexponent", "exponent", "fraction",
		"scale", "set_exponent", "nearest", "spacing", "rrspacing",
		"norm2", "hypot", "bessel_j0", "bessel_j1", "bessel_jn",
		"bessel_y0", "bessel_yn", "erf", "erfc", "erfc_scaled",
		"gamma", "log_gamma", "command_argument_count",
		"get_command", "get_command_argument", "get_environment_variable",
		"system_clock", "date_and_time", "random_number", "random_seed",
		"execute_command_line", "move_alloc", "new_line",
		"omp_get_thread_num", "omp_get_num_threads", "omp_get_max_threads",
		"omp_in_parallel", "omp_get_level", "omp_get_ancestor_thread_num"
	));

    public COMDATAInitialisation() {
    }

        @Override
        public void setInputFile(final File file) throws FileNotFoundException {
                super.setInputFile(file);

                this.parsedFileName = file.toString();
        this.zzReader = new FileReader(new File(file.getAbsolutePath()));
        }

	/**
	 * @param position
	 */
	private void addVariableByCallType(final String funct, final String paramVar,final String location,final int line){
		//if variable is declared
		if(variables.containsKey(paramVar)){
			//if variable is not initialized
			//then add in this  mVariableByType to check if this type naming  
			//initialize it.
			if(!variables.get(paramVar)){

				List<String> param ;
				if (mVariableByCallType.get(funct)!=null){
					param = mVariableByCallType.get(funct);
				}else{					
					param = new ArrayList<String>();					
				}
				param.add("paramVar="+paramVar);
				param.add("location="+location);
				param.add("line="+line);
				param.add("error=false");

				mVariableByCallType.put(funct,param);

			}
		}
	}

	/**
	 * This function parse Naming subroutin, function, module in List  
	 * in order to analyse at the end of parsing if 
	 * this variable is initialized by this naming .
	 * this function is applied in type or naming .
	 * @param funct
	 * @param paramVar
	 * @param position
	 */
	private void addVariableByType(final String funct, final String paramVar){

		List<String> param ;
		if (mVariableByType.get(funct)!=null){
			param = mVariableByType.get(funct);										
		}else{					
			param = new ArrayList<String>();				
		}
		param.add("paramVar="+paramVar);
		mVariableByType.put(funct,param);

	}

	/**
	 * This fonction is recommended in intent treatment to update initialized state of variable
	 * @param funct
	 * @param paramVar
	 * @return true if this variable is updated as no initialized false else
	 */
	private boolean setErrorVariableByType(final String funct, final String paramVar){
		//test limitation of this rule with call function
		boolean ret = false;  
		if(mVariableByCallType.containsKey(funct)  && mVariableByType.containsKey(funct)){
			List<String> paramCall = mVariableByCallType.get(funct);
			List<String> param = mVariableByType.get(funct);
			if(param!=null && paramCall!=null ){
				final int indexParam = param.indexOf("paramVar="+paramVar);
				//if it is the same function cause of prototype function
				//then param are in same place in signature function
				if((indexParam > -1) && (paramCall.size() >(indexParam * 4))){
					final String sParamCall = paramCall.get(indexParam * 4);
					if(sParamCall.contains("paramVar=")){
						paramCall.set(indexParam + 3, "error=true");
						ret = true;
					}
				}
			}
		}
		return ret;
	}
	
	/**
	 * this function display add violation for variables which are not initialized in call function 
	 * @throws JFlexException
	 * @throws NumberFormatException
	 */
	private void displayErrorVariableByType() throws JFlexException,NumberFormatException {
		
		//add at the end all violation error 
		//function shall be described in this source code
		if(!mVariableByCallType.isEmpty()){
			final Set<Map.Entry<String,List<String>>> entryCall = mVariableByCallType.entrySet();
			
			
			for (Map.Entry<String,List<String>> ent:entryCall){
				
				final List<String> entList =  ent.getValue();			
				if(entList!=null && !entList.isEmpty())
				for(int i=0;i<entList.size();i++){				
					if(entList.get(i).contains("paramVar=")){
						if(entList.size() > (i+3)){
							final String error= entList.get(i+3).substring(entList.get(i+3).indexOf("=")+1, entList.get(i+3).length());
							final String paramVar= entList.get(i).substring(entList.get(i).indexOf("=")+1, entList.get(i).length());
							if("true".equals(error) && !useWithoutOnly){
								final String dLocation= entList.get(i+1).substring(entList.get(i+1).indexOf("=")+1, entList.get(i+1).length());
								final String line= entList.get(i+2).substring(entList.get(i+2).indexOf("=")+1, entList.get(i+2).length());									
								setError(dLocation,"The variable " + paramVar + " is used before being initialized. ", Integer.parseInt(line));
													 
							}
							
						}else{
							
							
				            final String errorMessage = "Analysis failure : Excepted parameter of "+ entList.get(i) +" unreachable.";
				            throw new JFlexException(this.getClass().getName(), parsedFileName,
				                            errorMessage, yytext(), yyline, yycolumn);
							
						}
						
					}
					
				}
				
			}	
		}
	}
		
%}

%eofval{
//mantis 316
displayErrorVariableByType();
return getCheckResults();
%eofval}
%eofclose


%%          

/******************************************************************************/
/* This part deals with a "free" comment, which means not at the beginning of */
/* a line.																	  */
/******************************************************************************/
				{FREE_COMMENT}	{yybegin(COMMENT);}


/******************************************************************************/
/* This part deals with the comment section, to avoid any word on these lines.*/
/******************************************************************************/
/************************/
/* COMMENT STATE	    */
/************************/
<COMMENT>   	\n             	{yybegin(NEW_LINE);}  
<COMMENT>   	.              	{}

/************************/
/* AVOID STATE	   		*/
/************************/
<AVOID>			{COMMENT_LINE}		{}
<AVOID>			{SPACE}				{}
<AVOID>			\n[\ ]{1,5}{SIMBOL}	{}
<AVOID>   		\n             		{yybegin(NEW_LINE);}  
<AVOID>   		.              		{}

/******************************************************************************/
/* This part deals with function, procedure and other's name. It is 	 	  */
/* to determine, when it exists, the name of each one. Whenever a name  	  */
/* is encountered, the following part is ignored, moving to COMMENT state.    */
/******************************************************************************/
/************************/
/* NAMING STATE	        */
/************************/
<NAMING>		{COMMENT_LINE}	{}
<NAMING>		{VAR}			{nameType=yytext();location = location + " " + yytext(); variables.clear(); dimension.clear(); yybegin(PARAMS);}
<NAMING>    	\n             	{variables.clear(); dimension.clear(); yybegin(NEW_LINE);}
<NAMING>    	.              	{}


/************************/
/* PARAMS STATE	        */
/************************/
<PARAMS>		{COMMENT_LINE}		{}
<PARAMS>		{VAR}				{addVariableByType(nameType, yytext());variables.put(yytext(), true);}
<PARAMS>		{SPACE}				{}
<PARAMS>		\n[\ ]{1,5}{SIMBOL}	{}
<PARAMS>   		\n             		{yybegin(NEW_LINE);}  
<PARAMS>   		.              		{}

/******************************************************************************/
/* This is the first state of the automaton. The automaton will never go back */
/* to this state after.                                                       */
/******************************************************************************/
/************************/
/* YYINITIAL STATE	    */
/************************/
<YYINITIAL>  	{COMMENT_WORD} 	{yybegin(COMMENT);}
<YYINITIAL>		{TYPE}        	{location = yytext(); yybegin(NAMING);}
<YYINITIAL>     {VAR_T}			{yybegin(DECLARATION);}
<YYINITIAL> 	\n             	{yybegin(NEW_LINE);}
<YYINITIAL> 	.              	{yybegin(LINE);}

/******************************************************************************/
/* This state is reached whenever a new line starts.                          */
/******************************************************************************/
/************************/
/* NEW_LINE STATE       */
/************************/
<NEW_LINE>		{COMMENT_WORD} 	{yybegin(COMMENT);}
<NEW_LINE>		{STRING}		{yybegin(LINE);}
<NEW_LINE>  	{TYPE}         	{location = yytext(); yybegin(NAMING);}
<NEW_LINE>		{INITILIAZE}	{
									if ("call".equals(yytext().trim().toLowerCase())){
									 isCall=true;	
									 firstCall=true;	
									 }							
									 yybegin(DATA);
									
								}
<NEW_LINE>      {VAR_T}			{yybegin(DECLARATION);}
<NEW_LINE>		{USE_KW}			{hasOnly = false; yybegin(USE_STATE);}
<NEW_LINE>		{CLE}			{yybegin(AVOID);}
<NEW_LINE>		{SEE_FUNC}		{}
<NEW_LINE>	    {COMP}   		{
								  if(isPotentialError && variables.containsKey(variable)){
									Boolean init = variables.get(variable);
								 	if(init != null && !init){
								  		setError(location,"The variable " + variable + " is used before being initialized. ", yyline+1); 
									}
									isPotentialError=false;
								  }
                                }
<NEW_LINE>		{VAR_PAR}		{variable = yytext().substring(0,yytext().length()-1).trim();  par = 1;
								 if (!dimension.contains(variable)){
								 	 yybegin(FUNC);
								 		 
								 }else{
								 	 isPotentialError = true;
								 	 yybegin(ARRAY);
								 }
								 		
								}
<NEW_LINE>		{NUM_LITERAL}	{}
<NEW_LINE>		{IMPLIED_DO}	{String var = yytext().replaceAll("[^a-zA-Z0-9_,=\\s\\(\\/\\)]", "").trim();
								 String[] parts = var.split("[,=]");
								 if(parts.length >= 2) {
									 String loopVar = parts[1].trim();
									 if(variables.containsKey(loopVar)) variables.put(loopVar, true);
								 }
								 yybegin(LINE);}
<NEW_LINE>		{VAR}			{if(variables.containsKey(yytext())) { variable = yytext(); initialized = false; yybegin(VAR_EQ);} } 
<NEW_LINE>		{NUM}|{POINT}	{yybegin(LINE);}
<NEW_LINE>  	\n             	{}
<NEW_LINE>  	.              	{yybegin(LINE);}


/******************************************************************************/
/* This state is whenever none of the others has been reached.                */
/******************************************************************************/
/************************/
/* LINE STATE           */
/************************/
<LINE>			{COMMENT_LINE} 	{yybegin(COMMENT);}
<LINE>			{STRING}		{}
<LINE>  		{TYPE}         	{location = yytext(); yybegin(NAMING);}
<LINE>			{INITILIAZE}	{
									if ("call".equals(yytext().trim().toLowerCase())){
									 isCall=true;
		                             firstCall=true;
		                             }							 
									 yybegin(DATA);
							    }
<LINE>   	    {VAR_T}			{yybegin(DECLARATION);}
<LINE>			{USE_KW}			{hasOnly = false; yybegin(USE_STATE);}
<LINE>			{CLE}			{yybegin(AVOID);}
<LINE>	        {SEE_FUNC}		{}
<LINE>	        {COMP}   		{
								  if(isPotentialError && variables.containsKey(variable)){
									Boolean init = variables.get(variable);
								 	if(init != null && !init){
								  		setError(location,"The variable " + variable + " is used before being initialized. ", yyline+1); 
									}
									isPotentialError=false;
								  }
								}
<LINE>			{VAR_PAR}		{variable = yytext().substring(0,yytext().length()-1).trim();  par = 1;
								  if (!dimension.contains(variable)){
								        yybegin(FUNC);
								  }else{
								  		isPotentialError = true;
								        yybegin(ARRAY);
								  }
								}
<LINE>			{VAR}			{if(variables.containsKey(yytext())) { variable = yytext(); initialized = false; yybegin(VAR_EQ);} } 
<LINE>			{NUM_LITERAL}	{}
<LINE>			{NUM}|{POINT}	{}
<LINE>			{POINTER_ASSIGN}	{isPotentialError = false; if(variables.containsKey(variable)) variables.put(variable, true);}
<LINE>			{EQUAL} 		{isPotentialError = false;;if(variables.containsKey(variable)) variables.put(variable, true ); }
<LINE>      	\n             	{if(isPotentialError && variables.containsKey(variable)){
									Boolean init = variables.get(variable);
								 	if(init != null && !init){
								  		setError(location,"The variable " + variable + " is used before being initialized. ", yyline+1); 
									}
									isPotentialError=false;
								  }
								  yybegin(NEW_LINE);
									
								}
<LINE>      	.            	{yybegin(NEW_LINE);}

/************************/
/* INIT STATE           */
/************************/
<INIT>			{COMMENT_LINE}		{}
<INIT>			{STRING}			{}
<INIT>		  	{VAR} 				{variable = yytext(); fin=true;
									 if (isIntentIn || isParameter){
									 	variables.put(variable, true);
									 	setErrorVariableByType(nameType, variable);
									 } else if(isIntentOut){
									 	variables.put(variable, true);
									 } else if(!variables.containsKey(variable)) variables.put(variable, false);
								 	 if(dim) dimension.add(variable);}
<INIT>			{EQUAL}				{variables.put(variable, true ); yybegin(WAIT);}
<INIT>			{NUM}				{fin=true;}
<INIT>			\(					{par=1; yybegin(WAIT_ARRAY);}
<INIT>			{SPACE}				{}
<INIT>			\&{SPACE}*\n		{}
<INIT>			\n[\ ]{1,5}{SIMBOL}	{}
<INIT>			\n					{dim=false; isIntentIn=false; isIntentOut=false; isParameter=false; if(fin)yybegin(NEW_LINE);}
<INIT>			.					{fin=true;}

/************************/
/* DECLARATION STATE    */
/************************/
<DECLARATION>	{TYPE}				{location = yytext(); yybegin(NAMING);}
<DECLARATION>	{STRING}	        {}
<DECLARATION>	{DIMENSION}		    {dim=true;}
<DECLARATION>	{PARAMETER}		    {isParameter=true;}
<DECLARATION>	{INTENTIN}		    {dim=false; isIntentIn=true;}
<DECLARATION>	{INTENTOUT}		    {dim=false; isIntentOut=true;}
<DECLARATION>	{INTENTINOUT}	    {dim=false; isIntentIn=true;}
<DECLARATION>	{INTENT}		    {dim=false; yybegin(COMMENT);}
<DECLARATION>	\:\:			    {yybegin(INIT);}
<DECLARATION>	{VAR}[\ ]* \(		{variable = yytext().substring(0, yytext().length()-1).trim();  
										 String v = variable.toLowerCase();
										 if(!fortranKeywords.contains(v) && !fortranIntrinsics.contains(v)) {
										     if(!variables.containsKey(variable))variables.put(variable, false); 
										     dimension.add(variable);
										 }}
<DECLARATION>	{VAR}				{String v = yytext().toLowerCase(); if(!fortranKeywords.contains(v) && !fortranIntrinsics.contains(v)) {if(!variables.containsKey(yytext())) variables.put(yytext(), false);}}
<DECLARATION>	{EQUAL}				{variables.put(variable, true ); yybegin(WAIT);}
<DECLARATION>	{NUM}				{}
<DECLARATION>	\&{SPACE}*\n		{}
<DECLARATION>	\n[\ ]{1,5}{SIMBOL}	{}
<DECLARATION>  	\n             		{yybegin(NEW_LINE);}
<DECLARATION>  	.              		{}

/************************/
/* WAIT STATE           */
/************************/
<WAIT>			{COMMENT_LINE}	{}
<WAIT>			{STRING}		{}
<WAIT>			\&{SPACE}*\n	{}
<WAIT>			\,				{yybegin(DECLARATION);}
<WAIT>			\n				{yybegin(NEW_LINE);}
<WAIT>			.				{}

/************************/
/* WAIT_ARRAY STATE     */
/************************/
<WAIT_ARRAY>		{COMMENT_LINE}	{}
<WAIT_ARRAY>		{STRING}		{}
<WAIT_ARRAY>		\(				{par++;}
<WAIT_ARRAY>		\)				{par--; if(par==0) yybegin(DECLARATION);}
<WAIT_ARRAY>		[^] 			{}

/************************/
/* DATA STATE           */
/************************/
<DATA>			{COMMENT_LINE}		{}
<DATA>			{STRING}			{}
<DATA>			{VAR}				{
										if (firstCall){
										 nameType=yytext();
										 firstCall=false;
										}	
										if(isCall){
										    final String var = yytext();
											addVariableByCallType(nameType, var, location,yyline +1);
										}						
										variables.put(yytext(), true)
										; fin=true;
									}
<DATA>			{SPACE}				{}
<DATA>			\&{SPACE}*\n		{}
<DATA>			\n[\ ]{1,5}{SIMBOL}	{}
<DATA>   		\n             		{isCall=false;yybegin(NEW_LINE);}  
<DATA>			.					{}

/************************/
/* FUNC STATE           */
/************************/
<FUNC>			{COMMENT_LINE}	{}
<FUNC>			{STRING}		{}
<FUNC>			{VAR}			{String var = yytext();
								 if(variables.containsKey(var)) variables.put(var, true);}
<FUNC>			\(				{par++;}
<FUNC>			\)				{par--; if(par==0) yybegin(LINE);}
<FUNC>			[^] 			{}

/************************/
/* ARRAY STATE           */
/************************/
<ARRAY>			{COMMENT_LINE}	{}
<ARRAY>			{STRING}		{}
<ARRAY>			{VAR}			{String var = yytext();
								 Boolean init = variables.get(var);
								 if(init != null && !init) setError(location,"The variable " + var + " is used before being initialized. ", yyline+1); }
<ARRAY>			\(				{par++;}
<ARRAY>			\)				{par--; if(par==0) yybegin(LINE);}
<ARRAY>			[^] 			{}

/************************/
/* VAR_EQ STATE         */
/************************/
<VAR_EQ>		{COMMENT_LINE}	{}
<VAR_EQ>		{STRING}		{}
<VAR_EQ>	    {SEE_FUNC}		{}
<VAR_EQ>		{VAR_PAR}		{String var = yytext().substring(0,yytext().length()-1).trim();
								 if (!dimension.contains(var)) { par = 1; yybegin(FUNC);}  }
<VAR_EQ>		{VAR}{SPACE}*\=		{String v = yytext().replaceAll("[\\s=]", ""); variables.put(v, true); initialized = true;}
<VAR_EQ>		{VAR}			{variable = yytext(); initialized = false;}
<VAR_EQ>		{POINTER_ASSIGN} 	{initialized = true;
							 variables.put(variable, true ); yybegin(AVOID);}
<VAR_EQ>		{EQUAL} 		{initialized = true;
								 variables.put(variable, true ); }
<VAR_EQ>		{COMP}          {}
<VAR_EQ>		{SPACE}			{}
<VAR_EQ>		{NUM}|{POINT}	{}
<VAR_EQ>		\n				{if(!initialized) {
									Boolean init = variables.get(variable);
									if(init != null && !init) setError(location,"The variable " + variable + " is used before being initialized. ", yyline+1);
								 } 
								 initialized = false;
								 yybegin(NEW_LINE);}
<VAR_EQ>		.				{if(!initialized) {
									Boolean init = variables.get(variable);
									if(init != null && !init) setError(location,"The variable " + variable + " is used before being initialized. ", yyline+1);
								 } 
								 initialized = false; variable = yytext();
								}

/************************/
/* USE_STATE            */
/************************/
<USE_STATE>		{COMMENT_LINE}		{}
<USE_STATE>		"only"{SPACE}*":"	{hasOnly = true;}
<USE_STATE>		{VAR}				{variables.put(yytext(), true);}
<USE_STATE>		\&{SPACE}*\n		{}
<USE_STATE>		\n					{if(!hasOnly) useWithoutOnly = true; yybegin(NEW_LINE);}
<USE_STATE>		.					{}

/************************/
/* ERROR STATE	        */
/************************/
				[^]            {
                                    
				                    final String errorMessage = "Analysis failure : Your file could not be analyzed. Please verify that it was encoded in an UNIX format.";
				                    throw new JFlexException(this.getClass().getName(), parsedFileName,
				                                    errorMessage, yytext(), yyline, yycolumn);
                                }