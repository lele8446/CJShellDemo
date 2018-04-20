//
//  IPAToolUtls.h
//  AutoIPA
//
//  Created by luo.h on 17/4/25.
//  Copyright © 2017年 apple. All rights reserved.
//

#import <Foundation/Foundation.h>

static NSString *kMobileprovisionDirName = @"Library/MobileDevice/Provisioning Profiles";
typedef void(^SuccessBlock)(id);
typedef void(^ErrorBlock)(NSString*);
typedef void(^LogBlock)(NSString*);
typedef void(^CerListBlock)(NSMutableArray *cerArray);


@interface IPAToolUtls : NSObject

+ (NSArray *)getAllProvisioningProfileList;
+ (NSDictionary *)provisioningProfileAtPath:(NSString *)path;

+ (void)loadCerListBlock:(CerListBlock)listBlock;
+ (NSString *)filePathOfOptionList;

@end
