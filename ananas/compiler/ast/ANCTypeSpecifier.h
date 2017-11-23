//
//  NSCTypeSpecifier.h
//  ananasExample
//
//  Created by jerry.yong on 2017/11/13.
//  Copyright © 2017年 yongpengliang. All rights reserved.
//

#import <Foundation/Foundation.h>
typedef NS_ENUM(NSInteger, ANCExpressionTypeKind) {
	ANC_TYPE_VOID,
	ANC_TYPE_BOOL,
	ANC_TYPE_NS_U_INTEGER,
	ANC_TYPE_NS_INTEGER,
	ANC_TYPE_STRING,
	ANC_TYPE_OC,
	ANC_TYPE_STRUCT,
	ANC_TYPE_BLOCK,
	ANC_TYPE_UNKNOWN
};
@interface ANCTypeSpecifier : NSObject
@property (copy, nonatomic) NSString *identifer;
@property (assign, nonatomic) ANCExpressionTypeKind typeKind;
@property (copy, nonatomic) NSString *typeEncoding;

@property (strong, nonatomic) ANCTypeSpecifier *returnTypeSpecifier;
@property (strong, nonatomic) NSArray<ANCTypeSpecifier *> *paramsTypeSpecifier;

@end
