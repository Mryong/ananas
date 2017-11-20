//
//  ANCDeclaration.h
//  ananasExample
//
//  Created by jerry.yong on 2017/11/20.
//  Copyright © 2017年 yongpengliang. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ANCDeclaration: NSObject
@property (strong, nonatomic) ANCTypeSpecifier *type;
@property (copy, nonatomic) NSString *name;
@property (strong, nonatomic) ANCExpression *initializer;
@end
