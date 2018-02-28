//
//  ANEScopeChain.h
//  ananasExample
//
//  Created by jerry.yong on 2018/2/28.
//  Copyright © 2018年 yongpengliang. All rights reserved.
//

#import <Foundation/Foundation.h>
@class ANEValue;

NS_ASSUME_NONNULL_BEGIN
@interface ANEScopeChain: NSObject
@property (strong, nonatomic) id instance;
@property (strong, nonatomic) NSMutableDictionary<NSString *,ANEValue *> *vars;
@property (strong, nonatomic) ANEScopeChain *next;

+ (instancetype)scopeChainWithNext:(ANEScopeChain *)next;
- (ANEValue *)getValueWithIdentifier:(NSString *)identifier;

@end
NS_ASSUME_NONNULL_END




