//
//  ViewController.m
//  Archive
//
//  Created by ChiJinLian on 2018/3/23.
//  Copyright © 2018年 ChiJinLian. All rights reserved.
//

#import "ViewController.h"
#import "ArchiveHelper.h"
#import "IPAToolUtls.h"
#import "YAProvisioningProfile.h"
#import <objc/runtime.h>

static char kAssociatedProvisioningProfile;

@interface ViewController ()<NSComboBoxDelegate>
{
    NSDate *_startDate;
    NSAlert *_alert;
}
@property (nonatomic, weak) IBOutlet NSButton *finderButton;
@property (nonatomic, weak) IBOutlet NSButton *refreshButton;
//项目路径
@property (nonatomic, weak) IBOutlet NSTextView *projPathScrollView;
@property (nonatomic, weak) IBOutlet NSTextField *placeholderLabel;
//同步代码勾选
@property (nonatomic, weak) IBOutlet NSButton *updateCodeButton;
//拉取代码
@property (nonatomic, weak) IBOutlet NSButton *pullCodeButton;
@property (nonatomic, weak) IBOutlet NSButton *xcodeBuildButton;
//推送代码
@property (nonatomic, weak) IBOutlet NSButton *pushCodeButton;
//APP_ID
@property (nonatomic, weak) IBOutlet NSComboBox *appIDButton;
@property (nonatomic, weak) IBOutlet NSTextField *appIDWarnLabel;

//版本号
@property (nonatomic, weak) IBOutlet NSTextField *majorTextField;
@property (nonatomic, weak) IBOutlet NSTextField *minorTextField;
@property (nonatomic, weak) IBOutlet NSTextField *codeTextField;
@property (nonatomic, weak) IBOutlet NSButton *addCodeNumButton;
@property (nonatomic, weak) IBOutlet NSTextField *versionWarnLabel;

//默认签名
@property (nonatomic, weak) IBOutlet NSButton *signButton;
@property (nonatomic, weak) IBOutlet NSButton *openProjButton;
//打包证书
@property (nonatomic, weak) IBOutlet NSPopUpButton *signIdentityButton;
//描述文件
@property (nonatomic, weak) IBOutlet NSPopUpButton *profileButton;

//日志
@property (nonatomic, weak) IBOutlet NSTextView *logScrollView;
//菊花
@property (nonatomic, weak) IBOutlet NSProgressIndicator *indicatorView;

//ExportOptions.plist
@property (nonatomic, copy) NSString *exportOptionsPath;
@property (nonatomic, weak) IBOutlet NSButton *plistButton;
@property (nonatomic, weak) IBOutlet NSTextField *plistWarnLabel;

//一键打包
@property (nonatomic, weak) IBOutlet NSButton *archiveButton;
//耗时
@property (nonatomic, weak) IBOutlet NSTextField *timeLabel;

@property (nonatomic, copy) NSString *prjPath;
@property (nonatomic, copy) NSString *appIDStr;
@property (nonatomic, assign) BOOL autoGitAction;//自动管理Git操作
@property (nonatomic, assign) BOOL needUpdateCode;//是否需要更新代码
//@property (nonatomic, assign) BOOL autoSignIdentity;//选择默认打包证书
@property (nonatomic, assign) BOOL haveSelectProfile;//是否成功选择打包证书
@property (nonatomic, strong) NSMutableString *logStr;
@property (nonatomic, strong) NSMutableArray *provisioningArray;

@end

@implementation ViewController

- (NSString *)prjPath {
    return [self.projPathScrollView.string stringByDeletingLastPathComponent];
}

- (void)setAutoGitAction:(BOOL)autoGitAction {
    _autoGitAction = autoGitAction;
    if (autoGitAction) {
        self.pullCodeButton.enabled =
        self.pushCodeButton.enabled =
        self.xcodeBuildButton.enabled = YES;
    }else{
        self.pullCodeButton.enabled =
        self.pushCodeButton.enabled =
        self.xcodeBuildButton.enabled = NO;
    }
}

- (void)setNeedUpdateCode:(BOOL)needUpdateCode {
    _needUpdateCode = needUpdateCode;
    if (needUpdateCode) {
        self.appIDButton.enabled =
        self.majorTextField.enabled =
        self.minorTextField.enabled =
        self.codeTextField.enabled =
        self.addCodeNumButton.enabled =
        self.signButton.enabled = 
        self.archiveButton.enabled = NO;
    }else{
        self.appIDButton.enabled =
        self.majorTextField.enabled =
        self.minorTextField.enabled =
        self.codeTextField.enabled =
        self.addCodeNumButton.enabled =
        self.signButton.enabled =
        self.archiveButton.enabled = YES;
    }
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"一键打包";
    [self doSomethingDefault];
    [self selectExportOptionsPlist];
}

