//
//  ANCStructDeclare.h
//  ananasExample
//
//  Created by jerry.yong on 2017/11/16.
//  Copyright © 2017年 yongpengliang. All rights reserved.
//

#import <Foundation/Foundation.h>
@class ANCExpression;

@interface ANCStructDeclare : NSObject
@property (strong, nonatomic) ANCExpression *annotationIfConditionExpr;
@property (assign, nonatomic) NSUInteger lineNumber;
@property (copy, nonatomic) NSString *name;
@property (assign, nonatomic)const char *typeEncoding;
@property (strong, nonatomic) NSArray<NSString *> *keys;

- (instancetype)initWithName:(NSString *)name typeEncoding:(const char *)typeEncoding keys:(NSArray<NSString *> *)keys;

@end
