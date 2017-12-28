//
//  ANEVariable.h
//  ananasExample
//
//  Created by jerry.yong on 2017/12/26.
//  Copyright © 2017年 yongpengliang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ANEValue.h"

@interface ANEVariable : NSObject

@property (copy, nonatomic) NSString *name;
@property (strong, nonatomic) ANEValue *value;

@end
