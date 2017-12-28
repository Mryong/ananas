//
//  ANCValue.h
//  ananasExample
//
//  Created by jerry.yong on 2017/12/25.
//  Copyright © 2017年 yongpengliang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "ANCTypeSpecifier.h"
#import "ANEBlock.h"



@interface ANEValue : NSObject
@property (assign, nonatomic) ANCTypeSpecifier *type;
@property (assign, nonatomic) BOOL boolValue;
@property (assign, nonatomic) NSUInteger uintValue;
@property (assign, nonatomic) NSInteger intValue;
@property (assign, nonatomic) CGFloat cgFloatValue;
@property (assign, nonatomic) long double doubleValue;
@property (assign, nonatomic) char *stringValue;
@property (strong, nonatomic) Class classValue;
@property (assign, nonatomic) SEL selValue;
@property (strong, nonatomic) id nsObjValue;
@property (assign, nonatomic) id nsBlockValue;
@property (strong, nonatomic) ANEBlock *ananasBlockValue;
@property (assign, nonatomic) void *unknownKindValue;


- (BOOL)isTrue;






//ANC_TYPE_VOID,
//ANC_TYPE_BOOL,
//ANC_TYPE_NS_U_INTEGER,
//ANC_TYPE_NS_INTEGER,
//ANC_TYPE_CG_FLOAT,
//ANC_TYPE_DOUBLE,
//ANC_TYPE_STRING,//char *
//ANC_TYPE_CLASS,
//ANC_TYPE_SEL,
//ANC_TYPE_OC,
//ANC_TYPE_STRUCT,
//ANC_TYPE_BLOCK,
//ANC_TYPE_UNKNOWN


@end
