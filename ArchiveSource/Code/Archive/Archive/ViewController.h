//
//  ViewController.h
//  Archive
//
//  Created by ChiJinLian on 2018/3/23.
//  Copyright © 2018年 ChiJinLian. All rights reserved.
//

#import <Cocoa/Cocoa.h>
//证书失效日期（默认一个月30天）
#define EXPIRATION_DAY  30

@interface ViewController : NSViewController

@end

@interface MyMenuItem : NSMenuItem
@property (nonatomic, copy) NSString *appBundleIdentifier;
@end

