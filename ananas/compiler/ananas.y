%{
	#define YYDEBUG 1
	#define YYERROR_VERBOSE
	#import <Foundation/Foundation.h>
	#import "ananasc.h"
	#import "anc_ast.h"

int yyerror(char const *str);
int yylex(void);

%}

%union{
	void	*identifier;
	void	*expression;
	void	*statement;
	void	*dic_entry;
	void	*type_specifier;
	void	*one_case;
	void	*else_if;
	void	*class_definition;
	void	*declare_struct;
	void	*member_definition;
	void	*block_statement;
	void	*list;
	void	*method_name_item;
	void	*function_param;
	void	*declaration;
	ANCAssignKind assignment_operator;
	ANCPropertyModifier property_modifier_list;



}

%token <identifier> IDENTIFIER
%token <expression> DOUBLE_LITERAL
%token <expression> STRING_LITERAL
%token <expression> INTETER_LITERAL
%token <expression> SELF
%token <expression> SUPER
%token <expression> NIL
%token <expression> YES_
%token <expression> NO_

%token COLON SEMICOLON COMMA  LA RA LP RP LB RB LC RC  QUESTION DOT ASSIGN AT POWER
	AND OR NOT EQ NE LT LE GT GE MINUS MINUS_ASSIGN PLUS PLUS_ASSIGN MUL MUL_ASSIGN DIV DIV_ASSIGN MOD MOD_ASSIGN INCREMENT DECREMENT
	CLASS STRUCT DECLARE
	RETURN IF ELSE FOR WHILE DO SWITCH CASE DEFAULT BREAK CONTINUE 
	PROPERTY WEAK STRONG COPY ASSIGN_MEM NONATOMIC ATOMIC  ADDRESS ASTERISK ASTERISK_ASSIGN VOID
	BOOL_ NS_INTEGER NS_U_INTEGER  CG_FLOAT  DOUBLE CHAR NS_STRING NS_NUMBER NS_ARRAY NS_MUTABLE_ARRAY NS_DICTIONARY NS_MUTABLE_DICTIONARY ID
	CG_RECT CG_SIZE CG_POINT CG_AFFINE_TRANSFORM NS_RANGE

%type <assignment_operator> assignment_operator
%type <expression> expression expression_opt assign_expression ternary_operator_expression logic_or_expression logic_and_expression  
equality_expression relational_expression additive_expression multiplication_expression unary_expression postfix_expression
primary_expression dic block_body

%type <identifier> label_opt identifier_opt struct_name selector selector_1 selector_2

%type <list> identifier_list dic_entry_list statement_list type_specifier_list protocol_list else_if_list case_list member_definition_list
method_name method_name_1 method_name_2 expression_list function_param_list 

%type <method_name_item> method_name_item
%type <dic_entry> dic_entry
%type <statement> statement if_statement switch_statement for_statement foreach_statement while_statement do_while_statement
break_statement continue_statement return_statement declaration_statement
%type <type_specifier> type_specifier non_block_type_specifier base_type_specifier oc_type_specifier struct_type_specifier custom_type_specifier block_type_specifier
%type <block_statement> block_statement default_opt
%type <declare_struct> declare_struct
%type <property_modifier_list> property_modifier_list property_modifier property_rc_modifier  property_atomic_modifier
%type <class_definition> class_definition
%type <member_definition> member_definition property_definition method_definition class_method_definition instance_method_definition
%type <one_case> one_case
%type <else_if> else_if
%type <function_param> function_param
%type <declaration> declaration
%%

compile_util: /*empty*/
			| definition_list
			;


definition_list: definition
			| definition_list definition
			;

definition:  class_definition
			{
				ANCClassDefinition *classDefinition = (__bridge_transfer ANCClassDefinition *)$1;
				anc_add_class_definition(classDefinition);
			}
			| declare_struct
			{
				ANCStructDeclare *structDeclare = (__bridge_transfer ANCStructDeclare *)$1;
				anc_add_struct_declare(structDeclare);
			}
			| statement
			{
				ANCStatement *statement = (__bridge_transfer ANCStatement *)$1;
				anc_add_statement(statement);
			}
			;

struct_name: IDENTIFIER
			| CG_RECT
			{
				$$ = (__bridge_retained void *)@"CGRect";
			}
			| CG_SIZE
			{
				$$ = (__bridge_retained void *)@"CGSzie";
			}
			| CG_POINT
			{
				$$ = (__bridge_retained void *)@"CGPoint";
			}
			| CG_AFFINE_TRANSFORM
			{
				$$ = (__bridge_retained void *)@"CGAffineTransform";
			}
			| NS_RANGE
			{
				$$ = (__bridge_retained void *)@"NSRange";
			}
			;

declare_struct: DECLARE STRUCT struct_name LC
			IDENTIFIER COLON STRING_LITERAL COMMA
			IDENTIFIER COLON identifier_list
			RC
			{
				NSString *structName = (__bridge_transfer NSString *)$3;
				NSString *typeEncodingKey = (__bridge_transfer NSString *)$5;
				NSString *typeEncodingValue = (__bridge_transfer NSString *)$7;
				NSString *keysKey = (__bridge_transfer NSString *)$9;
				NSArray *keysValue = (__bridge_transfer NSArray *)$11;
				ANCStructDeclare *structDeclare = anc_create_struct_declare(structName, typeEncodingKey, typeEncodingValue, keysKey, keysValue);
				$$ = (__bridge_retained void *)structDeclare;
				
			}
			| DECLARE STRUCT struct_name LC
			IDENTIFIER COLON identifier_list COMMA
			IDENTIFIER COLON STRING_LITERAL
			RC
			{
				NSString *structName = (__bridge_transfer NSString *)$3;
				NSString *keysKey = (__bridge_transfer NSString *)$5;
				NSArray *keysValue = (__bridge_transfer NSArray *)$7;
				NSString *typeEncodingKey = (__bridge_transfer NSString *)$9;
				NSString *typeEncodingValue = (__bridge_transfer NSString *)$11;
				ANCStructDeclare *structDeclare = anc_create_struct_declare(structName, typeEncodingKey, typeEncodingValue, keysKey, keysValue);
				$$ = (__bridge_retained void *)structDeclare;
				
			}
			;

identifier_list: IDENTIFIER
			{
				NSMutableArray *list = [NSMutableArray array];
				NSString *identifier = (__bridge_transfer NSString *)$1;
				[list addObject:identifier];
				$$ = (__bridge_retained void *)list;
				
			}
			| identifier_list COMMA IDENTIFIER
			{
				NSMutableArray *list = (__bridge_transfer NSMutableArray *)$1;
				NSString *identifier = (__bridge_transfer NSString *)$3;
				[list addObject:identifier];
				$$ = (__bridge_retained void *)list;
			}
			;




