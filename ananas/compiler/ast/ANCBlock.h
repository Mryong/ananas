//
//  ANCBlock.h
//  ananasExample
//
//  Created by jerry.yong on 2017/11/28.
//  Copyright © 2017年 yongpengliang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ANCStatement.h"

typedef NS_ENUM(NSInteger, ANCBlockKind) {
	ANCBlockKindStatement,
	ANCBlockKindeFunction,
	ANCBlockKindBock
	
};


@interface ANCBlock: NSObject
@property (strong, nonatomic) NSArray<ANCStatement *> *statementList;
@property (strong, nonatomic) NSMutableArray<ANCDeclaration *> *declarations;
@property (weak, nonatomic) ANCBlock *outBlock;


@end
