//
//  ArchiveHelper.m
//  Archive
//
//  Created by ChiJinLian on 2018/3/30.
//  Copyright © 2018年 ChiJinLian. All rights reserved.
//

#import "ArchiveHelper.h"
#import "AppDelegate.h"

@implementation ArchiveHelper

+ (NSString *)getCurrentAppPath {
    NSString* path = @"";
    NSString* str_app_full_file_name = [[NSBundle mainBundle] bundlePath];
    NSRange range = [str_app_full_file_name rangeOfString:@"/" options:NSBackwardsSearch];
    if (range.location != NSNotFound) {
        path = [str_app_full_file_name substringToIndex:range.location];
        path = [path stringByAppendingFormat:@"%@",@"/"];
    }
    return path;
}


+ (void)launchShellName:(NSString *)name arguments:(NSArray *)arguments responeHandler:(void(^)(NSString *msg))responeHandler failBlock:(void(^)(NSString *msg))failBlock {
    
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    /**设置最大并发数*/
//    queue.maxConcurrentOperationCount = 1;
    [queue addOperationWithBlock:^(void) {
        
        NSString *shellPath = [[NSBundle mainBundle] pathForResource:name ofType:@"sh"];
//        if (![name isEqualToString:@"git"]) {
//            NSString *currentAppPath = [self getCurrentAppPath];
//            shellPath = [NSString stringWithFormat:@"%@%@.sh",currentAppPath,name];
//        }
        
//#ifdef DEBUG
//        NSString *shellPath = [[NSBundle mainBundle] pathForResource:name ofType:@"sh"];
//#else
//        NSString *currentAppPath = [self getCurrentAppPath];
//        NSString *shellPath = [NSString stringWithFormat:@"%@/%@.sh",currentAppPath,name];
//#endif
        
        if (![[NSFileManager defaultManager]fileExistsAtPath:shellPath]) {
            NSString *title = [NSString stringWithFormat:@"%@.sh 脚本不存在",name];
            NSString *msg = [NSString stringWithFormat:@"请检查脚本路径 : %@",shellPath];
            NSApplication *app = [NSApplication sharedApplication];
            
//            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
//                [ArchiveHelper alertTitle:title message:msg forView:app.keyWindow completionHandler:nil];
//                if (failBlock) {
//                    failBlock(msg);
//                }
//            }];
            
            cj_dispatch_async_main_queue(^{
                [ArchiveHelper alertTitle:title message:msg forView:app.keyWindow completionHandler:nil];
                if (failBlock) {
                    failBlock(msg);
                }
            });
        }
        else{
            //1.创建一个新的Task
            NSTask *optTask = [[NSTask alloc] init];
            optTask.launchPath = shellPath;
            
            NSMutableArray *args = [NSMutableArray arrayWithArray:arguments];
            /*
             *  默认传递参数： -e = SHELL_ERROR，shell脚本抛出日志以 SHELL_ERROR 为前缀，OC端接收后判断是否出错
             */
            [args addObjectsFromArray:@[@"-e",SHELL_ERROR,]];
            optTask.arguments = args;
            
            //2.创建一个新的pipe
            NSPipe *outputPipe = [NSPipe pipe];
            [optTask setStandardOutput:outputPipe];
            NSPipe *errorPipe = [NSPipe pipe];
            [optTask setStandardError:errorPipe];
            
            //3.Block 通知
            optTask.terminationHandler = ^(NSTask *theTask) {
                // do your stuff on completion
                [theTask.standardOutput fileHandleForReading].readabilityHandler = nil;
                [theTask.standardError fileHandleForReading].readabilityHandler = nil;
                
//                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
//                    if (responeHandler) {
//                        responeHandler(SHELL_TERMINATION);
//                    }
//                }];
                cj_dispatch_async_main_queue(^{
                    if (responeHandler) {
                        responeHandler(SHELL_TERMINATION);
                    }
                });
            };
            
            
            [[errorPipe fileHandleForReading] setReadabilityHandler:^(NSFileHandle *file) {
                NSData *data = [file availableData]; // this will read to EOF, so call only once
                NSString *text = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                //        printf("++++++++++++++++++++ standardError ++++++++++++++++++++\n%s",[text UTF8String]);
                
//                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
//                    if (responeHandler) {
//                        responeHandler(text);
//                    }
//                }];
                cj_dispatch_async_main_queue(^{
                    if (responeHandler) {
                        responeHandler(text);
                    }
                });
            }];
            
            [[outputPipe fileHandleForReading] setReadabilityHandler:^(NSFileHandle *file) {
                NSData *data = [file availableData];
                NSString *text = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                //        printf("++++++++++++++++++++ standardOutput ++++++++++++++++++++\n%s",[text UTF8String]);
                
//                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
//                    if (responeHandler) {
//                        responeHandler(text);
//                    }
//                }];
                cj_dispatch_async_main_queue(^{
                    if (responeHandler) {
                        responeHandler(text);
                    }
                });
            }];
            
            @try {
                [optTask launch];
            } @catch (NSException *exception) {
                NSLog(@"exception:%@",exception);
                NSString *msg = [NSString stringWithFormat:@"%@脚本出错，脚本路径：%@\n\n获取脚本权限请在终端执行：1、cd到脚本所在路径；2、执行：chmod 777 %@.sh",name,shellPath,name];
                
//                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
//                    if (responeHandler) {
//                        responeHandler(msg);
//                    }
//                }];
                cj_dispatch_async_main_queue(^{
                    if (responeHandler) {
                        responeHandler(msg);
                    }
                });
            }
            
            [optTask waitUntilExit];
            
            [[outputPipe fileHandleForReading] closeFile];
            [[errorPipe fileHandleForReading] closeFile];
        }
    }];
    
}