class_definition: CLASS IDENTIFIER COLON IDENTIFIER LC RC
			{
				NSString *name = (__bridge_transfer NSString *)$2;
				NSString *superNmae = (__bridge_transfer NSString *)$4;
				ANCClassDefinition *classDefinition = anc_create_class_definition(name, superNmae,nil, nil);
				$$ = (__bridge_retained void *)classDefinition;
			}
			| CLASS IDENTIFIER COLON IDENTIFIER LC member_definition_list RC
			{
				NSString *name = (__bridge_transfer NSString *)$2;
				NSString *superNmae = (__bridge_transfer NSString *)$4;
				NSArray *members = (__bridge_transfer NSArray *)$6;
				ANCClassDefinition *classDefinition = anc_create_class_definition(name, superNmae,nil, members);
				$$ = (__bridge_retained void *)classDefinition;
			}
			| CLASS IDENTIFIER COLON IDENTIFIER LA protocol_list RA LC RC
			{
				NSString *name = (__bridge_transfer NSString *)$2;
				NSString *superNmae = (__bridge_transfer NSString *)$4;
				NSArray *protocolNames = (__bridge_transfer NSArray *)$6;
				ANCClassDefinition *classDefinition = anc_create_class_definition(name, superNmae,protocolNames, nil);
				$$ = (__bridge_retained void *)classDefinition;
			}
			| CLASS IDENTIFIER COLON IDENTIFIER LA protocol_list RA LC member_definition_list RC
			{
				NSString *name = (__bridge_transfer NSString *)$2;
				NSString *superNmae = (__bridge_transfer NSString *)$4;
				NSArray *protocolNames = (__bridge_transfer NSArray *)$6;
				NSArray *members = (__bridge_transfer NSArray *)$9;
				ANCClassDefinition *classDefinition = anc_create_class_definition(name, superNmae,protocolNames, members);
				$$ = (__bridge_retained void *)classDefinition;
			}
			;

protocol_list: IDENTIFIER
			{
				NSMutableArray *list = [NSMutableArray array];
				NSString *identifier = (__bridge_transfer NSString *)$1;
				[list addObject:identifier];
				$$ = (__bridge_retained void *)list;
			}
			| protocol_list COMMA IDENTIFIER
			{
				NSMutableArray *list = (__bridge_transfer NSMutableArray *)$1;
				NSString *identifier = (__bridge_transfer NSString *)$3;
				[list addObject:identifier];
				$$ = (__bridge_retained void *)list;
			}
			;


property_definition: PROPERTY LP property_modifier_list RP type_specifier IDENTIFIER  SEMICOLON
			{
				ANCPropertyModifier modifier = $3;
				ANCTypeSpecifier *typeSpecifier = (__bridge_transfer ANCTypeSpecifier *)$5;
				NSString *name = (__bridge_transfer NSString *)$6;
				ANCPropertyDefinition *propertyDefinition = anc_create_property_definition(modifier, typeSpecifier, name);
				$$ = (__bridge_retained void *)propertyDefinition;
			}
			| PROPERTY LP  RP type_specifier IDENTIFIER SEMICOLON
			{
				ANCTypeSpecifier *typeSpecifier = (__bridge_transfer ANCTypeSpecifier *)$4;
				NSString *name = (__bridge_transfer NSString *)$5;
				ANCPropertyDefinition *propertyDefinition = anc_create_property_definition(0x00, typeSpecifier, name);
				$$ = (__bridge_retained void *)propertyDefinition;
			}
			;



property_modifier_list: property_modifier
			| property_modifier_list COMMA property_modifier
			{
				$$ = $1 | $3;
			}
			;


property_modifier: property_rc_modifier
				| property_atomic_modifier
			;

property_rc_modifier: WEAK
			{
				$$ = ANCPropertyModifierMemWeak;
			}
			| STRONG
			{
				$$ = ANCPropertyModifierMemStrong;
			}
			| COPY
			{
				$$ = ANCPropertyModifierMemCopy;
			}
			| ASSIGN_MEM
			{
				$$ = ANCPropertyModifierMemAssign;
			}
			;

property_atomic_modifier: NONATOMIC
			{
				$$ = ANCPropertyModifierNonatomic;
			}
			| ATOMIC
			{
				$$ = ANCPropertyModifierAtomic;
			}
			;


type_specifier: non_block_type_specifier
			| block_type_specifier
			;

type_specifier_list: type_specifier
			{
				NSMutableArray *list = [NSMutableArray array];
				ANCTypeSpecifier *type_specifier = (__bridge_transfer ANCTypeSpecifier *)$1;
				[list addObject:type_specifier];
				$$ = (__bridge_retained void *)list;
			}
			| type_specifier_list COMMA type_specifier
			{
				NSMutableArray *list = (__bridge_transfer NSMutableArray *)$1;
				ANCTypeSpecifier *type_specifier = (__bridge_transfer ANCTypeSpecifier *)$3;
				[list addObject:type_specifier];
				$$ = (__bridge_retained void *)list;
			}
			;



non_block_type_specifier: base_type_specifier
			| struct_type_specifier
			| oc_type_specifier
			| custom_type_specifier
			;



block_type_specifier: IDENTIFIER LP POWER  RP LP type_specifier_list RP
			{
				NSString *identifier = (__bridge_transfer NSString *)$1;
				ANCTypeSpecifier *returnTypeSpecifier = anc_create_type_specifier(ANC_TYPE_UNKNOWN,identifier,@"^v");
				NSArray *type_specifier_list = (__bridge_transfer NSArray *)$6;
				ANCTypeSpecifier * block_type_specifier = anc_create_block_type_specifier(returnTypeSpecifier,type_specifier_list);
				$$ = (__bridge_retained void *)block_type_specifier;
			}
			|  type_specifier LP POWER  RP LP type_specifier_list RP
			{
				ANCTypeSpecifier *returnTypeSpecifier = (__bridge_transfer ANCTypeSpecifier *)$1;
				NSArray *type_specifier_list = (__bridge_transfer NSArray *)$6;
				ANCTypeSpecifier * block_type_specifier = anc_create_block_type_specifier(returnTypeSpecifier,type_specifier_list);
				$$ = (__bridge_retained void *)block_type_specifier;
			}
			;


