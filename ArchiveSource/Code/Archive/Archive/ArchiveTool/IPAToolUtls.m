//
//  IPAToolUtls.m
//  AutoIPA
//
//  Created by luo.h on 17/4/25.
//  Copyright © 2017年 apple. All rights reserved.
//

#import "IPAToolUtls.h"



@implementation IPAToolUtls

#pragma mark - Signign Certificate
//- (void)getCertificatesSuccess:(SuccessBlock)success error:(ErrorBlock)error
//{
//    successBlock = [success copy];
//    errorBlock = [error copy];
//    [self.certificatesArray removeAllObjects];
//    
//    NSTask *certTask = [[NSTask alloc] init];
//    [certTask setLaunchPath:@"/usr/bin/security"];
//    [certTask setArguments:[NSArray arrayWithObjects:@"find-identity", @"-v", @"-p", @"codesigning", nil]];
//    [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(checkCerts:) userInfo:@{@"task": certTask} repeats:TRUE];
//    NSPipe *pipe = [NSPipe pipe];
//    [certTask setStandardOutput:pipe];
//    [certTask setStandardError:pipe];
//    NSFileHandle *handle = [pipe fileHandleForReading];
//    [certTask launch];
//    [NSThread detachNewThreadSelector:@selector(watchGetCerts:) toTarget:self withObject:handle];
//}





+ (NSArray *)getAllProvisioningProfileList{
    NSString  *path=[NSString stringWithFormat:@"%@/%@", NSHomeDirectory(), kMobileprovisionDirName];
    
    NSFileManager *fileManager=[NSFileManager defaultManager];
    
    NSArray *provisioningProfiles =[fileManager contentsOfDirectoryAtPath:path error:nil];
    provisioningProfiles = [provisioningProfiles filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"pathExtension IN %@",  @[@"mobileprovision", @"provisionprofile"]]];
    
    return provisioningProfiles;
}



//解析provisionprofile
+ (NSDictionary *)provisioningProfileAtPath:(NSString *)path {
    CMSDecoderRef decoder = NULL;
    CFDataRef dataRef = NULL;
    NSString *plistString = nil;
    NSDictionary *plist = nil;
    
    @try {
        CMSDecoderCreate(&decoder);
        NSData *fileData = [NSData dataWithContentsOfFile:path];
        CMSDecoderUpdateMessage(decoder, fileData.bytes, fileData.length);
        CMSDecoderFinalizeMessage(decoder);
        CMSDecoderCopyContent(decoder, &dataRef);
        plistString = [[NSString alloc] initWithData:(__bridge NSData *)dataRef encoding:NSUTF8StringEncoding];
        NSData *plistData = [plistString dataUsingEncoding:NSUTF8StringEncoding];
        
        plist = [NSPropertyListSerialization propertyListWithData:plistData options:NSPropertyListImmutable format:nil error:nil];
    }
    @catch (NSException *exception) {
        NSLog(@"Could not decode file.\n");
    }
    @finally {
        if (decoder) CFRelease(decoder);
        if (dataRef) CFRelease(dataRef);
    }
    
    
    return plist;
}



+ (void)loadCerListBlock:(CerListBlock)listBlock {
    NSDictionary *options = @{(__bridge id)kSecClass: (__bridge id)kSecClassCertificate,
                              (__bridge id)kSecMatchLimit: (__bridge id)kSecMatchLimitAll};
    CFArrayRef certs = NULL;
    __unused OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)options, (CFTypeRef *)&certs);
    NSArray *certificates = CFBridgingRelease(certs);

    NSMutableArray  *tempArray=[NSMutableArray array];
    for (int i=0;i<[certificates count];i++) {
        SecCertificateRef  certificate = (__bridge SecCertificateRef)([certificates objectAtIndex:i]);
        NSString *name =  CFBridgingRelease(SecCertificateCopySubjectSummary(certificate));

        if ([name hasPrefix:@"iPhone Distribution"]||[name hasPrefix:@"iPhone Developer"]) {
            [tempArray addObject:name];
        }
    }
    listBlock(tempArray);
}


+ (NSString *)filePathOfOptionList {
    return [[NSBundle mainBundle] pathForResource:@"ExportOptions.plist" ofType:nil];
}


@end