+ (NSAlert *)alertTitle:(NSString *)title message:(NSString *)message forView:(NSWindow *)view completionHandler:(void (^)(NSModalResponse returnCode))handler {
    NSAlert *alert = [NSAlert new];
    alert.icon = [NSImage imageNamed:@"warn"];
    [alert addButtonWithTitle:@"确定"];
    [alert setMessageText:title];
    [alert setInformativeText:message];
    [alert setAlertStyle:NSAlertStyleWarning];
    [alert beginSheetModalForWindow:view completionHandler:^(NSModalResponse returnCode) {
        if (handler) {
            handler(returnCode);
        } 
    }];
    return alert;
}

+ (void)getAppBundleIdentifierProjectPath:(NSString *)projectPath responeHandler:(void(^)(NSString *AppBundleIdentifier))responeHandler failBlock:(void(^)(NSString *msg))failBlock {
    
    NSArray *args = @[@"-p",projectPath,
                      @"-a",@"BUNDLE_IDENTIFIER",
                      ];
    [self launchShellName:@"xcodebuild" arguments:args responeHandler:^(NSString *msg) {
        if (responeHandler) {
            // 注意！！"AppId：" 要与 shell脚本中的 echo "AppId：${Bundle_Identifier}" 对应
            if ([msg hasPrefix:@"AppId："]) {
                NSRange range = [msg rangeOfString:@"AppId："];
                NSString *AppBundleIdentifier = [msg substringFromIndex:range.location+range.length];
                AppBundleIdentifier = [AppBundleIdentifier stringByReplacingOccurrencesOfString:@";\n" withString:@""];
                AppBundleIdentifier = [AppBundleIdentifier stringByReplacingOccurrencesOfString:@"\n" withString:@""];
                responeHandler(AppBundleIdentifier);
            }
        }
        if (failBlock) {
            if ([msg hasPrefix:SHELL_ERROR]) {
                NSRange range = [msg rangeOfString:SHELL_ERROR];
                NSString *str = [msg substringFromIndex:range.location+range.length];
                str = [str stringByReplacingOccurrencesOfString:@"\n" withString:@""];
                failBlock(str);
            }
        }
    }failBlock:^(NSString *msg) {
        if (failBlock) {
                failBlock(msg);
        }
    }];
}

+ (void)getAppVersionProjectPath:(NSString *)projectPath appID:(NSString *)appID responeHandler:(void(^)(NSString *AppVersion))responeHandler failBlock:(void(^)(NSString *msg))failBlock {
    NSArray *args = @[@"-p",projectPath,
                      @"-a",@"BUNDLE_SHORT_VRESION",
                      @"-n",appID,
                      ];
    [self launchShellName:@"xcodebuild"arguments:args responeHandler:^(NSString *msg) {
        if (responeHandler) {
            // 注意！！"App版本号：" 要与 shell脚本中的 echo "App版本号：${App_Version}" 对应
            if ([msg hasPrefix:@"App版本号："]) {
                msg = [msg stringByReplacingOccurrencesOfString:@"\n" withString:@""];
                responeHandler(msg);
            }
        }
        if (failBlock) {
            if ([msg hasPrefix:SHELL_ERROR]) {
                NSRange range = [msg rangeOfString:SHELL_ERROR];
                NSString *str = [msg substringFromIndex:range.location+range.length];
                str = [str stringByReplacingOccurrencesOfString:@"\n" withString:@""];
                failBlock(str);
            }
        }
    }failBlock:^(NSString *msg) {
        if (failBlock) {
            failBlock(msg);
        }
    }];
}

+ (BOOL)isOutOfDateTime:(NSDate *)expirationDate outDay:(NSInteger)outDay {
    
    //获取当前的系统时间
    NSDate *date = [NSDate date];
    //消除8小时的误差。
    NSTimeZone *zone = [NSTimeZone systemTimeZone];
    NSInteger interval = [zone secondsFromGMTForDate:date];
    
    //追加8小时
    NSDate *localeDate = [date dateByAddingTimeInterval:interval];
    //计算时间差间隔
    NSTimeInterval timeBetween = [expirationDate timeIntervalSinceDate:localeDate];
    
    //根据相差的秒数，看是否大于7天
    if (timeBetween > outDay * 24 * 3600) {
        return YES;
    }
    return NO;
}

@end
