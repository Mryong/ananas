//
//  ANCStructDeclare.h
//  ananasExample
//
//  Created by jerry.yong on 2017/11/16.
//  Copyright © 2017年 yongpengliang. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ANCStructDeclare : NSObject
@property (strong, nonatomic) ANCExpression *annotationIfConditionExpr;
@property (assign, nonatomic) NSUInteger lineNumber;
@property (copy, nonatomic) NSString *name;
@property (strong, nonatomic) NSString *typeEncoding;
@property (strong, nonatomic) NSArray<NSString *> *keys;

@end
