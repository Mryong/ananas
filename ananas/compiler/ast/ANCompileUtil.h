//
//  ANCTranslationUtil.h
//  ananasExample
//
//  Created by jerry.yong on 2017/11/23.
//  Copyright © 2017年 yongpengliang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ANCClassDefinition.h"
#import "ANCStructDeclare.h"

@interface ANCompileUtil : NSObject
@property (assign, nonatomic) NSUInteger currentLineNumber;
@property (strong, nonatomic) NSMutableArray<ANCClassDefinition *> *classDefinitionList;
@property (strong, nonatomic) NSMutableArray<ANCStructDeclare *> *structDeclareList;
@property (strong, nonatomic) NSMutableArray<ANCStatement *> *statementList;
@property (strong, nonatomic) ANCClassDefinition *currentClassDefinition;
@property (strong, nonatomic) ANCBlock *currentBlock;
@end
