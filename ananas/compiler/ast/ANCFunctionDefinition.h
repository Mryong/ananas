//
//  ANCFunctionDefinition.h
//  ananasExample
//
//  Created by jerry.yong on 2017/11/16.
//  Copyright © 2017年 yongpengliang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ANCTypeSpecifier.h"

@interface ANCParameter:NSObject
@property (strong, nonatomic) ANCTypeSpecifier *type;
@property (copy, nonatomic) NSString *name;
@end


@interface ANCFunctionDefinition: NSObject
@property (assign, nonatomic) NSUInteger lineNumber;
@property (copy, nonatomic) NSString *name;//or selecor
@property (strong, nonatomic) NSMutableArray<ANCParameter *> *params;


@end
