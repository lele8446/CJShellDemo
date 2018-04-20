//
//  ArchiveHelper.h
//  Archive
//
//  Created by ChiJinLian on 2018/3/30.
//  Copyright © 2018年 ChiJinLian. All rights reserved.
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

@interface ArchiveHelper : NSObject

/**
 获取当前app运行路径

 @return <#return value description#>
 */
+ (NSString *)getCurrentAppPath;

/**
 获取app id

 @param projectPath <#projectPath description#>
 @param responeHandler <#responeHandler description#>
 @param failBlock <#failBlock description#>
 */
+ (void)getAppBundleIdentifierProjectPath:(NSString *)projectPath responeHandler:(void(^)(NSString *AppBundleIdentifier))responeHandler failBlock:(void(^)(NSString *msg))failBlock;


/**
 获取app 版本号

 @param projectPath <#projectPath description#>
 @param appID <#appID description#>
 @param responeHandler <#responeHandler description#>
 @param failBlock <#failBlock description#>
 */
+ (void)getAppVersionProjectPath:(NSString *)projectPath appID:(NSString *)appID responeHandler:(void(^)(NSString *AppVersion))responeHandler failBlock:(void(^)(NSString *msg))failBlock;

/**
 执行shell脚本

 @param name <#name description#>
 @param arguments <#arguments description#>
 @param responeHandler <#responeHandler description#>
 @param failBlock <#failBlock description#>
 */
+ (void)launchShellName:(NSString *)name arguments:(NSArray *)arguments responeHandler:(void(^)(NSString *msg))responeHandler failBlock:(void(^)(NSString *msg))failBlock;

/**
 显示警告信息

 @param title <#title description#>
 @param message <#message description#>
 @param view <#view description#>
 @param handler <#handler description#>
 */
+ (NSAlert *)alertTitle:(NSString *)title message:(NSString *)message forView:(NSWindow *)view completionHandler:(void (^)(NSModalResponse returnCode))handler;

/**
 expirationDate距离今天是否大于指定天数

 @param expirationDate <#expirationDate description#>
 @param outDay <#outDay description#>
 @return <#return value description#>
 */
+ (BOOL)isOutOfDateTime:(NSDate *)expirationDate outDay:(NSInteger)outDay;
@end