- (void)doSomethingDefault {
    self.logStr = [[NSMutableString alloc]initWithCapacity:3];
    [self.logStr setString:@""];
    self.logScrollView.string = @"";
    self.exportOptionsPath = @"";
    
    self.provisioningArray = [NSMutableArray array];
    
    self.projPathScrollView.font = [NSFont systemFontOfSize:13];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textViewDidChange:) name:NSTextViewDidChangeSelectionNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textDidEndEditing:) name:NSControlTextDidEndEditingNotification object:nil];
    
    self.autoGitAction = NO;
    self.needUpdateCode = YES;
    self.haveSelectProfile = NO;
    self.appIDButton.delegate = self;
    
}

- (void)selectExportOptionsPlist {
    NSString *appPath = [ArchiveHelper getCurrentAppPath];
    NSString *exportOptionsPlist = [NSString stringWithFormat:@"%@/ExportOptions.plist",appPath];
    if ([[NSFileManager defaultManager]fileExistsAtPath:exportOptionsPlist]) {
        self.exportOptionsPath = exportOptionsPlist;
        self.plistButton.image = [NSImage imageNamed:@"plistFile"];
        self.plistWarnLabel.stringValue = @"已选择导出.ipa包配置文件ExportOptions.plist";
    }
}

- (void)clearDataFromSelectProj:(BOOL)selectProj; {
    [self.logStr setString:@""];
    self.logScrollView.string = @"";
    self.appIDStr = @"";
    self.majorTextField.stringValue =
    self.minorTextField.stringValue =
    self.codeTextField.stringValue = @"";
    self.haveSelectProfile = NO;
    if (selectProj) {
        self.appIDButton.stringValue = @"";
        [self.appIDButton removeAllItems];
        [self.signIdentityButton removeAllItems];
        [self.profileButton removeAllItems];
    }
}

- (void)textViewDidChange:(NSNotification *)aNotification {
    if (self.projPathScrollView.string.length > 0) {
        self.placeholderLabel.hidden = YES;
    }else{
        self.placeholderLabel.hidden = NO;
    }
}
- (void)textDidEndEditing:(NSNotification *)aNotification {
    NSTextField *textField = (NSTextField *)aNotification.object;
    if (textField == self.appIDButton) {
        [self clearDataFromSelectProj:NO];
        self.appIDStr = self.appIDButton.stringValue;
        //选择证书
        self.haveSelectProfile = [self selectProfileSuccess:self.appIDStr];
        self.appIDWarnLabel.hidden = YES;
        [self getAppVersion:self.prjPath afterGetAppID:NO];
    }
}

#pragma mark - NSComboBoxDelegate
#pragma mark 选择APP ID
- (void)comboBoxSelectionIsChanging:(NSNotification *)notification {
    [self clearDataFromSelectProj:NO];
    self.appIDStr = self.appIDButton.objectValues[self.appIDButton.indexOfSelectedItem];
    //选择证书
    self.haveSelectProfile = [self selectProfileSuccess:self.appIDStr];
    [self getAppVersion:self.prjPath afterGetAppID:NO];
}

#pragma mark 获取打包证书以及Profile描述文件
- (void)loadCerAndProfileData {
    [self signIdentityButtonData];
    [self profileButtonData];
}

- (void)signIdentityButtonData {
    [self.signIdentityButton removeAllItems];
    __weak __typeof(self) weakSelf = self;
    [IPAToolUtls loadCerListBlock:^(NSMutableArray *cerArray) {
        NSMutableArray *ary = [NSMutableArray arrayWithArray:cerArray];
        //追加一个空证书
        [ary addObject:@" "];
        [weakSelf.signIdentityButton addItemsWithTitles:ary];
    }];
}

