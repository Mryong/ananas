//
//  NSCTypeSpecifier.h
//  ananasExample
//
//  Created by jerry.yong on 2017/11/13.
//  Copyright © 2017年 yongpengliang. All rights reserved.
//

#import <Foundation/Foundation.h>
typedef NS_ENUM(NSInteger, NACExpressionTypeKind) {
	NAC_VOID_TYPE,
	NAC_BOOL_TYPE,
	NAC_NS_INTEGER_TYPE,
	NAC_NS_U_INTEGER_TYPE,
	NAC_CG_RECT_TYPE,
	NAC_CG_DOUBLE_TYPE,
	NAC_OC_TYPE,
	NSC_NS_STRING_TYPE,
	NSC_NS_NUMBER_TYPE,
	NAC_STRUCT,
};
@interface NACTypeSpecifier : NSObject
@property (copy, nonatomic) NSString *identifer;
@property (assign, nonatomic) NACExpressionTypeKind typeKind;
@property (copy, nonatomic) NSString *typeEncoding;
@end
