//
//  ViewController.m
//  CJCrashTools
//
//  Created by ChiJinLian on 2017/9/10.
//  Copyright © 2017年 ChiJinLian. All rights reserved.
//

#import "ViewController.h"
#import "CJDragDropView.h"
#import "CJShellHelper.h"

@interface ViewController ()<CJDragDropViewDelegate>
@property (nonatomic, weak)IBOutlet CJDragDropView *dragDropView;
@property (nonatomic, weak)IBOutlet NSTextView *dsymPathView;
@property (nonatomic, weak)IBOutlet NSTextField *placeholderLabel;

@property (nonatomic, weak)IBOutlet NSButton *arm64Button;
@property (nonatomic, weak)IBOutlet NSButton *armv7Button;

@property (nonatomic, weak)IBOutlet NSButton *analyzeButton;

@property (nonatomic, weak)IBOutlet NSTextField *UUIDField;
/**
 默认内存地址偏移量
 */
@property (nonatomic, weak)IBOutlet NSTextField *slideAddressField;
/**
 错误内存地址
 */
@property (nonatomic, weak)IBOutlet NSTextField *crashAddressField;

//日志
@property (nonatomic, strong) NSMutableString *logStr;
@property (nonatomic, weak) IBOutlet NSTextView *logScrollView;
@end

@implementation ViewController

- (void)windowDidLoad {
    [super windowDidLoad];
    self.dragDropView.delegate = self;
    self.arm64Button.enabled =
    self.armv7Button.enabled =
    self.analyzeButton.enabled = NO;
    
    self.logStr = [[NSMutableString alloc]initWithCapacity:3];
    [self.logStr setString:@""];
    self.logScrollView.string = @"";
}

- (IBAction)exportLog:(id)sender {
    [CJShellHelper exportLogdSYMPath:self.dsymPathView.string log:self.logScrollView.string responeHandler:^(NSString *log) {
        
    } failBlock:^(NSString *msg) {
        
    }];
}


- (IBAction)aboutMe:(id)sender {
    NSAlert *alert = [NSAlert new];
    alert.icon = [NSImage imageNamed:@"warn"];
    [alert addButtonWithTitle:@"确定"];
    [alert setMessageText:@"关于"];
    [alert setInformativeText:@"CJCrashTools 作者 ChiJinLian"];
    [alert setAlertStyle:NSAlertStyleInformational];
    [alert beginSheetModalForWindow:[NSApplication sharedApplication].keyWindow completionHandler:^(NSModalResponse returnCode) {
        
    }];
}

- (void)dragDropViewFileLists:(NSArray*)fileLists {
    self.placeholderLabel.hidden = YES;
    self.arm64Button.enabled = self.armv7Button.enabled = YES;
    self.dsymPathView.string = fileLists[0];
    
    [self.logStr setString:@""];
    self.logScrollView.string = self.logStr;
}

- (IBAction)openFinder:(id)sender {
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    [panel setCanChooseFiles:YES];  //是否能选择文件file
    [panel setCanChooseDirectories:NO];  //是否能打开文件夹
    [panel setAllowsMultipleSelection:YES];  //是否允许多选file
    [panel setAllowedFileTypes:@[@"dSYM"]];
    
    NSInteger finded = [panel runModal];   //获取panel的响应
    if (finded == NSModalResponseOK) {
        //   NSFileHandlingPanelCancelButton    = NSModalResponseCancel；
        //   NSFileHandlingPanelOKButton        = NSModalResponseOK,
        
        BOOL projectFile = NO;
        for (NSURL *url in [panel URLs]) {
            
            NSString *path = url.absoluteString;
            path = [path stringByRemovingPercentEncoding];
            NSString *fileExtension = [path pathExtension];
            if ([fileExtension isEqualToString:@"dSYM"]) {
                path = [path stringByReplacingOccurrencesOfString:@"file://" withString:@""];
                projectFile = YES;
                self.placeholderLabel.hidden = YES;
                self.dsymPathView.string = path;
                self.arm64Button.enabled = self.armv7Button.enabled = YES;
                [self.logStr setString:@""];
                self.logScrollView.string = self.logStr;
                break;
            }
        }
        if (!projectFile) {
            NSAlert *alert = [NSAlert new];
            [alert addButtonWithTitle:@"确定"];
            [alert setMessageText:@"请选择dSYM文件"];
            [alert setInformativeText:@"只能选择 .dSYM 文件"];
            [alert setAlertStyle:NSAlertStyleWarning];
            [alert beginSheetModalForWindow:[self window] completionHandler:^(NSModalResponse returnCode) {
            }];
        }
    }
}

- (IBAction)select64CPUButton:(NSButton *)sender {
    self.armv7Button.state = NSControlStateValueOff;
    [CJShellHelper dsymUUID:self.dsymPathView.string cpuType:CPU_ARM64 responeHandler:^(NSString *UUID) {
        self.UUIDField.stringValue = UUID;
        self.slideAddressField.stringValue = @"0x100000000";
        self.analyzeButton.enabled = YES;
    } failBlock:^(NSString *msg) {
        
    }];
}

- (IBAction)select7CPUButton:(NSButton *)sender {
    self.arm64Button.state = NSControlStateValueOff;
    [CJShellHelper dsymUUID:self.dsymPathView.string cpuType:CPU_ARMV7 responeHandler:^(NSString *UUID) {
        self.UUIDField.stringValue = UUID;
        self.slideAddressField.stringValue = @"0x000004000";
        self.analyzeButton.enabled = YES;
    } failBlock:^(NSString *msg) {
        
    }];
}

- (IBAction)analyzeButtonClick:(NSButton *)sender {
    [self.logStr setString:@""];
    self.logScrollView.string = self.logStr;
    NSString *cpuType = CPU_ARM64;
    if (self.arm64Button.state == NSControlStateValueOn) {
        cpuType = CPU_ARM64;
    }else {
        cpuType = CPU_ARMV7;
    }
    [CJShellHelper analyzedSYMPath:self.dsymPathView.string cpuType:cpuType address:self.crashAddressField.stringValue responeHandler:^(NSString *log) {
        [self changeLogStr:log];
    } failBlock:^(NSString *msg) {
        
    }];
}


- (void)changeLogStr:(NSString *)msg {
    if (msg.length > 0) {
        [self.logStr appendString:msg];
        self.logScrollView.string = self.logStr;
    }
}
@end