- (void)profileButtonData {
    [self.profileButton removeAllItems];
    [self.provisioningArray removeAllObjects];
    
    NSMutableArray *allProArray = [[NSMutableArray alloc] init];
    NSArray *prolist = [IPAToolUtls getAllProvisioningProfileList];
    [prolist enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSString *path = [NSString stringWithFormat:@"%@/%@/%@", NSHomeDirectory(), kMobileprovisionDirName,obj];
        YAProvisioningProfile *profile = [[YAProvisioningProfile alloc] initWithPath:path];
//        if ([profile.debug isEqualToString:@"NO"] && [profile.valid isEqualToString:@"YES"]){
//            [allProArray addObject:profile];
//        }
        [allProArray addObject:profile];
    }];
    
    NSMutableArray *handleProNameArray = [NSMutableArray arrayWithCapacity:3];
    [allProArray enumerateObjectsUsingBlock:^(YAProvisioningProfile *profile, NSUInteger idx, BOOL * _Nonnull stop) {
        [self handleProfile:profile handleProNameArray:handleProNameArray allProArray:allProArray];
    }];
    
    NSArray *proArray = [allProArray copy];
    //排序
    self.provisioningArray = [[proArray sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        return [((YAProvisioningProfile *)obj1).name compare:((YAProvisioningProfile *)obj2).name];
    }] mutableCopy];
    
    __weak typeof(self)weakSelf = self;
    [self.provisioningArray enumerateObjectsUsingBlock:^(YAProvisioningProfile *obj, NSUInteger idx, BOOL * _Nonnull stop) {
//        [weakSelf.profileButton addItemWithTitle:[NSString stringWithFormat:@"%@(%@)",obj.name,obj.teamIdentifier]];
        
        NSMenuItem *item = [[NSMenuItem alloc] init];
        if (![ArchiveHelper isOutOfDateTime:obj.expirationDate outDay:EXPIRATION_DAY]) {
            NSAttributedString *expirationStr = [[NSAttributedString alloc]initWithString:@"（即将失效!!）" attributes:@{NSForegroundColorAttributeName:[NSColor redColor]}];
            NSMutableAttributedString *str = [[NSMutableAttributedString alloc]initWithString:[NSString stringWithFormat:@"%@(%@) 失效日期:%@",obj.name,obj.teamIdentifier,obj.expirationDate]];
            [str appendAttributedString:expirationStr];
            [item setAttributedTitle:str];
        }else{
            [item setTitle:[NSString stringWithFormat:@"%@(%@) 失效日期:%@",obj.name,obj.teamIdentifier,obj.expirationDate]];
        }
        
        objc_setAssociatedObject(item, &kAssociatedProvisioningProfile, obj, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        [weakSelf.profileButton.menu addItem:item];
    }];
    //追加一个空证书
    NSMenuItem *item = [[NSMenuItem alloc] init];
    [item setTitle:@" "];
    [self.profileButton.menu addItem:item];
}

- (void)handleProfile:(YAProvisioningProfile *)profile handleProNameArray:(NSMutableArray *)handleProNameArray allProArray:(NSArray *)allProArray {
    if ([handleProNameArray containsObject:profile.name]) {
        return;
    }
    else{
        [handleProNameArray addObject:profile.name];
        
        YAProvisioningProfile *newestProfile = profile;
        for (int j = 0; j < allProArray.count; j ++) {
            YAProvisioningProfile *tempProfile = allProArray[j];
            if ([profile.name isEqualToString:tempProfile.name]) {
                if ([[newestProfile.expirationDate laterDate:tempProfile.expirationDate] isEqualToDate:tempProfile.expirationDate]) {
                    newestProfile = tempProfile;
                }
            }
        }
        
        for (YAProvisioningProfile *pro in allProArray) {
            if ([profile.name isEqualToString:pro.name]) {
                if ([pro isEqual:newestProfile]) {
                    pro.newest = YES;
                }else{
                    pro.newest = NO;
                }
            }
        }
    }
}

