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

NS_ASSUME_NONNULL_BEGIN


@interface ANEValue : NSObject

@property (strong, nonatomic) ANCTypeSpecifier *type;
@property (assign, nonatomic) unsigned long long uintValue;
@property (assign, nonatomic) long long integerValue;
@property (assign, nonatomic) double doubleValue;
@property (strong, nonatomic, nullable) id objectValue;
@property (strong, nonatomic, nullable) Class classValue;
@property (assign, nonatomic) SEL selValue;
@property (assign, nonatomic) const char * cstringValue;
@property (assign, nonatomic) void *pointerValue;

- (BOOL)isSubtantial;
- (BOOL)isObject;
- (BOOL)isMember;
- (BOOL)isBaseValue;

- (void)assignFrom:(ANEValue *)src;

- (unsigned long long)c2uintValue;
- (long long)c2integerValue;
- (double)c2doubleValue;
- (nullable id)c2objectValue;
- (void *)c2pointerValue;

- (void)assign2CValuePointer:(void *)cvaluePointer typeEncoding:(char *)typeEncoding inter:(nullable ANCInterpreter *)inter;
- (instancetype)initWithCValuePointer:(void *)cValuePointer typeEncoding:(char *)typeEncoding;
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


NS_ASSUME_NONNULL_END




