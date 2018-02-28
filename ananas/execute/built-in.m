//
//  built-in.m
//  ananasExample
//
//  Created by jerry.yong on 2018/2/28.
//  Copyright © 2018年 yongpengliang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "man_ast.h"
#import "runenv.h"

static void add_built_in_struct_declare(){
	ANANASStructDeclareTable *table = [ANANASStructDeclareTable shareInstance];
	
	MANStructDeclare *cgPoinerStructDeclare = [[MANStructDeclare alloc] initWithName:@"CGPoint" typeEncoding:"{CGPoint=dd}" keys:@[@"x",@"y"]];
	[table addStructDeclare:cgPoinerStructDeclare];
	
	MANStructDeclare *cgSizeStructDeclare = [[MANStructDeclare alloc] initWithName:@"CGSize" typeEncoding:"{CGSize=dd}" keys:@[@"width",@"height"]];
	[table addStructDeclare:cgSizeStructDeclare];
	
	MANStructDeclare *cgRectStructDeclare = [[MANStructDeclare alloc] initWithName:@"CGRect" typeEncoding:"{CGRect={CGPoint=dd}{CGSize=dd}}" keys:@[@"origin",@"size"]];
	[table addStructDeclare:cgRectStructDeclare];
	
	MANStructDeclare *cgAffineTransformStructDeclare = [[MANStructDeclare alloc] initWithName:@"CGAffineTransform" typeEncoding:"{CGAffineTransform=dddddd}" keys:@[@"a",@"b",@"c", @"d", @"tx", @"ty"]];
	[table addStructDeclare:cgAffineTransformStructDeclare];
	
	MANStructDeclare *cgVectorStructDeclare = [[MANStructDeclare alloc] initWithName:@"CGVector" typeEncoding:"{CGVector=dd}" keys:@[@"dx",@"dy"]];
	[table addStructDeclare:cgVectorStructDeclare];
	//todo _NSRange
	MANStructDeclare *nsRangeStructDeclare = [[MANStructDeclare alloc] initWithName:@"NSRange" typeEncoding:"{_NSRange=QQ}" keys:@[@"location",@"length"]];
	[table addStructDeclare:nsRangeStructDeclare];
	
	MANStructDeclare *uiOffsetStructDeclare = [[MANStructDeclare alloc] initWithName:@"UIOffset" typeEncoding:"{UIOffset=dd}" keys:@[@"horizontal",@"vertical"]];
	[table addStructDeclare:uiOffsetStructDeclare];
	
	MANStructDeclare *uiEdgeInsetsStructDeclare = [[MANStructDeclare alloc] initWithName:@"UIEdgeInsets" typeEncoding:"{UIEdgeInsets=dddd}" keys:@[@"top",@"left",@"bottom",@"right"]];
	[table addStructDeclare:uiEdgeInsetsStructDeclare];
	
	MANStructDeclare *caTransform3DStructDeclare = [[MANStructDeclare alloc] initWithName:@"CATransform3D" typeEncoding:"" keys:@[@"m11",@"m12",@"m13",@"m14",@"m21",@"m22",@"m23",@"m24",@"m31",@"m32",@"m33",@"m34",@"41",@"m42",@"m43",@"m44",]];
	[table addStructDeclare:caTransform3DStructDeclare];
	
}

