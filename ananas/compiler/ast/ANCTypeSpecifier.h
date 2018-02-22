//
//  NSCTypeSpecifier.h
//  ananasExample
//
//  Created by jerry.yong on 2017/11/13.
//  Copyright © 2017年 yongpengliang. All rights reserved.
//

#import <Foundation/Foundation.h>
@class ANCInterpreter;
typedef NS_ENUM(NSUInteger, ANATypeSpecifierKind) {
	ANC_TYPE_VOID,
	ANC_TYPE_BOOL,
	ANC_TYPE_INT,
	ANC_TYPE_U_INT,
	ANC_TYPE_DOUBLE,
	ANC_TYPE_C_STRING,
	ANC_TYPE_CLASS,
	ANC_TYPE_SEL,
	ANC_TYPE_OBJECT,
	ANC_TYPE_BLOCK,
	ANC_TYPE_STRUCT,
	ANC_TYPE_STRUCT_LITERAL,
	ANC_TYPE_POINTER
};
@interface ANCTypeSpecifier : NSObject
@property (copy, nonatomic) NSString *structName;
@property (copy, nonatomic) NSString *typeName;
@property (assign, nonatomic) ANATypeSpecifierKind typeKind;
- (const char *)typeEncodingWithInterpreter:(ANCInterpreter *)inter;


@end
