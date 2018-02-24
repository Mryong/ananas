//
//  ANANASMethodMapTable.h
//  ananasExample
//
//  Created by jerry.yong on 2018/2/23.
//  Copyright © 2018年 yongpengliang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "anc_ast.h"

@interface ANANASMethodMapTableItem:NSObject
@property (strong, nonatomic) Class clazz;
@property (weak, nonatomic) ANCInterpreter *inter;
@property (weak, nonatomic) ANCMethodDefinition *method;

- (instancetype)initWithClass:(Class)clazz inter:(ANCInterpreter *)inter method:(ANCMethodDefinition *)method;
@end

@interface ANANASMethodMapTable : NSObject

+ (instancetype)shareInstance;

- (void)addMethodMapTableItem:(ANANASMethodMapTableItem *)methodMapTableItem;
- (ANANASMethodMapTableItem *)getMethodMapTableItemWith:(Class)clazz classMethod:(BOOL)classMethod sel:(SEL)sel;

@end
