//
//  CJShellHelper.h
//  CJCrashTools
//
//  Created by ChiJinLian on 2017/9/11.
//  Copyright © 2017年 ChiJinLian. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>

#define SHELL_TERMINATION  @"shellTermination"       //用于判断shell执行完毕
#define SHELL_ERROR        @"CJL_ShellError"         //用于判断shell执行出错

#define cj_dispatch_async_main_queue(block)\
        if ([NSThread isMainThread]) {\
            block();\
        } else {\
            dispatch_async(dispatch_get_main_queue(), block);\
        }

@interface CJShellHelper : NSObject

+ (void)dsymUUID:(NSString *)path cpuType:(NSString *)cupType responeHandler:(void(^)(NSString *UUID))responeHandler failBlock:(void(^)(NSString *msg))failBlock;

+ (void)analyzedSYMPath:(NSString *)path cpuType:(NSString *)cpuType address:(NSString *)address responeHandler:(void(^)(NSString *log))responeHandler failBlock:(void(^)(NSString *msg))failBlock;

+ (void)exportLogdSYMPath:(NSString *)path log:(NSString *)log responeHandler:(void(^)(NSString *log))responeHandler failBlock:(void(^)(NSString *msg))failBlock;
@end


