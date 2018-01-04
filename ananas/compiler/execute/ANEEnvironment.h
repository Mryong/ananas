//
//  ANEEnvironment.h
//  ananasExample
//
//  Created by jerry.yong on 2018/1/2.
//  Copyright © 2018年 yongpengliang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "ANCTypeSpecifier.h"
#import "ANEBlock.h"



@interface ANEValue : NSObject
@property (assign, nonatomic) ANCTypeSpecifier *type;
@property (assign, nonatomic) BOOL boolValue;
@property (assign, nonatomic) NSUInteger uintValue;
@property (assign, nonatomic) NSInteger intValue;
@property (assign, nonatomic) CGFloat cgFloatValue;
@property (assign, nonatomic) long double doubleValue;
@property (assign, nonatomic) char *stringValue;
@property (strong, nonatomic) Class classValue;
@property (assign, nonatomic) SEL selValue;
@property (strong, nonatomic) id nsObjValue;
@property (assign, nonatomic) id nsBlockValue;
@property (strong, nonatomic) ANEBlock *ananasBlockValue;
@property (assign, nonatomic) void *unknownKindValue;
- (BOOL)isTrue;
@end

@interface ANEVariable:NSObject
@property (assign, nonatomic)BOOL ananasVar;
@property (copy, nonatomic) NSString *name;
@property (strong, nonatomic) ANEValue *value;
@end

@interface ANEScopeChain: NSObject
@property (assign, nonatomic,getter=isClazz) BOOL clazz;
@property (strong, nonatomic) NSMutableArray<ANEVariable *> *vars;
@property (strong, nonatomic) ANEScopeChain *next;

@end

typedef NS_ENUM(NSInteger, ANEStatementResultType) {
	ANEStatementResultTypeNormal,
	ANEStatementResultTypeReutun,
	ANEStatementResultTypeBreak,
	ANEStatementResultTypeContinue,
};


@interface ANEStatementResult : NSObject
@property (assign, nonatomic) ANEStatementResultType type;
@property (strong, nonatomic) ANEValue *reutrnValue;
@end

@interface ANEEnvironment : NSObject
@property (strong, nonatomic) Class clazz;
@property (strong, nonatomic) ANEScopeChain *scope;
@end