static void add_build_in_function(MANInterpreter *interpreter){
	
	interpreter.commonScope.vars[@"CGPointMake"] = [ANEValue valueInstanceWithBlock:^CGPoint(CGFloat x, CGFloat y){
		return CGPointMake(x, y);
	}];
	
	interpreter.commonScope.vars[@"CGSizeMake"] = [ANEValue valueInstanceWithBlock:^CGSize(CGFloat width, CGFloat height){
		return CGSizeMake(width, height);
	}];
	
	interpreter.commonScope.vars[@"CGRectMake"] = [ANEValue valueInstanceWithBlock:^CGRect (CGFloat x, CGFloat y, CGFloat width, CGFloat height){
		return CGRectMake(x, y, width, height);
	}];
	
	interpreter.commonScope.vars[@"NSMakeRange"] = [ANEValue valueInstanceWithBlock:^NSRange(NSUInteger loc, NSUInteger len){
		return NSMakeRange(loc, len);
	}];
	
	interpreter.commonScope.vars[@"UIOffsetMake"] = [ANEValue valueInstanceWithBlock:^UIOffset(CGFloat horizontal, CGFloat vertical){
		return UIOffsetMake(horizontal, vertical);
	}];
	
	interpreter.commonScope.vars[@"UIEdgeInsetsMake"] = [ANEValue valueInstanceWithBlock:^UIEdgeInsets(CGFloat top, CGFloat left, CGFloat bottom, CGFloat right){
		return UIEdgeInsetsMake(top, left, bottom, right);
	}];
	
	interpreter.commonScope.vars[@"CGVectorMake"] = [ANEValue valueInstanceWithBlock:^CGVector(CGFloat dx, CGFloat dy){
		return CGVectorMake(dx, dy);
	}];
	
	interpreter.commonScope.vars[@"CGAffineTransformMake"] = [ANEValue valueInstanceWithBlock:^ CGAffineTransform(CGFloat a, CGFloat b, CGFloat c, CGFloat d, CGFloat tx, CGFloat ty){
		return CGAffineTransformMake(a, b, c, d, tx, ty);
	}];
	
	interpreter.commonScope.vars[@"CGAffineTransformMakeScale"] = [ANEValue valueInstanceWithBlock:^CGAffineTransform(CGFloat sx, CGFloat sy){
		return CGAffineTransformMakeScale(sx, sy);
	}];
	
	interpreter.commonScope.vars[@"CGAffineTransformMakeRotation"] = [ANEValue valueInstanceWithBlock:^CGAffineTransform(CGFloat angle){
		return CGAffineTransformMakeRotation(angle);
	}];
	
	interpreter.commonScope.vars[@"CGAffineTransformMakeTranslation"] = [ANEValue valueInstanceWithBlock:^CGAffineTransform(CGFloat tx, CGFloat ty){
		return CGAffineTransformMakeTranslation(tx, ty);
	}];
	
	interpreter.commonScope.vars[@"CGAffineTransformRotate"] = [ANEValue valueInstanceWithBlock:^CGAffineTransform(CGAffineTransform t, CGFloat angle){
		return CGAffineTransformRotate(t, angle);
	}];
	
	interpreter.commonScope.vars[@"CGAffineTransformConcat"] = [ANEValue valueInstanceWithBlock:^CGAffineTransform(CGAffineTransform t1, CGAffineTransform t2){
		return CGAffineTransformConcat(t1,t2);
	}];
	
	
	interpreter.commonScope.vars[@"CGAffineTransformScale"] = [ANEValue valueInstanceWithBlock:^CGAffineTransform(CGAffineTransform t, CGFloat sx, CGFloat sy){
		return CGAffineTransformScale(t, sx, sy);
	}];
	
	interpreter.commonScope.vars[@"CGAffineTransformTranslate"] = [ANEValue valueInstanceWithBlock:^CGAffineTransform(CGAffineTransform t, CGFloat tx, CGFloat ty){
		return CGAffineTransformTranslate(t, tx, ty);
	}];

	interpreter.commonScope.vars[@"CGAffineTransformFromString"] = [ANEValue valueInstanceWithBlock:^CGAffineTransform(NSString * _Nonnull string){
		return CGAffineTransformFromString(string);
	}];

	interpreter.commonScope.vars[@"CATransform3DMakeScale"] = [ANEValue valueInstanceWithBlock:^CATransform3D(CGFloat sx, CGFloat sy, CGFloat sz){
		return CATransform3DMakeScale(sx, sy, sz);
	}];
	
	
	interpreter.commonScope.vars[@"NSLog"] = [ANEValue valueInstanceWithBlock:^void (id obj){
		NSLog(@"%@",obj);
	}];
	
}
static void add_build_in_var(MANInterpreter *inter){
	inter.commonScope.vars[@"NSRunLoopCommonModes"] = [ANEValue valueInstanceWithObject:NSRunLoopCommonModes];
	inter.commonScope.vars[@"NSDefaultRunLoopMode"] = [ANEValue valueInstanceWithObject:NSDefaultRunLoopMode];
	
	inter.commonScope.vars[@"M_PI"] = [ANEValue valueInstanceWithDouble:M_PI];
	inter.commonScope.vars[@"M_PI_2"] = [ANEValue valueInstanceWithDouble:M_PI_2];
	inter.commonScope.vars[@"M_PI_4"] = [ANEValue valueInstanceWithDouble:M_PI_4];
	inter.commonScope.vars[@"M_1_PI"] = [ANEValue valueInstanceWithDouble:M_1_PI];
	inter.commonScope.vars[@"M_2_PI"] = [ANEValue valueInstanceWithDouble:M_2_PI];
	
	UIDevice *device = [UIDevice currentDevice];
	NSDictionary *infoDictionary = [[NSBundle mainBundle] infoDictionary];
	inter.commonScope.vars[@"$systemVersion"] = [ANEValue valueInstanceWithObject:device.systemVersion];
	inter.commonScope.vars[@"$appVersion"] =  [ANEValue valueInstanceWithObject:[infoDictionary objectForKey:@"CFBundleShortVersionString"]];
	inter.commonScope.vars[@"$buildVersion"] =  [ANEValue valueInstanceWithObject:[infoDictionary objectForKey:@"CFBundleVersion"]];
	
}

void mango_add_built_in(MANInterpreter *inter){
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		add_built_in_struct_declare();
		add_build_in_function(inter);
		add_build_in_var(inter);
	});
	
}
