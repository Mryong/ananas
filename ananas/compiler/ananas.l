%{
	#include <Foundation/Foundation.h>
	#include "ananasc.h"
	#include "y.tab.h"
	#import "NACExpression.h"
	
	extern int line_number;

int yywrap(){
	return 1;
}
%}
%start C_COMMENT CC_COMMENT STRING_LITERAL_STATE
%%
<INITIAL>":" {return COLON; }
<INITIAL>"^" {return POWER; }
<INITIAL>"," {return COMMA ;}
<INITIAL>";" {return SEMICOLON; }
<INITIAL>"<" {return LA; }
<INITIAL>">" {return RA; }
<INITIAL>"(" {return LP; }
<INITIAL>")" {return RP; }
<INITIAL>"[" {return LB; }
<INITIAL>"]" {return RB; }
<INITIAL>"{" {return LC; }
<INITIAL>"}" {return RC; }
<INITIAL>"?" {return QUESTION; }
<INITIAL>"." { return DOT; }
<INITIAL>"@" { return AT; }


<INITIAL>"&&" {return AND; }
<INITIAL>"||" {return OR; }
<INITIAL>"!" {return NOT; }

<INITIAL>"==" {return EQ; }
<INITIAL>"!=" {return NE; }
<INITIAL>"<" {return LT; }
<INITIAL>"<=" {return LE; }
<INITIAL>">" {return GT; }
<INITIAL>">=" {return GE; }   


<INITIAL>"-" {return MINUS; }
<INITIAL>"+" {return PLUS; }
<INITIAL>"*" {return ASTERISK; }
<INITIAL>"/" {return DIV; }
<INITIAL>"%" {return MOD; }

<INITIAL>"-=" {return MINUS_ASSIGN; }
<INITIAL>"+=" {return PLUS_ASSIGN; }
<INITIAL>"*=" {return ASTERISK_ASSIGN; }
<INITIAL>"/=" {return DIV_ASSIGN; }
<INITIAL>"%=" {return MOD_ASSIGN; }


<INITIAL>"&" {return ADDRESS; }

<INITIAL>"=" {return ASSIGN; }



<INITIAL>"++" { return INCREMENT; }
<INITIAL>"--" { return DECREMENT; }

      
<INITIAL>"declare"  {return DECLARE; }
<INITIAL>"struct"  {return STRUCT; }
<INITIAL>"class"  {return CLASS; }


<INITIAL>"if"  {return IF; }
<INITIAL>"else"  {return ELSE; }
<INITIAL>"for"  {return FOR; }
<INITIAL>"while"  {return WHILE; }
<INITIAL>"do"  {return DO; }
<INITIAL>"switch"  {return SWITCH; }
<INITIAL>"case"  {return CASE; }
<INITIAL>"default"  {return DEFAULT; }
<INITIAL>"break"  {return BREAK; }
<INITIAL>"continue"  {return CONTINUE; }
<INITIAL>"return" {return RETURN; }



          




<INITIAL>"@property" {return PROPERTY; }
<INITIAL>"weak" {return WEAK; }
<INITIAL>"strong" {return STRONG; }
<INITIAL>"copy" {return COPY; }
<INITIAL>"assign" {return ASSIGN_MEM; }
<INITIAL>"nonatomic" {return NONATOMIC; }
<INITIAL>"atomic" {return ATOMIC; }

<INITIAL>"BOOL" {return BOOL_; }
<INITIAL>"NSInteger" {return NS_INTEGER; }
<INITIAL>"NSUInteger" {return NS_U_INTEGER; }
<INITIAL>"CGFloat" {return CG_FLOAT; }
<INITIAL>"double" {return DOUBLE; }

<INITIAL>"CGRect" {return CG_RECT; }
<INITIAL>"CGSize" {return CG_SIZE; }
<INITIAL>"CGPoint" {return CG_POINT; }
<INITIAL>"CGAffineTransform" {return CG_AFFINE_TRANSFORM; }
<INITIAL>"NSRange" {return NS_RANGE; }

<INITIAL>"NSString" {return NS_STRING; }
<INITIAL>"NSNumber" {return NS_NUMBER; }
<INITIAL>"NSArray" {return NS_ARRAY; }
<INITIAL>"NSMutableArray" {return NS_MUTABLE_ARRAY; }
<INITIAL>"NSDictionary" {return NS_DICTIONARY; }
<INITIAL>"NSMutableDictionary" {return NS_MUTABLE_DICTIONARY; }
<INITIAL>"id" {return ID; }

<INITIAL>"self" {return SELF; }
<INITIAL>"super" {return SUPER; }
<INITIAL>"nil" {return NIL; }
<INITIAL>"YES" {return YES_; }
<INITIAL>"NO" {return NO_; }



<INITIAL>[A-Za-z_][A-Za-z_0-9]* {
	NSString *identifier = anc_create_identifier(yytext);
	yylval.identifier = (__bridge_retained void *)identifier;
	return IDENTIFIER;
}



<INITIAL>[1-9][0-9]* {
	NACExpression *expression = anc_create_expression(NAC_INT_EXPRESSION);
	NSInteger val;
	sscanf(yytext,"%lx",&val);
	expression.integer_value = val;
	yylval.expression = (__bridge_retained void *)expression;
	return INTETER_LITERAL;
}



<INITIAL>"0"[xX][0-9a-fA-F]+ {
	NACExpression *expression = anc_create_expression(NAC_INT_EXPRESSION);
	NSInteger val;
	sscanf(yytext,"%lx",&val);
	expression.integer_value = val;
	yylval.expression = (__bridge_retained void *)expression;
	return INTETER_LITERAL;
}


<INITIAL>"0" {
	NACExpression *expression = anc_create_expression(NAC_INT_EXPRESSION);
	expression.integer_value = 0;
	yylval.expression = (__bridge_retained void *)expression;
	return INTETER_LITERAL;
}


<INITIAL>[0-9]\.[0-9]+ {
	NACExpression *expression = anc_create_expression(NAC_DOUBLE_EXPRESSION);
	double val;
	sscanf(yytext,"%lf",&val);
	expression.double_value = val;
	yylval.expression = (__bridge_retained void *)expression;
	return DOUBLE_LITERAL;
}

<INITIAL>\" {
	anc_open_string_literal_buf();
	BEGIN STRING_LITERAL_STATE;
}


<STRING_LITERAL_STATE>\" {
	NACExpression *expression = anc_create_expression(NAC_STRING_EXPRESSION);
	expression.string_value = anc_end_string_literal();
	yylval.expression = (__bridge_retained void *)expression;
	BEGIN  INITIAL;
	return STRING_LITERAL;
}

<STRING_LITERAL_STATE>. {
	anc_append_string_literal(yytext[0]);
} 


<STRING_LITERAL_STATE>\\\"  { anc_append_string_literal('\"'); }
<STRING_LITERAL_STATE>\\n	{ anc_append_string_literal('\"'); }
<STRING_LITERAL_STATE>\\t	{ anc_append_string_literal('\t'); }
<STRING_LITERAL_STATE>\\\\	{ anc_append_string_literal('\\'); }
<STRING_LITERAL_STATE>[\x81-\x9f\xe0-\xef][\x40-\x7e\x80-\xfc] {
	anc_append_string_literal(yytext[0]);
	anc_append_string_literal(yytext[1]);
}



<INITIAL>"//" { BEGIN CC_COMMENT; }
<CC_COMMENT>\n { line_number++; BEGIN INITIAL; }
<CC_COMMENT>. ;

<INITIAL>[ \t]+  ;
<INITIAL>[\n]  { line_number++; };
<INITIAL>.  ;
%%


