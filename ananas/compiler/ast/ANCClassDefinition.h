//
//  ANCClassDefinition.h
//  ananasExample
//
//  Created by jerry.yong on 2017/11/16.
//  Copyright © 2017年 yongpengliang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ANCFunctionDefinition.h"


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

@end

@interface ANCPropertyDefinition: ANCMemberDefinition
@property (assign, nonatomic) ANCPropertyModifier modifier;
@property (strong, nonatomic) ANCTypeSpecifier *typeSpecifier;
@property (copy, nonatomic) NSString *name;

@end


@interface ANCMethodDefinition: ANCMemberDefinition
@property (assign, nonatomic) BOOL classMethod;
@property (strong, nonatomic) ANCFunctionDefinition *functionDefinition;
@end


@interface ANCClassDefinition : NSObject
@property (copy, nonatomic) NSString *name;
@property (copy, nonatomic) NSString *superNmae;
@property (strong, nonatomic) NSArray<NSString *> *protocolNames;
@property (strong, nonatomic) NSArray<ANCPropertyDefinition *> *properties;
@property (strong, nonatomic) NSArray<ANCMethodDefinition *> *classMethods;
@property (strong, nonatomic) NSArray<ANCMethodDefinition *> *instanceMethods;
@end
















