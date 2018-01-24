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
@property (assign, nonatomic) char charValue;
@property (assign, nonatomic) NSUInteger uintValue;
@property (assign, nonatomic) NSInteger intValue;
@property (assign, nonatomic) CGFloat cgFloatValue;
@property (assign, nonatomic) double doubleValue;
@property (assign, nonatomic) const char *stringValue;
@property (strong, nonatomic) Class classValue;
@property (assign, nonatomic) SEL selValue;
@property (strong, nonatomic) id nsObjValue;
@property (assign, nonatomic) BOOL isSuper;
@property (strong, nonatomic) id nsBlockValue;
@property (strong, nonatomic) ANEBlock *ananasBlockValue;
@property (assign, nonatomic) void *structValue;
@property (strong, nonatomic) NSDictionary *structLiteralValue;
@property (assign, nonatomic) void *pointerValue;


- (BOOL)isSubtantial;
- (BOOL)isObject;
- (BOOL)isMember;
- (BOOL)isBaseValue;
@end

@interface ANEVariable:NSObject
@property (assign, nonatomic)BOOL ananasVar;
@property (copy, nonatomic) NSString *name;
@property (strong, nonatomic) ANEValue *value;
@end

@interface ANEScopeChain: NSObject
@property (strong, nonatomic) id instance;
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


@interface ANEStack : NSObject

- (void)push:(ANEValue *)value;
- (ANEValue *)pop;
- (ANEValue *)peekStack:(NSUInteger)index;
- (void)shrinkStack:(NSUInteger)shrinkSize;
@end