#pragma mark - button click
#pragma mark 选择项目文件
- (IBAction)openFinder:(id)sender {
    NSOpenPanel *panel = [NSOpenPanel openPanel];
//    [panel setDirectoryURL:[NSURL URLWithString:NSHomeDirectory()]];//起始目录为Home
    [panel setCanChooseFiles:YES];  //是否能选择文件file
    [panel setCanChooseDirectories:NO];  //是否能打开文件夹
    [panel setAllowsMultipleSelection:YES];  //是否允许多选file
    [panel setAllowedFileTypes:@[@"xcworkspace",@"xcodeproj"]];
    
    NSInteger finded = [panel runModal];   //获取panel的响应
    if (finded == NSFileHandlingPanelOKButton) {
        //   NSFileHandlingPanelCancelButton    = NSModalResponseCancel； NSFileHandlingPanelOKButton    = NSModalResponseOK,
        
        BOOL projectFile = NO;
        for (NSURL *url in [panel URLs]) {
            
            NSString *path = url.absoluteString;
            NSString *fileExtension = [path pathExtension];
            if ([fileExtension isEqualToString:@"xcodeproj"] || [fileExtension isEqualToString:@"xcworkspace"]) {
                path = [path stringByReplacingOccurrencesOfString:@"file://" withString:@""];
                self.projPathScrollView.string = path;
                projectFile = YES;
                break;
            }
        }
        if (!projectFile) {
            NSAlert *alert = [NSAlert new];
            [alert addButtonWithTitle:@"确定"];
            [alert setMessageText:@"请选择项目文件"];
            [alert setInformativeText:@"只能选择 .xcodeproj 或 .xcworkspace 文件"];
            [alert setAlertStyle:NSAlertStyleWarning];
            [alert beginSheetModalForWindow:[self.view window] completionHandler:^(NSModalResponse returnCode) {
            }];
        }else{
            self.refreshButton.hidden = NO;
            [self refreshProj:self.openProjButton];
        }
    }
}

- (IBAction)refreshProj:(id)sender {
    [self clearDataFromSelectProj:YES];
    if (self.autoGitAction) {
        if (self.updateCodeButton.state == NSOnState) {
            [self.indicatorView startAnimation:nil];
            self.pullCodeButton.enabled = YES;
            //获取AppBundleIdentifier
            [self getAppBundleIdentifier];
        }
    }else{
        [self.indicatorView startAnimation:nil];
        //获取AppBundleIdentifier
        [self getAppBundleIdentifier];
    }
}

#pragma mark 点击同步代码
- (IBAction)updateCodeButtonClick:(NSButton *)sender {
    if ([sender state] == NSOnState) {
        self.autoGitAction = YES;
        self.updateCodeButton.title = @"注意⚠️勾选后每次打包会自动管理git操作";
    }else {
        self.autoGitAction = NO;
        self.updateCodeButton.title = @"手动管理Git操作";
    }
}
#pragma mark git操作
- (IBAction)gitButtonClick:(NSButton *)sender {
    if ([self projectPathIsNull]) {
        return;
    }
    
    //拉取代码，并build项目
    if ([sender tag] == 101) {
        [self startActionLog:@"拉取代码"];
        NSArray *args = @[@"-p",self.prjPath,
                          @"-a",@"pull origin",
                          ];
        [self launchShellName:@"git" arguments:args completionHandler:^{
            self.needUpdateCode = NO;
            [self xcodeBuild];
        }];
    }
    //提交代码到git
    else {
        
        NSString *commitStr = [NSString stringWithFormat:@"add ."];
        [self startActionLog:@"代码入栈"];
        NSArray *args = @[@"-p",self.prjPath,
                          @"-a",commitStr,
                          ];
        [self launchShellName:@"git" arguments:args completionHandler:^{
            if (!_alert) {
                NSString *appVersion = [NSString stringWithFormat:@"%@.%@.%@",self.majorTextField.stringValue,self.minorTextField.stringValue,self.codeTextField.stringValue];
                NSString *commitStr = [NSString stringWithFormat:@"commit -m \"%@版本号v%@提交打包配置\"",self.appIDButton.stringValue,appVersion];
                [self startActionLog:@"提交代码"];
                NSArray *args = @[@"-p",self.prjPath,
                                  @"-a",commitStr,
                                  ];
                [self launchShellName:@"git" arguments:args completionHandler:^{
                    if (!_alert) {
                        [self startActionLog:@"推送代码"];
                        NSArray *args = @[@"-p",self.prjPath,
                                          @"-a",@"push origin",
                                          ];
                        [self launchShellName:@"git" arguments:args completionHandler:^{
                            [self startActionLog:@"代码推送成功"];
                        }];
                    }
                }];
            }
        }];
    }
}
//同步代码
- (IBAction)xcodeBuildButtonClick:(NSButton *)sender {
    if ([sender state] == NSOnState) {
        self.xcodeBuildButton.title = @"拉取代码后自动执行Xcode Build";
    }else {
        self.xcodeBuildButton.title = @"不同步执行Xcode Build";
    }
}