base_type_specifier: VOID
			{
				ANCTypeSpecifier *typeSpecifier = anc_create_type_specifier(ANC_TYPE_VOID,@"void",@"v");
				$$ = (__bridge_retained void *)typeSpecifier;
			}
			| BOOL_
			{
				ANCTypeSpecifier *typeSpecifier = anc_create_type_specifier(ANC_TYPE_BOOL,@"BOOL",@"B");
				$$ = (__bridge_retained void *)typeSpecifier;
			}
			| NS_INTEGER
			{
				ANCTypeSpecifier *typeSpecifier = anc_create_type_specifier(ANC_TYPE_NS_INTEGER,@"NSInteger",@"q");
				$$ = (__bridge_retained void *)typeSpecifier;
			}
			| NS_U_INTEGER
			{
				ANCTypeSpecifier *typeSpecifier = anc_create_type_specifier(ANC_TYPE_NS_U_INTEGER,@"NSUInteger",@"Q");
				$$ = (__bridge_retained void *)typeSpecifier;
			}
			| CG_FLOAT
			{
				ANCTypeSpecifier *typeSpecifier = anc_create_type_specifier(ANC_TYPE_CG_FLOAT,@"CGFloat",@"d");
				$$ = (__bridge_retained void *)typeSpecifier;
			}
			| DOUBLE
			{
				ANCTypeSpecifier *typeSpecifier = anc_create_type_specifier(ANC_TYPE_DOUBLE,@"long double",@"D");
				$$ = (__bridge_retained void *)typeSpecifier;
			}
			| CHAR ASTERISK
			{
				ANCTypeSpecifier *typeSpecifier = anc_create_type_specifier(ANC_TYPE_STRING,@"char *",@"*");
				$$ = (__bridge_retained void *)typeSpecifier;
			}
			;

struct_type_specifier: CG_RECT
			{
				ANCTypeSpecifier *typeSpecifier = anc_create_type_specifier(ANC_TYPE_STRUCT,@"CGRect",@"{CGRect={CGPoint=dd}{CGSize=dd}}");
				$$ = (__bridge_retained void *)typeSpecifier;
			}
			| CG_SIZE
			{
				ANCTypeSpecifier *typeSpecifier = anc_create_type_specifier(ANC_TYPE_STRUCT,@"CGSzie",@"{CGSize=dd}");
				$$ = (__bridge_retained void *)typeSpecifier;
			}
			| CG_POINT
			{
				ANCTypeSpecifier *typeSpecifier = anc_create_type_specifier(ANC_TYPE_STRUCT,@"CGPointer",@"{CGPoint=dd}");
				$$ = (__bridge_retained void *)typeSpecifier;
			}
			| CG_AFFINE_TRANSFORM
			{
				ANCTypeSpecifier *typeSpecifier = anc_create_type_specifier(ANC_TYPE_STRUCT,@"CGAffineTransform",@"{CGAffineTransform=dddddd}");
				$$ = (__bridge_retained void *)typeSpecifier;
			}
			| NS_RANGE
			{
				ANCTypeSpecifier *typeSpecifier = anc_create_type_specifier(ANC_TYPE_STRUCT,@"NSRange",@"{_NSRange=QQ}");
				$$ = (__bridge_retained void *)typeSpecifier;
			}
			;

oc_type_specifier: NS_STRING ASTERISK
			{
				ANCTypeSpecifier *typeSpecifier = anc_create_type_specifier(ANC_TYPE_OC,@"NSString",@"@");
				$$ = (__bridge_retained void *)typeSpecifier;
			}
			| NS_NUMBER ASTERISK
			{
				ANCTypeSpecifier *typeSpecifier = anc_create_type_specifier(ANC_TYPE_OC,@"NSNumber",@"@");
				$$ = (__bridge_retained void *)typeSpecifier;
			}
			| NS_ARRAY ASTERISK
			{
				ANCTypeSpecifier *typeSpecifier = anc_create_type_specifier(ANC_TYPE_OC,@"NSArray",@"@");
				$$ = (__bridge_retained void *)typeSpecifier;
			}
			| NS_MUTABLE_ARRAY ASTERISK
			{
				ANCTypeSpecifier *typeSpecifier = anc_create_type_specifier(ANC_TYPE_OC,@"NSMutableArray",@"@");
				$$ = (__bridge_retained void *)typeSpecifier;
			}
			| NS_DICTIONARY ASTERISK
			{
				ANCTypeSpecifier *typeSpecifier = anc_create_type_specifier(ANC_TYPE_OC,@"NSDictionary",@"@");
				$$ = (__bridge_retained void *)typeSpecifier;
			}
			| NS_MUTABLE_DICTIONARY ASTERISK
			{
				ANCTypeSpecifier *typeSpecifier = anc_create_type_specifier(ANC_TYPE_OC,@"NSMutableDictionary",@"@");
				$$ = (__bridge_retained void *)typeSpecifier;
			}
			| IDENTIFIER ASTERISK
			{
				NSString *identifier = (__bridge_transfer NSString *)$1;
				ANCTypeSpecifier *typeSpecifier = anc_create_type_specifier(ANC_TYPE_OC,identifier,@"@");
				$$ = (__bridge_retained void *)typeSpecifier;
			}
			| ID
			{
				ANCTypeSpecifier *typeSpecifier = anc_create_type_specifier(ANC_TYPE_OC,@"id",@"@");
				$$ = (__bridge_retained void *)typeSpecifier;
			}
			;


custom_type_specifier: IDENTIFIER
			{
				NSString *identifier = (__bridge_transfer NSString *)$1;
				$$ = (__bridge_retained void *)anc_create_type_specifier(ANC_TYPE_UNKNOWN,identifier,@"^v");
			}
			;




method_definition: instance_method_definition
			| class_method_definition
			;

instance_method_definition: MINUS LP type_specifier RP method_name block_statement
			{
				ANCTypeSpecifier *returnTypeSpecifier = (__bridge_transfer ANCTypeSpecifier *)$3;
				NSArray *items = (__bridge_transfer NSArray *)$5;
				ANCBlock *block = (__bridge_transfer ANCBlock *)$6;
				ANCMethodDefinition *methodDefinition = anc_create_method_definition(NO, returnTypeSpecifier, items, block);
				$$ = (__bridge_retained void *)methodDefinition;
			}
			;

class_method_definition: PLUS LP type_specifier RP method_name  block_statement
			{
				ANCTypeSpecifier *returnTypeSpecifier = (__bridge_transfer ANCTypeSpecifier *)$3;
				NSArray *items = (__bridge_transfer NSArray *)$5;
				ANCBlock *block = (__bridge_transfer ANCBlock *)$6;
				ANCMethodDefinition *methodDefinition = anc_create_method_definition(YES, returnTypeSpecifier, items, block);
				$$ = (__bridge_retained void *)methodDefinition;
			}
			;	

method_name: method_name_1
			| method_name_2
			;		

method_name_1: IDENTIFIER
			{
				NSString *name = (__bridge_transfer NSString *)$1;
				ANCMethodNameItem *item = anc_create_method_name_item(name, nil, nil);
				NSMutableArray *list = [NSMutableArray array];
				[list addObject:item];
				$$ = (__bridge_retained void *)list;
			}
			;

method_name_2: method_name_item
			{
				NSMutableArray *list = [NSMutableArray array];
				ANCMethodNameItem *item = (__bridge_transfer ANCMethodNameItem *)$1;
				[list addObject:item];
				$$ = (__bridge_retained void *)list;
			}
			| method_name_2 method_name_item
			{
				NSMutableArray *list = (__bridge_transfer NSMutableArray *)$1;
				ANCMethodNameItem *item = (__bridge_transfer ANCMethodNameItem *)$2;
				[list addObject:item];
				$$ = (__bridge_retained void *)list;
			}
			;

