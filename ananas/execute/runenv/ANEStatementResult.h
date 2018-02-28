//
//  ANEStatementResult.h
//  ananasExample
//
//  Created by jerry.yong on 2018/2/28.
//  Copyright © 2018年 yongpengliang. All rights reserved.
//

#import <Foundation/Foundation.h>
@class ANEValue;


typedef NS_ENUM(NSInteger, ANEStatementResultType) {
	ANEStatementResultTypeNormal,
	ANEStatementResultTypeReturn,
	ANEStatementResultTypeBreak,
	ANEStatementResultTypeContinue,
};

@interface ANEStatementResult : NSObject
@property (assign, nonatomic) ANEStatementResultType type;
@property (strong, nonatomic) ANEValue *reutrnValue;
+ (instancetype)normalResult;
+ (instancetype)returnResult;
+ (instancetype)breakResult;
+ (instancetype)continueResult;
@end
