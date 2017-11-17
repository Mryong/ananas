//
//  NACFunctionDefinition.h
//  ananasExample
//
//  Created by jerry.yong on 2017/11/16.
//  Copyright © 2017年 yongpengliang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NACTypeSpecifier.h"

@interface NACParameter:NSObject
@property (strong, nonatomic) NACTypeSpecifier *type;
@property (copy, nonatomic) NSString *name;
@end


@interface NACFunctionDefinition: NSObject
@property (assign, nonatomic) NSUInteger lineNumber;
@property (copy, nonatomic) NSString *name;//or selecor
@property (strong, nonatomic) NSMutableArray<NACParameter *> *params;


@end