method_name_item: IDENTIFIER COLON LP type_specifier RP IDENTIFIER
			{
				NSString *name = (__bridge_transfer NSString *)$1;
				name = [NSString stringWithFormat:@"%@:",name];
				ANCTypeSpecifier *typeSpecifier = (__bridge_transfer ANCTypeSpecifier *)$4;
				NSString *paramName = (__bridge_transfer NSString *)$6;
				ANCMethodNameItem *item = anc_create_method_name_item(name, typeSpecifier, paramName);
				$$ = (__bridge_retained void *)item;
			}
		;

member_definition: property_definition
			| method_definition
			;
		
member_definition_list: member_definition
			{
				NSMutableArray *list = [NSMutableArray array];
				ANCMemberDefinition *memberDefinition = (__bridge_transfer ANCMemberDefinition *)$1;
				[list addObject:memberDefinition];
				$$ = (__bridge_retained void *)list;
			}
			| member_definition_list member_definition
			{
				NSMutableArray *list = (__bridge_transfer NSMutableArray *)$1;
				ANCMemberDefinition *memberDefinition = (__bridge_transfer ANCMemberDefinition *)$2;
				[list addObject:memberDefinition];
				$$ = (__bridge_retained void *)list;
			}
			;

selector: selector_1
			| selector_2
			;

selector_1: IDENTIFIER
			;

selector_2: IDENTIFIER COLON
			{
				NSString *name = (__bridge_transfer NSString *)$1;
				NSString *selector = [NSString stringWithFormat:@"%@:",name];
				$$ = (__bridge_retained void *)selector;
			}
			| selector_2 IDENTIFIER COLON
			{
				NSString *name1 = (__bridge_transfer NSString *)$1;
				NSString *name2 = (__bridge_transfer NSString *)$2;
				NSString *selector = [NSString stringWithFormat:@"%@%@:", name1, name2];
				$$ = (__bridge_retained void *)selector;
			}
			;

expression: assign_expression
			;
	
assign_expression:  ternary_operator_expression
			| primary_expression assignment_operator ternary_operator_expression
			{
				ANCAssignExpression *expr = (ANCAssignExpression *)anc_create_expression(ANC_ASSIGN_EXPRESSION);
				expr.assignKind = $2;
				expr.left = (__bridge_transfer ANCExpression *)$1;
				expr.right = (__bridge_transfer ANCExpression *)$3;
				$$ = (__bridge_retained void *)expr;
			}
			;

assignment_operator: ASSIGN
				{
					$$ = ANC_NORMAL_ASSIGN;
					
				}
                | MINUS_ASSIGN
				{
					$$ = ANC_MINUS_ASSIGN;
				}
                | PLUS_ASSIGN
				{
					$$ = ANC_PLUS_ASSIGN;
				}
                | MUL_ASSIGN
				{
					$$ = ANC_MUL_ASSIGN;
				}
                | DIV_ASSIGN
				{
					$$ = ANC_DIV_ASSIGN;
				}
                | MOD_ASSIGN
				{
					$$ = ANC_MOD_ASSIGN;
				}
                ;

ternary_operator_expression: logic_or_expression
 			| logic_or_expression  QUESTION ternary_operator_expression  COLON ternary_operator_expression
			{
				ANCTernaryExpression *expr = (ANCTernaryExpression *)anc_create_expression(ANC_TERNARY_EXPRESSION);
				expr.condition = (__bridge_transfer ANCExpression *)$1;
				expr.trueExpr = (__bridge_transfer ANCExpression *)$3;
				expr.falseExpr = (__bridge_transfer ANCExpression *)$5;
				$$ = (__bridge_retained void *)expr;
			}
			| logic_or_expression  QUESTION COLON ternary_operator_expression
			{
				ANCTernaryExpression *expr = (ANCTernaryExpression *)anc_create_expression(ANC_TERNARY_EXPRESSION);
				expr.condition = (__bridge_transfer ANCExpression *)$1;
				expr.falseExpr = (__bridge_transfer ANCExpression *)$4;
				$$ = (__bridge_retained void *)expr;
			}
			;

logic_or_expression: logic_and_expression
			| logic_or_expression OR logic_and_expression
			{
				ANCBinaryExpression *expr = (ANCBinaryExpression *)anc_create_expression(ANC_LOGICAL_OR_EXPRESSION);
				expr.left = (__bridge_transfer ANCExpression *)$1;
				expr.right = (__bridge_transfer ANCExpression *)$3;
				$$ = (__bridge_retained void *)expr;
			}
			;

logic_and_expression: equality_expression
			| logic_and_expression AND equality_expression
			{
				ANCBinaryExpression *expr = (ANCBinaryExpression *)anc_create_expression(ANC_LOGICAL_AND_EXPRESSION);
				expr.left = (__bridge_transfer ANCExpression *)$1;
				expr.right = (__bridge_transfer ANCExpression *)$3;
				$$ = (__bridge_retained void *)expr;
			}
			;

equality_expression: relational_expression
			| equality_expression EQ relational_expression
			{
				ANCBinaryExpression *expr = (ANCBinaryExpression *)anc_create_expression(ANC_EQ_EXPRESSION);
				expr.left = (__bridge_transfer ANCExpression *)$1;
				expr.right = (__bridge_transfer ANCExpression *)$3;
				$$ = (__bridge_retained void *)expr;
			}
			| equality_expression NE relational_expression
			{
				ANCBinaryExpression *expr = (ANCBinaryExpression *)anc_create_expression(ANC_NE_EXPRESSION);
				expr.left = (__bridge_transfer ANCExpression *)$1;
				expr.right = (__bridge_transfer ANCExpression *)$3;
				$$ = (__bridge_retained void *)expr;
			}
			;

relational_expression: additive_expression
			| relational_expression LT additive_expression
			{
				ANCBinaryExpression *expr = (ANCBinaryExpression *)anc_create_expression(ANC_LT_EXPRESSION);
				expr.left = (__bridge_transfer ANCExpression *)$1;
				expr.right = (__bridge_transfer ANCExpression *)$3;
				$$ = (__bridge_retained void *)expr;
			}
			| relational_expression LE additive_expression
			{
				ANCBinaryExpression *expr = (ANCBinaryExpression *)anc_create_expression(ANC_LE_EXPRESSION);
				expr.left = (__bridge_transfer ANCExpression *)$1;
				expr.right = (__bridge_transfer ANCExpression *)$3;
				$$ = (__bridge_retained void *)expr;
			}
			| relational_expression GT additive_expression
			{
				ANCBinaryExpression *expr = (ANCBinaryExpression *)anc_create_expression(ANC_GT_EXPRESSION);
				expr.left = (__bridge_transfer ANCExpression *)$1;
				expr.right = (__bridge_transfer ANCExpression *)$3;
				$$ = (__bridge_retained void *)expr;
			}
			| relational_expression GE additive_expression
			{
				ANCBinaryExpression *expr = (ANCBinaryExpression *)anc_create_expression(ANC_GE_EXPRESSION);
				expr.left = (__bridge_transfer ANCExpression *)$1;
				expr.right = (__bridge_transfer ANCExpression *)$3;
				$$ = (__bridge_retained void *)expr;
			}
			;

