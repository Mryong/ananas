//
//  ANCClassDefinition.h
//  ananasExample
//
//  Created by jerry.yong on 2017/11/16.
//  Copyright © 2017年 yongpengliang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ANCFunctionDefinition.h"


typedef NS_ENUM(NSInteger, ANCPropertyModifier) {
	ANCPropertyModifierMemStrong = 0x00,
	ANCPropertyModifierMemWeak = 0x01,
	ANCPropertyModifierMemCopy = 0x2,
	ANCPropertyModifierMemAssign = 0x03,
	ANCPropertyModifierMemMask = 0x0F,
	
	ANCPropertyModifierAtomic = 0x00,
	ANCPropertyModifierNonatomic =  0x10,
	ANCPropertyModifierAtomicMask = 0xF0,
};




@interface ANCClassMemberDefinition: NSObject

@end

@interface ANCClassPropertyDefinition: ANCClassMemberDefinition
@property (assign, nonatomic) ANCPropertyModifier modifier;
@property (strong, nonatomic) ANCTypeSpecifier *type;
@property (copy, nonatomic) NSString *name;



@end


@interface ANCClassMehodDefinition: ANCClassMemberDefinition
@property (strong, nonatomic) ANCFunctionDefinition *func;
@end


@interface ANCClassDefinition : NSObject
@property (copy, nonatomic) NSString *name;
@property (copy, nonatomic) NSString *superNmae;
@property (strong, nonatomic) NSMutableArray<NSString *> *protocol;
@property (strong, nonatomic) NSMutableArray<ANCClassPropertyDefinition *> *properties;
@property (strong, nonatomic) NSMutableArray<ANCClassMehodDefinition *> *methods;
@end
