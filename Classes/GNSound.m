//
//  Sound.rb
//  Gmail Notifr
//
//  Created by James Chen on 8/19/09.
//  Copyright (c) 2009 ashchan.com. All rights reserved.
//

#import "GNSound.h"
@import AppKit.NSSound;

NSString *const GNSoundNone = @"None";

@implementation GNSound

+ (NSArray *)all {
    static NSMutableArray *allSounds;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        allSounds = [[NSMutableArray alloc] init];
        NSArray *knownSoundTypes = [NSSound soundUnfilteredTypes];
        NSArray *libs = NSSearchPathForDirectoriesInDomains(
            NSLibraryDirectory,
            NSUserDomainMask | NSLocalDomainMask | NSSystemDomainMask,
            YES);

        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSWorkspace *workspace = [NSWorkspace sharedWorkspace];
        for (NSString *folder in libs) {
            NSString *folderName = [folder stringByAppendingPathComponent:@"Sounds"];
            BOOL isDir;
            if ([fileManager fileExistsAtPath:folderName isDirectory:&isDir] && isDir) {
                for (NSString *file in [fileManager contentsOfDirectoryAtPath:folderName error:nil]) {
                    NSString *absoluteFile = [folderName stringByAppendingPathComponent:file];
                    NSString *fileType = [workspace typeOfFile:absoluteFile error:nil];
                    if (fileType && [knownSoundTypes containsObject:fileType]) {
                        [allSounds addObject:[file stringByDeletingPathExtension]];
                    }
                }
            }
        }
    });

    return allSounds;
}

@end
