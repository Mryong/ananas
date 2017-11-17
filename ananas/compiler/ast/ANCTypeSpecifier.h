//
//  NSCTypeSpecifier.h
//  ananasExample
//
//  Created by jerry.yong on 2017/11/13.
//  Copyright © 2017年 yongpengliang. All rights reserved.
//

#import <Foundation/Foundation.h>
typedef NS_ENUM(NSInteger, ANCExpressionTypeKind) {
	ANC_VOID_TYPE,
	ANC_BOOL_TYPE,
	ANC_NS_INTEGER_TYPE,
	ANC_NS_U_INTEGER_TYPE,
	ANC_CG_RECT_TYPE,
	ANC_CG_DOUBLE_TYPE,
	ANC_OC_TYPE,
	NSC_NS_STRING_TYPE,
	NSC_NS_NUMBER_TYPE,
	ANC_STRUCT,
};
@interface ANCTypeSpecifier : NSObject
@property (copy, nonatomic) NSString *identifer;
@property (assign, nonatomic) ANCExpressionTypeKind typeKind;
@property (copy, nonatomic) NSString *typeEncoding;
@end