//同步代码
- (IBAction)selectPlist:(NSButton *)sender {
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    [panel setCanChooseFiles:YES];  //是否能选择文件file
    [panel setCanChooseDirectories:NO];  //是否能打开文件夹
    [panel setAllowsMultipleSelection:NO];  //是否允许多选file
    [panel setAllowedFileTypes:@[@"plist",]];
    
    NSInteger finded = [panel runModal];   //获取panel的响应
    if (finded == NSFileHandlingPanelOKButton) {
        
        BOOL plistFile = NO;
        for (NSURL *url in [panel URLs]) {
            
            NSString *path = url.absoluteString;
            NSString *fileName = [path lastPathComponent];
            if ([fileName isEqualToString:@"ExportOptions.plist"]) {
                path = [path stringByReplacingOccurrencesOfString:@"file://" withString:@""];
                self.exportOptionsPath = path;
                plistFile = YES;
                break;
            }
        }
        
        if (plistFile) {
            self.plistButton.image = [NSImage imageNamed:@"plistFile"];
            self.plistWarnLabel.stringValue = @"已选择导出.ipa包配置文件ExportOptions.plist";
        }else{
            self.plistButton.image = [NSImage imageNamed:@"FileMiss"];
            self.plistWarnLabel.stringValue = @"❌请选择ExportOptions.plist文件";
            self.exportOptionsPath = @"";
        }
        
    }
}

#pragma mark 点击默认签名
- (IBAction)signButtonClick:(NSButton *)sender {
    if ([self projectPathIsNull]) {
        sender.state = !sender.state;
        return;
    }
    if ([sender state] == NSOnState) {
        [self loadCerAndProfileData];
        //选择证书
        self.haveSelectProfile = [self selectProfileSuccess:self.appIDButton.stringValue];
    }else {
        self.signIdentityButton.enabled =
        self.profileButton.enabled = YES;
        self.openProjButton.hidden = NO;
        self.signButton.title = @"手动选择证书，请确保Xcode项目证书配置与所选证书相同";
    }
}

- (IBAction)operProjFile:(NSButton *)sender {
    
    NSTask *optTask = [[NSTask alloc] init];
    optTask.launchPath = @"/bin/bash";
    
    NSPipe *outputPipe = [NSPipe pipe];
    [optTask setStandardOutput:outputPipe];
    NSPipe *errorPipe = [NSPipe pipe];
    [optTask setStandardError:errorPipe];
    
    [optTask setStandardOutput:outputPipe];
    [optTask setStandardError:errorPipe];
    
    
    NSString *prjName = [[self.projPathScrollView.string lastPathComponent] stringByDeletingPathExtension];
    NSString *prjNamePath = [NSString stringWithFormat:@"%@/%@.xcworkspace",self.prjPath,prjName];
    if (![[NSFileManager defaultManager]fileExistsAtPath:prjNamePath]) {
        prjNamePath = [NSString stringWithFormat:@"%@/%@.xcodeproj",self.prjPath,prjName];
        if (![[NSFileManager defaultManager]fileExistsAtPath:prjNamePath]) {
            [ArchiveHelper alertTitle:@"项目文件不存在" message:prjNamePath forView:[self.view window] completionHandler:nil];
            return;
        }
    }
    
    // -c 用来执行string-commands（命令字符串），也就说不管后面的字符串里是什么都会被当做shellcode来执行
    NSString *cmd = [NSString stringWithFormat:@"cd %@; open %@",self.prjPath,prjNamePath];
    NSArray *arguments = [NSArray arrayWithObjects: @"-c", cmd, nil];
    [optTask setArguments:arguments];
    
    optTask.terminationHandler = ^(NSTask *theTask) {
        [theTask.standardOutput fileHandleForReading].readabilityHandler = nil;
        [theTask.standardError fileHandleForReading].readabilityHandler = nil;
    };
    
    @try {
        [optTask launch];
    } @catch (NSException *exception) {
        NSLog(@"exception:%@",exception);
    }
    
    [optTask waitUntilExit];
    [[outputPipe fileHandleForReading] closeFile];
    [[errorPipe fileHandleForReading] closeFile];
}

