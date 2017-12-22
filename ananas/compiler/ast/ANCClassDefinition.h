//
//  ANCClassDefinition.h
//  ananasExample
//
//  Created by jerry.yong on 2017/11/16.
//  Copyright © 2017年 yongpengliang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ANCFunctionDefinition.h"

@class ANCClassDefinition;


typedef NS_ENUM(NSUInteger, ANCPropertyModifier) {
	ANCPropertyModifierMemStrong = 0x00,
	ANCPropertyModifierMemWeak = 0x01,
	ANCPropertyModifierMemCopy = 0x2,
	ANCPropertyModifierMemAssign = 0x03,
	ANCPropertyModifierMemMask = 0x0F,
	
	ANCPropertyModifierAtomic = 0x00,
	ANCPropertyModifierNonatomic =  0x10,
	ANCPropertyModifierAtomicMask = 0xF0,
};




@interface ANCMemberDefinition: NSObject
@property (strong, nonatomic) ANCExpression *annotationIfConditionExpr;
@property (weak, nonatomic) ANCClassDefinition *classDefinition;
@end

@interface ANCPropertyDefinition: ANCMemberDefinition
@property (assign, nonatomic) NSUInteger lineNumber;
@property (assign, nonatomic) ANCPropertyModifier modifier;
@property (strong, nonatomic) ANCTypeSpecifier *typeSpecifier;
@property (copy, nonatomic) NSString *name;

@end


@interface ANCMethodNameItem: NSObject
@property (copy, nonatomic) NSString *name;
@property (strong, nonatomic) ANCParameter *param;

@end


@interface ANCMethodDefinition: ANCMemberDefinition
@property (assign, nonatomic) BOOL classMethod;
@property (strong, nonatomic) ANCFunctionDefinition *functionDefinition;
@end


@interface ANCClassDefinition : NSObject
@property (assign, nonatomic) NSUInteger lineNumber;
@property (copy, nonatomic) NSString *name;
@property (copy, nonatomic) NSString *superNmae;
@property (strong, nonatomic) NSArray<NSString *> *protocolNames;
@property (strong, nonatomic) NSArray<ANCPropertyDefinition *> *properties;
@property (strong, nonatomic) NSArray<ANCMethodDefinition *> *classMethods;
@property (strong, nonatomic) NSArray<ANCMethodDefinition *> *instanceMethods;
@property (strong, nonatomic) ANCExpression *annotationIfConditionExpr;
@end
