additive_expression: multiplication_expression
			| additive_expression PLUS multiplication_expression
			{
				ANCBinaryExpression *expr = (ANCBinaryExpression *)anc_create_expression(ANC_PLUS_EXPRESSION);
				expr.left = (__bridge_transfer ANCExpression *)$1;
				expr.right = (__bridge_transfer ANCExpression *)$3;
				$$ = (__bridge_retained void *)expr;
			}
			| additive_expression MINUS multiplication_expression
			{
				ANCBinaryExpression *expr = (ANCBinaryExpression *)anc_create_expression(ANC_MINUS_EXPRESSION);
				expr.left = (__bridge_transfer ANCExpression *)$1;
				expr.right = (__bridge_transfer ANCExpression *)$3;
				$$ = (__bridge_retained void *)expr;
			}
			;

multiplication_expression: unary_expression
			| multiplication_expression ASTERISK unary_expression
			{
				ANCBinaryExpression *expr = (ANCBinaryExpression *)anc_create_expression(ANC_MUL_EXPRESSION);
				expr.left = (__bridge_transfer ANCExpression *)$1;
				expr.right = (__bridge_transfer ANCExpression *)$3;
				$$ = (__bridge_retained void *)expr;
			}
			| multiplication_expression DIV unary_expression
			{
				ANCBinaryExpression *expr = (ANCBinaryExpression *)anc_create_expression(ANC_DIV_EXPRESSION);
				expr.left = (__bridge_transfer ANCExpression *)$1;
				expr.right = (__bridge_transfer ANCExpression *)$3;
				$$ = (__bridge_retained void *)expr;
			}
			| multiplication_expression MOD unary_expression
			{
				ANCBinaryExpression *expr = (ANCBinaryExpression *)anc_create_expression(ANC_MOD_EXPRESSION);
				expr.left = (__bridge_transfer ANCExpression *)$1;
				expr.right = (__bridge_transfer ANCExpression *)$3;
				$$ = (__bridge_retained void *)expr;
			}
			;

unary_expression: postfix_expression
			| NOT unary_expression
			{
				ANCUnaryExpression *expr = (ANCUnaryExpression *)anc_create_expression(ANC_LOGICAL_NOT_EXPRESSION);
				ANCExpression *subExpr = (__bridge_transfer ANCExpression *)$2;
				expr.expr = subExpr;
				$$ = (__bridge_retained void *)expr;
			}
			| MINUS unary_expression
			{
				ANCUnaryExpression *expr = (ANCUnaryExpression *)anc_create_expression(NSC_NEGATIVE_EXPRESSION);
				ANCExpression *subExpr = (__bridge_transfer ANCExpression *)$2;
				expr.expr = subExpr;
				$$ = (__bridge_retained void *)expr;
			}
			;

postfix_expression: primary_expression
			| primary_expression INCREMENT
			{
				ANCUnaryExpression *expr = (ANCUnaryExpression *)anc_create_expression(ANC_INCREMENT_EXPRESSION);
				ANCExpression *subExpr = (__bridge_transfer ANCExpression *)$1;
				expr.expr = subExpr;
				$$ = (__bridge_retained void *)expr;
			}
			| primary_expression DECREMENT
			{
				ANCUnaryExpression *expr = (ANCUnaryExpression *)anc_create_expression(ANC_DECREMENT_EXPRESSION);
				ANCExpression *subExpr = (__bridge_transfer ANCExpression *)$1;
				expr.expr = subExpr;
				$$ = (__bridge_retained void *)expr;
			}
			;

expression_list: assign_expression
			{
				NSMutableArray *list = [NSMutableArray array];
				ANCExpression *expr = (__bridge_transfer ANCExpression *)$1;
				[list addObject:expr];
				$$ = (__bridge_retained void *)list;
			}
			| expression_list COMMA assign_expression
			{
				NSMutableArray *list = (__bridge_transfer NSMutableArray *)$1;
				ANCExpression *expr = (__bridge_transfer ANCExpression *)$3;
				[list addObject:expr];
				$$ = (__bridge_retained void *)list;
			}
			;

dic_entry: primary_expression COLON primary_expression
			{
				ANCExpression *keyExpr = (__bridge_transfer ANCExpression *)$1;
				ANCExpression *valueExpr = (__bridge_transfer ANCExpression *)$3;
				ANCDicEntry *dicEntry = anc_create_dic_entry(keyExpr, valueExpr);
				$$ = (__bridge_retained void *)dicEntry;
			}
			;

dic_entry_list: dic_entry
			{
				NSMutableArray *list = [NSMutableArray array];
				ANCDicEntry *dicEntry = (__bridge_transfer ANCDicEntry *)$1;
				[list addObject:dicEntry];
				$$ = (__bridge_retained void *)list;
			} 
			| dic_entry_list COMMA dic_entry
			{
				NSMutableArray *list = (__bridge_transfer NSMutableArray *)$1;
				ANCDicEntry *dicEntry = (__bridge_transfer ANCDicEntry *)$3;
				[list addObject:dicEntry];
				$$ = (__bridge_retained void *)list;
			}
			;

dic: AT LC  dic_entry_list RC
			{
				ANCDictionaryExpression *expr = (ANCDictionaryExpression *)anc_create_expression(ANC_DIC_LITERAL_EXPRESSION);
				NSArray *entriesExpr = (__bridge_transfer NSArray *)$3;
				expr.entriesExpr = entriesExpr;
				$$ = (__bridge_retained void *)expr;
			}
			| AT LC  RC
			{
				ANCDictionaryExpression *expr = (ANCDictionaryExpression *)anc_create_expression(ANC_DIC_LITERAL_EXPRESSION);
				$$ = (__bridge_retained void *)expr;
			}
			;

