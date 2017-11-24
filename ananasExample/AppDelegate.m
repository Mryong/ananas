//
//  AppDelegate.m
//  ananasExample
//
//  Created by jerry.yong on 2017/10/31.
//  Copyright © 2017年 yongpengliang. All rights reserved.
//

#import "AppDelegate.h"
#import <objc/message.h>
#import <objc/runtime.h>



@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
	// Override point for customization after application launch.
//	objc_setAssociatedObject(nil, NULL, nil, objc_AssociationPolicy policy)
	void (^bb)(NSInteger);
	
	return YES;
}





@end