#pragma mark 版本号 +1
- (IBAction)changeNum:(NSButton *)sender {
    if ([self projectPathIsNull]) {
        return;
    }
    NSInteger codeNum = [self.codeTextField.stringValue integerValue];
    if (sender.tag == 100) {
        codeNum ++;
    }else{
        codeNum --;
        codeNum = (codeNum <= 0)?0:codeNum;
    }
    self.codeTextField.stringValue = [NSString stringWithFormat:@"%ld",(long)codeNum];
}
#pragma mark 点击打包
- (IBAction)archiveClick:(id)sender {
    if ([self projectPathIsNull]) {
        return;
    }
    
    if (self.exportOptionsPath.length <= 0) {
        [ArchiveHelper alertTitle:@"请选择ExportOptions.plist" message:@"请选择ExportOptions.plist文件" forView:[self.view window] completionHandler:nil];
        return;
    }
    
    if (self.majorTextField.stringValue.length <= 0 || self.minorTextField.stringValue.length <= 0 || self.codeTextField.stringValue.length <= 0) {
        [ArchiveHelper alertTitle:@"打包版本号不完整" message:@"请填写打包版本号" forView:[self.view window] completionHandler:nil];
        return;
    }
    
    self.timeLabel.stringValue = @"";
    _startDate = [NSDate date];
    [self changeLogStr:@"\n+++++++++++++++++++++++++++++++++++++++++++++++++\n"];
    [self changeLogStr:@"++++++++++++++++++   开始打包   +++++++++++++++++++++\n"];
    [self changeLogStr:@"+++++++++++++++++++++++++++++++++++++++++++++++++\n"];
    
    if (self.signButton.state == NSOnState && self.haveSelectProfile) {
        [self isArchiving:YES];
        [self changePbxprojConfigCompletionHandler:^{
            [self archiveIPA];
        }];
    }else{
        [self isArchiving:YES];
        [self archiveIPA];
    }
}

- (void)isArchiving:(BOOL)archiving {
    if (archiving) {
        self.needUpdateCode = YES;
        self.updateCodeButton.enabled = 
        self.finderButton.enabled =
        self.pullCodeButton.enabled =
        self.pushCodeButton.enabled =
        self.plistButton.enabled =
        self.refreshButton.enabled =
        self.openProjButton.enabled =
        self.xcodeBuildButton.enabled = NO;
    }else{
        self.needUpdateCode = NO;
        self.updateCodeButton.enabled =
        self.finderButton.enabled =
        self.pullCodeButton.enabled =
        self.pushCodeButton.enabled =
        self.plistButton.enabled =
        self.refreshButton.enabled =
        self.openProjButton.enabled =
        self.xcodeBuildButton.enabled = YES;
    }
}

- (void)changePbxprojConfigCompletionHandler:(void (^)(void))handler {
    
    [self startActionLog:@"修改 project.pbxproj 文件配置"];
    
    NSString *signCerIdentity = self.signIdentityButton.selectedItem.title;
    
    NSMenuItem *item = self.profileButton.selectedItem;
    YAProvisioningProfile *profile = objc_getAssociatedObject(item, &kAssociatedProvisioningProfile);
    NSArray *args = @[@"-p",self.prjPath,//项目文件路径
                      @"-n",self.appIDStr,// AppID
                      @"-a",@"PBXPROJ_CONFING", // 操作类型：打包
                      @"-s",signCerIdentity,//企业证书
                      @"-f",profile.UUID,//描述文件
                      @"-r",profile.name,//PROVISIONING_PROFILE_SPECIFIER（证书名）
                      @"-d",profile.teamIdentifier,//PRODUCT_NAME（开发者团队id）
                      ];
    
    [self launchShellName:@"xcodebuild" arguments:args completionHandler:^{
        if (_alert) {
            [self updateTimeout];
            [self isArchiving:NO];
        }else{
            if (handler) {
                handler();
            }
        }
    }];
}

- (void)archiveIPA {
    
    NSString *signCerIdentity = self.signIdentityButton.selectedItem.title;
    
    NSMenuItem *item = self.profileButton.selectedItem;
    YAProvisioningProfile *profile = objc_getAssociatedObject(item, &kAssociatedProvisioningProfile);
    
    NSString *appVerssion = [NSString stringWithFormat:@"%@_%@_%@",self.majorTextField.stringValue,self.minorTextField.stringValue,self.codeTextField.stringValue];
    
    NSArray *args = @[@"-p",self.prjPath,//项目文件路径
                      @"-n",self.appIDStr,// AppID
                      @"-a",@"XCODE_ARCHIVE", // 操作类型：打包
                      @"-c",((self.signButton.state == NSOnState)?@"NO":@"YES"),
                      @"-s",signCerIdentity,//企业证书
                      @"-f",profile.UUID,//描述文件
                      @"-r",profile.name,//PROVISIONING_PROFILE_SPECIFIER（证书名）
                      @"-o",self.exportOptionsPath,
                      @"-v",appVerssion,//版本号
                      ];

    [self launchShellName:@"xcodebuild" arguments:args completionHandler:^{
        [self updateTimeout];
        
        if (!_alert) {
            if (self.autoGitAction) {
                // git 上传代码
                [self gitButtonClick:self.pushCodeButton];
            }else{
                self.needUpdateCode = NO;
                [self.indicatorView stopAnimation:nil];
            }
        }
        [self isArchiving:NO];
    }];
}

