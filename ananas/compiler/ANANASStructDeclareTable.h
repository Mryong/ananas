//
//  ANANASStructDeclareTable.h
//  ananasExample
//
//  Created by jerry.yong on 2018/2/24.
//  Copyright © 2018年 yongpengliang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ANCStructDeclare.h"

@interface ANANASStructDeclareTable : NSObject
+ (instancetype)shareInstance;

- (void)addStructDeclare:(ANCStructDeclare *)structDeclare;
- (ANCStructDeclare *)getStructDeclareWithName:(NSString *)name;

@end
