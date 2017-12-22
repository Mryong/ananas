//
//  ANCBlock.m
//  ananasExample
//
//  Created by jerry.yong on 2017/11/28.
//  Copyright © 2017年 yongpengliang. All rights reserved.
//

#import "ANCBlock.h"

@implementation ANCBlock

- (NSMutableArray<ANCDeclaration *> *)declarations{
	if (_declarations == nil) {
		_declarations = [NSMutableArray array];
	}
	return _declarations;
}

@end