#pragma mark 执行 xcodeBuild
- (void)xcodeBuild {
    if (self.xcodeBuildButton.state == NSOnState) {
        [self startActionLog:@"执行 xcodebuild"];
        NSArray *args = @[@"-p",self.prjPath,
                          @"-n",self.appIDStr,
                          @"-a",@"XCODE_BUILD",
                          ];
        [self launchShellName:@"xcodebuild" arguments:args completionHandler:nil];
    }
}

#pragma mark 运行脚本
- (void)launchShellName:(NSString *)name arguments:(NSArray *)arguments completionHandler:(void (^)(void))handler {
    _alert = nil;
    [self.indicatorView startAnimation:nil];
    [ArchiveHelper launchShellName:name arguments:arguments responeHandler:^(NSString *msg) {
//        printf("%s",[msg UTF8String]);
        if ([msg isEqualToString:SHELL_TERMINATION]) {
            [self.indicatorView stopAnimation:nil];
            [self changeLogStr:@"\n"];
            if (handler) {
                handler();
            }
        }
        else {
            
            if ([msg hasPrefix:SHELL_ERROR]) {
                NSRange range = [msg rangeOfString:SHELL_ERROR];
                NSString *str = [msg substringFromIndex:range.location+range.length];
                [self changeLogStr:str];
                _alert = [ArchiveHelper alertTitle:@"错误！！" message:str forView:[self.view window] completionHandler:nil];
            }
            else{
                [self changeLogStr:msg];
            }
        }
    }failBlock:^(NSString *msg) {
        [self changeLogStr:msg];
    }];
}

#pragma mark 获取AppBundleIdentifier
- (void)getAppBundleIdentifier {
    //选择项目文件后获取 APP ID
    [self startActionLog:@"获取APP ID"];
    self.appIDWarnLabel.hidden = YES;
    
    [ArchiveHelper getAppBundleIdentifierProjectPath:self.prjPath responeHandler:^(NSString *AppBundleIdentifier) {
        if (AppBundleIdentifier.length <= 0) {
            [self changeLogStr:[NSString stringWithFormat:@"===================== APP ID：获取出错 ===================\n"]];
            self.appIDWarnLabel.hidden = NO;
            self.needUpdateCode = NO;
            [self.indicatorView stopAnimation:nil];
            [self.appIDButton becomeFirstResponder];
        }else{
            [self changeLogStr:[NSString stringWithFormat:@"===================== APP ID：%@ ===================\n",AppBundleIdentifier]];
            
            [self.appIDButton addItemWithObjectValue:AppBundleIdentifier];
            
            [self.appIDButton selectItemAtIndex:0];
            self.appIDStr = self.appIDButton.selectedCell.title;
            self.appIDWarnLabel.hidden = YES;
        }
        
        //获取App版本号
        [self getAppVersion:self.prjPath afterGetAppID:YES];
        
        [self loadCerAndProfileData];
        //选择证书
        self.haveSelectProfile = [self selectProfileSuccess:AppBundleIdentifier];
        
        //匹配证书
    } failBlock:^(NSString *msg) {
        [self changeLogStr:[NSString stringWithFormat:@"===================== %@ =====================\n",msg]];
        self.appIDWarnLabel.hidden = NO;
        
        [self.indicatorView stopAnimation:nil];
        self.needUpdateCode = YES;
        self.pullCodeButton.enabled = NO;
    }];
}

