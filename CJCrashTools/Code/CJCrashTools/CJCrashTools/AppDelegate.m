//
//  AppDelegate.m
//  CJCrashTools
//
//  Created by ChiJinLian on 2017/9/10.
//  Copyright © 2017年 ChiJinLian. All rights reserved.
//

#import "AppDelegate.h"
#import "ViewController.h"

@interface AppDelegate ()
@property (strong) ViewController *mainViewController;
@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    self.mainViewController = [[ViewController alloc] initWithWindowNibName:@"ViewController"];
    [self.mainViewController showWindow:self];
}


- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}

@end
