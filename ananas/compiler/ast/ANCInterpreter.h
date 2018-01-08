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
@class ANEScopeChain;
@class ANEStack;



@interface ANCInterpreter : NSObject
@property (assign, nonatomic) NSUInteger currentLineNumber;
@property (strong, nonatomic) NSMutableDictionary<NSString *, ANCStructDeclare *> *structDeclareDic;
@property (strong, nonatomic) NSMutableDictionary<NSString *, ANCClassDefinition *> *classDefinitionDic;
@property (strong, nonatomic) NSMutableDictionary<Class, NSMutableDictionary<NSString *, ANCFunctionDefinition *> *> *functionDefinitionDic;

@property (strong, nonatomic) NSMutableArray *topList;
@property (strong, nonatomic) ANCClassDefinition *currentClassDefinition;
@property (strong, nonatomic) ANCBlock *currentBlock;

@property (strong, nonatomic) ANEScopeChain *topScope;




@property (strong, nonatomic) ANEStack *stack;

- (void)compileSoruceWithURL:(NSURL *)url;
- (void)compileSoruceWithString:(NSString *)source;






@end
