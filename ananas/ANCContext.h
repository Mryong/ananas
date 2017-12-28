//
//  ANCContext.h
//  ananasExample
//
//  Created by jerry.yong on 2017/12/25.
//  Copyright © 2017年 yongpengliang. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ANCContext : NSObject
- (void)evalAnanasScriptWithURL:(NSURL *)url;
- (void)evalAnanasScriptWithSourceString:(NSString *)sourceString;
@end