#pragma mark 获取AppVersion
- (void)getAppVersion:(NSString *)prjPath afterGetAppID:(BOOL)afterGetAppID {
    [self startActionLog:[NSString stringWithFormat:@"获取%@版本号",self.appIDStr]];
    self.versionWarnLabel.hidden = YES;
    
    [ArchiveHelper getAppVersionProjectPath:prjPath appID:self.appIDStr responeHandler:^(NSString *msg) {
        [self changeLogStr:[NSString stringWithFormat:@"===================== %@ ===================\n",msg]];
        NSRange range = [msg rangeOfString:@"App版本号："];
        NSString *AppVersion = [msg substringFromIndex:range.location+range.length];
        NSArray *array = [AppVersion componentsSeparatedByString:@"."];
        
        self.majorTextField.stringValue = (array.count >= 1)?array[0]:@"1";
        self.minorTextField.stringValue = (array.count >= 2)?array[1]:@"0";
        self.codeTextField.stringValue = (array.count >= 3)?array[2]:@"0";
        
        self.versionWarnLabel.hidden = YES;
        
        if (afterGetAppID) {
            if (self.autoGitAction) {
                //获取 git 最新代码
                [self gitButtonClick:self.pullCodeButton];
            }else{
                self.needUpdateCode = NO;
                [self.indicatorView stopAnimation:nil];
            }
        }
    } failBlock:^(NSString *msg) {
        [self changeLogStr:[NSString stringWithFormat:@"===================== %@ =====================\n",msg]];
        self.versionWarnLabel.hidden = NO;
        if (self.autoGitAction) {
            //获取 git 最新代码
            [self gitButtonClick:self.pullCodeButton];
        }
    }];
}

#pragma mark 选择证书
- (BOOL)selectProfileSuccess:(NSString *)appBundleIdentifier {
    
    BOOL haveProfileSelect = NO;
    //匹配 profile 描述文件
    YAProvisioningProfile *profile = nil;
    for (int i = 0; i < self.profileButton.itemArray.count; i++) {
        NSMenuItem *item = self.profileButton.itemArray[i];
        profile = objc_getAssociatedObject(item, &kAssociatedProvisioningProfile);
        if ([profile.bundleIdentifier isEqualToString:appBundleIdentifier] && ![item.title hasPrefix:@"XC:"] && profile.newest) {
            [self.profileButton selectItemAtIndex:i];
            haveProfileSelect = YES;
            break;
        }
    }
    
    if (!haveProfileSelect) {
        [self.profileButton selectItemAtIndex:self.profileButton.itemArray.count-1];
    }
    
    BOOL haveCerSelect = NO;
    //匹配证书
    if (profile) {
        NSString *selectTitle = [NSString stringWithFormat:@"iPhone Distribution: %@",profile.teamName];
        for (int i = 0; i < self.signIdentityButton.itemArray.count; i++) {
            NSMenuItem *item = self.signIdentityButton.itemArray[i];
            if ([selectTitle isEqualToString:item.title]) {
                [self.signIdentityButton selectItemAtIndex:i];
                haveCerSelect = YES;
                break;
            }
        }
    }
    
    if (!haveCerSelect) {
        [self.signIdentityButton selectItemAtIndex:self.signIdentityButton.itemArray.count-1];
    }
    
    if (haveProfileSelect && haveCerSelect) {
        self.openProjButton.hidden = YES;
        self.signButton.enabled = YES;
        self.signButton.state = NSOnState;
        self.signIdentityButton.enabled = NO;
        self.profileButton.enabled = NO;
        self.signButton.title = @"自动选择默认证书";
        return YES;
    }else{
        self.openProjButton.hidden = NO;
        self.signButton.enabled = NO;
        self.signButton.state = NSOffState;
        self.signIdentityButton.enabled = YES;
        self.profileButton.enabled = YES;
        self.signButton.title = @"❌自动选择证书失败，请打开Xcode项目文件手动选择证书";
        return NO;
    }
}

- (void)changeLogStr:(NSString *)msg {
    if (msg.length > 0) {
        [self.logStr appendString:msg];
        self.logScrollView.string = self.logStr;
    }
}

- (void)startActionLog:(NSString *)log {
    [self changeLogStr:[NSString stringWithFormat:@"\n===================== %@ ===================\n",log]];
}

- (BOOL)projectPathIsNull {
    if (self.projPathScrollView.string.length <= 0) {
        [ArchiveHelper alertTitle:@"请选择项目文件" message:@"请选择项目文件" forView:[self.view window] completionHandler:nil];
        return YES;
    }
    return NO;
}

- (NSString *)timeFormatted:(int)totalSeconds {
    int seconds = totalSeconds % 60;
    int minutes = (totalSeconds / 60) % 60;
    return [NSString stringWithFormat:@"耗时： %02d:%02d", minutes, seconds];
}

-(void)updateTimeout {
    self.timeLabel.stringValue = [self timeFormatted:fabs([_startDate timeIntervalSinceNow])];
}
@end