primary_expression: IDENTIFIER
			{
				ANCIdentifierExpression *expr = (ANCIdentifierExpression *)anc_create_expression(ANC_IDENTIFIER_EXPRESSION);
				NSString *identifier = (__bridge_transfer NSString *)$1;;
				expr.identifier = identifier;
				$$ = (__bridge_retained void *)expr;
			}
			| primary_expression DOT IDENTIFIER
			{
				ANCMemberExpression *expr = (ANCMemberExpression *)anc_create_expression(ANC_MEMBER_EXPRESSION);
				expr.expr = (__bridge_transfer ANCExpression *)$1;
				expr.memberName = (__bridge_transfer NSString *)$3;
				$$ = (__bridge_retained void *)expr;
			}
			| primary_expression DOT selector LP RP
			{
				ANCFunctonCallExpression *expr = (ANCFunctonCallExpression *)anc_create_expression(ANC_FUNCTION_CALL_EXPRESSION);
				expr.expr = (__bridge_transfer ANCExpression *)$1;
				$$ = (__bridge_retained void *)expr;
			}
			| primary_expression DOT selector LP expression_list RP
			{
				ANCExpression *expr = (__bridge_transfer ANCExpression *)$1;
				NSString *selector = (__bridge_transfer NSString *)$3;
				ANCMemberExpression *memberExpr = (ANCMemberExpression *)anc_create_expression(ANC_MEMBER_EXPRESSION);
				memberExpr.expr = expr;
				memberExpr.memberName = selector;
				
				ANCFunctonCallExpression *funcCallExpr = (ANCFunctonCallExpression *)anc_create_expression(ANC_FUNCTION_CALL_EXPRESSION);
				funcCallExpr.expr = memberExpr;
				funcCallExpr.args = (__bridge_transfer NSArray<ANCExpression *> *)$5;
				
				$$ = (__bridge_retained void *)funcCallExpr;
			}
			| IDENTIFIER LP RP
			{
				ANCIdentifierExpression *identifierExpr = (ANCIdentifierExpression *)anc_create_expression(ANC_IDENTIFIER_EXPRESSION);
				NSString *identifier = (__bridge_transfer NSString *)$1;
				identifierExpr.identifier = identifier;
				ANCFunctonCallExpression *funcCallExpr = (ANCFunctonCallExpression *)anc_create_expression(ANC_FUNCTION_CALL_EXPRESSION);
				funcCallExpr.expr = identifierExpr;
				$$ = (__bridge_retained void *)funcCallExpr;
			}
		    | IDENTIFIER LP expression_list RP
			{
				ANCIdentifierExpression *identifierExpr = (ANCIdentifierExpression *)anc_create_expression(ANC_IDENTIFIER_EXPRESSION);
				NSString *identifier = (__bridge_transfer NSString *)$1;
				identifierExpr.identifier = identifier;
				ANCFunctonCallExpression *funcCallExpr = (ANCFunctonCallExpression *)anc_create_expression(ANC_FUNCTION_CALL_EXPRESSION);
				funcCallExpr.expr = identifierExpr;
				funcCallExpr.args = (__bridge_transfer NSArray<ANCExpression *> *)$3;
				$$ = (__bridge_retained void *)funcCallExpr;
			}
			| LP expression RP
			{
				$$ = $2;
			}
			| primary_expression LB expression RB
			{
				ANCExpression *arrExpr = (__bridge_transfer ANCExpression *)$1;
				ANCExpression *indexExpr = (__bridge_transfer ANCExpression *)$3;
				
				ANCIndexExpression *expr = (ANCIndexExpression *)anc_create_expression(ANC_IDENTIFIER_EXPRESSION);
				expr.arrayExpression = arrExpr;
				expr.indexExpression = indexExpr;
				$$ = (__bridge_retained void *)expr;
				
			}
			| YES_
			| NO_
			| INTETER_LITERAL
			| DOUBLE_LITERAL
			| STRING_LITERAL
			| NIL
			{
				ANCExpression *expr = anc_create_expression(ANC_NIL_EXPRESSION);
				$$ = (__bridge_retained void *)expr;
			}
			| AT INTETER_LITERAL
			{
				ANCUnaryExpression *expr = (ANCUnaryExpression *)anc_create_expression(ANC_AT_EXPRESSION);
				ANCExpression *subExpr = (__bridge_transfer ANCExpression *)$2;
				expr.expr = subExpr;
				$$ = (__bridge_retained void *)expr;
			}
			| AT DOUBLE_LITERAL
			{
				
				ANCUnaryExpression *expr = (ANCUnaryExpression *)anc_create_expression(ANC_AT_EXPRESSION);
				ANCExpression *subExpr = (__bridge_transfer ANCExpression *)$2;
				expr.expr = subExpr;
				$$ = (__bridge_retained void *)expr;
			}
			| AT STRING_LITERAL
			{
				$$ = $2;
			}
			| AT YES_
			{
				ANCUnaryExpression *expr = (ANCUnaryExpression *)anc_create_expression(ANC_AT_EXPRESSION);
				ANCExpression *subExpr = (__bridge_transfer ANCExpression *)$2;
				expr.expr = subExpr;
				$$ = (__bridge_retained void *)expr;
			}
			| AT NO_
			{
				ANCUnaryExpression *expr = (ANCUnaryExpression *)anc_create_expression(ANC_AT_EXPRESSION);
				ANCExpression *subExpr = (__bridge_transfer ANCExpression *)$2;
				expr.expr = subExpr;
				$$ = (__bridge_retained void *)expr;
			}
			| SELF
			{
				ANCExpression *expr = anc_create_expression(ANC_SELF_EXPRESSION);
				$$ = (__bridge_retained void *)expr;
			}
			| SUPER
			{
				ANCExpression *expr = anc_create_expression(ANC_SUPER_EXPRESSION);
				$$ = (__bridge_retained void *)expr;
			}
			| AT LP expression RP
			{
				ANCUnaryExpression *expr = (ANCUnaryExpression *)anc_create_expression(ANC_AT_EXPRESSION);
				ANCExpression *subExpr = (__bridge_transfer ANCExpression *)$3;
				expr.expr = subExpr;
				$$ = (__bridge_retained void *)expr;
			}
			| AT LB expression_list RB
			{
				ANCArrayExpression *expr = (ANCArrayExpression *)anc_create_expression(ANC_ARRAY_LITERAL_EXPRESSION);
				NSArray *itemExpressions = (__bridge_transfer NSArray *)$3;
				expr.itemExpressions = itemExpressions;
				$$ = (__bridge_retained void *)expr;
			}
			| AT LB  RB
			{
				ANCArrayExpression *expr = (ANCArrayExpression *)anc_create_expression(ANC_ARRAY_LITERAL_EXPRESSION);
				$$ = (__bridge_retained void *)expr;
			}
			| dic
			| block_body
			;




