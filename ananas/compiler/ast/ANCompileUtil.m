//
//  ANCTranslationUtil.m
//  ananasExample
//
//  Created by jerry.yong on 2017/11/23.
//  Copyright © 2017年 yongpengliang. All rights reserved.
//

#import "ANCompileUtil.h"

@implementation ANCompileUtil

- (NSMutableArray<ANCClassDefinition *> *)classDefinitionList{
	if (_classDefinitionList == nil) {
		_classDefinitionList = [NSMutableArray array];
	}
	return _classDefinitionList;
}

- (NSMutableArray<ANCStructDeclare *> *)structDeclareList{
	if (_structDeclareList == nil) {
		_structDeclareList = [NSMutableArray array];
	}
	return _structDeclareList;
}



@end
