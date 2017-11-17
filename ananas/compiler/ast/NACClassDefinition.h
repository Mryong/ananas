//
//  NACClassDefinition.h
//  ananasExample
//
//  Created by jerry.yong on 2017/11/16.
//  Copyright © 2017年 yongpengliang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NACFunctionDefinition.h"


typedef NS_ENUM(NSInteger, NACPropertyModifier) {
	NACPropertyModifierMemStrong = 0x00,
	NACPropertyModifierMemWeak = 0x01,
	NACPropertyModifierMemCopy = 0x2,
	NACPropertyModifierMemAssign = 0x03,
	NACPropertyModifierMemMask = 0x0F,
	
	NACPropertyModifierAtomic = 0x00,
	NACPropertyModifierNonatomic =  0x10,
	NACPropertyModifierAtomicMask = 0xF0,
};




@interface NACClassMemberDefinition: NSObject

@end

@interface NACClassPropertyDefinition: NACClassMemberDefinition
@property (assign, nonatomic) NACPropertyModifier modifier;
@property (strong, nonatomic) NACTypeSpecifier *type;
@property (copy, nonatomic) NSString *name;



@end


@interface NACClassMehodDefinition: NACClassMemberDefinition
@property (strong, nonatomic) NACFunctionDefinition *func;
@end


@interface NACClassDefinition : NSObject
@property (copy, nonatomic) NSString *name;
@property (copy, nonatomic) NSString *superNmae;
@property (strong, nonatomic) NSMutableArray<NSString *> *protocol;
@property (strong, nonatomic) NSMutableArray<NACClassPropertyDefinition *> *properties;
@property (strong, nonatomic) NSMutableArray<NACClassMehodDefinition *> *methods;
@end