block_body:  POWER type_specifier LP  RP block_statement
			{
				ANCTypeSpecifier *returnTypeSpecifier = (__bridge_transfer ANCTypeSpecifier *)$2;
				ANCBlock *block = (__bridge_transfer ANCBlock *)$5;
				ANCBlockExpression *expr = (ANCBlockExpression *)anc_create_expression(ANC_BLOCK_EXPRESSION);
				expr.returnTypeSpecifier = returnTypeSpecifier;
				expr.block = block;
				$$ = (__bridge_retained void *)expr;
				
			}
			| POWER type_specifier LP function_param_list RP block_statement
			{
				ANCTypeSpecifier *returnTypeSpecifier = (__bridge_transfer ANCTypeSpecifier *)$2;
				NSArray<ANCParameter *> *parameter = (__bridge_transfer NSArray<ANCParameter *> *)$4;
				ANCBlock *block = (__bridge_transfer ANCBlock *)$6;
				ANCBlockExpression *expr = (ANCBlockExpression *)anc_create_expression(ANC_BLOCK_EXPRESSION);
				expr.returnTypeSpecifier = returnTypeSpecifier;
				expr.parameter = parameter;
				expr.block = block;
				$$ = (__bridge_retained void *)expr;
				
			}
			| POWER  LP  RP block_statement
			{
				ANCBlock *block = (__bridge_transfer ANCBlock *)$4;
				ANCBlockExpression *expr = (ANCBlockExpression *)anc_create_expression(ANC_BLOCK_EXPRESSION);
				expr.block = block;
				$$ = (__bridge_retained void *)expr;
			}
			| POWER  LP function_param_list RP block_statement
			{
				NSArray<ANCParameter *> *parameter = (__bridge_transfer NSArray<ANCParameter *> *)$3;
				ANCBlock *block = (__bridge_transfer ANCBlock *)$5;
				ANCBlockExpression *expr = (ANCBlockExpression *)anc_create_expression(ANC_BLOCK_EXPRESSION);
				expr.parameter = parameter;
				expr.block = block;
				$$ = (__bridge_retained void *)expr;
			}
			;


function_param_list: function_param
			{
				NSMutableArray *list = [NSMutableArray array];
				ANCParameter *parameter = (__bridge_transfer ANCParameter *)$1;
				[list addObject:parameter];
				$$ = (__bridge_retained void *)list;
			}
			| function_param_list COMMA function_param
			{
				NSMutableArray *list = (__bridge_transfer NSMutableArray *)$1;
				ANCParameter *parameter = (__bridge_transfer ANCParameter *)$3;
				[list addObject:parameter];
				$$ = (__bridge_retained void *)list;
			}
			;

function_param: type_specifier IDENTIFIER
			{
				ANCTypeSpecifier *type = (__bridge_transfer ANCTypeSpecifier *)$1;
				NSString *name = (__bridge_transfer NSString *)$2;
				ANCParameter *parameter = anc_create_parameter(type, name);
				$$ = (__bridge_retained void *)parameter;
			}
			;

declaration_statement: declaration SEMICOLON
			{
				ANCDeclaration *declaration = (__bridge_transfer ANCDeclaration *)$1;
				ANCDeclarationStatement *statement = anc_create_declaration_statement(declaration);
				$$ = (__bridge_retained void *)statement;
			}
			;

declaration: type_specifier IDENTIFIER
			{
				ANCTypeSpecifier *type = (__bridge_transfer ANCTypeSpecifier *)$1;
				NSString *name = (__bridge_transfer NSString *)$2;
				ANCDeclaration *declaration = anc_create_declaration(type, name, nil);
				$$ = (__bridge_retained void *)declaration;
			}
			| type_specifier IDENTIFIER ASSIGN expression
			{
				ANCTypeSpecifier *type = (__bridge_transfer ANCTypeSpecifier *)$1;
				NSString *name = (__bridge_transfer NSString *)$2;
				ANCExpression *initializer = (__bridge_transfer ANCExpression *)$4;
				ANCDeclaration *declaration = anc_create_declaration(type, name, initializer);
				$$ = (__bridge_retained void *)declaration;
			}
			;
			


if_statement: IF LP expression RP block_statement
			{
				ANCExpression *condition = (__bridge_transfer ANCExpression *)$3;
				ANCBlock *thenBlock = (__bridge_transfer ANCBlock *)$5;
				ANCIfStatement *statement = anc_create_if_statement(condition, thenBlock, nil, nil);
				$$ = (__bridge_retained void *)statement;
			}
			| IF LP expression RP block_statement ELSE block_statement
			{
				ANCExpression *condition = (__bridge_transfer ANCExpression *)$3;
				ANCBlock *thenBlock = (__bridge_transfer ANCBlock *)$5;
				ANCBlock *elseBlocl = (__bridge_transfer ANCBlock *)$7;
				ANCIfStatement *statement = anc_create_if_statement(condition, thenBlock, nil, elseBlocl);
				$$ = (__bridge_retained void *)statement;
			}
			| IF LP expression RP block_statement else_if_list
			{
				ANCExpression *condition = (__bridge_transfer ANCExpression *)$3;
				ANCBlock *thenBlock = (__bridge_transfer ANCBlock *)$5;
				NSArray<ANCElseIf *> *elseIfList = (__bridge_transfer NSArray<ANCElseIf *> *)$6;
				ANCIfStatement *statement = anc_create_if_statement(condition, thenBlock, elseIfList, nil);
				$$ = (__bridge_retained void *)statement;
			}
			| IF LP expression RP block_statement else_if_list ELSE block_statement
			{
				ANCExpression *condition = (__bridge_transfer ANCExpression *)$3;
				ANCBlock *thenBlock = (__bridge_transfer ANCBlock *)$5;
				NSArray<ANCElseIf *> *elseIfList = (__bridge_transfer NSArray<ANCElseIf *> *)$6;
				ANCBlock *elseBlocl = (__bridge_transfer ANCBlock *)$8;
				ANCIfStatement *statement = anc_create_if_statement(condition, thenBlock, elseIfList, elseBlocl);
				$$ = (__bridge_retained void *)statement;
			}
			;

else_if_list: else_if
			{
				NSMutableArray *list = [NSMutableArray array];
				ANCElseIf *elseIf = (__bridge_transfer ANCElseIf *)$1;
				[list addObject:elseIf];
				$$ = (__bridge_retained void *)list;
			}
			| else_if_list else_if
			{
				NSMutableArray *list = (__bridge_transfer NSMutableArray *)$1;
				ANCElseIf *elseIf = (__bridge_transfer ANCElseIf *)$2;
				[list addObject:elseIf];
				$$ = (__bridge_retained void *)list;
			}
			;

else_if: ELSE IF  LP expression RP  block_statement
			{
				ANCExpression *condition = (__bridge_transfer ANCExpression *)$4;
				ANCBlock *thenBlock = (__bridge_transfer ANCBlock *)$6;
				ANCElseIf *elseIf = anc_create_else_if(condition, thenBlock);
				$$ = (__bridge_retained void *)elseIf;
			}
			;

switch_statement: SWITCH LP expression RP LC case_list default_opt RC
			{
				ANCExpression *expr = (__bridge_transfer ANCExpression *)$3;
				NSArray<ANCCase *> *caseList = (__bridge_transfer NSArray *)$6;
				ANCBlock *defaultBlock = (__bridge_transfer ANCBlock *)$7;
				ANCSwitchStatement *statement = anc_create_switch_statement(expr,caseList, defaultBlock);
				$$ = (__bridge_retained void *)statement;
			}
			;

