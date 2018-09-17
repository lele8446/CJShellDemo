//
//  CJShellHelper.m
//  CJCrashTools
//
//  Created by ChiJinLian on 2017/9/11.
//  Copyright © 2017年 ChiJinLian. All rights reserved.
//

#import "CJShellHelper.h"

@implementation CJShellHelper

+ (void)launchShellName:(NSString *)name arguments:(NSArray *)arguments responeHandler:(void(^)(NSString *msg))responeHandler failBlock:(void(^)(NSString *msg))failBlock {
    
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    /**设置最大并发数*/
    //    queue.maxConcurrentOperationCount = 1;
    [queue addOperationWithBlock:^(void) {
        
        NSString *shellPath = [[NSBundle mainBundle] pathForResource:name ofType:@"sh"];
        
        if (![[NSFileManager defaultManager]fileExistsAtPath:shellPath]) {
            NSString *title = [NSString stringWithFormat:@"%@.sh 脚本不存在",name];
            NSString *msg = [NSString stringWithFormat:@"请检查脚本路径 : %@",shellPath];
            NSApplication *app = [NSApplication sharedApplication];
            
            cj_dispatch_async_main_queue(^{
                [self alertTitle:title message:msg forView:app.keyWindow completionHandler:nil];
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
                [theTask.standardOutput fileHandleForReading].readabilityHandler = nil;
                [theTask.standardError fileHandleForReading].readabilityHandler = nil;
                
//                cj_dispatch_async_main_queue(^{
//                    if (responeHandler) {
//                        responeHandler(SHELL_TERMINATION);
//                    }
//                });
            };
            
            
            [[errorPipe fileHandleForReading] setReadabilityHandler:^(NSFileHandle *file) {
                NSData *data = [file availableData];
                NSString *text = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                cj_dispatch_async_main_queue(^{
                    if (responeHandler) {
                        responeHandler(text);
                    }
                });
            }];
            
            [[outputPipe fileHandleForReading] setReadabilityHandler:^(NSFileHandle *file) {
                NSData *data = [file availableData];
                NSString *text = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
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

+ (void)dsymUUID:(NSString *)path cpuType:(NSString *)cpuType responeHandler:(void(^)(NSString *UUID))responeHandler failBlock:(void(^)(NSString *msg))failBlock
{
    NSArray *args = @[@"-p",path,
                      @"-a",@"GET_UUID",
                      ];
    [self launchShellName:@"crash" arguments:args responeHandler:^(NSString *msg) {
        if (responeHandler && msg.length > 0) {

            NSArray *UUIDArray = [msg componentsSeparatedByString:@"\n"];
            
            BOOL getUUIDSuccess = NO;
            for (NSString *uuidStr in UUIDArray) {
                NSString *cupRangeStr = [NSString stringWithFormat:@" (%@",cpuType];
                NSRange range = [uuidStr rangeOfString:cupRangeStr];
                if (range.location != NSNotFound) {
                    NSRange uuidRange = [uuidStr rangeOfString:@"UUID: "];
                    NSRange uuidStrRange = NSMakeRange(uuidRange.location+uuidRange.length, range.location-range.length+1);
                    NSString *uuid = [uuidStr substringWithRange:uuidStrRange];
                    responeHandler(uuid);
                    getUUIDSuccess = YES;
                    break;
                }
            }
            
            if (!getUUIDSuccess) {
                failBlock(@"******************** 获取UUID失败！！ ********************");
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
    } failBlock:^(NSString *msg) {
        if (failBlock) {
            failBlock(msg);
        }
    }];
}

+ (void)analyzedSYMPath:(NSString *)path cpuType:(NSString *)cpuType address:(NSString *)address responeHandler:(void(^)(NSString *log))responeHandler failBlock:(void(^)(NSString *msg))failBlock
{
    if (address.length <= 0) {
        NSString *title = @"内存地址缺失";
        NSString *msg = @"请填写错误信息内存地址";
        NSApplication *app = [NSApplication sharedApplication];
        [self alertTitle:title message:msg forView:app.keyWindow completionHandler:nil];
        return;
    }
    
    NSArray *args = @[@"-p",path,
                      @"-a",@"CRASH_ANALYZE",
                      @"-t",cpuType,
                      @"-c",address
                      ];
    [self launchShellName:@"crash" arguments:args responeHandler:^(NSString *msg) {
        if (responeHandler && msg.length > 0) {
            responeHandler(msg);
        }
        if (failBlock) {
            if ([msg hasPrefix:SHELL_ERROR]) {
                NSRange range = [msg rangeOfString:SHELL_ERROR];
                NSString *str = [msg substringFromIndex:range.location+range.length];
                str = [str stringByReplacingOccurrencesOfString:@"\n" withString:@""];
                failBlock(str);
            }
        }
    } failBlock:^(NSString *msg) {
        if (failBlock) {
            failBlock(msg);
        }
    }];
}

+ (void)exportLogdSYMPath:(NSString *)path log:(NSString *)log responeHandler:(void(^)(NSString *log))responeHandler failBlock:(void(^)(NSString *msg))failBlock {
    
    if (path.length <= 0) {
        NSString *title = @"导出错误";
        NSString *msg = @"没有需要导出的日志文件";
        NSApplication *app = [NSApplication sharedApplication];
        [self alertTitle:title message:msg forView:app.keyWindow completionHandler:nil];
        return;
    }
    
    if (log.length <= 0) {
        NSString *title = @"导出错误";
        NSString *msg = @"没有需要导出的日志文件";
        NSApplication *app = [NSApplication sharedApplication];
        [self alertTitle:title message:msg forView:app.keyWindow completionHandler:nil];
        return;
    }
    
    NSArray *args = @[@"-p",path,
                      @"-a",@"EXPORT_LOG",
                      @"-l",log
                      ];
    [self launchShellName:@"crash" arguments:args responeHandler:^(NSString *msg) {
        if (responeHandler && msg.length > 0) {
            responeHandler(msg);
        }
        if (failBlock) {
            if ([msg hasPrefix:SHELL_ERROR]) {
                NSRange range = [msg rangeOfString:SHELL_ERROR];
                NSString *str = [msg substringFromIndex:range.location+range.length];
                str = [str stringByReplacingOccurrencesOfString:@"\n" withString:@""];
                failBlock(str);
            }
        }
    } failBlock:^(NSString *msg) {
        if (failBlock) {
            failBlock(msg);
        }
    }];
}
@end
