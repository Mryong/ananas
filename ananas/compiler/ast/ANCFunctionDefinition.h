//
//  ANCFunctionDefinition.h
//  ananasExample
//
//  Created by jerry.yong on 2017/11/16.
//  Copyright © 2017年 yongpengliang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ANCTypeSpecifier.h"
#import "ANCExpression.h"
#import "ANCStatement.h"
@class ANCBlock;
@class ANCMethodDefinition;

@interface ANCParameter:NSObject
@property (strong, nonatomic) ANCTypeSpecifier *type;
@property (copy, nonatomic) NSString *name;
@end


@interface ANCFunctionDefinition: NSObject
@property (assign, nonatomic) NSUInteger lineNumber;
@property (strong, nonatomic) ANCTypeSpecifier *returnTypeSpecifier;
@property (assign, nonatomic) BOOL method;
@property (weak, nonatomic) ANCMethodDefinition *methodDefinition;
@property (copy, nonatomic) NSString *name;//or selecor
@property (strong, nonatomic) NSArray<ANCParameter *> *params;
@property (strong, nonatomic) ANCBlock *block;


@end