case_list: one_case
			{
				NSMutableArray *list = [NSMutableArray array];
				ANCCase *case_ = (__bridge_transfer ANCCase *)$1;
				[list addObject:case_];
				$$ = (__bridge_retained void *)list;
			}
			| case_list one_case
			{
				NSMutableArray *list = (__bridge_transfer NSMutableArray *)$1;
				ANCCase *case_ = (__bridge_transfer ANCCase *)$2;
				[list addObject:case_];
				$$ = (__bridge_retained void *)list;
			}
			;

one_case: CASE expression COLON block_statement
			{
				ANCExpression *expr = (__bridge_transfer ANCExpression *)$2;
				ANCBlock *block = (__bridge_transfer ANCBlock *)$4;
				ANCCase *case_ = anc_create_case(expr, block);
				$$ = (__bridge_retained void *)case_;
			}
			;

default_opt: /* empty */
			{
				$$ = nil;
			}
			| DEFAULT COLON block_statement
			{
				$$ = $3;
			}
			;

expression_opt: /* empty */
			{
				$$ = nil;
			}
			| expression
			;

identifier_opt: /* empty */
			| IDENTIFIER
			;

label_opt: /* empty */
			{
				$$ = nil;
			}
			| IDENTIFIER COLON
			{
				$$ = $1;
			}
			;

for_statement: label_opt FOR LP expression_opt SEMICOLON expression_opt SEMICOLON expression_opt RP block_statement
			{
				NSString *label = (__bridge_transfer NSString *)$1;
				ANCExpression *initializerExpr = (__bridge_transfer ANCExpression *)$4;
				ANCExpression *condition = (__bridge_transfer ANCExpression *)$6;
				ANCExpression *post = (__bridge_transfer ANCExpression *)$8;
				ANCBlock *block = (__bridge_transfer ANCBlock *)$10;
				ANCForStatement *statement = anc_create_for_statement(label, initializerExpr, nil,
				condition, post, block);
				$$ = (__bridge_retained void *)statement;
			}

			| label_opt FOR LP declaration SEMICOLON  expression_opt SEMICOLON expression_opt RP block_statement
			{
				NSString *label = (__bridge_transfer NSString *)$1;
				ANCDeclaration *declaration = (__bridge_transfer ANCDeclaration *)$4;
				ANCExpression *condition = (__bridge_transfer ANCExpression *)$6;
				ANCExpression *post = (__bridge_transfer ANCExpression *)$8;
				ANCBlock *block = (__bridge_transfer ANCBlock *)$10;
				ANCForStatement *statement = anc_create_for_statement(label, nil, declaration,
				condition, post, block);
				$$ = (__bridge_retained void *)statement;
			}
			;

while_statement: label_opt WHILE LP expression RP block_statement
			{
				NSString *label = (__bridge_transfer NSString *)$1;
				ANCExpression *condition = (__bridge_transfer ANCExpression *)$4;
				ANCBlock *block = (__bridge_transfer ANCBlock *)$6;
				ANCWhileStatement *statement = anc_create_while_statement(label, condition, block);
				$$ = (__bridge_retained void *)statement;
			}
			;

do_while_statement:label_opt DO block_statement WHILE LP expression RP SEMICOLON
			{
				NSString *label = (__bridge_transfer NSString *)$1;
				ANCBlock *block = (__bridge_transfer ANCBlock *)$3;
				ANCExpression *condition = (__bridge_transfer ANCExpression *)$6;
				ANCDoWhileStatement *statement = anc_create_do_while_statement(label, block, condition);
				$$ = (__bridge_retained void *)statement;
			}
			;

foreach_statement: label_opt FOR  LP type_specifier IDENTIFIER COLON expression RP block_statement
			{
				NSString *label = (__bridge_transfer NSString *)$1;
				ANCTypeSpecifier *typeSpecifier = (__bridge_transfer ANCTypeSpecifier *)$4;
				NSString *varName = (__bridge_transfer NSString *)$5;
				ANCExpression *arrayExpr = (__bridge_transfer ANCExpression *)$7;
				ANCBlock *block = (__bridge_transfer ANCBlock *)$9;
				ANCForEachStatement *statement = anc_create_for_each_statement(label, typeSpecifier, varName, arrayExpr, block);
				$$ = (__bridge_retained void *)statement;
			}
			| label_opt FOR  LP IDENTIFIER COLON expression RP block_statement
			{
				NSString *label = (__bridge_transfer NSString *)$1;
				NSString *varName = (__bridge_transfer NSString *)$4;
				ANCExpression *arrayExpr = (__bridge_transfer ANCExpression *)$6;
				ANCBlock *block = (__bridge_transfer ANCBlock *)$8;
				ANCForEachStatement *statement = anc_create_for_each_statement(label, nil, varName, arrayExpr, block);
				$$ = (__bridge_retained void *)statement;
			}
			;


continue_statement: CONTINUE identifier_opt SEMICOLON
			{
				NSString *label = (__bridge_transfer NSString *)$2;
				ANCContinueStatement *statement = anc_create_continue_statement(label);
				$$ = (__bridge_retained void *)statement;
			}
			;


break_statement: BREAK identifier_opt SEMICOLON
			{
				NSString *label = (__bridge_transfer NSString *)$2;
				ANCBreakStatement *statement = anc_create_break_statement(label);
				$$ = (__bridge_retained void *)statement;
			}
			;


return_statement: RETURN expression_opt SEMICOLON
			{
				NSString *label = (__bridge_transfer NSString *)$2;
				ANCBreakStatement *statement = anc_create_break_statement(label);
				$$ = (__bridge_retained void *)statement;
			}
			;


block_statement: LC RC
			{
				ANCBlock *block = anc_create_blcok_statement(nil);
				$$ = (__bridge_retained void *)block;
			}
			| LC  statement_list RC
			{
				NSArray *list = (__bridge_transfer NSArray *)$2;
				ANCBlock *block = anc_create_blcok_statement(list);
				$$ = (__bridge_retained void *)block;
			}
			;


statement_list: statement
			{
				NSMutableArray *list = [NSMutableArray array];
				ANCStatement *statement = (__bridge_transfer ANCStatement *)$1;
				[list addObject:statement];
				$$ = (__bridge_retained void *)list;
			}
			| statement_list statement
			{
				NSMutableArray *list = (__bridge_transfer NSMutableArray *)$1;
				ANCStatement *statement = (__bridge_transfer ANCStatement *)$2;
				[list addObject:statement];
				$$ = (__bridge_retained void *)list;
			}
			;


statement:  declaration_statement
			| if_statement
			| switch_statement
			| for_statement
			| foreach_statement
			| while_statement
			| do_while_statement
			| break_statement
			| continue_statement
			| return_statement
			| expression SEMICOLON
			;

%%
